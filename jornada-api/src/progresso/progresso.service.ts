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

@Injectable()
export class ProgressoService {
  constructor(
    @InjectRepository(Progresso)
    private readonly progressoRepository: Repository<Progresso>,

    @InjectRepository(Jogador)
    private readonly jogadorRepository: Repository<Jogador>,
  ) {}

  async criar(criarProgressoDto: CriarProgressoDto): Promise<Progresso> {
    const { jogadorId, perguntaId, acertou, fase, salaId, salaCodigo } =
      criarProgressoDto;

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
        where: { id: perguntaId },
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

      const pontos = acertou ? this.calcularPontuacao(pergunta, fase) : 0;

      const progresso = progressoRepository.create({
        jogadorId,
        perguntaId,
        salaId: sala?.id ?? null,
        acertou,
        fase,
        pontuacaoGanha: pontos,
        jogador,
        pergunta,
        sala,
      });

      const progressoSalvo = await progressoRepository.save(progresso);

      jogador.pontuacao += pontos;

      if (fase > jogador.faseAtual) {
        jogador.faseAtual = fase;
      }

      await jogadorRepository.save(jogador);

      return progressoSalvo;
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

    return jogadores.map((jogador) =>
      this.montarResumoJogador(
        jogador,
        registros.filter((registro) => registro.jogadorId === jogador.id),
      ),
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
