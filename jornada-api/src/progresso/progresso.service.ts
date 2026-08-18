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
      acertou,
      fase,
      salaId,
      salaCodigo,
      casaAtual,
    } = criarProgressoDto;

    if (!jogadorId || !perguntaId || fase === undefined) {
      throw new BadRequestException('Dados do progresso incompletos.');
    }

    return this.progressoRepository.manager.transaction(async (manager) => {
      const jogadorRepository = manager.getRepository(Jogador);
      const perguntaRepository = manager.getRepository(Pergunta);
      const progressoRepository = manager.getRepository(Progresso);
      const salaRepository = manager.getRepository(Sala);

      const jogador = await jogadorRepository.findOne({
        where: { id: jogadorId },
      });

      if (!jogador) {
        throw new NotFoundException('Jogador não encontrado.');
      }

      const pergunta = await perguntaRepository.findOne({
        where: { id: perguntaId, ativa: true },
      });

      if (!pergunta) {
        throw new NotFoundException('Pergunta não encontrada.');
      }

      let sala: Sala | null = null;
      if (salaId) {
        sala =
          (await salaRepository.findOne({
            where: { id: salaId },
          })) ?? null;
      } else if (salaCodigo) {
        sala =
          (await salaRepository.findOne({
            where: { codigo: salaCodigo.trim().toUpperCase() },
          })) ?? null;
      }

      if ((salaId || salaCodigo) && !sala) {
        throw new NotFoundException('Sala nao encontrada.');
      }

      if (jogador.salaId && sala && jogador.salaId !== sala.id) {
        throw new BadRequestException(
          'O jogador nao pertence a sala informada.',
        );
      }

      if (jogador.salaId && !sala) {
        sala =
          (await salaRepository.findOne({
            where: { id: jogador.salaId },
          })) ?? null;
      }

      if (!jogador.salaId && sala) {
        jogador.salaId = sala.id;
        jogador.sala = sala;
      }

      if (!sala) {
        throw new BadRequestException(
          'O progresso precisa estar vinculado a uma sala.',
        );
      }

      if (!pergunta.salaId || pergunta.salaId !== sala.id) {
        throw new BadRequestException(
          'A pergunta nao pertence a sala informada.',
        );
      }

      const pontuacaoPergunta = this.calcularPontuacao(pergunta, fase);
      const pontos = acertou
        ? pontuacaoPergunta
        : -Math.round(pontuacaoPergunta / 2);
      const casaAtualNormalizada = Math.max(
        1,
        Number(casaAtual ?? jogador.casaAtual ?? 1),
      );
      const statusPartidaNormalizado = this.normalizarStatusDeResposta();

      const progresso = progressoRepository.create({
        jogadorId,
        perguntaId,
        salaId: sala?.id ?? null,
        acertou,
        fase,
        casaAtual: casaAtualNormalizada,
        statusPartida: statusPartidaNormalizado,
        pontuacaoGanha: pontos,
        jogador,
        pergunta,
        sala,
      });

      const progressoSalvo = await progressoRepository.save(progresso);

      await jogadorRepository.update(jogador.id, {
        salaId: sala?.id ?? jogador.salaId ?? null,
        faseAtual: Math.max(jogador.faseAtual, fase),
        casaAtual: Math.max(jogador.casaAtual ?? 1, casaAtualNormalizada),
        statusPartida:
          jogador.statusPartida === PARTIDA_STATUS.FINALIZADO
            ? PARTIDA_STATUS.FINALIZADO
            : statusPartidaNormalizado,
      });
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

    if (!progresso) {
      throw new NotFoundException('Registro de progresso não encontrado.');
    }

    return progresso;
  }

  async buscarPorJogador(jogadorId: number): Promise<Progresso[]> {
    const jogador = await this.jogadorRepository.findOne({
      where: { id: jogadorId },
    });

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
    if (Number.isInteger(pergunta.pontuacao) && pergunta.pontuacao >= 0) {
      return pergunta.pontuacao;
    }

    const dificuldade = Number(pergunta.dificuldade);

    if (Number.isInteger(dificuldade) && dificuldade > 0) {
      return dificuldade * 100;
    }

    return Math.max(1, fase) * 100;
  }

  private normalizarStatusDeResposta(): PartidaStatus {
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
