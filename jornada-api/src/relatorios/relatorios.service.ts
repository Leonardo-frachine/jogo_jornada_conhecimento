import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Jogador } from '../jogadores/jogador.entity';
import { PARTIDA_STATUS } from '../jogadores/partida-status';
import { Pergunta } from '../perguntas/pergunta.entity';
import { Progresso } from '../progresso/progresso.entity';
import { Sala } from '../salas/sala.entity';
import {
  ClassificacaoDesempenho,
  DesempenhoGrupo,
  QuestaoParaRevisarTurma,
  RelatorioAluno,
  RelatorioSala,
  RelatorioTurma,
  RespostaRelatorio,
} from './relatorios.types';

const CSV_COLUMNS: Array<{
  header: string;
  value: (resposta: RespostaRelatorio) => unknown;
}> = [
  { header: 'progresso_id', value: (item) => item.progressoId },
  { header: 'sala_id', value: (item) => item.salaId },
  { header: 'sala_nome', value: (item) => item.salaNome },
  { header: 'sala_codigo', value: (item) => item.salaCodigo },
  { header: 'professor_id', value: (item) => item.professorId },
  { header: 'professor_nome', value: (item) => item.professorNome },
  { header: 'aluno_id', value: (item) => item.alunoId },
  { header: 'aluno_nome', value: (item) => item.alunoNome },
  { header: 'pergunta_id', value: (item) => item.perguntaId },
  { header: 'pergunta_titulo', value: (item) => item.perguntaTitulo },
  { header: 'pergunta_enunciado', value: (item) => item.perguntaEnunciado },
  { header: 'materia', value: (item) => item.materia },
  { header: 'dificuldade', value: (item) => item.dificuldade },
  { header: 'fase', value: (item) => item.fase },
  { header: 'casa_atual', value: (item) => item.casaAtual },
  {
    header: 'resposta_escolhida_letra',
    value: (item) => item.respostaEscolhidaLetra,
  },
  {
    header: 'resposta_escolhida_texto',
    value: (item) => item.respostaEscolhidaTexto,
  },
  {
    header: 'resposta_correta_letra',
    value: (item) => item.respostaCorretaLetra,
  },
  {
    header: 'resposta_correta_texto',
    value: (item) => item.respostaCorretaTexto,
  },
  { header: 'acertou', value: (item) => item.acertou },
  { header: 'pontuacao_base', value: (item) => item.pontuacaoBase },
  { header: 'pontuacao_ganha', value: (item) => item.pontuacaoGanha },
  {
    header: 'respondido_em',
    value: (item) => item.respondidoEm.toISOString(),
  },
];

@Injectable()
export class RelatoriosService {
  constructor(
    @InjectRepository(Sala)
    private readonly salaRepository: Repository<Sala>,

    @InjectRepository(Jogador)
    private readonly jogadorRepository: Repository<Jogador>,

    @InjectRepository(Progresso)
    private readonly progressoRepository: Repository<Progresso>,
  ) {}

