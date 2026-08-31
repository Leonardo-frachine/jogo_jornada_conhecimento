import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Progresso } from './progresso.entity';
import { Jogador } from '../jogadores/jogador.entity';
import { Pergunta } from '../perguntas/pergunta.entity';
import { CriarProgressoDto } from './dto/criar-progresso.dto';
import { Sala } from '../salas/sala.entity';
import { PARTIDA_STATUS, PartidaStatus } from '../jogadores/partida-status';

type ProgressoComPontuacaoTotal = Progresso & {
  pontuacaoTotal: number;
};

/**
 * Registra cada resposta como evento historico e atualiza o estado resumido do jogador.
 * A transacao garante que resposta, posicao, status e pontuacao permaneçam coerentes.
 */
@Injectable()
export class ProgressoService {
  constructor(
    @InjectRepository(Progresso)
    private readonly progressoRepository: Repository<Progresso>,

    @InjectRepository(Jogador)
    private readonly jogadorRepository: Repository<Jogador>,
  ) {}

  async criar(
    criarProgressoDto: CriarProgressoDto,
  ): Promise<ProgressoComPontuacaoTotal> {
    const {
      jogadorId,
      perguntaId,
      fase,
      salaId,
      salaCodigo,
      casaAtual,
      respostaEscolhida,
    } = criarProgressoDto;

    // Rejeita eventos sem as chaves minimas para relacionar jogador, pergunta e fase.
    if (!jogadorId || !perguntaId || fase === undefined) {
      throw new BadRequestException('Dados do progresso incompletos.');
    }

    // Todas as leituras e escritas abaixo usam o mesmo manager transacional.
    return this.progressoRepository.manager.transaction(async (manager) => {
      const jogadorRepository = manager.getRepository(Jogador);
      const perguntaRepository = manager.getRepository(Pergunta);
      const progressoRepository = manager.getRepository(Progresso);
      const salaRepository = manager.getRepository(Sala);

      const jogador = await jogadorRepository.findOne({
        where: { id: jogadorId },
      });

      // Nao registra resposta para uma identidade que deixou de existir.
      if (!jogador) {
        throw new NotFoundException('Jogador não encontrado.');
      }

      const pergunta = await perguntaRepository.findOne({
        where: { id: perguntaId, ativa: true },
      });

      // Apenas perguntas existentes e ativas podem gerar pontos.
      if (!pergunta) {
        throw new NotFoundException('Pergunta não encontrada.');
      }

      let sala: Sala | null = null;
      // Quando ha ID, ele e a referencia prioritaria e nao depende do codigo digitado.
      if (salaId) {
        sala =
          (await salaRepository.findOne({
            where: { id: salaId },
          })) ?? null;
        // Sem ID, resolve o codigo publico informado pelo cliente.
      } else if (salaCodigo) {
        sala =
          (await salaRepository.findOne({
            where: { codigo: salaCodigo.trim().toUpperCase() },
          })) ?? null;
      }

      // Identificador fornecido mas nao resolvido representa sala invalida.
      if ((salaId || salaCodigo) && !sala) {
        throw new NotFoundException('Sala nao encontrada.');
      }

      // Bloqueia o envio de resposta em nome de uma turma diferente da do aluno.
      if (jogador.salaId && sala && jogador.salaId !== sala.id) {
        throw new BadRequestException(
          'O jogador nao pertence a sala informada.',
        );
      }

      // Se o cliente omitiu a sala, recupera a vinculacao persistida no jogador.
      if (jogador.salaId && !sala) {
        sala =
          (await salaRepository.findOne({
            where: { id: jogador.salaId },
          })) ?? null;
      }

      // Vincula cadastros legados sem sala quando a primeira resposta informa a turma.
      if (!jogador.salaId && sala) {
        jogador.salaId = sala.id;
        jogador.sala = sala;
      }

      // Toda resposta nova precisa pertencer a uma turma para manter o isolamento.
      if (!sala) {
        throw new BadRequestException(
          'O progresso precisa estar vinculado a uma sala.',
        );
      }

      // Evita misturar banco de perguntas de outra sala, mesmo com um ID valido.
      if (!pergunta.salaId || pergunta.salaId !== sala.id) {
        throw new BadRequestException(
          'A pergunta nao pertence a sala informada.',
        );
      }

      // Acerto recebe o valor integral; erro desconta metade arredondada.
      const pontuacaoPergunta = this.calcularPontuacao(pergunta, fase);
      const respostaEscolhidaNormalizada =
        respostaEscolhida?.toUpperCase() ?? null;
      // Clientes novos nao conseguem forjar o resultado: o servidor compara a escolha com o gabarito.
      const acertou = respostaEscolhidaNormalizada
        ? respostaEscolhidaNormalizada ===
          pergunta.respostaCorreta.toUpperCase()
        : criarProgressoDto.acertou;
      const pontos = acertou
        ? pontuacaoPergunta
        : -Math.round(pontuacaoPergunta / 2);
      const respostaCorretaNormalizada = pergunta.respostaCorreta.toUpperCase();
      // Posicao nunca pode ser anterior ao inicio do tabuleiro.
      const casaAtualNormalizada = Math.max(
        1,
        Number(casaAtual ?? jogador.casaAtual ?? 1),
      );
      const statusPartidaNormalizado = this.normalizarStatusDeResposta();

      // Salva primeiro o evento imutavel que servira de historico e auditoria.
      const progresso = progressoRepository.create({
        jogadorId,
        perguntaId,
        salaId: sala?.id ?? null,
        acertou,
        respostaEscolhida: respostaEscolhidaNormalizada,
        respostaEscolhidaTexto: this.obterTextoAlternativa(
          pergunta,
          respostaEscolhidaNormalizada,
        ),
        respostaCorretaSnapshot: respostaCorretaNormalizada,
        respostaCorretaTextoSnapshot: this.obterTextoAlternativa(
          pergunta,
          respostaCorretaNormalizada,
        ),
        perguntaTituloSnapshot: pergunta.titulo?.trim() || null,
        perguntaEnunciadoSnapshot: pergunta.enunciado,
        materiaSnapshot: pergunta.materia?.trim() || null,
        dificuldadeSnapshot: pergunta.dificuldade?.trim() || null,
        pontuacaoBaseSnapshot: pontuacaoPergunta,
        fase,
        casaAtual: casaAtualNormalizada,
        statusPartida: statusPartidaNormalizado,
        pontuacaoGanha: pontos,
        jogador,
        pergunta,
        sala,
      });

      const progressoSalvo = await progressoRepository.save(progresso);

      // O resumo do jogador avanca fase/casa e preserva uma partida ja finalizada.
      await jogadorRepository.update(jogador.id, {
        salaId: sala?.id ?? jogador.salaId ?? null,
        faseAtual: Math.max(jogador.faseAtual, fase),
        casaAtual: Math.max(jogador.casaAtual ?? 1, casaAtualNormalizada),
        statusPartida:
          jogador.statusPartida === PARTIDA_STATUS.FINALIZADO
            ? PARTIDA_STATUS.FINALIZADO
            : statusPartidaNormalizado,
      });
      // Increment atomico evita perder pontos quando duas respostas chegam juntas.
      await jogadorRepository.increment(
        { id: jogador.id },
        'pontuacao',
        pontos,
      );
      const jogadorAtualizado = await jogadorRepository.findOneByOrFail({
        id: jogador.id,
      });

      return Object.assign(progressoSalvo, {
        pontuacaoTotal: jogadorAtualizado.pontuacao,
      });
    });
  }

