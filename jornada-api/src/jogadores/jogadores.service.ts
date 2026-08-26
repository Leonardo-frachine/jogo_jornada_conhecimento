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
    // Nomes vazios apos trim nao formam um jogador valido.
    if (!nome) {
      throw new BadRequestException('O nome do jogador e obrigatorio.');
    }

    const sala = await this.resolverSala(
      criarJogadorDto.salaId,
      criarJogadorDto.salaCodigo,
    );

    // Com sala informada, o par sala + nome normalizado representa o mesmo aluno.
    if (sala) {
      const nomeNormalizado = this.normalizarNome(nome);
      const jogadorExistente = await this.buscarNaSala(
        sala.id,
        nomeNormalizado,
      );

      // Um aluno recorrente e reutilizado para evitar duplicacao dentro da sala.
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
        // Erros que nao sao concorrencia de cadastro mantem sua causa original.
        if (!this.ehViolacaoDeUnicidade(error)) {
          throw error;
        }

        // Uma requisicao paralela pode ter criado o mesmo aluno entre busca e insert.
        const jogadorCriadoEmParalelo = await this.buscarNaSala(
          sala.id,
          nomeNormalizado,
        );
        // Se a linha concorrente nao for localizada, nao ha recuperacao segura.
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

    // O fluxo legado sem sala continua aceito, mas nao permite deduplicacao por turma.
    return this.salvarNovoJogador(nome, null, null);
  }

  private salvarNovoJogador(
    nome: string,
    nomeNormalizado: string | null,
    sala: Sala | null,
  ): Promise<Jogador> {
    // Todo cadastro novo nasce no inicio do tabuleiro e com partida aguardando inicio.
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
    // O indice normalizado atende rapidamente os cadastros criados no modelo atual.
    if (jogadorNormalizado) {
      return jogadorNormalizado;
    }

    // Percorre cadastros legados porque eles podem nao possuir nomeNormalizado salvo.
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
    // Reaproveita a identidade do aluno e reinicia somente o estado corrente da partida.
    // A pontuacao nao e zerada aqui no modelo atual; alterar isso exige separar tentativas.
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
    // Remove espacos externos e reduz sequencias internas a um unico separador.
    return nome?.trim().replace(/\s+/g, ' ') ?? '';
  }

  private normalizarNome(nome: string): string {
    // A normalizacao Unicode e de caixa torna a comparacao de nomes previsivel.
    return this.formatarNome(nome).normalize('NFKC').toLocaleLowerCase('pt-BR');
  }

  private ehViolacaoDeUnicidade(error: unknown): boolean {
    // Somente erros do driver podem representar uma disputa de chave unica.
    if (!(error instanceof QueryFailedError)) {
      return false;
    }

    const driverError = error.driverError as {
      code?: string;
      errno?: number;
    };
    // Reconhece os codigos equivalentes de Postgres e SQLite.
    return (
      driverError.code === '23505' ||
      driverError.code?.startsWith('SQLITE_CONSTRAINT') === true ||
      driverError.errno === 19
    );
  }

  async listar(): Promise<Jogador[]> {
    // O ranking geral parte sempre da maior pontuacao persistida.
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

    // Os demais metodos reutilizam esta guarda para manter o mesmo erro HTTP 404.
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
    // Atualiza apenas a fase solicitada; validacao de faixa pertence ao DTO.
    const jogador = await this.buscarPorId(id);
    jogador.faseAtual = faseAtual;
    return this.jogadorRepository.save(jogador);
  }

  async finalizarPartida(
    id: number,
    finalizarPartidaDto: FinalizarPartidaDto,
  ): Promise<Jogador> {
    const jogador = await this.buscarPorId(id);
    // A primeira finalizacao registra o instante; repeticoes mantem a data original.
    if (
      jogador.statusPartida !== PARTIDA_STATUS.FINALIZADO ||
      !jogador.finalizadoEm
    ) {
      jogador.finalizadoEm = new Date();
    }
    jogador.statusPartida = PARTIDA_STATUS.FINALIZADO;

    // Nunca recua a casa ao receber uma finalizacao atrasada do cliente.
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
    // O ID tem precedencia quando ambos os identificadores forem enviados.
    if (salaId) {
      const sala = await this.salaRepository.findOne({
        where: { id: salaId },
      });

      // Um ID desconhecido nao pode criar jogador solto silenciosamente.
      if (!sala) {
        throw new NotFoundException('Sala nao encontrada.');
      }

      return sala;
    }

    // O codigo e a alternativa usada pelo aluno na tela de entrada da turma.
    if (salaCodigo) {
      const sala = await this.salaRepository.findOne({
        where: { codigo: salaCodigo.trim().toUpperCase() },
      });

      // Codigo inexistente e erro de entrada, nao cadastro fora de sala.
      if (!sala) {
        throw new NotFoundException(
          'Sala nao encontrada para o codigo informado.',
        );
      }

      return sala;
    }

    // Ausencia dos dois campos preserva compatibilidade com jogadores legados.
    return null;
  }
}
    // Reconstroi os totais a partir do historico, util para reparar dados derivados.
