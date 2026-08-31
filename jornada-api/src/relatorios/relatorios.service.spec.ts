import { ForbiddenException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { Jogador } from '../jogadores/jogador.entity';
import { Pergunta } from '../perguntas/pergunta.entity';
import { Professor } from '../professores/professor.entity';
import { Progresso } from '../progresso/progresso.entity';
import { ProgressoService } from '../progresso/progresso.service';
import { Sala } from '../salas/sala.entity';
import { RelatorioPdfService } from './relatorio-pdf.service';
import { RelatoriosService } from './relatorios.service';

describe('RelatoriosService', () => {
  let moduleRef: TestingModule;
  let dataSource: DataSource;
  let progressoService: ProgressoService;
  let relatoriosService: RelatoriosService;
  let pdfService: RelatorioPdfService;

  beforeEach(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [
        TypeOrmModule.forRoot({
          type: 'better-sqlite3',
          database: ':memory:',
          entities: [Pergunta, Progresso, Jogador, Sala, Professor],
          synchronize: true,
          retryAttempts: 0,
        }),
        TypeOrmModule.forFeature([
          Pergunta,
          Progresso,
          Jogador,
          Sala,
          Professor,
        ]),
      ],
      providers: [ProgressoService, RelatoriosService, RelatorioPdfService],
    }).compile();

    dataSource = moduleRef.get(DataSource);
    progressoService = moduleRef.get(ProgressoService);
    relatoriosService = moduleRef.get(RelatoriosService);
    pdfService = moduleRef.get(RelatorioPdfService);
  });

  afterEach(async () => {
    await moduleRef.close();
  });

  it('calcula acerto pela escolha e preserva o snapshot da pergunta', async () => {
    const { sala, professor, jogador } = await criarContexto();
    const pergunta = await criarPergunta(sala, {
      titulo: 'Fracoes equivalentes',
      enunciado: 'Qual fracao equivale a um meio?',
      materia: 'Matematica',
      respostaCorreta: 'B',
    });

    const progresso = await progressoService.criar({
      jogadorId: jogador.id,
      perguntaId: pergunta.id,
      acertou: true,
      respostaEscolhida: 'A',
      fase: 2,
      salaId: sala.id,
    });
    expect(progresso.acertou).toBe(false);
    expect(progresso.respostaEscolhida).toBe('A');
    expect(progresso.respostaEscolhidaTexto).toBe('Opcao A');
    expect(progresso.respostaCorretaTextoSnapshot).toBe('Opcao B');

    await dataSource.getRepository(Pergunta).update(pergunta.id, {
      enunciado: 'Enunciado alterado depois da resposta',
      materia: 'Materia alterada',
      respostaCorreta: 'D',
    });
    const relatorio = await relatoriosService.obterRelatorioAluno(
      sala.id,
      jogador.id,
      professor.id,
    );

    expect(relatorio.erros[0]).toMatchObject({
      perguntaEnunciado: 'Qual fracao equivale a um meio?',
      materia: 'Matematica',
      respostaEscolhidaLetra: 'A',
      respostaCorretaLetra: 'B',
    });
  });

  it('classifica pontos fortes e pontos a desenvolver somente com amostra suficiente', async () => {
    const { sala, professor, jogador } = await criarContexto();
    const matematica = await criarPergunta(sala, {
      materia: 'Matematica',
      respostaCorreta: 'A',
    });
    const historia = await criarPergunta(sala, {
      materia: 'Historia',
      respostaCorreta: 'D',
    });
    const ciencias = await criarPergunta(sala, {
      materia: 'Ciencias',
      respostaCorreta: 'B',
    });

    for (let indice = 0; indice < 3; indice += 1) {
      await responder(jogador, sala, matematica, 'A');
      await responder(jogador, sala, historia, 'A');
    }
    await responder(jogador, sala, ciencias, 'B');

    const relatorio = await relatoriosService.obterRelatorioAluno(
      sala.id,
      jogador.id,
      professor.id,
    );

    expect(relatorio.resumo).toMatchObject({
      respondidas: 7,
      acertos: 4,
      erros: 3,
      aproveitamento: 57,
    });
    expect(relatorio.pontosFortes.map((grupo) => grupo.nome)).toEqual([
      'Matematica',
    ]);
    expect(relatorio.pontosADesenvolver.map((grupo) => grupo.nome)).toEqual([
      'Historia',
    ]);
    expect(
      relatorio.desempenhoPorMateria.find((grupo) => grupo.nome === 'Ciencias')
        ?.classificacao,
    ).toBe('amostra_insuficiente');
  });

  it('gera CSV UTF-8 valido com uma linha por resposta e campos escapados', async () => {
    const { sala, professor, jogador } = await criarContexto();
    const pergunta = await criarPergunta(sala, {
      titulo: 'Texto, aspas e acentos',
      enunciado: 'O aluno disse "olá". Qual opção está correta?',
      materia: 'Língua Portuguesa',
      respostaCorreta: 'C',
    });
    await responder(jogador, sala, pergunta, 'C');

    const relatorio = await relatoriosService.obterRelatorioSala(
      sala.id,
      professor.id,
    );
    const csv = relatoriosService.gerarCsv(relatorio);
    const texto = csv.toString('utf-8');

    expect(csv.subarray(0, 3)).toEqual(Buffer.from([0xef, 0xbb, 0xbf]));
    expect(texto).toContain('progresso_id,sala_id,sala_nome');
    expect(texto).toContain('"Texto, aspas e acentos"');
    expect(texto).toContain(
      '"O aluno disse ""olá"". Qual opção está correta?"',
    );
    expect(texto.trim().split('\r\n')).toHaveLength(2);
  });

  it('gera PDF paginado com assinatura e conteudo relevante', async () => {
    const { sala, professor, jogador } = await criarContexto();
    const pergunta = await criarPergunta(sala, {
      titulo: 'Conhecimentos gerais',
      enunciado: 'Qual alternativa representa a resposta correta?',
      materia: 'Conhecimentos Gerais',
      respostaCorreta: 'B',
    });

    for (let indice = 0; indice < 12; indice += 1) {
      await responder(jogador, sala, pergunta, indice % 3 === 0 ? 'B' : 'A');
    }

    const relatorio = await relatoriosService.obterRelatorioAluno(
      sala.id,
      jogador.id,
      professor.id,
    );
    const pdf = await pdfService.gerar(relatorio);

    expect(pdf.subarray(0, 5).toString('ascii')).toBe('%PDF-');
    expect(pdf.length).toBeGreaterThan(20_000);
    expect(pdf.toString('latin1')).toContain('/Type /Page');
  });

  it('exporta estados vazios validos para aluno e sala sem respostas', async () => {
    const { sala, professor, jogador } = await criarContexto();
    const relatorioAluno = await relatoriosService.obterRelatorioAluno(
      sala.id,
      jogador.id,
      professor.id,
    );
    const relatorioSala = await relatoriosService.obterRelatorioSala(
      sala.id,
      professor.id,
    );
    const csv = relatoriosService.gerarCsv(relatorioSala).toString('utf-8');
    const pdf = await pdfService.gerar(relatorioAluno);

    expect(relatorioAluno.resumo).toMatchObject({
      respondidas: 0,
      acertos: 0,
      erros: 0,
      aproveitamento: 0,
    });
    expect(relatorioAluno.periodo).toEqual({ inicio: null, fim: null });
    expect(csv.trim().split('\r\n')).toHaveLength(1);
    expect(pdf.subarray(0, 5).toString('ascii')).toBe('%PDF-');
  });

  it('bloqueia exportacao quando a sala pertence a outro professor', async () => {
    const { sala, jogador } = await criarContexto();
    const outroProfessor = await dataSource.getRepository(Professor).save({
      nome: 'Professor sem acesso',
      email: 'sem-acesso@example.com',
      senhaHash: 'hash',
    });

    await expect(
      relatoriosService.obterRelatorioAluno(
        sala.id,
        jogador.id,
        outroProfessor.id,
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  async function criarContexto(): Promise<{
    professor: Professor;
    sala: Sala;
    jogador: Jogador;
  }> {
    const professor = await dataSource.getRepository(Professor).save({
      nome: 'Professora Helena',
      email: `helena-${Date.now()}-${Math.random()}@example.com`,
      senhaHash: 'hash',
    });
    const sala = await dataSource.getRepository(Sala).save({
      professorId: professor.id,
      professor,
      nome: '7 Ano A',
      codigo: `S${String(Math.random()).slice(2, 7)}`,
      ativa: true,
    });
    const jogador = await dataSource.getRepository(Jogador).save({
      nome: 'Ana Clara',
      pontuacao: 0,
      faseAtual: 1,
      salaId: sala.id,
      sala,
      casaAtual: 1,
    });
    return { professor, sala, jogador };
  }

  async function criarPergunta(
    sala: Sala,
    dados: Partial<Pergunta> = {},
  ): Promise<Pergunta> {
    return dataSource.getRepository(Pergunta).save({
      salaId: sala.id,
      sala,
      titulo: 'Pergunta de teste',
      enunciado: 'Qual alternativa esta correta?',
      alternativaA: 'Opcao A',
      alternativaB: 'Opcao B',
      alternativaC: 'Opcao C',
      alternativaD: 'Opcao D',
      respostaCorreta: 'A',
      materia: 'Matematica',
      dificuldade: 'Medio',
      pontuacao: 100,
      tempoLimite: 30,
      ...dados,
    });
  }

  async function responder(
    jogador: Jogador,
    sala: Sala,
    pergunta: Pergunta,
    respostaEscolhida: string,
  ): Promise<void> {
    await progressoService.criar({
      jogadorId: jogador.id,
      perguntaId: pergunta.id,
      acertou: false,
      respostaEscolhida,
      fase: 1,
      salaId: sala.id,
      casaAtual: 2,
    });
  }
});