  async listar(): Promise<Progresso[]> {
    // Lista mais recentes primeiro e inclui os dados usados pelos relatorios.
    return this.progressoRepository.find({
      relations: ['jogador', 'pergunta', 'sala'],
      order: {
        id: 'DESC',
      },
    });
  }

  async buscarPorId(id: number): Promise<Progresso> {
    const progresso = await this.progressoRepository.findOne({
      where: { id },
      relations: ['jogador', 'pergunta', 'sala'],
    });

    // Diferencia registro inexistente de uma resposta valida sem relacionamentos.
    if (!progresso) {
      throw new NotFoundException('Registro de progresso não encontrado.');
    }

    return progresso;
  }

  async buscarPorJogador(jogadorId: number): Promise<Progresso[]> {
    const jogador = await this.jogadorRepository.findOne({
      where: { id: jogadorId },
    });

    // Valida a identidade antes de retornar uma lista vazia ambigua.
    if (!jogador) {
      throw new NotFoundException('Jogador não encontrado.');
    }

    return this.progressoRepository.find({
      where: { jogadorId },
      relations: ['pergunta', 'sala'],
      order: {
        id: 'DESC',
      },
    });
  }

  async relatorioJogadores(): Promise<
    Array<{
      jogadorId: number;
      nome: string;
      pontuacao: number;
      faseAtual: number;
      respostas: number;
      acertos: number;
      erros: number;
      aproveitamento: number;
    }>
  > {
    const jogadores = await this.jogadorRepository.find({
      order: {
        pontuacao: 'DESC',
      },
    });
    const registros = await this.progressoRepository.find();

    // Para cada jogador, filtra somente suas respostas antes de calcular os totais.
    return jogadores
      .map((jogador) =>
        this.montarResumoJogador(
          jogador,
          registros.filter((registro) => registro.jogadorId === jogador.id),
        ),
      )
      .sort(
        (a, b) => b.pontuacao - a.pontuacao || a.nome.localeCompare(b.nome),
      );
  }

