import { Test, TestingModule } from '@nestjs/testing';
import { PerguntasAiService } from './perguntas-ai.service';

jest.mock('@google/genai', () => ({
  GoogleGenAI: jest.fn().mockImplementation(() => ({
    models: {
      generateContent: jest.fn(),
    },
  })),
}));

describe('PerguntasAiService', () => {
  let service: PerguntasAiService;
  let generateContentMock: jest.Mock;
  let googleGenAiMock: jest.Mock;
  const originalIaEnabled = process.env.IA_ENABLED;
  const originalGeminiApiKey = process.env.GEMINI_API_KEY;
  const originalGeminiModel = process.env.GEMINI_MODEL;

  beforeEach(async () => {
    const genAiModule = jest.requireMock('@google/genai') as {
      GoogleGenAI: jest.Mock;
    };
    googleGenAiMock = genAiModule.GoogleGenAI;
    generateContentMock = jest.fn();
    googleGenAiMock.mockReset();
    googleGenAiMock.mockImplementation(() => ({
      models: {
        generateContent: generateContentMock,
      },
    }));

    const module: TestingModule = await Test.createTestingModule({
      providers: [PerguntasAiService],
    }).compile();

    service = module.get<PerguntasAiService>(PerguntasAiService);
    process.env.IA_ENABLED = 'true';
    process.env.GEMINI_API_KEY = 'fake-gemini-key';
    process.env.GEMINI_MODEL = 'gemini-2.5-flash';
  });

  afterAll(() => {
    process.env.IA_ENABLED = originalIaEnabled;
    process.env.GEMINI_API_KEY = originalGeminiApiKey;
    process.env.GEMINI_MODEL = originalGeminiModel;
  });

  it('gera perguntas validadas a partir do JSON retornado pelo Gemini', async () => {
    generateContentMock.mockResolvedValue({
      text: JSON.stringify([
        {
          titulo: 'Sistema Solar',
          enunciado: 'Qual planeta e conhecido como planeta vermelho?',
          alternativaA: 'Marte',
          alternativaB: 'Venus',
          alternativaC: 'Jupiter',
          alternativaD: 'Saturno',
          respostaCorreta: 'a',
          materia: 'Materia ignorada',
          dificuldade: 'Dificuldade ignorada',
          pontuacao: 999,
          tempoLimite: 45,
        },
        {
          titulo: 'Sistema Solar 2',
          enunciado: 'Qual planeta e o maior do sistema solar?',
          alternativaA: 'Terra',
          alternativaB: 'Jupiter',
          alternativaC: 'Marte',
          alternativaD: 'Mercurio',
          respostaCorreta: 'B',
          materia: 'Materia ignorada',
          dificuldade: 'Dificuldade ignorada',
          pontuacao: 999,
          tempoLimite: 45,
        },
      ]),
    });

    const result = await service.gerarPerguntas({
      tema: 'Sistema Solar',
      materia: 'Ciencias',
      dificuldade: 'Medio',
      quantidade: 2,
      pontuacao: 100,
      tempoLimite: 30,
    });

    expect(googleGenAiMock).toHaveBeenCalledWith({
      apiKey: 'fake-gemini-key',
    });
    expect(result.total).toBe(2);
    expect(result.perguntas[0]).toMatchObject({
      titulo: 'Sistema Solar',
      materia: 'Ciencias',
      dificuldade: 'Medio',
      pontuacao: 100,
      tempoLimite: 30,
      respostaCorreta: 'A',
    });
  });

  it('retorna erro amigavel quando o Gemini devolve JSON invalido', async () => {
    generateContentMock.mockResolvedValue({
      text: '```json\n{"titulo":"fora do formato"}\n```',
    });

    await expect(
      service.gerarPerguntas({
        tema: 'Sistema Solar',
        materia: 'Ciencias',
        dificuldade: 'Medio',
        quantidade: 1,
        pontuacao: 100,
        tempoLimite: 30,
      }),
    ).rejects.toThrow('A IA nao retornou uma lista valida de perguntas.');
  });
});
