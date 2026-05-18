import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Progresso } from '../progresso/progresso.entity';
import { Jogador } from './jogador.entity';

@Injectable()
export class JogadoresService {
  constructor(
    @InjectRepository(Jogador)
    private readonly jogadorRepository: Repository<Jogador>,

    @InjectRepository(Progresso)
    private readonly progressoRepository: Repository<Progresso>,
  ) {}

  async criar(nome: string): Promise<Jogador> {
    if (!nome || nome.trim() === '') {
      throw new BadRequestException('O nome do jogador Ã© obrigatÃ³rio.');
    }

    const jogador = this.jogadorRepository.create({
      nome: nome.trim(),
      pontuacao: 0,
      faseAtual: 1,
    });

    return this.jogadorRepository.save(jogador);
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
      throw new NotFoundException('Jogador nÃ£o encontrado');
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
}
