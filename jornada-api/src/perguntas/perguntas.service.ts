import {
  BadRequestException,
  Injectable,
  OnModuleInit,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { DataSource, Repository } from 'typeorm';
import * as XLSX from 'xlsx';
import { Progresso } from '../progresso/progresso.entity';
import { Sala } from '../salas/sala.entity';
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

/**
 * Mantem o banco de perguntas isolado por sala e concentra importacao/exportacao.
 * Exclusoes sao logicas para nao quebrar respostas historicas ja registradas.
 */
@Injectable()
export class PerguntasService implements OnModuleInit {
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
    @InjectRepository(Sala)
    private readonly salaRepository: Repository<Sala>,
    private readonly dataSource: DataSource,
  ) {}

  async onModuleInit(): Promise<void> {
    // A ordem importa: cria dados iniciais, corrige IDs e so depois replica legados por sala.
    await this.semearPerguntasSeNecessario();
    await this.normalizarIdsPerguntasSeNecessario();
    await this.migrarPerguntasLegadasPorSala();
  }

  async criar(criarPerguntaDto: CriarPerguntaDto): Promise<Pergunta> {
    // Valida conteudo e sala antes de construir a entidade persistente.
    this.validarCamposObrigatorios(criarPerguntaDto);
    const sala = await this.validarSalaExistente(criarPerguntaDto.salaId);

    const pergunta = this.perguntaRepository.create(
      this.montarDadosPergunta(criarPerguntaDto, sala),
    );

    return this.perguntaRepository.save(pergunta);
  }

  async salvarGeradas(
    perguntasDto: SalvarPerguntaGeradaDto[],
    salaId: number,
  ): Promise<{
    total: number;
    perguntas: Pergunta[];
  }> {
    // Um lote vazio nao representa uma aprovacao valida do professor.
    if (perguntasDto.length === 0) {
      throw new BadRequestException(
        'Envie ao menos uma pergunta aprovada para salvar.',
      );
    }

    const sala = await this.validarSalaExistente(salaId);
    const perguntas = perguntasDto.map((perguntaDto) =>
      this.perguntaRepository.create(
        this.montarDadosPergunta(perguntaDto, sala),
      ),
    );

    const perguntasSalvas = await this.perguntaRepository.save(perguntas);

    return {
      total: perguntasSalvas.length,
      perguntas: perguntasSalvas,
    };
  }

  async listar(salaId: number): Promise<Pergunta[]> {
    // Confirma a sala e retorna somente perguntas ativas daquela turma.
    await this.validarSalaExistente(salaId);
    return this.perguntaRepository.find({
      where: { salaId, ativa: true },
      order: {
        id: 'ASC',
      },
    });
  }

  async buscarPorId(id: number, salaId: number): Promise<Pergunta> {
    const pergunta = await this.perguntaRepository.findOne({
      where: { id, salaId, ativa: true },
    });

    // O filtro conjunto impede acessar por ID uma pergunta de outra sala.
    if (!pergunta) {
      throw new NotFoundException('Pergunta nao encontrada.');
    }

    return pergunta;
  }

  async buscarAleatoria(salaId: number): Promise<Pergunta> {
    await this.validarSalaExistente(salaId);
    const perguntas = await this.perguntaRepository.find({
      where: { salaId, ativa: true },
    });

    // Sem perguntas ativas o jogo deve avisar, nao tentar sortear indice invalido.
    if (perguntas.length === 0) {
      throw new NotFoundException('Nenhuma pergunta cadastrada nesta sala.');
    }

    const indiceAleatorio = Math.floor(Math.random() * perguntas.length);

    return perguntas[indiceAleatorio];
  }

  async atualizar(
    id: number,
    salaId: number,
    atualizarPerguntaDto: AtualizarPerguntaDto,
  ): Promise<Pergunta> {
    const pergunta = await this.buscarPorId(id, salaId);

    // PATCH sem nenhum campo nao produz mudanca e provavelmente indica erro do cliente.
    if (Object.keys(atualizarPerguntaDto).length === 0) {
      throw new BadRequestException(
        'Informe ao menos um campo para atualizar.',
      );
    }

    Object.assign(pergunta, this.montarDadosAtualizacao(atualizarPerguntaDto));

    return this.perguntaRepository.save(pergunta);
  }

  async remover(
    id: number,
    salaId: number,
  ): Promise<{ id: number; removido: true }> {
    const pergunta = await this.buscarPorId(id, salaId);

    pergunta.ativa = false;
    await this.perguntaRepository.save(pergunta);

    return { id, removido: true };
  }

  async removerTodasDaSala(salaId: number): Promise<{
    salaId: number;
    total: number;
    removido: true;
  }> {
    await this.validarSalaExistente(salaId);
    const resultado = await this.perguntaRepository.update(
      { salaId, ativa: true },
      { ativa: false },
    );

    return {
      salaId,
      total: resultado.affected ?? 0,
      removido: true,
    };
  }

  async importarCsv(
    csv: string,
    salaId: number,
  ): Promise<{
    total: number;
    perguntas: Pergunta[];
  }> {
    const linhas = this.parseCsv(csv);
    const sala = await this.validarSalaExistente(salaId);
    return this.importarLinhasTabulares(linhas, false, sala);
  }

  async importarPlanilha(
    fileName: string,
    contentBase64: string,
    salaId: number,
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

    const sala = await this.validarSalaExistente(salaId);
    const resultado = await this.importarLinhasTabulares(linhas, true, sala);

    return {
      ...resultado,
      formato,
    };
  }

  async exportarCsv(salaId: number): Promise<string> {
    // Exporta exatamente o conjunto ativo visivel no banco da sala.
    const perguntas = await this.listar(salaId);
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

  async validarSalaExistente(salaId: number): Promise<Sala> {
    const sala = await this.salaRepository.findOne({
      where: { id: salaId },
    });

    // Todas as operacoes por sala reutilizam a mesma verificacao de existencia.
    if (!sala) {
      throw new NotFoundException('Sala nao encontrada.');
    }

    return sala;
  }

  private validarCamposObrigatorios(dto: PerguntaPersistivel): void {
    // Enunciado, quatro alternativas e gabarito formam o nucleo minimo jogavel.
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

  private montarDadosPergunta(
    dto: PerguntaPersistivel,
    sala: Sala,
  ): Partial<Pergunta> {
    return {
      salaId: sala.id,
      sala,
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
      ativa: true,
    };
  }

  private montarDadosAtualizacao(dto: AtualizarPerguntaDto): Partial<Pergunta> {
    const dados: Partial<Pergunta> = {};

    // Percorre apenas os campos enviados no PATCH, preservando os demais valores.
    for (const [chave, valor] of Object.entries(dto)) {
      // undefined significa campo ausente; valores falsy validos ainda sao aplicados.
      if (valor !== undefined) {
        dados[chave as keyof Pergunta] = valor as never;
      }
    }

    return dados;
  }

  private async importarLinhasTabulares(
    linhas: string[][],
    strictSpreadsheetValidation: boolean,
    sala: Sala,
  ): Promise<{
    total: number;
    perguntas: Pergunta[];
  }> {
    // A primeira linha e cabecalho; por isso uma unica linha nunca contem pergunta.
    if (linhas.length < 2) {
      throw new BadRequestException(
        'A planilha deve conter cabecalho e ao menos uma pergunta.',
      );
    }

    const cabecalho = linhas[0].map((coluna) =>
      this.normalizarCabecalho(coluna),
    );

    // Planilhas XLSX/CSV do fluxo novo precisam seguir o modelo oficial completo.
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
          sala,
        ),
      );

    // Depois dos filtros, ainda deve existir ao menos uma pergunta importavel.
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
    sala: Sala,
  ): Partial<Pergunta> {
    const valor = (nomes: string[]): string | undefined => {
      // Procura aliases aceitos na ordem de preferencia definida para cada campo.
      for (const nome of nomes) {
        const indice = cabecalho.indexOf(nome);
        // A primeira coluna correspondente fornece o valor normalizado da celula.
        if (indice >= 0) {
          return linha[indice]?.trim();
        }
      }

      // Nenhum alias encontrado deixa o campo ausente para a validacao posterior.
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

    const pergunta: PerguntaPersistivel = {
      titulo: valor(['titulo']),
      enunciado: valor(['enunciado', 'descricao']) ?? valor(['titulo']) ?? '',
      alternativaA: valor(['alternativaa', 'a']) ?? '',
      alternativaB: valor(['alternativab', 'b']) ?? '',
      alternativaC: valor(['alternativac', 'c']) ?? '',
      alternativaD: valor(['alternativad', 'd']) ?? '',
      respostaCorreta: (
        valor(['respostacorreta', 'corretaad', 'correta']) ?? ''
      ).toUpperCase(),
      materia: valor(['materia', 'disciplina']) ?? '',
      dificuldade: valor(['dificuldade', 'dificuldade16'])?.trim() ?? '',
      pontuacao,
      tempoLimite,
    };

    this.validarCamposObrigatorios(pergunta);

    // No modo estrito, materia, dificuldade e pontuacao tambem sao obrigatorios.
    if (strictSpreadsheetValidation) {
      this.validarCamposObrigatoriosPlanilha(pergunta, numeroLinha);
    }

    // O gabarito precisa apontar para uma das quatro alternativas existentes.
    if (!['A', 'B', 'C', 'D'].includes(pergunta.respostaCorreta)) {
      throw new BadRequestException(
        `Resposta correta invalida na linha ${numeroLinha}. Use A, B, C ou D.`,
      );
    }

    return this.montarDadosPergunta(pergunta, sala);
  }

  private validarCabecalhoPlanilha(cabecalho: string[]): void {
    // Calcula todas as ausencias para devolver um unico erro util ao professor.
    const colunasAusentes = this.requiredSpreadsheetColumns.filter(
      (coluna) => !cabecalho.includes(coluna),
    );

    // Qualquer coluna obrigatoria ausente invalida o modelo inteiro.
    if (colunasAusentes.length > 0) {
      throw new BadRequestException(
        `Colunas obrigatorias ausentes na planilha: ${colunasAusentes.join(', ')}.`,
      );
    }
  }

  private validarCamposObrigatoriosPlanilha(
    dto: PerguntaPersistivel,
    numeroLinha: number,
  ): void {
    const camposAusentes: string[] = [];

    // Acumula os campos ausentes para corrigir a linha em uma unica tentativa.
    if (!dto.materia) {
      camposAusentes.push('materia');
    }

    // Dificuldade alimenta nivel, pontuacao padrao e relatorios.
    if (!dto.dificuldade) {
      camposAusentes.push('dificuldade');
    }

    // Zero e valido; somente undefined/null representam pontuacao ausente.
    if (dto.pontuacao === undefined || dto.pontuacao === null) {
      camposAusentes.push('pontuacao');
    }

    // So interrompe a importacao depois de examinar todos os campos obrigatorios.
    if (camposAusentes.length > 0) {
      throw new BadRequestException(
        `Campos obrigatorios ausentes na linha ${numeroLinha}: ${camposAusentes.join(', ')}.`,
      );
    }
  }

  private calcularPontuacaoPadrao(dificuldade?: string): number {
    const dificuldadeNumerica = Number(dificuldade);

    // Dificuldade numerica positiva vale centenas de pontos.
    if (Number.isInteger(dificuldadeNumerica) && dificuldadeNumerica > 0) {
      return dificuldadeNumerica * 100;
    }

    // Texto ou valor ausente recebe o minimo padrao de 100 pontos.
    return 100;
  }

  private parseNumeroPlanilha(
    valor: string | undefined,
    campo: string,
    numeroLinha: number,
    obrigatorio: boolean,
    minimo: number,
  ): number | undefined {
    // Celula vazia so e erro quando o contrato marcou o campo como obrigatorio.
    if (!valor) {
      // Campos obrigatorios nao podem usar o fallback undefined.
      if (obrigatorio) {
        throw new BadRequestException(
          `Campo ${campo} obrigatorio na linha ${numeroLinha}.`,
        );
      }

      return undefined;
    }

    const numero = Number(valor);
    // Rejeita decimais, infinito, texto e valores abaixo do minimo de negocio.
    if (
      !Number.isFinite(numero) ||
      !Number.isInteger(numero) ||
      numero < minimo
    ) {
      throw new BadRequestException(
        `Valor invalido para ${campo} na linha ${numeroLinha}.`,
      );
    }

    return numero;
  }

  private identificarFormatoPlanilha(fileName: string): SpreadsheetFormat {
    const extensao = fileName.split('.').pop()?.trim().toLowerCase();

    // Somente formatos implementados pelos parsers abaixo sao aceitos.
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
      // Buffer vazio indica upload sem conteudo, mesmo que a string fosse decodificavel.
      if (arquivo.length === 0) {
        throw new Error('Arquivo vazio');
      }

      return arquivo;
    } catch {
      // Nao expoe detalhes de decodificacao; informa apenas que o arquivo e ilegivel.
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
    // Usa a primeira aba como fonte; arquivo sem aba nao contem tabela importavel.
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
    // Remove acentos, espacos e pontuacao para comparar variantes do mesmo titulo.
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

    // Percorre caractere a caractere para respeitar separadores e quebras dentro de aspas.
    for (let indice = 0; indice < csv.length; indice += 1) {
      const caractere = csv[indice];
      const proximo = csv[indice + 1];

      // Duas aspas dentro de campo citado representam uma aspa literal.
      if (caractere === '"' && dentroDeAspas && proximo === '"') {
        celula += '"';
        indice += 1;
        continue;
      }

      // Uma aspa simples abre ou fecha o modo de campo citado.
      if (caractere === '"') {
        dentroDeAspas = !dentroDeAspas;
        continue;
      }

      // Virgula e ponto-e-virgula separam celulas somente fora de aspas.
      if (!dentroDeAspas && (caractere === ',' || caractere === ';')) {
        linha.push(celula);
        celula = '';
        continue;
      }

      // Nova linha encerra o registro apenas quando nao faz parte de um texto citado.
      if (!dentroDeAspas && caractere === '\n') {
        linha.push(celula);
        linhas.push(linha);
        linha = [];
        celula = '';
        continue;
      }

      // Ignora retorno de carro para aceitar tanto LF quanto CRLF.
      if (caractere !== '\r') {
        celula += caractere;
      }
    }

    linha.push(celula);
    linhas.push(linha);

    return linhas;
  }

  private escapeCsv(valor: string): string {
    // Texto simples nao precisa de aspas e permanece mais legivel no arquivo exportado.
    if (!/[",\n\r]/.test(valor)) {
      return valor;
    }

    return `"${valor.replace(/"/g, '""')}"`;
  }

  private async migrarPerguntasLegadasPorSala(): Promise<void> {
    // A transacao evita deixar apenas parte das salas com copias das perguntas antigas.
    await this.dataSource.transaction(async (manager) => {
      const perguntaRepository = manager.getRepository(Pergunta);
      const salaRepository = manager.getRepository(Sala);
      const progressoRepository = manager.getRepository(Progresso);
      const totalPerguntasComSala = await perguntaRepository
        .createQueryBuilder('pergunta')
        .where('pergunta.salaId IS NOT NULL')
        .getCount();

      // Se a instalacao ja possui perguntas por sala, considera a migracao inicial executada.
      if (totalPerguntasComSala > 0) {
        return;
      }

      const perguntasLegadas = await perguntaRepository
        .createQueryBuilder('pergunta')
        .where('pergunta.salaId IS NULL')
        .orderBy('pergunta.id', 'ASC')
        .getMany();
      const salas = await salaRepository.find({ order: { id: 'ASC' } });

      // Sem perguntas legadas ou sem salas nao existe destino util para a migracao.
      if (perguntasLegadas.length === 0 || salas.length === 0) {
        return;
      }

      // Replica o banco legado para cada sala, mantendo o conteudo e o estado ativo.
      const copias = salas.flatMap((sala) =>
        perguntasLegadas.map((pergunta) =>
          perguntaRepository.create({
            salaId: sala.id,
            sala,
            titulo: pergunta.titulo,
            enunciado: pergunta.enunciado,
            alternativaA: pergunta.alternativaA,
            alternativaB: pergunta.alternativaB,
            alternativaC: pergunta.alternativaC,
            alternativaD: pergunta.alternativaD,
            respostaCorreta: pergunta.respostaCorreta,
            materia: pergunta.materia,
            dificuldade: pergunta.dificuldade,
            pontuacao: pergunta.pontuacao,
            tempoLimite: pergunta.tempoLimite,
            ativa: pergunta.ativa,
          }),
        ),
      );

      await perguntaRepository.save(copias);

      // Examina cada pergunta antiga para preservar somente as que possuem historico.
      for (const pergunta of perguntasLegadas) {
        const possuiHistorico =
          (await progressoRepository.count({
            where: { perguntaId: pergunta.id },
          })) > 0;

        // Sem respostas vinculadas, a linha original pode ser removida apos as copias.
        if (!possuiHistorico) {
          await perguntaRepository.remove(pergunta);
        }
      }
    });
  }

  private async semearPerguntasSeNecessario(): Promise<void> {
    // Testes e ambientes explicitamente desativados nunca recebem dados automaticos.
    if (
      process.env.NODE_ENV === 'test' ||
      process.env.DB_SEED_DISABLED === 'true'
    ) {
      return;
    }

    const totalPerguntas = await this.perguntaRepository.count();
    // Banco com qualquer pergunta e preservado integralmente.
    if (totalPerguntas > 0) {
      return;
    }

    const configuredSeedPath = process.env.DATABASE_SEED_SQL_PATH?.trim();
    const seedPath =
      configuredSeedPath || path.join('sql', 'perguntas_teste_25.sql');
    const resolvedSeedPath = path.resolve(seedPath);

    // Ausencia do arquivo de seed e aceita como instalacao vazia valida.
    if (!fs.existsSync(resolvedSeedPath)) {
      return;
    }

    const seedSql = fs.readFileSync(resolvedSeedPath, 'utf-8').trim();
    // Arquivo presente mas vazio tambem nao gera consulta SQL sem conteudo.
    if (!seedSql) {
      return;
    }

    await this.dataSource.query(seedSql);
  }

  private async normalizarIdsPerguntasSeNecessario(): Promise<void> {
    const perguntas: Array<{ id: number }> = await this.dataSource.query(
      'SELECT id FROM perguntas ORDER BY id ASC',
    );

    // Postgres nao precisa renumerar IDs; apenas sincroniza a sequencia atual.
    if (!this.usaBancoSqlite()) {
      const maiorId = perguntas.at(-1)?.id ?? 0;
      await this.resetarSequenciaPerguntas(maiorId);
      return;
    }

    // Tabela SQLite vazia deve reiniciar sua proxima chave em 1.
    if (perguntas.length === 0) {
      await this.resetarSequenciaPerguntas(0);
      return;
    }

    const precisaNormalizar = perguntas.some(
      (pergunta, index) => pergunta.id !== index + 1,
    );

    // IDs ja contiguos exigem apenas ajuste da tabela de sequencia.
    if (!precisaNormalizar) {
      await this.resetarSequenciaPerguntas(perguntas.length);
      return;
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();

    try {
      // Desativa FKs temporariamente porque IDs de pergunta e progresso mudam juntos.
      await queryRunner.query('PRAGMA foreign_keys = OFF');
      await queryRunner.startTransaction();

      const mapeamentos = perguntas.map((pergunta, index) => ({
        idAtual: Number(pergunta.id),
        idTemporario: -(index + 1),
        idFinal: index + 1,
      }));

      // Primeiro move todos os IDs para negativos, eliminando colisoes durante a troca.
      for (const mapeamento of mapeamentos) {
        await queryRunner.query('UPDATE perguntas SET id = ? WHERE id = ?', [
          mapeamento.idTemporario,
          mapeamento.idAtual,
        ]);
        await queryRunner.query(
          'UPDATE progresso SET perguntaId = ? WHERE perguntaId = ?',
          [mapeamento.idTemporario, mapeamento.idAtual],
        );
      }

      // Depois converte os IDs temporarios na sequencia final 1..N.
      for (const mapeamento of mapeamentos) {
        await queryRunner.query('UPDATE perguntas SET id = ? WHERE id = ?', [
          mapeamento.idFinal,
          mapeamento.idTemporario,
        ]);
        await queryRunner.query(
          'UPDATE progresso SET perguntaId = ? WHERE perguntaId = ?',
          [mapeamento.idFinal, mapeamento.idTemporario],
        );
      }

      await this.atualizarSequenciaPerguntasComQueryRunner(
        queryRunner,
        mapeamentos.length,
      );

      await queryRunner.commitTransaction();
    } catch (error) {
      // Qualquer falha desfaz todas as renumeracoes de pergunta e progresso.
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      try {
        // Reativa a integridade referencial mesmo quando a transacao falha.
        await queryRunner.query('PRAGMA foreign_keys = ON');
      } finally {
        // O runner sempre precisa liberar sua conexao dedicada.
        await queryRunner.release();
      }
    }
  }

  private async resetarSequenciaPerguntas(seq: number): Promise<void> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();

    try {
      // Reutiliza a implementacao especifica do driver selecionado.
      await this.atualizarSequenciaPerguntasComQueryRunner(queryRunner, seq);
    } finally {
      // Evita vazamento de conexao mesmo se a atualizacao da sequencia falhar.
      await queryRunner.release();
    }
  }

  private async atualizarSequenciaPerguntasComQueryRunner(
    queryRunner: {
      query: (query: string, parameters?: unknown[]) => Promise<unknown>;
    },
    seq: number,
  ): Promise<void> {
    // Postgres usa a sequencia associada a coluna serial/identity.
    if (this.usaBancoPostgres()) {
      // Com registros, marca o maior ID como ja utilizado.
      if (seq > 0) {
        await queryRunner.query(
          "SELECT setval(pg_get_serial_sequence('perguntas', 'id'), $1, true)",
          [seq],
        );
        return;
      }

      await queryRunner.query(
        "SELECT setval(pg_get_serial_sequence('perguntas', 'id'), 1, false)",
      );
      return;
    }

    const tabelas = (await queryRunner.query(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      ['sqlite_sequence'],
    )) as Array<{ name: string }>;

    // Instalacoes sem a tabela interna nao precisam de ajuste manual.
    if (tabelas.length === 0) {
      return;
    }

    await queryRunner.query('DELETE FROM sqlite_sequence WHERE name = ?', [
      'perguntas',
    ]);

    // Tabela vazia permanece sem linha; tabela populada recebe o maior ID atual.
    if (seq > 0) {
      await queryRunner.query(
        'INSERT INTO sqlite_sequence (name, seq) VALUES (?, ?)',
        ['perguntas', seq],
      );
    }
  }

  private usaBancoSqlite(): boolean {
    // Aceita os dois nomes de driver SQLite suportados pelo TypeORM.
    return (
      this.dataSource.options.type === 'better-sqlite3' ||
      this.dataSource.options.type === 'sqlite'
    );
  }

  private usaBancoPostgres(): boolean {
    // Mantem a deteccao de Postgres isolada da logica de sequencias.
    return this.dataSource.options.type === 'postgres';
  }
}
    // Todas as perguntas aprovadas herdam a mesma sala escolhida na geracao.
    // Sorteia uniformemente entre as perguntas disponiveis na sala.
    // Exclusao logica preserva relacionamentos de progresso e relatorios antigos.
    // O update em lote atua apenas nas perguntas ainda ativas da sala informada.
    // CSV legado usa validacao flexivel, mas ainda exige uma sala valida.
    // O nome define o parser e o conteudo base64 e convertido para bytes uma unica vez.
    // A planilha moderna usa validacao estrita de cabecalho e campos.
    // Cada pergunta vira uma linha e cada celula passa pelo escape de CSV.
    // Novas perguntas sempre nascem ativas e vinculadas explicitamente a uma sala.
    // Ignora linhas vazias e informa o numero humano da linha nos erros de validacao.
    // Salva o lote de uma vez para reduzir idas ao banco e evitar resultados parciais comuns.
    // Converte nomes de colunas legados e modernos no mesmo formato interno.
    // Converte todas as celulas para texto para reutilizar o parser tabular comum.
    // Fecha a ultima celula/linha, pois o arquivo pode nao terminar com quebra de linha.
    // Campos especiais recebem aspas e duplicam aspas internas conforme o padrao CSV.
      // Sem registros, configura 1 como o proximo valor ainda nao utilizado.
    // SQLite so possui sqlite_sequence quando alguma tabela autoincrement a criou.
    // Remove o valor antigo antes de inserir a nova sequencia calculada.
