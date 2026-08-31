import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Jogador } from '../jogadores/jogador.entity';
import { PARTIDA_STATUS } from '../jogadores/partida-status';
import type { PartidaStatus } from '../jogadores/partida-status';
import { Pergunta } from '../perguntas/pergunta.entity';
import { Professor } from '../professores/professor.entity';
import { Progresso } from '../progresso/progresso.entity';
import { CriarSalaDto } from './dto/criar-sala.dto';
import { Sala } from './sala.entity';

type SalaResumo = {
  id: number;
  professorId: number;
  professorNome: string;
  nome: string;
  codigo: string;
  ativa: boolean;
  criadoEm: Date;
};

type AlunoSalaResumo = {
  jogadorId: number;
  nome: string;
  pontuacao: number;
  faseAtual: number;
  casaAtual: number;
  statusPartida: PartidaStatus;
  finalizadoEm: Date | null;
  criadoEm: Date;
};

type RankingSalaItem = {
  posicao: number;
  jogadorId: number;
  nome: string;
  pontuacao: number;
  statusPartida: typeof PARTIDA_STATUS.FINALIZADO;
  finalizadoEm: Date | null;
};

/**
 * Aplica o isolamento por sala e monta as visoes consumidas pelo professor.
 * Consultas de dashboard, alunos, respostas e ranking nunca devem misturar turmas.
 */
@Injectable()
export class SalasService {
  constructor(
    @InjectRepository(Sala)
    private readonly salaRepository: Repository<Sala>,

    @InjectRepository(Professor)
    private readonly professorRepository: Repository<Professor>,

    @InjectRepository(Progresso)
    private readonly progressoRepository: Repository<Progresso>,

    @InjectRepository(Jogador)
    private readonly jogadorRepository: Repository<Jogador>,
  ) {}

  async criar(criarSalaDto: CriarSalaDto): Promise<{
    mensagem: string;
    sala: SalaResumo;
  }> {
    const professor = await this.professorRepository.findOne({
      where: { id: criarSalaDto.professorId },
    });

    // Uma sala sempre pertence a um professor existente.
    if (!professor) {
      throw new NotFoundException('Professor nao encontrado.');
    }

    // Nome omitido recebe um identificador legivel baseado no codigo publico.
    const codigo = await this.gerarCodigoUnico();
    const nomeSala = criarSalaDto.nome?.trim() || `Sala ${codigo}`;

    const sala = this.salaRepository.create({
      professorId: professor.id,
      professor,
      nome: nomeSala,
      codigo,
      ativa: true,
    });

    const salaSalva = await this.salaRepository.save(sala);

    return {
      mensagem: 'Sala criada com sucesso.',
      sala: this.serializarSala(salaSalva, professor.nome),
    };
  }

  async listarPorProfessor(professorId: number): Promise<SalaResumo[]> {
    const professor = await this.professorRepository.findOne({
      where: { id: professorId },
    });

    // Evita que um ID invalido seja interpretado apenas como professor sem salas.
    if (!professor) {
      throw new NotFoundException('Professor nao encontrado.');
    }

    const salas = await this.salaRepository.find({
      where: { professorId },
      order: {
        criadoEm: 'DESC',
      },
    });

    return salas.map((sala) => this.serializarSala(sala, professor.nome));
  }

  async buscarPorId(id: number): Promise<SalaResumo> {
    const sala = await this.salaRepository.findOne({
      where: { id },
      relations: ['professor'],
    });

    // Centraliza o 404 usado pelas telas que abrem uma sala pelo identificador interno.
    if (!sala) {
      throw new NotFoundException('Sala nao encontrada.');
    }

    return this.serializarSala(sala, sala.professor?.nome);
  }