  async relatorioPorJogador(jogadorId: number): Promise<{
    resumo: {
      jogadorId: number;
      nome: string;
      pontuacao: number;
      faseAtual: number;
      respostas: number;
      acertos: number;
      erros: number;
      aproveitamento: number;
    };
    respostas: Progresso[];
  }> {
    const jogador = await this.jogadorRepository.findOne({
      where: { id: jogadorId },
    });

    // Um relatorio individual so existe para um jogador cadastrado.
    if (!jogador) {
      throw new NotFoundException('Jogador não encontrado.');
    }

    const respostas = await this.progressoRepository.find({
      where: { jogadorId },
      relations: ['pergunta', 'sala'],
      order: {
        id: 'DESC',
      },
    });

    return {
      resumo: this.montarResumoJogador(jogador, respostas),
      respostas,
    };
  }

  private calcularPontuacao(pergunta: Pergunta, fase: number): number {
    // Pontuacao explicita da pergunta sempre vence as regras de fallback.
    if (Number.isInteger(pergunta.pontuacao) && pergunta.pontuacao >= 0) {
      return pergunta.pontuacao;
    }

    const dificuldade = Number(pergunta.dificuldade);

    // Perguntas antigas sem pontuacao usam a dificuldade como multiplicador.
    if (Number.isInteger(dificuldade) && dificuldade > 0) {
      return dificuldade * 100;
    }

    // Ultimo fallback usa a fase, garantindo no minimo 100 pontos-base.
    return Math.max(1, fase) * 100;
  }

  private obterTextoAlternativa(
    pergunta: Pergunta,
    letra?: string | null,
  ): string | null {
    if (!letra) {
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

  private normalizarStatusDeResposta(): PartidaStatus {
    // Responder significa partida em andamento; apenas o encerramento oficial finaliza.
    return PARTIDA_STATUS.JOGANDO;
  }

  private montarResumoJogador(
    jogador: Jogador,
    respostas: Progresso[],
  ): {
    jogadorId: number;
    nome: string;
    pontuacao: number;
    faseAtual: number;
    respostas: number;
    acertos: number;
    erros: number;
    aproveitamento: number;
  } {
    // Conta somente respostas corretas; erros sao derivados do total para fechar a soma.
    const acertos = respostas.filter((resposta) => resposta.acertou).length;
    const total = respostas.length;
    return {
      jogadorId: jogador.id,
      nome: jogador.nome,
      pontuacao: jogador.pontuacao,
      faseAtual: jogador.faseAtual,
      respostas: total,
      acertos,
      erros: total - acertos,
      aproveitamento: total === 0 ? 0 : Math.round((acertos / total) * 100),
    };
  }
}