  async obterRelatorioAluno(
    salaId: number,
    jogadorId: number,
    professorId: number,
  ): Promise<RelatorioAluno> {
    const sala = await this.validarSalaDoProfessor(salaId, professorId);
    const jogador = await this.jogadorRepository.findOne({
      where: { id: jogadorId, salaId },
    });

    if (!jogador) {
      throw new NotFoundException('Aluno nao encontrado na sala informada.');
    }

    const progressos = await this.progressoRepository.find({
      where: { salaId, jogadorId },
      relations: ['jogador', 'pergunta'],
      order: { criadoEm: 'ASC', id: 'ASC' },
    });
    const respostas = progressos.map((progresso) =>
      this.normalizarResposta(progresso, sala),
    );
    const acertos = respostas.filter((resposta) => resposta.acertou).length;
    const respondidas = respostas.length;
    const desempenhoPorMateria = this.agruparDesempenho(
      respostas,
      (resposta) => resposta.materia,
    );
    const desempenhoPorDificuldade = this.agruparDesempenho(
      respostas,
      (resposta) => resposta.dificuldade,
    );
    const pontosFortes = desempenhoPorMateria.filter(
      (grupo) => grupo.classificacao === 'ponto_forte',
    );
    const pontosADesenvolver = desempenhoPorMateria.filter(
      (grupo) => grupo.classificacao === 'ponto_a_desenvolver',
    );

    return {
      geradoEm: new Date(),
      sala: { id: sala.id, nome: sala.nome, codigo: sala.codigo },
      professor: { id: sala.professor.id, nome: sala.professor.nome },
      aluno: {
        id: jogador.id,
        nome: jogador.nome,
        statusPartida: jogador.statusPartida,
        faseAtual: jogador.faseAtual,
        casaAtual: jogador.casaAtual,
        finalizadoEm: jogador.finalizadoEm ?? null,
      },
      periodo: {
        inicio: respostas[0]?.respondidoEm ?? null,
        fim: respostas.at(-1)?.respondidoEm ?? null,
      },
      resumo: {
        pontuacao: respostas.reduce(
          (total, resposta) => total + resposta.pontuacaoGanha,
          0,
        ),
        respondidas,
        acertos,
        erros: respondidas - acertos,
        aproveitamento:
          respondidas === 0 ? 0 : Math.round((acertos / respondidas) * 100),
        ultimaAtividade: respostas.at(-1)?.respondidoEm ?? null,
      },
      desempenhoPorMateria,
      desempenhoPorDificuldade,
      pontosFortes,
      pontosADesenvolver,
      recomendacoes: this.montarRecomendacoes(
        desempenhoPorMateria,
        respondidas,
      ),
      respostas,
      erros: respostas.filter((resposta) => !resposta.acertou).reverse(),
    };
  }

  async obterRelatorioSala(
    salaId: number,
    professorId: number,
  ): Promise<RelatorioSala> {
    const sala = await this.validarSalaDoProfessor(salaId, professorId);
    const progressos = await this.progressoRepository.find({
      where: { salaId },
      relations: ['jogador', 'pergunta'],
      order: { criadoEm: 'ASC', id: 'ASC' },
    });

    return {
      geradoEm: new Date(),
      sala: { id: sala.id, nome: sala.nome, codigo: sala.codigo },
      professor: { id: sala.professor.id, nome: sala.professor.nome },
      respostas: progressos.map((progresso) =>
        this.normalizarResposta(progresso, sala),
      ),
    };
  }

  async obterRelatorioTurma(
    salaId: number,
    professorId: number,
  ): Promise<RelatorioTurma> {
    const sala = await this.validarSalaDoProfessor(salaId, professorId);
    const [jogadores, progressos] = await Promise.all([
      this.jogadorRepository.find({
        where: { salaId },
        order: { nome: 'ASC', id: 'ASC' },
      }),
      this.progressoRepository.find({
        where: { salaId },
        relations: ['jogador', 'pergunta'],
        order: { criadoEm: 'ASC', id: 'ASC' },
      }),
    ]);
    const respostas = progressos.map((progresso) =>
      this.normalizarResposta(progresso, sala),
    );
    const respostasPorAluno = new Map<number, RespostaRelatorio[]>();
    for (const resposta of respostas) {
      const historico = respostasPorAluno.get(resposta.alunoId) ?? [];
      historico.push(resposta);
      respostasPorAluno.set(resposta.alunoId, historico);
    }

    const alunos = jogadores
      .map((jogador) => {
        const historico = respostasPorAluno.get(jogador.id) ?? [];
        const acertos = historico.filter((resposta) => resposta.acertou).length;
        const respondidas = historico.length;
        return {
          id: jogador.id,
          nome: jogador.nome,
          statusPartida: jogador.statusPartida,
          faseAtual: jogador.faseAtual,
          casaAtual: jogador.casaAtual,
          pontuacao: historico.reduce(
            (total, resposta) => total + resposta.pontuacaoGanha,
            0,
          ),
          respondidas,
          acertos,
          erros: respondidas - acertos,
          aproveitamento:
            respondidas === 0 ? 0 : Math.round((acertos / respondidas) * 100),
          ultimaAtividade: historico.at(-1)?.respondidoEm ?? null,
          classificacao: this.classificarDesempenho(
            respondidas,
            respondidas === 0 ? 0 : Math.round((acertos / respondidas) * 100),
          ),
        };
      })
      .sort(
        (a, b) =>
          Number(a.respondidas === 0) - Number(b.respondidas === 0) ||
          a.aproveitamento - b.aproveitamento ||
          b.respondidas - a.respondidas ||
          a.nome.localeCompare(b.nome, 'pt-BR'),
      );
    const totalAlunos = alunos.length;
    const alunosComRespostas = alunos.filter(
      (aluno) => aluno.respondidas > 0,
    ).length;
    const finalizados = alunos.filter(
      (aluno) => aluno.statusPartida === PARTIDA_STATUS.FINALIZADO,
    ).length;
    const acertos = respostas.filter((resposta) => resposta.acertou).length;
    const pontuacaoTotal = alunos.reduce(
      (total, aluno) => total + aluno.pontuacao,
      0,
    );

    return {
      geradoEm: new Date(),
      sala: { id: sala.id, nome: sala.nome, codigo: sala.codigo },
      professor: { id: sala.professor.id, nome: sala.professor.nome },
      periodo: {
        inicio: respostas[0]?.respondidoEm ?? null,
        fim: respostas.at(-1)?.respondidoEm ?? null,
      },
      resumo: {
        totalAlunos,
        alunosComRespostas,
        alunosSemRespostas: totalAlunos - alunosComRespostas,
        participacao:
          totalAlunos === 0
            ? 0
            : Math.round((alunosComRespostas / totalAlunos) * 100),
        finalizados,
        emAndamento: totalAlunos - finalizados,
        respondidas: respostas.length,
        acertos,
        erros: respostas.length - acertos,
        aproveitamento:
          respostas.length === 0
            ? 0
            : Math.round((acertos / respostas.length) * 100),
        pontuacaoTotal,
        pontuacaoMedia:
          totalAlunos === 0 ? 0 : Math.round(pontuacaoTotal / totalAlunos),
      },
      desempenhoPorMateria: this.agruparDesempenho(
        respostas,
        (resposta) => resposta.materia,
      ),
      desempenhoPorDificuldade: this.agruparDesempenho(
        respostas,
        (resposta) => resposta.dificuldade,
      ),
      alunos,
      questoesParaRevisar: this.agruparQuestoesParaRevisar(respostas),
    };
  }

