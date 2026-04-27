import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Pergunta } from './pergunta.entity';
import { CriarPerguntaDto } from './dto/criar-pergunta.dto';

@Injectable()
export class PerguntasService {
  constructor(
    @InjectRepository(Pergunta)
    private readonly perguntaRepository: Repository<Pergunta>,
  ) {}

  async criar(criarPerguntaDto: CriarPerguntaDto): Promise<Pergunta> {
    const {
      enunciado,
      alternativaA,
      alternativaB,
      alternativaC,
      alternativaD,
      respostaCorreta,
      materia,
      dificuldade,
    } = criarPerguntaDto;

    if (
      !enunciado ||
      !alternativaA ||
      !alternativaB ||
      !alternativaC ||
      !alternativaD ||
      !respostaCorreta
    ) {
      throw new BadRequestException('Todos os campos principais da pergunta são obrigatórios.');
    }

    const pergunta = this.perguntaRepository.create({
      enunciado: enunciado.trim(),
      alternativaA: alternativaA.trim(),
      alternativaB: alternativaB.trim(),
      alternativaC: alternativaC.trim(),
      alternativaD: alternativaD.trim(),
      respostaCorreta: respostaCorreta.trim().toUpperCase(),
      materia: materia?.trim(),
      dificuldade: dificuldade?.trim(),
    });

    return this.perguntaRepository.save(pergunta);
  }

  async listar(): Promise<Pergunta[]> {
    return this.perguntaRepository.find({
      order: {
        id: 'ASC',
      },
    });
  }

  async buscarPorId(id: number): Promise<Pergunta> {
    const pergunta = await this.perguntaRepository.findOne({
      where: { id },
    });

    if (!pergunta) {
      throw new NotFoundException('Pergunta não encontrada.');
    }

    return pergunta;
  }

  async buscarAleatoria(): Promise<Pergunta> {
    const perguntas = await this.perguntaRepository.find();

    if (perguntas.length === 0) {
      throw new NotFoundException('Nenhuma pergunta cadastrada.');
    }

    const indiceAleatorio = Math.floor(Math.random() * perguntas.length);

    return perguntas[indiceAleatorio];
  }
}