import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Progresso } from './progresso.entity';
import { Jogador } from '../jogadores/jogador.entity';
import { Pergunta } from '../perguntas/pergunta.entity';
import { CriarProgressoDto } from './dto/criar-progresso.dto';

@Injectable()
export class ProgressoService {
  constructor(
    @InjectRepository(Progresso)
    private readonly progressoRepository: Repository<Progresso>,

    @InjectRepository(Jogador)
    private readonly jogadorRepository: Repository<Jogador>,

    @InjectRepository(Pergunta)
    private readonly perguntaRepository: Repository<Pergunta>,
  ) {}

  async criar(criarProgressoDto: CriarProgressoDto): Promise<Progresso> {
    const { jogadorId, perguntaId, acertou, fase, pontuacaoGanha } =
      criarProgressoDto;

    if (!jogadorId || !perguntaId || fase === undefined) {
      throw new BadRequestException('Dados do progresso incompletos.');
    }

    const jogador = await this.jogadorRepository.findOne({
      where: { id: jogadorId },
    });

    if (!jogador) {
      throw new NotFoundException('Jogador não encontrado.');
    }

    const pergunta = await this.perguntaRepository.findOne({
      where: { id: perguntaId },
    });

    if (!pergunta) {
      throw new NotFoundException('Pergunta não encontrada.');
    }

    const pontos = acertou ? pontuacaoGanha : 0;

    const progresso = this.progressoRepository.create({
      jogadorId,
      perguntaId,
      acertou,
      fase,
      pontuacaoGanha: pontos,
      jogador,
      pergunta,
    });

    const progressoSalvo = await this.progressoRepository.save(progresso);

    jogador.pontuacao += pontos;

    if (fase > jogador.faseAtual) {
      jogador.faseAtual = fase;
    }

    await this.jogadorRepository.save(jogador);

    return progressoSalvo;
  }

  async listar(): Promise<Progresso[]> {
    return this.progressoRepository.find({
      relations: ['jogador', 'pergunta'],
      order: {
        id: 'DESC',
      },
    });
  }

  async buscarPorId(id: number): Promise<Progresso> {
    const progresso = await this.progressoRepository.findOne({
      where: { id },
      relations: ['jogador', 'pergunta'],
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
      relations: ['pergunta'],
      order: {
        id: 'DESC',
      },
    });
  }
}