  gerarCsv(relatorio: RelatorioSala): Buffer {
    const linhas = [
      CSV_COLUMNS.map((coluna) => coluna.header).join(','),
      ...relatorio.respostas.map((resposta) =>
        CSV_COLUMNS.map((coluna) =>
          this.serializarCelulaCsv(coluna.value(resposta)),
        ).join(','),
      ),
    ];

    return Buffer.from(`\uFEFF${linhas.join('\r\n')}\r\n`, 'utf-8');
  }

  nomeArquivoPdf(relatorio: RelatorioAluno): string {
    return `relatorio_${this.sanitizarNomeArquivo(relatorio.aluno.nome)}_${this.sanitizarNomeArquivo(relatorio.sala.nome)}_${this.dataArquivo(relatorio.geradoEm)}.pdf`;
  }

  nomeArquivoCsv(relatorio: RelatorioSala): string {
    return `desempenho_${this.sanitizarNomeArquivo(relatorio.sala.nome)}_${this.dataArquivo(relatorio.geradoEm)}.csv`;
  }

  nomeArquivoPdfTurma(relatorio: RelatorioTurma): string {
    return `relatorio_turma_${this.sanitizarNomeArquivo(relatorio.sala.nome)}_${this.dataArquivo(relatorio.geradoEm)}.pdf`;
  }

  private async validarSalaDoProfessor(
    salaId: number,
    professorId: number,
  ): Promise<Sala> {
    const sala = await this.salaRepository.findOne({
      where: { id: salaId },
      relations: ['professor'],
    });

    if (!sala) {
      throw new NotFoundException('Sala nao encontrada.');
    }

    if (sala.professorId !== professorId) {
      throw new ForbiddenException(
        'O professor nao possui acesso aos relatorios desta sala.',
      );
    }

    return sala;
  }

