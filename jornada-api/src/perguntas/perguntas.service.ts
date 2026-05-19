import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as XLSX from 'xlsx';
import { Pergunta } from './pergunta.entity';
import { AtualizarPerguntaDto } from './dto/atualizar-pergunta.dto';
import { CriarPerguntaDto } from './dto/criar-pergunta.dto';
import { SalvarPerguntaGeradaDto } from './dto/salvar-perguntas-geradas.dto';

type SpreadsheetFormat = 'csv' | 'xlsx';
type PerguntaPersistivel = {
  titulo?: string;
  enunciado: string;
  alternativaA: string;
  alternativaB: string;
  alternativaC: string;
  alternativaD: string;
  respostaCorreta: string;
  materia?: string;
  dificuldade?: string;
  pontuacao?: number;
  tempoLimite?: number;
};

@Injectable()
export class PerguntasService {
  private readonly requiredSpreadsheetColumns = [
    'enunciado',
    'alternativaa',
    'alternativab',
    'alternativac',
    'alternativad',
    'respostacorreta',
    'materia',
    'dificuldade',
    'pontuacao',
  ];

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

  async salvarGeradas(perguntasDto: SalvarPerguntaGeradaDto[]): Promise<{
    total: number;
    perguntas: Pergunta[];
  }> {
    if (perguntasDto.length === 0) {
      throw new BadRequestException(
        'Envie ao menos uma pergunta aprovada para salvar.',
      );
    }

    const perguntas = perguntasDto.map((perguntaDto) =>
      this.perguntaRepository.create(this.montarDadosPergunta(perguntaDto)),
    );

    const perguntasSalvas = await this.perguntaRepository.save(perguntas);

    return {
      total: perguntasSalvas.length,
      perguntas: perguntasSalvas,
    };
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
      throw new NotFoundException('Pergunta nao encontrada.');
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
    return this.importarLinhasTabulares(linhas, false);
  }

  async importarPlanilha(
    fileName: string,
    contentBase64: string,
  ): Promise<{
    total: number;
    perguntas: Pergunta[];
    formato: SpreadsheetFormat;
  }> {
    const formato = this.identificarFormatoPlanilha(fileName);
    const arquivo = this.decodificarBase64(contentBase64);
    const linhas =
      formato === 'csv'
        ? this.parseCsv(arquivo.toString('utf-8'))
        : this.parseXlsx(arquivo);

    const resultado = await this.importarLinhasTabulares(linhas, true);

    return {
      ...resultado,
      formato,
    };
  }

