import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import * as XLSX from 'xlsx';
import { configureApp } from '../src/app.config';
import { AppModule } from '../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication<App>;
  const originalIaEnabled = process.env.IA_ENABLED;
  const originalGeminiApiKey = process.env.GEMINI_API_KEY;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
  });

  afterEach(() => {
    process.env.IA_ENABLED = originalIaEnabled;
    process.env.GEMINI_API_KEY = originalGeminiApiKey;
  });

  it('/ (GET)', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });

  it('valida parametros numericos antes de consultar o banco', () => {
    return request(app.getHttpServer()).get('/jogadores/abc').expect(400);
  });

  it('registra jogador, pergunta, progresso e relatorio sem inconsistir pontuacao', async () => {
    const jogadorResponse = await request(app.getHttpServer())
      .post('/jogadores')
      .send({ nome: '  Ana Teste  ' })
      .expect(201);

    const jogador = jogadorResponse.body as { id: number; nome: string };
    expect(jogador.nome).toBe('Ana Teste');

    const perguntaResponse = await request(app.getHttpServer())
      .post('/perguntas')
      .send({
        titulo: 'Godot',
        enunciado: 'Qual linguagem e usada na Godot?',
        alternativaA: 'Python',
        alternativaB: 'GDScript',
        alternativaC: 'Java',
        alternativaD: 'PHP',
        respostaCorreta: 'b',
        dificuldade: '2',
        pontuacao: 250,
        tempoLimite: 30,
      })
      .expect(201);

    const pergunta = perguntaResponse.body as {
      id: number;
      respostaCorreta: string;
      pontuacao: number;
    };
    expect(pergunta.respostaCorreta).toBe('B');
    expect(pergunta.pontuacao).toBe(250);

    const progressoResponse = await request(app.getHttpServer())
      .post('/progresso')
      .send({
        jogadorId: jogador.id,
        perguntaId: pergunta.id,
        acertou: true,
        fase: 2,
        pontuacaoGanha: 9999,
      })
      .expect(201);

    expect(progressoResponse.body).toMatchObject({
      jogadorId: jogador.id,
      perguntaId: pergunta.id,
      acertou: true,
      fase: 2,
      pontuacaoGanha: 250,
    });

    const jogadorAtualizadoResponse = await request(app.getHttpServer())
      .get(`/jogadores/${jogador.id}`)
      .expect(200);

    expect(jogadorAtualizadoResponse.body).toMatchObject({
      id: jogador.id,
      pontuacao: 250,
      faseAtual: 2,
    });

    const jogadorRecalculadoResponse = await request(app.getHttpServer())
      .patch(`/jogadores/${jogador.id}/pontuacao`)
      .expect(200);

    expect(jogadorRecalculadoResponse.body).toMatchObject({
      pontuacao: 250,
      faseAtual: 2,
    });

    const relatorioResponse = await request(app.getHttpServer())
      .get(`/progresso/relatorios/jogador/${jogador.id}`)
      .expect(200);

    const relatorio = relatorioResponse.body as {
      resumo: {
        jogadorId: number;
        pontuacao: number;
        respostas: number;
        acertos: number;
        erros: number;
        aproveitamento: number;
      };
    };

    expect(relatorio.resumo).toMatchObject({
      jogadorId: jogador.id,
      pontuacao: 250,
      respostas: 1,
      acertos: 1,
      erros: 0,
      aproveitamento: 100,
    });
  });

  it('importa e exporta perguntas em CSV', async () => {
    const csv = [
      'Título,Descrição,A,B,C,D,Correta (A-D),Dificuldade (1-6),Pontuação,Tempo,Matéria',
      'Matematica,Quanto e 2 + 2?,3,4,5,6,B,1,100,20,Matematica',
    ].join('\n');

    const importacaoResponse = await request(app.getHttpServer())
      .post('/perguntas/importar-csv')
      .send({ csv })
      .expect(201);

    const importacao = importacaoResponse.body as { total: number };
    expect(importacao.total).toBe(1);

    const exportacaoResponse = await request(app.getHttpServer())
      .get('/perguntas/exportar-csv')
      .expect(200);

    expect(exportacaoResponse.text).toContain('Correta (A-D)');
    expect(exportacaoResponse.text).toContain('Quanto e 2 + 2?');
  });

  it('importa perguntas por planilha CSV e XLSX', async () => {
    const csv = [
      'id,enunciado,alternativaA,alternativaB,alternativaC,alternativaD,respostaCorreta,materia,dificuldade,titulo,pontuacao,tempoLimite',
      '999,Qual numero vem antes do 11?,10,11,12,13,A,Matematica,1,Sequencia numerica,120,25',
    ].join('\n');

    const importacaoCsvResponse = await request(app.getHttpServer())
      .post('/perguntas/importar-planilha')
      .send({
        fileName: 'perguntas-importacao.csv',
        contentBase64: Buffer.from(csv, 'utf-8').toString('base64'),
      })
      .expect(201);

    expect(importacaoCsvResponse.body).toMatchObject({
      total: 1,
      formato: 'csv',
    });
    expect(importacaoCsvResponse.body.perguntas[0]).toMatchObject({
      respostaCorreta: 'A',
      materia: 'Matematica',
      pontuacao: 120,
    });
    expect(importacaoCsvResponse.body.perguntas[0].id).not.toBe(999);

    const workbook = XLSX.utils.book_new();
    const worksheet = XLSX.utils.aoa_to_sheet([
      [
        'id',
        'enunciado',
        'alternativaA',
        'alternativaB',
        'alternativaC',
        'alternativaD',
        'respostaCorreta',
        'materia',
        'dificuldade',
        'titulo',
        'pontuacao',
        'tempoLimite',
      ],
      [
        500,
        'Qual planeta habitamos?',
        'Terra',
        'Marte',
        'Venus',
        'Jupiter',
        'A',
        'Ciencias',
        '2',
        'Planeta Terra',
        220,
        30,
      ],
    ]);
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Perguntas');
    const xlsxBase64 = XLSX.write(workbook, {
      type: 'base64',
      bookType: 'xlsx',
    });

    const importacaoXlsxResponse = await request(app.getHttpServer())
      .post('/perguntas/importar-planilha')
      .send({
        fileName: 'perguntas-importacao.xlsx',
        contentBase64: xlsxBase64,
      })
      .expect(201);

    expect(importacaoXlsxResponse.body).toMatchObject({
      total: 1,
      formato: 'xlsx',
    });
    expect(importacaoXlsxResponse.body.perguntas[0]).toMatchObject({
      respostaCorreta: 'A',
      materia: 'Ciencias',
      pontuacao: 220,
    });
    expect(importacaoXlsxResponse.body.perguntas[0].id).not.toBe(500);
  });

  it('retorna erro amigavel quando a geracao por IA esta desativada', async () => {
    process.env.IA_ENABLED = 'false';
    delete process.env.GEMINI_API_KEY;

    const response = await request(app.getHttpServer())
      .post('/perguntas/gerar-ia')
      .send({
        tema: 'Sistema Solar',
        materia: 'Ciencias',
        dificuldade: 'Medio',
        quantidade: 2,
        pontuacao: 100,
        tempoLimite: 30,
      })
      .expect(503);

    expect(response.body.message).toBe(
      'A geracao por IA esta desativada no servidor.',
    );
  });

  it('retorna erro amigavel quando a chave do Gemini nao esta configurada', async () => {
    process.env.IA_ENABLED = 'true';
    delete process.env.GEMINI_API_KEY;

    const response = await request(app.getHttpServer())
      .post('/perguntas/gerar-ia')
      .send({
        tema: 'Sistema Solar',
        materia: 'Ciencias',
        dificuldade: 'Medio',
        quantidade: 2,
        pontuacao: 100,
        tempoLimite: 30,
      })
      .expect(503);

    expect(response.body.message).toBe(
      'Chave da API Gemini nao configurada no servidor.',
    );
  });

  it('salva apenas as perguntas aprovadas enviadas pelo professor', async () => {
    const response = await request(app.getHttpServer())
      .post('/perguntas/salvar-geradas')
      .send([
        {
          titulo: 'Sistema Solar',
          enunciado: 'Qual planeta e conhecido como planeta vermelho?',
          alternativaA: 'Marte',
          alternativaB: 'Venus',
          alternativaC: 'Jupiter',
          alternativaD: 'Saturno',
          respostaCorreta: 'A',
          materia: 'Ciencias',
          dificuldade: 'Facil',
          pontuacao: 100,
          tempoLimite: 30,
        },
        {
          titulo: 'Oceanos',
          enunciado: 'Qual oceano banha a costa leste do Brasil?',
          alternativaA: 'Pacifico',
          alternativaB: 'Atlantico',
          alternativaC: 'Indico',
          alternativaD: 'Artico',
          respostaCorreta: 'B',
          materia: 'Geografia',
          dificuldade: 'Medio',
          pontuacao: 150,
        },
      ])
      .expect(201);

    expect(response.body).toMatchObject({
      total: 2,
    });
    expect(response.body.perguntas[0].id).toBeGreaterThan(0);
    expect(response.body.perguntas[1].id).toBeGreaterThan(0);

    const perguntasResponse = await request(app.getHttpServer())
      .get('/perguntas')
      .expect(200);

    const perguntas = perguntasResponse.body as Array<{
      enunciado: string;
      respostaCorreta: string;
      materia: string;
    }>;

    expect(
      perguntas.some(
        (pergunta) =>
          pergunta.enunciado ===
            'Qual planeta e conhecido como planeta vermelho?' &&
          pergunta.respostaCorreta === 'A' &&
          pergunta.materia === 'Ciencias',
      ),
    ).toBe(true);
    expect(
      perguntas.some(
        (pergunta) =>
          pergunta.enunciado ===
            'Qual oceano banha a costa leste do Brasil?' &&
          pergunta.respostaCorreta === 'B' &&
          pergunta.materia === 'Geografia',
      ),
    ).toBe(true);
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });
});