  private normalizarResposta(
    progresso: Progresso,
    sala: Sala,
  ): RespostaRelatorio {
    const pergunta = progresso.pergunta;
    const respostaEscolhidaLetra = progresso.respostaEscolhida ?? null;
    const respostaCorretaLetra =
      progresso.respostaCorretaSnapshot ?? pergunta?.respostaCorreta ?? '';
    const materia =
      progresso.materiaSnapshot?.trim() ||
      pergunta?.materia?.trim() ||
      'Nao informada';
    const dificuldade =
      progresso.dificuldadeSnapshot?.trim() ||
      pergunta?.dificuldade?.trim() ||
      `Nivel ${progresso.fase}`;

    return {
      progressoId: progresso.id,
      salaId: sala.id,
      salaNome: sala.nome,
      salaCodigo: sala.codigo,
      professorId: sala.professor.id,
      professorNome: sala.professor.nome,
      alunoId: progresso.jogadorId,
      alunoNome: progresso.jogador?.nome ?? 'Aluno',
      perguntaId: progresso.perguntaId,
      perguntaTitulo:
        progresso.perguntaTituloSnapshot ?? pergunta?.titulo ?? '',
      perguntaEnunciado:
        progresso.perguntaEnunciadoSnapshot ?? pergunta?.enunciado ?? '',
      materia,
      dificuldade,
      fase: progresso.fase,
      casaAtual: progresso.casaAtual,
      respostaEscolhidaLetra,
      respostaEscolhidaTexto:
        progresso.respostaEscolhidaTexto ??
        this.obterTextoAlternativa(pergunta, respostaEscolhidaLetra),
      respostaCorretaLetra,
      respostaCorretaTexto:
        progresso.respostaCorretaTextoSnapshot ??
        this.obterTextoAlternativa(pergunta, respostaCorretaLetra) ??
        '',
      acertou: progresso.acertou,
      pontuacaoBase:
        progresso.pontuacaoBaseSnapshot ??
        pergunta?.pontuacao ??
        Math.abs(progresso.pontuacaoGanha) * (progresso.acertou ? 1 : 2),
      pontuacaoGanha: progresso.pontuacaoGanha,
      respondidoEm: progresso.criadoEm,
    };
  }

  private obterTextoAlternativa(
    pergunta: Pergunta | undefined,
    letra: string | null | undefined,
  ): string | null {
    if (!pergunta || !letra) {
      return null;
    }

    const alternativas: Record<string, string> = {
      A: pergunta.alternativaA,
      B: pergunta.alternativaB,
      C: pergunta.alternativaC,
      D: pergunta.alternativaD,
    };

    return alternativas[letra.toUpperCase()]?.trim() || null;
  }

  private agruparDesempenho(
    respostas: RespostaRelatorio[],
    selecionarGrupo: (resposta: RespostaRelatorio) => string,
  ): DesempenhoGrupo[] {
    const acumuladores = new Map<
      string,
      { respondidas: number; acertos: number }
    >();

    for (const resposta of respostas) {
      const nome = selecionarGrupo(resposta).trim() || 'Nao informada';
      const acumulador = acumuladores.get(nome) ?? {
        respondidas: 0,
        acertos: 0,
      };
      acumulador.respondidas += 1;
      acumulador.acertos += resposta.acertou ? 1 : 0;
      acumuladores.set(nome, acumulador);
    }

    return Array.from(acumuladores.entries())
      .map(([nome, acumulador]) => {
        const percentualAcerto = Math.round(
          (acumulador.acertos / acumulador.respondidas) * 100,
        );
        return {
          nome,
          respondidas: acumulador.respondidas,
          acertos: acumulador.acertos,
          erros: acumulador.respondidas - acumulador.acertos,
          percentualAcerto,
          classificacao: this.classificarDesempenho(
            acumulador.respondidas,
            percentualAcerto,
          ),
        };
      })
      .sort(
        (a, b) =>
          b.percentualAcerto - a.percentualAcerto ||
          a.nome.localeCompare(b.nome, 'pt-BR'),
      );
  }