  async exportarCsv(): Promise<string> {
    const perguntas = await this.listar();
    const cabecalho = [
      'Titulo',
      'Descricao',
      'A',
      'B',
      'C',
      'D',
      'Correta (A-D)',
      'Dificuldade (1-6)',
      'Pontuacao',
      'Tempo',
      'Materia',
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
        'Todos os campos principais da pergunta sao obrigatorios.',
      );
    }
  }

  private montarDadosPergunta(dto: PerguntaPersistivel): Partial<Pergunta> {
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

  private async importarLinhasTabulares(
    linhas: string[][],
    strictSpreadsheetValidation: boolean,
  ): Promise<{
    total: number;
    perguntas: Pergunta[];
  }> {
    if (linhas.length < 2) {
      throw new BadRequestException(
        'A planilha deve conter cabecalho e ao menos uma pergunta.',
      );
    }

    const cabecalho = linhas[0].map((coluna) =>
      this.normalizarCabecalho(coluna),
    );

    if (strictSpreadsheetValidation) {
      this.validarCabecalhoPlanilha(cabecalho);
    }

    const perguntas = linhas
      .slice(1)
      .filter((linha) => linha.some((celula) => celula.trim() !== ''))
      .map((linha, indice) =>
        this.montarPerguntaTabular(
          cabecalho,
          linha,
          indice + 2,
          strictSpreadsheetValidation,
        ),
      );

    if (perguntas.length === 0) {
      throw new BadRequestException(
        'Nenhuma pergunta valida foi encontrada na planilha.',
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

  private montarPerguntaTabular(
    cabecalho: string[],
    linha: string[],
    numeroLinha: number,
    strictSpreadsheetValidation: boolean,
  ): Partial<Pergunta> {
    const valor = (nomes: string[]): string | undefined => {
      for (const nome of nomes) {
        const indice = cabecalho.indexOf(nome);
        if (indice >= 0) {
          return linha[indice]?.trim();
        }
      }

      return undefined;
    };

    const pontuacao = this.parseNumeroPlanilha(
      valor(['pontuacao']),
      'pontuacao',
      numeroLinha,
      strictSpreadsheetValidation,
      0,
    );
    const tempoLimite = this.parseNumeroPlanilha(
      valor(['tempolimite', 'tempo']),
      'tempoLimite',
      numeroLinha,
      false,
      1,
    );

    const pergunta: CriarPerguntaDto = {
      titulo: valor(['titulo']),
      enunciado:
        valor(['enunciado', 'descricao']) ?? valor(['titulo']) ?? '',
      alternativaA: valor(['alternativaa', 'a']) ?? '',
      alternativaB: valor(['alternativab', 'b']) ?? '',
      alternativaC: valor(['alternativac', 'c']) ?? '',
      alternativaD: valor(['alternativad', 'd']) ?? '',
      respostaCorreta: (
        valor(['respostacorreta', 'corretaad', 'correta']) ?? ''
      ).toUpperCase(),
      materia: valor(['materia', 'disciplina']) ?? '',
      dificuldade:
        valor(['dificuldade', 'dificuldade16'])?.trim() ?? '',
      pontuacao,
      tempoLimite,
    };

    this.validarCamposObrigatorios(pergunta);

    if (strictSpreadsheetValidation) {
      this.validarCamposObrigatoriosPlanilha(pergunta, numeroLinha);
    }

    if (!['A', 'B', 'C', 'D'].includes(pergunta.respostaCorreta)) {
      throw new BadRequestException(
        `Resposta correta invalida na linha ${numeroLinha}. Use A, B, C ou D.`,
      );
    }

    return this.montarDadosPergunta(pergunta);
  }

  private validarCabecalhoPlanilha(cabecalho: string[]): void {
    const colunasAusentes = this.requiredSpreadsheetColumns.filter(
      (coluna) => !cabecalho.includes(coluna),
    );

    if (colunasAusentes.length > 0) {
      throw new BadRequestException(
        `Colunas obrigatorias ausentes na planilha: ${colunasAusentes.join(', ')}.`,
      );
    }
  }

  private validarCamposObrigatoriosPlanilha(
    dto: CriarPerguntaDto,
    numeroLinha: number,
  ): void {
    const camposAusentes: string[] = [];

    if (!dto.materia) {
      camposAusentes.push('materia');
    }

    if (!dto.dificuldade) {
      camposAusentes.push('dificuldade');
    }

    if (dto.pontuacao === undefined || dto.pontuacao === null) {
      camposAusentes.push('pontuacao');
    }

    if (camposAusentes.length > 0) {
      throw new BadRequestException(
        `Campos obrigatorios ausentes na linha ${numeroLinha}: ${camposAusentes.join(', ')}.`,
      );
    }
  }

  private calcularPontuacaoPadrao(dificuldade?: string): number {
    const dificuldadeNumerica = Number(dificuldade);

    if (Number.isInteger(dificuldadeNumerica) && dificuldadeNumerica > 0) {
      return dificuldadeNumerica * 100;
    }

    return 100;
  }

  private parseNumeroPlanilha(
    valor: string | undefined,
    campo: string,
    numeroLinha: number,
    obrigatorio: boolean,
    minimo: number,
  ): number | undefined {
    if (!valor) {
      if (obrigatorio) {
        throw new BadRequestException(
          `Campo ${campo} obrigatorio na linha ${numeroLinha}.`,
        );
      }

      return undefined;
    }

    const numero = Number(valor);
    if (!Number.isFinite(numero) || !Number.isInteger(numero) || numero < minimo) {
      throw new BadRequestException(
        `Valor invalido para ${campo} na linha ${numeroLinha}.`,
      );
    }

    return numero;
  }

  private identificarFormatoPlanilha(fileName: string): SpreadsheetFormat {
    const extensao = fileName.split('.').pop()?.trim().toLowerCase();

    if (extensao === 'csv' || extensao === 'xlsx') {
      return extensao;
    }

    throw new BadRequestException(
      'Formato de arquivo invalido. Use apenas arquivos .csv ou .xlsx.',
    );
  }

  private decodificarBase64(contentBase64: string): Buffer {
    try {
      const arquivo = Buffer.from(contentBase64, 'base64');
      if (arquivo.length === 0) {
        throw new Error('Arquivo vazio');
      }

      return arquivo;
    } catch {
      throw new BadRequestException(
        'Nao foi possivel ler o arquivo enviado para importacao.',
      );
    }
  }

  private parseXlsx(arquivo: Buffer): string[][] {
    const workbook = XLSX.read(arquivo, {
      type: 'buffer',
      cellDates: false,
    });

    const firstSheetName = workbook.SheetNames[0];
    if (!firstSheetName) {
      throw new BadRequestException('A planilha XLSX nao possui abas validas.');
    }

    const worksheet = workbook.Sheets[firstSheetName];
    const rows = XLSX.utils.sheet_to_json<(string | number | boolean | null)[]>(
      worksheet,
      {
        header: 1,
        raw: false,
        defval: '',
      },
    );

    return rows.map((row) => row.map((cell) => String(cell ?? '')));
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