  async buscarPorCodigo(codigo: string): Promise<SalaResumo> {
    // Codigos sao case-insensitive para facilitar a digitacao pelo aluno.
    const codigoNormalizado = codigo.trim().toUpperCase();
    const sala = await this.salaRepository.findOne({
      where: { codigo: codigoNormalizado },
      relations: ['professor'],
    });

    // Um codigo desconhecido nao pode cair em uma sala padrao.
    if (!sala) {
      throw new NotFoundException(
        'Sala nao encontrada para o codigo informado.',
      );
    }

    return this.serializarSala(sala, sala.professor?.nome);
  }

  async obterDashboard(id: number): Promise<{
    sala: SalaResumo;
    indicadores: {
      totalAlunos: number;
      totalPerguntasRespondidas: number;
      quantidadeAcertos: number;
      quantidadeErros: number;
      percentualAcertoTurma: number;
      pontuacaoTotalTurma: number;
    };
    desempenhoPorMateria: Array<{
      materia: string;
      respondidas: number;
      acertos: number;
      erros: number;
      percentualAcerto: number;
    }>;
    desempenhoPorDificuldade: Array<{
      dificuldade: string;
      respondidas: number;
      acertos: number;
      erros: number;
      percentualAcerto: number;
    }>;
    ranking: RankingSalaItem[];
  }> {
    const sala = await this.salaRepository.findOne({
      where: { id },
      relations: ['professor'],
    });

    // O dashboard so pode agregar dados de uma sala valida.
    if (!sala) {
      throw new NotFoundException('Sala nao encontrada.');
    }

    // Respostas ficam filtradas desde a consulta, antes de qualquer agregacao.
    const respostas = await this.progressoRepository.find({
      where: { salaId: sala.id },
      relations: ['jogador', 'pergunta'],
      order: {
        id: 'DESC',
      },
    });

    // Os indicadores derivam da mesma colecao para permanecerem consistentes entre si.
    const totalPerguntasRespondidas = respostas.length;
    const quantidadeAcertos = respostas.filter(
      (resposta) => resposta.acertou,
    ).length;
    const quantidadeErros = totalPerguntasRespondidas - quantidadeAcertos;
    const alunos = await this.montarAlunosDaSala(sala.id, respostas);
    const totalAlunos = alunos.length;
    const pontuacaoTotalTurma = alunos.reduce(
      (soma, aluno) => soma + aluno.pontuacao,
      0,
    );
    const ranking = await this.montarRankingDaSala(sala.id);

    return {
      sala: this.serializarSala(sala, sala.professor?.nome),
      indicadores: {
        totalAlunos,
        totalPerguntasRespondidas,
        quantidadeAcertos,
        quantidadeErros,
        pontuacaoTotalTurma,
        // Turma sem respostas exibe 0%, evitando divisao por zero.
        percentualAcertoTurma:
          totalPerguntasRespondidas === 0
            ? 0
            : Math.round((quantidadeAcertos / totalPerguntasRespondidas) * 100),
      },
      desempenhoPorMateria: this.agruparDesempenho(
        respostas,
        'materia',
      ) as Array<{
        materia: string;
        respondidas: number;
        acertos: number;
        erros: number;
        percentualAcerto: number;
      }>,
      desempenhoPorDificuldade: this.agruparDesempenho(
        respostas,
        'dificuldade',
      ) as Array<{
        dificuldade: string;
        respondidas: number;
        acertos: number;
        erros: number;
        percentualAcerto: number;
      }>,
      ranking,
    };
  }

  async obterRanking(id: number): Promise<{
    sala: SalaResumo;
    ranking: RankingSalaItem[];
  }> {
    const sala = await this.salaRepository.findOne({
      where: { id },
      relations: ['professor'],
    });

    // Confirma a sala antes de montar um ranking possivelmente vazio.
    if (!sala) {
      throw new NotFoundException('Sala nao encontrada.');
    }

    return {
      sala: this.serializarSala(sala, sala.professor?.nome),
      ranking: await this.montarRankingDaSala(sala.id),
    };
  }

