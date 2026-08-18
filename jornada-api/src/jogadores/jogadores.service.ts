import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';
import { Progresso } from '../progresso/progresso.entity';
import { Sala } from '../salas/sala.entity';
import { CriarJogadorDto } from './dto/criar-jogador.dto';
import { FinalizarPartidaDto } from './dto/finalizar-partida.dto';
import { Jogador } from './jogador.entity';
import { PARTIDA_STATUS } from './partida-status';

@Injectable()
export class JogadoresService {
  constructor(
    @InjectRepository(Jogador)
    private readonly jogadorRepository: Repository<Jogador>,

    @InjectRepository(Progresso)
    private readonly progressoRepository: Repository<Progresso>,

    @InjectRepository(Sala)
    private readonly salaRepository: Repository<Sala>,
  ) {}

  async criar(criarJogadorDto: CriarJogadorDto): Promise<Jogador> {
    const nome = this.formatarNome(criarJogadorDto.nome);
    if (!nome) {
      throw new BadRequestException('O nome do jogador e obrigatorio.');
    }

    const sala = await this.resolverSala(
      criarJogadorDto.salaId,
      criarJogadorDto.salaCodigo,
    );

    if (sala) {
      const nomeNormalizado = this.normalizarNome(nome);
      const jogadorExistente = await this.buscarNaSala(
        sala.id,
        nomeNormalizado,
      );

      if (jogadorExistente) {
        return this.iniciarNovaPartida(
          jogadorExistente,
          nome,
          nomeNormalizado,
          sala,
        );
      }

      try {
        return await this.salvarNovoJogador(nome, nomeNormalizado, sala);
      } catch (error) {
        if (!this.ehViolacaoDeUnicidade(error)) {
          throw error;
        }

        const jogadorCriadoEmParalelo = await this.buscarNaSala(
          sala.id,
          nomeNormalizado,
        );
        if (!jogadorCriadoEmParalelo) {
          throw error;
        }

        return this.iniciarNovaPartida(
          jogadorCriadoEmParalelo,
          nome,
          nomeNormalizado,
          sala,
        );
      }
    }

    return this.salvarNovoJogador(nome, null, null);
  }

  private salvarNovoJogador(
    nome: string,
    nomeNormalizado: string | null,
    sala: Sala | null,
  ): Promise<Jogador> {
    const jogador = this.jogadorRepository.create({
      nome,
      nomeNormalizado,
      pontuacao: 0,
      faseAtual: 1,
      salaId: sala?.id ?? null,
      sala: sala ?? null,
      casaAtual: 1,
      statusPartida: PARTIDA_STATUS.INICIADO,
      finalizadoEm: null,
    });

    return this.jogadorRepository.save(jogador);
  }

  private async buscarNaSala(
    salaId: number,
    nomeNormalizado: string,
  ): Promise<Jogador | null> {
    const jogadorNormalizado = await this.jogadorRepository.findOne({
      where: { salaId, nomeNormalizado },
    });
    if (jogadorNormalizado) {
      return jogadorNormalizado;
    }

    // Mantem compatibilidade com alunos criados antes da chave normalizada.
    const jogadoresDaSala = await this.jogadorRepository.find({
      where: { salaId },
      order: { criadoEm: 'ASC', id: 'ASC' },
    });
    return (
      jogadoresDaSala.find(
        (jogador) => this.normalizarNome(jogador.nome) === nomeNormalizado,
      ) ?? null
    );
  }

  private async iniciarNovaPartida(
    jogador: Jogador,
    nome: string,
    nomeNormalizado: string,
    sala: Sala,
  ): Promise<Jogador> {
    jogador.nome = nome;
    jogador.nomeNormalizado = nomeNormalizado;
    jogador.salaId = sala.id;
    jogador.sala = sala;
    jogador.faseAtual = 1;
    jogador.casaAtual = 1;
    jogador.statusPartida = PARTIDA_STATUS.INICIADO;
    jogador.finalizadoEm = null;

    return this.jogadorRepository.save(jogador);
  }

  private formatarNome(nome: string): string {
    return nome?.trim().replace(/\s+/g, ' ') ?? '';
  }

  private normalizarNome(nome: string): string {
    return this.formatarNome(nome).normalize('NFKC').toLocaleLowerCase('pt-BR');
  }

  private ehViolacaoDeUnicidade(error: unknown): boolean {
    if (!(error instanceof QueryFailedError)) {
      return false;
    }

    const driverError = error.driverError as {
      code?: string;
      errno?: number;
    };
    return (
      driverError.code === '23505' ||
      driverError.code?.startsWith('SQLITE_CONSTRAINT') === true ||
      driverError.errno === 19
    );
  }

  async listar(): Promise<Jogador[]> {
    return this.jogadorRepository.find({
      order: {
        pontuacao: 'DESC',
      },
    });
  }

  async buscarPorId(id: number): Promise<Jogador> {
    const jogador = await this.jogadorRepository.findOne({
      where: { id },
    });

    if (!jogador) {
      throw new NotFoundException('Jogador nao encontrado');
    }

    return jogador;
  }

  async recalcularPontuacao(id: number): Promise<Jogador> {
    const jogador = await this.buscarPorId(id);

    const totais = await this.progressoRepository
      .createQueryBuilder('progresso')
      .select('COALESCE(SUM(progresso.pontuacaoGanha), 0)', 'pontuacao')
      .addSelect('COALESCE(MAX(progresso.fase), 1)', 'faseAtual')
      .where('progresso.jogadorId = :id', { id })
      .getRawOne<{ pontuacao: string | number; faseAtual: string | number }>();

    jogador.pontuacao = Number(totais?.pontuacao ?? 0);
    jogador.faseAtual = Math.max(1, Number(totais?.faseAtual ?? 1));

    return this.jogadorRepository.save(jogador);
  }

  async atualizarFase(id: number, faseAtual: number): Promise<Jogador> {
    const jogador = await this.buscarPorId(id);
    jogador.faseAtual = faseAtual;
    return this.jogadorRepository.save(jogador);
  }

  async finalizarPartida(
    id: number,
    finalizarPartidaDto: FinalizarPartidaDto,
  ): Promise<Jogador> {
    const jogador = await this.buscarPorId(id);
    if (
      jogador.statusPartida !== PARTIDA_STATUS.FINALIZADO ||
      !jogador.finalizadoEm
    ) {
      jogador.finalizadoEm = new Date();
    }
    jogador.statusPartida = PARTIDA_STATUS.FINALIZADO;

    if (finalizarPartidaDto.casaAtual !== undefined) {
      jogador.casaAtual = Math.max(
        jogador.casaAtual ?? 1,
        finalizarPartidaDto.casaAtual,
      );
    }

    return this.jogadorRepository.save(jogador);
  }

  private async resolverSala(
    salaId?: number,
    salaCodigo?: string,
  ): Promise<Sala | null> {
    if (salaId) {
      const sala = await this.salaRepository.findOne({
        where: { id: salaId },
      });

      if (!sala) {
        throw new NotFoundException('Sala nao encontrada.');
      }

      return sala;
    }

    if (salaCodigo) {
      const sala = await this.salaRepository.findOne({
        where: { codigo: salaCodigo.trim().toUpperCase() },
      });

      if (!sala) {
        throw new NotFoundException(
          'Sala nao encontrada para o codigo informado.',
        );
      }

      return sala;
    }

    return null;
  }
}
