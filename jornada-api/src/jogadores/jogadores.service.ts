import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Jogador } from './jogador.entity';

@Injectable()
export class JogadoresService {
  constructor(
    @InjectRepository(Jogador)
    private readonly jogadorRepository: Repository<Jogador>,
  ) {}

  async criar(nome: string): Promise<Jogador> {
    if (!nome || nome.trim() === '') {
      throw new BadRequestException('O nome do jogador é obrigatório.');
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
      throw new NotFoundException('Jogador não encontrado');
    }

    return jogador;
  }

  async atualizarPontuacao(id: number, pontuacao: number): Promise<Jogador> {
    const jogador = await this.buscarPorId(id);
    jogador.pontuacao = pontuacao;
    return this.jogadorRepository.save(jogador);
  }

  async atualizarFase(id: number, faseAtual: number): Promise<Jogador> {
    const jogador = await this.buscarPorId(id);
    jogador.faseAtual = faseAtual;
    return this.jogadorRepository.save(jogador);
  }
}