  async listarRespostas(id: number): Promise<{
    sala: SalaResumo;
    alunos: AlunoSalaResumo[];
    respostas: Array<{
      progressoId: number;
      jogadorId: number;
      aluno: string;
      perguntaId: number;
      enunciado: string;
      materia: string;
      dificuldade: string;
      acertou: boolean;
      respostaEscolhida: string | null;
      respostaEscolhidaTexto: string | null;
      respostaCorreta: string;
      respostaCorretaTexto: string;
      fase: number;
      casaAtual: number;
      statusPartida: PartidaStatus;
      pontuacaoGanha: number;
      respondidoEm: Date;
    }>;
  }> {
    const sala = await this.salaRepository.findOne({
      where: { id },
      relations: ['professor'],
    });

    // Relatorio detalhado nao existe fora do contexto de uma sala.
    if (!sala) {
      throw new NotFoundException('Sala nao encontrada.');
    }

    const respostas = await this.progressoRepository.find({
      where: { salaId: sala.id },
      relations: ['jogador', 'pergunta'],
      order: {
        id: 'DESC',
      },
    });
    const alunos = await this.montarAlunosDaSala(sala.id, respostas);

    // Serializa valores legados com fallbacks para a interface nunca receber null inesperado.
    return {
      sala: this.serializarSala(sala, sala.professor?.nome),
      alunos,
      respostas: respostas.map((resposta) => ({
        progressoId: resposta.id,
        jogadorId: resposta.jogadorId,
        aluno: resposta.jogador?.nome ?? 'Aluno',
        perguntaId: resposta.perguntaId,
        enunciado: resposta.pergunta?.enunciado ?? '',
        materia: resposta.pergunta?.materia ?? 'Nao informada',
        dificuldade: resposta.pergunta?.dificuldade ?? `Nivel ${resposta.fase}`,
        acertou: resposta.acertou,
        respostaEscolhida: resposta.respostaEscolhida ?? null,
        respostaEscolhidaTexto: resposta.respostaEscolhidaTexto ?? null,
        respostaCorreta:
          resposta.respostaCorretaSnapshot ??
          resposta.pergunta?.respostaCorreta ??
          '',
        respostaCorretaTexto:
          resposta.respostaCorretaTextoSnapshot ??
          this.obterTextoAlternativa(
            resposta.pergunta,
            resposta.respostaCorretaSnapshot ??
              resposta.pergunta?.respostaCorreta,
          ),
        fase: resposta.fase,
        casaAtual: resposta.casaAtual ?? resposta.jogador?.casaAtual ?? 1,
        statusPartida:
          resposta.jogador?.statusPartida ??
          resposta.statusPartida ??
          PARTIDA_STATUS.JOGANDO,
        pontuacaoGanha: resposta.pontuacaoGanha,
        respondidoEm: resposta.criadoEm,
      })),
    };
  }

  async listarAlunos(id: number): Promise<AlunoSalaResumo[]> {
    const sala = await this.salaRepository.findOne({
      where: { id },
    });

    // Diferencia sala vazia de sala inexistente.
    if (!sala) {
      throw new NotFoundException('Sala nao encontrada.');
    }

    const jogadores = await this.jogadorRepository.find({
      where: { salaId: sala.id },
      order: {
        nome: 'ASC',
        id: 'ASC',
      },
    });

    return jogadores.map((jogador) => this.serializarAlunoSala(jogador));
  }

  async remover(id: number): Promise<{
    mensagem: string;
    salaId: number;
    progressosRemovidos: number;
  }> {
    const sala = await this.salaRepository.findOne({
      where: { id },
    });

    // Nao executa deletes parciais para uma sala que nao existe.
    if (!sala) {
      throw new NotFoundException('Sala nao encontrada.');
    }

    // Remove primeiro os eventos dependentes para respeitar a integridade referencial.
    const deletedProgressResult = await this.progressoRepository.delete({
      salaId: sala.id,
    });

    await this.salaRepository.delete(sala.id);

    return {
      mensagem: 'Sala e dados vinculados removidos com sucesso.',
      salaId: sala.id,
      progressosRemovidos: deletedProgressResult.affected ?? 0,
    };
  }

