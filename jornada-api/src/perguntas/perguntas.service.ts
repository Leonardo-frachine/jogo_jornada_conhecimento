import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Pergunta } from './pergunta.entity';
import { AtualizarPerguntaDto } from './dto/atualizar-pergunta.dto';
import { CriarPerguntaDto } from './dto/criar-pergunta.dto';

@Injectable()
export class PerguntasService {
  constructor(
    @InjectRepository(Pergunta)
    private readonly perguntaRepository: Repository<Pergunta>,
  ) {}

  async criar(criarPerguntaDto: CriarPerguntaDto): Promise<Pergunta> {
    this.validarCamposObrigatorios(criarPerguntaDto);

    const pergunta = this.perguntaRepository.create(
      this.montarDadosPergunta(criarPerguntaDto),
    );

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

  async atualizar(
    id: number,
    atualizarPerguntaDto: AtualizarPerguntaDto,
  ): Promise<Pergunta> {
    const pergunta = await this.buscarPorId(id);

    if (Object.keys(atualizarPerguntaDto).length === 0) {
      throw new BadRequestException(
        'Informe ao menos um campo para atualizar.',
      );
    }

    Object.assign(pergunta, this.montarDadosAtualizacao(atualizarPerguntaDto));

    return this.perguntaRepository.save(pergunta);
  }

  async remover(id: number): Promise<{ id: number; removido: true }> {
    const pergunta = await this.buscarPorId(id);

    await this.perguntaRepository.remove(pergunta);

    return { id, removido: true };
  }

  async importarCsv(csv: string): Promise<{
    total: number;
    perguntas: Pergunta[];
  }> {
    const linhas = this.parseCsv(csv);

    if (linhas.length < 2) {
      throw new BadRequestException(
        'CSV deve conter cabeçalho e ao menos uma pergunta.',
      );
    }

    const cabecalho = linhas[0].map((coluna) =>
      this.normalizarCabecalho(coluna),
    );
    const perguntas = linhas
      .slice(1)
      .filter((linha) => linha.some((celula) => celula.trim() !== ''))
      .map((linha, indice) =>
        this.montarPerguntaCsv(cabecalho, linha, indice + 2),
      );

    if (perguntas.length === 0) {
      throw new BadRequestException(
        'Nenhuma pergunta válida foi encontrada no CSV.',
      );
    }

    const perguntasSalvas = await this.perguntaRepository.save(
      perguntas.map((pergunta) => this.perguntaRepository.create(pergunta)),
    );

    return {
      total: perguntasSalvas.length,
      perguntas: perguntasSalvas,
    };
  }

  async exportarCsv(): Promise<string> {
    const perguntas = await this.listar();
    const cabecalho = [
      'Título',
      'Descrição',
      'A',
      'B',
      'C',
      'D',
      'Correta (A-D)',
      'Dificuldade (1-6)',
      'Pontuação',
      'Tempo',
      'Matéria',
    ];

    const linhas = perguntas.map((pergunta) =>
      [
        pergunta.titulo ?? '',
        pergunta.enunciado,
        pergunta.alternativaA,
        pergunta.alternativaB,
        pergunta.alternativaC,
        pergunta.alternativaD,
        pergunta.respostaCorreta,
        pergunta.dificuldade ?? '',
        String(pergunta.pontuacao ?? 0),
        pergunta.tempoLimite ? String(pergunta.tempoLimite) : '',
        pergunta.materia ?? '',
      ]
        .map((valor) => this.escapeCsv(valor))
        .join(','),
    );

    return [
      cabecalho.map((valor) => this.escapeCsv(valor)).join(','),
      ...linhas,
    ].join('\n');
  }

  private validarCamposObrigatorios(dto: CriarPerguntaDto): void {
    if (
      !dto.enunciado ||
      !dto.alternativaA ||
      !dto.alternativaB ||
      !dto.alternativaC ||
      !dto.alternativaD ||
      !dto.respostaCorreta
    ) {
      throw new BadRequestException(
        'Todos os campos principais da pergunta são obrigatórios.',
      );
    }
  }

  private montarDadosPergunta(dto: CriarPerguntaDto): Partial<Pergunta> {
    return {
      titulo: dto.titulo,
      enunciado: dto.enunciado,
      alternativaA: dto.alternativaA,
      alternativaB: dto.alternativaB,
      alternativaC: dto.alternativaC,
      alternativaD: dto.alternativaD,
      respostaCorreta: dto.respostaCorreta,
      materia: dto.materia,
      dificuldade: dto.dificuldade,
      pontuacao: dto.pontuacao ?? this.calcularPontuacaoPadrao(dto.dificuldade),
      tempoLimite: dto.tempoLimite ?? null,
    };
  }

  private montarDadosAtualizacao(dto: AtualizarPerguntaDto): Partial<Pergunta> {
    const dados: Partial<Pergunta> = {};

    for (const [chave, valor] of Object.entries(dto)) {
      if (valor !== undefined) {
        dados[chave as keyof Pergunta] = valor as never;
      }
    }

    return dados;
  }

  private montarPerguntaCsv(
    cabecalho: string[],
    linha: string[],
    numeroLinha: number,
  ): Partial<Pergunta> {
    const valor = (nome: string): string | undefined => {
      const indice = cabecalho.indexOf(nome);
      return indice >= 0 ? linha[indice]?.trim() : undefined;
    };

    const dificuldade = valor('dificuldade16') ?? valor('dificuldade');
    const respostaCorreta = (
      valor('corretaad') ??
      valor('correta') ??
      valor('respostacorreta') ??
      ''
    ).toUpperCase();

    const pergunta: CriarPerguntaDto = {
      titulo: valor('titulo'),
      enunciado:
        valor('descricao') ?? valor('enunciado') ?? valor('titulo') ?? '',
      alternativaA: valor('a') ?? valor('alternativaa') ?? '',
      alternativaB: valor('b') ?? valor('alternativab') ?? '',
      alternativaC: valor('c') ?? valor('alternativac') ?? '',
      alternativaD: valor('d') ?? valor('alternativad') ?? '',
      respostaCorreta,
      dificuldade,
      materia: valor('materia') ?? valor('disciplina'),
      pontuacao: this.parseNumeroOpcional(valor('pontuacao')),
      tempoLimite: this.parseNumeroOpcional(
        valor('tempo') ?? valor('tempolimite'),
      ),
    };

    this.validarCamposObrigatorios(pergunta);

    if (!['A', 'B', 'C', 'D'].includes(pergunta.respostaCorreta)) {
      throw new BadRequestException(
        `Resposta correta inválida na linha ${numeroLinha}. Use A, B, C ou D.`,
      );
    }

    return this.montarDadosPergunta(pergunta);
  }

  private calcularPontuacaoPadrao(dificuldade?: string): number {
    const dificuldadeNumerica = Number(dificuldade);

    if (Number.isInteger(dificuldadeNumerica) && dificuldadeNumerica > 0) {
      return dificuldadeNumerica * 100;
    }

    return 100;
  }

  private parseNumeroOpcional(valor?: string): number | undefined {
    if (!valor) {
      return undefined;
    }

    const numero = Number(valor);

    return Number.isFinite(numero) ? numero : undefined;
  }

  private normalizarCabecalho(cabecalho: string): string {
    return cabecalho
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-zA-Z0-9]/g, '')
      .toLowerCase();
  }

  private parseCsv(csv: string): string[][] {
    const linhas: string[][] = [];
    let linha: string[] = [];
    let celula = '';
    let dentroDeAspas = false;

    for (let indice = 0; indice < csv.length; indice += 1) {
      const caractere = csv[indice];
      const proximo = csv[indice + 1];

      if (caractere === '"' && dentroDeAspas && proximo === '"') {
        celula += '"';
        indice += 1;
        continue;
      }

      if (caractere === '"') {
        dentroDeAspas = !dentroDeAspas;
        continue;
      }

      if (!dentroDeAspas && (caractere === ',' || caractere === ';')) {
        linha.push(celula);
        celula = '';
        continue;
      }

      if (!dentroDeAspas && caractere === '\n') {
        linha.push(celula);
        linhas.push(linha);
        linha = [];
        celula = '';
        continue;
      }

      if (caractere !== '\r') {
        celula += caractere;
      }
    }

    linha.push(celula);
    linhas.push(linha);

    return linhas;
  }

  private escapeCsv(valor: string): string {
    if (!/[",\n\r]/.test(valor)) {
      return valor;
    }

    return `"${valor.replace(/"/g, '""')}"`;
  }
}
