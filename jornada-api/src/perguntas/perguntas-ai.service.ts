import {
  BadGatewayException,
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { GoogleGenAI } from '@google/genai';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { GerarPerguntasIaDto } from './dto/gerar-perguntas-ia.dto';
import { SalvarPerguntaGeradaDto } from './dto/salvar-perguntas-geradas.dto';

@Injectable()
export class PerguntasAiService {
  async gerarPerguntas(
    gerarPerguntasIaDto: GerarPerguntasIaDto,
  ): Promise<{
    total: number;
    perguntas: SalvarPerguntaGeradaDto[];
  }> {
    this.validarDisponibilidadeIa();

    const client = new GoogleGenAI({
      apiKey: this.obterApiKeyConfigurada(),
    });

    try {
      const response = await client.models.generateContent({
        model: this.obterModeloConfigurado(),
        contents: this.montarPrompt(gerarPerguntasIaDto),
        config: {
          responseMimeType: 'application/json',
          responseSchema: this.montarResponseSchema(),
        },
      });

      const responseText = this.extrairTextoDaResposta(response?.text);
      const perguntas = this.processarPerguntasGeradas(
        responseText,
        gerarPerguntasIaDto,
      );

      return {
        total: perguntas.length,
        perguntas,
      };
    } catch (error) {
      throw this.mapearErroDaIa(error);
    }
  }

  private validarDisponibilidadeIa(): void {
    if (process.env.IA_ENABLED !== 'true') {
      throw new ServiceUnavailableException(
        'A geracao por IA esta desativada no servidor.',
      );
    }
  }

  private obterApiKeyConfigurada(): string {
    const apiKey = process.env.GEMINI_API_KEY?.trim();

    if (!apiKey) {
      throw new ServiceUnavailableException(
        'Chave da API Gemini nao configurada no servidor.',
      );
    }

    return apiKey;
  }

  private obterModeloConfigurado(): string {
    const configuredModel = process.env.GEMINI_MODEL?.trim();
    return configuredModel && configuredModel !== ''
      ? configuredModel
      : 'gemini-2.5-flash';
  }

  private montarPrompt(gerarPerguntasIaDto: GerarPerguntasIaDto): string {
    const tempoLimite = gerarPerguntasIaDto.tempoLimite ?? null;

    return [
      `Gere exatamente ${gerarPerguntasIaDto.quantidade} perguntas de multipla escolha sobre o tema "${gerarPerguntasIaDto.tema}", para a materia "${gerarPerguntasIaDto.materia}", com dificuldade "${gerarPerguntasIaDto.dificuldade}".`,
      '',
      'Cada pergunta deve ter:',
      '- titulo',
      '- enunciado',
      '- alternativaA',
      '- alternativaB',
      '- alternativaC',
      '- alternativaD',
      '- respostaCorreta',
      '- materia',
      '- dificuldade',
      '- pontuacao',
      '- tempoLimite',
      '',
      'Regras:',
      '- Cada pergunta deve ter exatamente 4 alternativas.',
      '- Apenas uma alternativa deve estar correta.',
      '- respostaCorreta deve ser somente "A", "B", "C" ou "D".',
      `- materia deve ser "${gerarPerguntasIaDto.materia}".`,
      `- dificuldade deve ser "${gerarPerguntasIaDto.dificuldade}".`,
      `- pontuacao deve ser ${gerarPerguntasIaDto.pontuacao}.`,
      `- tempoLimite deve ser ${tempoLimite === null ? 'null' : tempoLimite}.`,
      '- Retorne exclusivamente um array JSON valido.',
      '- Nao use markdown.',
      '- Nao coloque texto antes ou depois.',
      '- Nao coloque comentarios.',
      '- Nao coloque explicacoes.',
      '',
      'Formato obrigatorio:',
      '[',
      '  {',
      '    "titulo": "Titulo da pergunta",',
      '    "enunciado": "Texto da pergunta",',
      '    "alternativaA": "Alternativa A",',
      '    "alternativaB": "Alternativa B",',
      '    "alternativaC": "Alternativa C",',
      '    "alternativaD": "Alternativa D",',
      '    "respostaCorreta": "A",',
      `    "materia": "${gerarPerguntasIaDto.materia}",`,
      `    "dificuldade": "${gerarPerguntasIaDto.dificuldade}",`,
      `    "pontuacao": ${gerarPerguntasIaDto.pontuacao},`,
      `    "tempoLimite": ${tempoLimite === null ? 'null' : tempoLimite}`,
      '  }',
      ']',
    ].join('\n');
  }

  private montarResponseSchema(): Record<string, unknown> {
    return {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          titulo: { type: 'string' },
          enunciado: { type: 'string' },
          alternativaA: { type: 'string' },
          alternativaB: { type: 'string' },
          alternativaC: { type: 'string' },
          alternativaD: { type: 'string' },
          respostaCorreta: { type: 'string' },
          materia: { type: 'string' },
          dificuldade: { type: 'string' },
          pontuacao: { type: 'integer' },
          tempoLimite: {
            anyOf: [{ type: 'integer' }, { type: 'null' }],
          },
        },
        required: [
          'titulo',
          'enunciado',
          'alternativaA',
          'alternativaB',
          'alternativaC',
          'alternativaD',
          'respostaCorreta',
          'materia',
          'dificuldade',
          'pontuacao',
          'tempoLimite',
        ],
      },
    };
  }

  private extrairTextoDaResposta(responseText?: string): string {
    const sanitized = (responseText ?? '')
      .trim()
      .replace(/^```json\s*/i, '')
      .replace(/^```\s*/i, '')
      .replace(/\s*```$/i, '')
      .trim();

    if (sanitized === '') {
      throw new BadGatewayException(
        'A IA nao retornou perguntas em um formato valido.',
      );
    }

    return sanitized;
  }

  private processarPerguntasGeradas(
    responseText: string,
    gerarPerguntasIaDto: GerarPerguntasIaDto,
  ): SalvarPerguntaGeradaDto[] {
    let parsedResponse: unknown;

    try {
      parsedResponse = JSON.parse(responseText);
    } catch {
      throw new BadGatewayException(
        'A IA retornou um JSON invalido para as perguntas.',
      );
    }

    if (!Array.isArray(parsedResponse)) {
      throw new BadGatewayException(
        'A IA nao retornou uma lista valida de perguntas.',
      );
    }

    if (parsedResponse.length !== gerarPerguntasIaDto.quantidade) {
      throw new BadGatewayException(
        'A IA retornou uma quantidade diferente de perguntas da solicitada.',
      );
    }

    return parsedResponse.map((question, index) =>
      this.validarPerguntaGerada(question, gerarPerguntasIaDto, index),
    );
  }

  private validarPerguntaGerada(
    question: unknown,
    gerarPerguntasIaDto: GerarPerguntasIaDto,
    index: number,
  ): SalvarPerguntaGeradaDto {
    if (!question || typeof question !== 'object' || Array.isArray(question)) {
      throw new BadGatewayException(
        `A pergunta gerada na posicao ${index + 1} esta invalida.`,
      );
    }

    const rawQuestion = question as Record<string, unknown>;
    const titulo = this.extrairTextoCampo(rawQuestion.titulo);
    if (!titulo) {
      throw new BadGatewayException(
        `A pergunta gerada na posicao ${index + 1} veio incompleta.`,
      );
    }

    const normalizedPayload: Record<string, unknown> = {
      titulo,
      enunciado: this.extrairTextoCampo(rawQuestion.enunciado),
      alternativaA: this.extrairTextoCampo(rawQuestion.alternativaA),
      alternativaB: this.extrairTextoCampo(rawQuestion.alternativaB),
      alternativaC: this.extrairTextoCampo(rawQuestion.alternativaC),
      alternativaD: this.extrairTextoCampo(rawQuestion.alternativaD),
      respostaCorreta: this.extrairTextoCampo(rawQuestion.respostaCorreta)
        .toUpperCase(),
      materia: gerarPerguntasIaDto.materia,
      dificuldade: gerarPerguntasIaDto.dificuldade,
      pontuacao: gerarPerguntasIaDto.pontuacao,
      tempoLimite:
        gerarPerguntasIaDto.tempoLimite === undefined
          ? undefined
          : gerarPerguntasIaDto.tempoLimite,
    };

    const instance = plainToInstance(
      SalvarPerguntaGeradaDto,
      normalizedPayload,
    );
    const validationErrors = validateSync(instance);

    if (validationErrors.length > 0) {
      throw new BadGatewayException(
        `A pergunta gerada na posicao ${index + 1} veio incompleta ou invalida.`,
      );
    }

    return instance;
  }

  private extrairTextoCampo(value: unknown): string {
    return typeof value === 'string' ? value.trim() : '';
  }

  private mapearErroDaIa(error: unknown): Error {
    if (
      error instanceof BadGatewayException ||
      error instanceof BadRequestException ||
      error instanceof ServiceUnavailableException
    ) {
      return error;
    }

    const message = this.extrairMensagemErro(error).toLowerCase();

    if (
      message.includes('quota') ||
      message.includes('429') ||
      message.includes('resource_exhausted')
    ) {
      return new ServiceUnavailableException(
        'Limite de uso da API Gemini atingido. Tente novamente mais tarde.',
      );
    }

    if (
      message.includes('api key') ||
      message.includes('permission') ||
      message.includes('403') ||
      message.includes('401') ||
      message.includes('unauthorized')
    ) {
      return new ServiceUnavailableException(
        'Falha ao autenticar na API Gemini. Verifique a configuracao do servidor.',
      );
    }

    return new BadGatewayException(
      'Nao foi possivel gerar perguntas com IA no momento.',
    );
  }

  private extrairMensagemErro(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }

    if (typeof error === 'string') {
      return error;
    }

    return 'Erro desconhecido';
  }
}