  private async gerarCodigoUnico(): Promise<string> {
    const caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    // Limita tentativas para que uma colisao anormal nao prenda a requisicao indefinidamente.
    for (let tentativa = 0; tentativa < 20; tentativa += 1) {
      let codigo = '';

      // Monta um codigo de seis caracteres, omitindo simbolos visualmente ambiguos.
      for (let indice = 0; indice < 6; indice += 1) {
        const posicao = Math.floor(Math.random() * caracteres.length);
        codigo += caracteres[posicao];
      }

      const salaExistente = await this.salaRepository.findOne({
        where: { codigo },
      });

      // A primeira combinacao ainda nao cadastrada pode ser entregue ao professor.
      if (!salaExistente) {
        return codigo;
      }
    }

    throw new Error('Nao foi possivel gerar um codigo unico para a sala.');
  }

  private serializarSala(sala: Sala, professorNome?: string): SalaResumo {
    // Retorna somente os campos que compoem o contrato publico da sala.
    return {
      id: sala.id,
      professorId: sala.professorId,
      professorNome: professorNome ?? 'Professor',
      nome: sala.nome,
      codigo: sala.codigo,
      ativa: sala.ativa,
      criadoEm: sala.criadoEm,
    };
  }

  private async montarAlunosDaSala(
    salaId: number,
    respostas: Progresso[],
  ): Promise<AlunoSalaResumo[]> {
    const alunosPorId = new Map<number, Jogador>();
    const jogadores = await this.jogadorRepository.find({
      where: { salaId },
      order: {
        criadoEm: 'DESC',
      },
    });

    // Primeiro inclui todos os cadastros atuais, mesmo quem ainda nao respondeu.
    for (const jogador of jogadores) {
      alunosPorId.set(jogador.id, jogador);
    }

    // Depois incorpora jogadores de respostas legadas que nao apareceram na consulta atual.
    for (const resposta of respostas) {
      // O Map elimina duplicatas pelo ID sem descartar o objeto relacionado ja carregado.
      if (resposta.jogador && !alunosPorId.has(resposta.jogador.id)) {
        alunosPorId.set(resposta.jogador.id, resposta.jogador);
      }
    }

    return Array.from(alunosPorId.values()).map((jogador) =>
      this.serializarAlunoSala(jogador),
    );
  }

  private serializarAlunoSala(jogador: Jogador): AlunoSalaResumo {
    // Fallbacks mantem compatibilidade com linhas criadas antes dos novos campos de partida.
    return {
      jogadorId: jogador.id,
      nome: jogador.nome,
      pontuacao: jogador.pontuacao,
      faseAtual: jogador.faseAtual,
      casaAtual: jogador.casaAtual ?? 1,
      statusPartida: jogador.statusPartida ?? PARTIDA_STATUS.INICIADO,
      finalizadoEm: jogador.finalizadoEm ?? null,
      criadoEm: jogador.criadoEm,
    };
  }

  private async montarRankingDaSala(
    salaId: number,
  ): Promise<RankingSalaItem[]> {
    // Somente quem concluiu oficialmente participa do ranking final.
    const finalizados = await this.jogadorRepository.find({
      where: {
        salaId,
        statusPartida: PARTIDA_STATUS.FINALIZADO,
      },
    });
    const alunosUnicos = new Map<string, Jogador>();

    // Deduplica nomes antigos, mantendo a melhor tentativa encontrada para cada aluno.
    for (const jogador of finalizados) {
      const chave = jogador.nome
        .trim()
        .replace(/\s+/g, ' ')
        .toLocaleLowerCase('pt-BR');
      const atual = alunosUnicos.get(chave);
      // Substitui o representante quando a nova linha vence pelos criterios do ranking.
      if (!atual || this.compararJogadoresRanking(jogador, atual) < 0) {
        alunosUnicos.set(chave, jogador);
      }
    }

    return Array.from(alunosUnicos.values())
      .sort((a, b) => this.compararJogadoresRanking(a, b))
      .map((jogador, index) => ({
        posicao: index + 1,
        jogadorId: jogador.id,
        nome: jogador.nome,
        pontuacao: jogador.pontuacao,
        statusPartida: PARTIDA_STATUS.FINALIZADO,
        finalizadoEm: jogador.finalizadoEm ?? null,
      }));
  }