  private agruparQuestoesParaRevisar(
    respostas: RespostaRelatorio[],
  ): QuestaoParaRevisarTurma[] {
    const grupos = new Map<
      number,
      {
        referencia: RespostaRelatorio;
        respondidas: number;
        erros: number;
      }
    >();

    for (const resposta of respostas) {
      const grupo = grupos.get(resposta.perguntaId) ?? {
        referencia: resposta,
        respondidas: 0,
        erros: 0,
      };
      grupo.respondidas += 1;
      grupo.erros += resposta.acertou ? 0 : 1;
      grupos.set(resposta.perguntaId, grupo);
    }

    return Array.from(grupos.values())
      .filter((grupo) => grupo.erros > 0)
      .map((grupo) => ({
        perguntaId: grupo.referencia.perguntaId,
        titulo: grupo.referencia.perguntaTitulo,
        enunciado: grupo.referencia.perguntaEnunciado,
        materia: grupo.referencia.materia,
        dificuldade: grupo.referencia.dificuldade,
        respondidas: grupo.respondidas,
        erros: grupo.erros,
        percentualErro: Math.round((grupo.erros / grupo.respondidas) * 100),
      }))
      .sort(
        (a, b) =>
          b.erros - a.erros ||
          b.percentualErro - a.percentualErro ||
          a.titulo.localeCompare(b.titulo, 'pt-BR'),
      )
      .slice(0, 8);
  }

  private classificarDesempenho(
    respondidas: number,
    percentualAcerto: number,
  ): ClassificacaoDesempenho {
    if (respondidas < 3) {
      return 'amostra_insuficiente';
    }
    if (percentualAcerto >= 75) {
      return 'ponto_forte';
    }
    if (percentualAcerto < 50) {
      return 'ponto_a_desenvolver';
    }
    return 'em_desenvolvimento';
  }

  private montarRecomendacoes(
    materias: DesempenhoGrupo[],
    totalRespostas: number,
  ): string[] {
    if (totalRespostas === 0) {
      return [
        'Ainda nao ha respostas registradas para produzir uma analise pedagogica.',
      ];
    }

    const recomendacoes: string[] = [];
    const pontosADesenvolver = materias.filter(
      (grupo) => grupo.classificacao === 'ponto_a_desenvolver',
    );
    const emDesenvolvimento = materias.filter(
      (grupo) => grupo.classificacao === 'em_desenvolvimento',
    );
    const pontosFortes = materias.filter(
      (grupo) => grupo.classificacao === 'ponto_forte',
    );

    if (pontosADesenvolver.length > 0) {
      recomendacoes.push(
        `Priorizar a revisao de ${pontosADesenvolver
          .slice(0, 3)
          .map((grupo) => grupo.nome)
          .join(', ')}, retomando os conceitos das questoes incorretas.`,
      );
    } else if (emDesenvolvimento.length > 0) {
      recomendacoes.push(
        `Consolidar ${emDesenvolvimento
          .slice(0, 3)
          .map((grupo) => grupo.nome)
          .join(
            ', ',
          )} com atividades graduais e nova verificacao de aprendizagem.`,
      );
    }

    if (pontosFortes.length > 0) {
      recomendacoes.push(
        `Manter e ampliar o bom desempenho em ${pontosFortes
          .slice(0, 3)
          .map((grupo) => grupo.nome)
          .join(', ')} com desafios de dificuldade progressiva.`,
      );
    }

    if (materias.every((grupo) => grupo.respondidas < 3)) {
      recomendacoes.push(
        'Coletar ao menos tres respostas por materia antes de concluir quais sao os pontos fortes e as dificuldades.',
      );
    }

    return recomendacoes.length > 0
      ? recomendacoes
      : [
          'Manter o acompanhamento e aplicar novas atividades para observar a evolucao.',
        ];
  }

  private serializarCelulaCsv(value: unknown): string {
    if (value === null || value === undefined) {
      return '';
    }

    let texto: string;
    switch (typeof value) {
      case 'string':
        texto = value;
        break;
      case 'number':
      case 'boolean':
      case 'bigint':
        texto = value.toString();
        break;
      default:
        throw new TypeError('Tipo de valor nao suportado no CSV.');
    }
    // Evita que nomes e enunciados sejam interpretados como formulas por planilhas.
    if (/^[=+@]/.test(texto) || /^-\D/.test(texto)) {
      texto = `'${texto}`;
    }

    return /[",\r\n]/.test(texto) ? `"${texto.replace(/"/g, '""')}"` : texto;
  }

  private sanitizarNomeArquivo(value: string): string {
    const normalizado = value
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-zA-Z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '')
      .toLowerCase();
    return normalizado || 'relatorio';
  }

  private dataArquivo(value: Date): string {
    return new Intl.DateTimeFormat('en-CA', {
      timeZone: 'America/Sao_Paulo',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(value);
  }
}
