import { Test, TestingModule } from '@nestjs/testing';
import { PerguntasAiService } from './perguntas-ai.service';

jest.mock('@google/genai', () => ({
  GoogleGenAI: jest.fn().mockImplementation(() => ({
    models: {
      generateContent: jest.fn(),
    },
  })),
}));

// Garante que respostas da IA sejam validadas, balanceadas e tenham erros mapeados.
describe('PerguntasAiService', () => {
  let service: PerguntasAiService;
  let generateContentMock: jest.Mock;
  let googleGenAiMock: jest.Mock;
  const originalIaEnabled = process.env.IA_ENABLED;
  const originalGeminiApiKey = process.env.GEMINI_API_KEY;
  const originalGeminiModel = process.env.GEMINI_MODEL;

  beforeEach(async () => {
    const genAiModule = jest.requireMock<{
      GoogleGenAI: jest.Mock;
    }>('@google/genai');
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
      salaId: 1,
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
    });
    expect(
      new Set(result.perguntas.map((item) => item.respostaCorreta)).size,
    ).toBe(2);
    expect(obterTextoRespostaCorreta(result.perguntas[0])).toBe('Marte');
    expect(obterTextoRespostaCorreta(result.perguntas[1])).toBe('Jupiter');
  });

  it('distribui as respostas corretas entre A, B, C e D e preserva o conteudo correto', async () => {
    generateContentMock.mockResolvedValue({
      text: JSON.stringify(
        Array.from({ length: 4 }, (_, index) => ({
          titulo: `Pergunta ${index + 1}`,
          enunciado: `Enunciado ${index + 1}`,
          alternativaA: `Correta ${index + 1}`,
          alternativaB: `Distrator B ${index + 1}`,
          alternativaC: `Distrator C ${index + 1}`,
          alternativaD: `Distrator D ${index + 1}`,
          respostaCorreta: 'A',
          materia: 'Teste',
          dificuldade: 'Medio',
          pontuacao: 100,
          tempoLimite: 30,
        })),
      ),
    });

    const result = await service.gerarPerguntas({
      salaId: 1,
      tema: 'Distribuicao',
      materia: 'Teste',
      dificuldade: 'Medio',
      quantidade: 4,
      pontuacao: 100,
      tempoLimite: 30,
    });

    expect(result.perguntas.map((item) => item.respostaCorreta).sort()).toEqual(
      ['A', 'B', 'C', 'D'],
    );
    result.perguntas.forEach((pergunta, index) => {
      expect(obterTextoRespostaCorreta(pergunta)).toBe(`Correta ${index + 1}`);
    });
  });

  it('rejeita perguntas com alternativas duplicadas', async () => {
    generateContentMock.mockResolvedValue({
      text: JSON.stringify([
        {
          titulo: 'Duplicada',
          enunciado: 'Qual alternativa esta correta?',
          alternativaA: 'Mesmo texto',
          alternativaB: 'Mesmo texto',
          alternativaC: 'Outra alternativa',
          alternativaD: 'Mais uma alternativa',
          respostaCorreta: 'A',
          materia: 'Teste',
          dificuldade: 'Medio',
          pontuacao: 100,
          tempoLimite: 30,
        },
      ]),
    });

    await expect(
      service.gerarPerguntas({
        salaId: 1,
        tema: 'Duplicadas',
        materia: 'Teste',
        dificuldade: 'Medio',
        quantidade: 1,
        pontuacao: 100,
        tempoLimite: 30,
      }),
    ).rejects.toThrow('possui alternativas duplicadas');
  });

  it('rejeita um lote em que a resposta correta e sempre o maior numero', async () => {
    generateContentMock.mockResolvedValue({
      text: JSON.stringify([
        {
          titulo: 'Numerica 1',
          enunciado: 'Primeira pergunta numerica',
          alternativaA: '10',
          alternativaB: '20',
          alternativaC: '30',
          alternativaD: '40',
          respostaCorreta: 'D',
          materia: 'Matematica',
          dificuldade: 'Medio',
          pontuacao: 100,
          tempoLimite: 30,
        },
        {
          titulo: 'Numerica 2',
          enunciado: 'Segunda pergunta numerica',
          alternativaA: '1',
          alternativaB: '2',
          alternativaC: '3',
          alternativaD: '4',
          respostaCorreta: 'D',
          materia: 'Matematica',
          dificuldade: 'Medio',
          pontuacao: 100,
          tempoLimite: 30,
        },
      ]),
    });

    await expect(
      service.gerarPerguntas({
        salaId: 1,
        tema: 'Numeros',
        materia: 'Matematica',
        dificuldade: 'Medio',
        quantidade: 2,
        pontuacao: 100,
        tempoLimite: 30,
      }),
    ).rejects.toThrow('padrao previsivel');
  });

  it('retorna erro amigavel quando o Gemini devolve JSON invalido', async () => {
    generateContentMock.mockResolvedValue({
      text: '```json\n{"titulo":"fora do formato"}\n```',
    });

    await expect(
      service.gerarPerguntas({
        salaId: 1,
        tema: 'Sistema Solar',
        materia: 'Ciencias',
        dificuldade: 'Medio',
        quantidade: 1,
        pontuacao: 100,
        tempoLimite: 30,
      }),
    ).rejects.toThrow('A IA nao retornou uma lista valida de perguntas.');
  });

  function obterTextoRespostaCorreta(pergunta: {
    alternativaA: string;
    alternativaB: string;
    alternativaC: string;
    alternativaD: string;
    respostaCorreta: string;
  }): string {
    const alternativas = {
      A: pergunta.alternativaA,
      B: pergunta.alternativaB,
      C: pergunta.alternativaC,
      D: pergunta.alternativaD,
    };

    return alternativas[pergunta.respostaCorreta as keyof typeof alternativas];
  }
});