  private compararJogadoresRanking(a: Jogador, b: Jogador): number {
    const diferencaPontuacao = b.pontuacao - a.pontuacao;
    // Pontuacao maior e o primeiro criterio de classificacao.
    if (diferencaPontuacao !== 0) {
      return diferencaPontuacao;
    }

    const terminoA = a.finalizadoEm?.getTime() ?? Number.MAX_SAFE_INTEGER;
    const terminoB = b.finalizadoEm?.getTime() ?? Number.MAX_SAFE_INTEGER;
    // Em empate, quem terminou antes ocupa a melhor posicao.
    if (terminoA !== terminoB) {
      return terminoA - terminoB;
    }

    // Nome e ID tornam o resultado deterministico quando todos os demais dados empatam.
    const diferencaNome = a.nome.localeCompare(b.nome, 'pt-BR');
    return diferencaNome !== 0 ? diferencaNome : a.id - b.id;
  }

  private agruparDesempenho(
    respostas: Progresso[],
    chave: 'materia' | 'dificuldade',
  ): Array<{
    materia?: string;
    dificuldade?: string;
    respondidas: number;
    acertos: number;
    erros: number;
    percentualAcerto: number;
  }> {
    const grupos = new Map<
      string,
      {
        respondidas: number;
        acertos: number;
      }
    >();

    // Cada resposta alimenta exatamente um grupo de materia ou dificuldade.
    for (const resposta of respostas) {
      const valorBruto =
        chave === 'materia'
          ? resposta.pergunta?.materia
          : resposta.pergunta?.dificuldade;
      const nomeGrupo =
        valorBruto && String(valorBruto).trim() !== ''
          ? String(valorBruto).trim()
          : chave === 'materia'
            ? 'Nao informada'
            : `Nivel ${resposta.fase}`;

      // Cria o acumulador somente na primeira ocorrencia do grupo.
      if (!grupos.has(nomeGrupo)) {
        grupos.set(nomeGrupo, {
          respondidas: 0,
          acertos: 0,
        });
      }

      const grupo = grupos.get(nomeGrupo)!;
      grupo.respondidas += 1;
      // Apenas respostas corretas incrementam acertos; erros sao calculados depois.
      if (resposta.acertou) {
        grupo.acertos += 1;
      }
    }

    // Converte os acumuladores internos no formato esperado pelo dashboard.
    return Array.from(grupos.entries()).map(([nomeGrupo, grupo]) => {
      const payload = {
        respondidas: grupo.respondidas,
        acertos: grupo.acertos,
        erros: grupo.respondidas - grupo.acertos,
        percentualAcerto:
          grupo.respondidas === 0
            ? 0
            : Math.round((grupo.acertos / grupo.respondidas) * 100),
      };

      return chave === 'materia'
        ? { materia: nomeGrupo, ...payload }
        : { dificuldade: nomeGrupo, ...payload };
    });
  }

  private obterTextoAlternativa(
    pergunta: Pergunta | undefined,
    letra: string | null | undefined,
  ): string {
    if (!pergunta || !letra) {
      return '';
    }

    const alternativas: Record<string, string> = {
      A: pergunta.alternativaA,
      B: pergunta.alternativaB,
      C: pergunta.alternativaC,
      D: pergunta.alternativaD,
    };

    return alternativas[letra.toUpperCase()] ?? '';
  }
}
