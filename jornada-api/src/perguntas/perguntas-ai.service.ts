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

const ALTERNATIVE_LETTERS = ['A', 'B', 'C', 'D'] as const;
type AlternativeLetter = (typeof ALTERNATIVE_LETTERS)[number];

@Injectable()
export class PerguntasAiService {
  async gerarPerguntas(gerarPerguntasIaDto: GerarPerguntasIaDto): Promise<{
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
      '- Varie a posicao da resposta correta entre A, B, C e D.',
      '- Crie alternativas incorretas plausiveis, relacionadas ao mesmo assunto e com nivel de detalhe semelhante ao da correta.',
      '- Nao use alternativas absurdas, obviamente falsas ou duplicadas.',
      '- Evite pistas visuais: a correta nao deve ser sistematicamente a alternativa mais longa, mais detalhada ou com o maior numero.',
      '- Em perguntas numericas, use distratores proximos e verossimeis, sem tornar a maior opcao automaticamente correta.',
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

    const perguntasValidadas = parsedResponse.map((question, index) =>
      this.validarPerguntaGerada(question, gerarPerguntasIaDto, index),
    );

    this.validarAusenciaDePadraoObvio(perguntasValidadas);
    return this.distribuirRespostasCorretas(perguntasValidadas);
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
      respostaCorreta: this.extrairTextoCampo(
        rawQuestion.respostaCorreta,
      ).toUpperCase(),
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

    this.validarAlternativasDistintas(instance, index);

    return instance;
  }

  private validarAlternativasDistintas(
    pergunta: SalvarPerguntaGeradaDto,
    index: number,
  ): void {
    const alternativas = [
      pergunta.alternativaA,
      pergunta.alternativaB,
      pergunta.alternativaC,
      pergunta.alternativaD,
    ].map((alternativa) => alternativa.trim().toLocaleLowerCase('pt-BR'));

    if (new Set(alternativas).size !== ALTERNATIVE_LETTERS.length) {
      throw new BadGatewayException(
        `A pergunta gerada na posicao ${index + 1} possui alternativas duplicadas.`,
      );
    }
  }

  private validarAusenciaDePadraoObvio(
    perguntas: SalvarPerguntaGeradaDto[],
  ): void {
    if (perguntas.length < 2) {
      return;
    }

    const corretaSempreMaiorNumero = perguntas.every((pergunta) => {
      const alternativas = this.obterAlternativas(pergunta);
      const numeros = alternativas.map((alternativa) =>
        this.extrairNumeroComparavel(alternativa),
      );

      if (numeros.some((numero) => numero === null)) {
        return false;
      }

      const valores = numeros as number[];
      const indiceCorreto = ALTERNATIVE_LETTERS.indexOf(
        pergunta.respostaCorreta as AlternativeLetter,
      );
      const maiorValor = Math.max(...valores);
      return (
        valores[indiceCorreto] === maiorValor &&
        valores.filter((valor) => valor === maiorValor).length === 1
      );
    });

    const corretaSempreTextoMaisLongo = perguntas.every((pergunta) => {
      const comprimentos = this.obterAlternativas(pergunta).map(
        (alternativa) => alternativa.trim().length,
      );
      const indiceCorreto = ALTERNATIVE_LETTERS.indexOf(
        pergunta.respostaCorreta as AlternativeLetter,
      );
      const maiorComprimento = Math.max(...comprimentos);
      return (
        comprimentos[indiceCorreto] === maiorComprimento &&
        comprimentos.filter((comprimento) => comprimento === maiorComprimento)
          .length === 1
      );
    });

    if (corretaSempreMaiorNumero || corretaSempreTextoMaisLongo) {
      throw new BadGatewayException(
        'A IA gerou alternativas com um padrao previsivel. Gere novamente para obter opcoes mais equilibradas.',
      );
    }
  }

  private obterAlternativas(pergunta: SalvarPerguntaGeradaDto): string[] {
    return [
      pergunta.alternativaA,
      pergunta.alternativaB,
      pergunta.alternativaC,
      pergunta.alternativaD,
    ];
  }

  private extrairNumeroComparavel(alternativa: string): number | null {
    const valorNormalizado = alternativa
      .trim()
      .replace(/\s/g, '')
      .replace(',', '.')
      .replace(/%$/, '');

    if (!/^-?\d+(?:\.\d+)?$/.test(valorNormalizado)) {
      return null;
    }

    const numero = Number(valorNormalizado);
    return Number.isFinite(numero) ? numero : null;
  }

  private distribuirRespostasCorretas(
    perguntas: SalvarPerguntaGeradaDto[],
  ): SalvarPerguntaGeradaDto[] {
    const posicoesCorretas = this.criarPosicoesCorretasBalanceadas(
      perguntas.length,
    );

    return perguntas.map((pergunta, index) =>
      this.reordenarAlternativas(pergunta, posicoesCorretas[index]),
    );
  }

  private criarPosicoesCorretasBalanceadas(quantidade: number): number[] {
    const posicoes: number[] = [];

    while (posicoes.length < quantidade) {
      const bloco = this.embaralhar([0, 1, 2, 3]);
      const ultimaPosicao = posicoes.at(-1);

      if (ultimaPosicao !== undefined && bloco[0] === ultimaPosicao) {
        const indiceTroca = bloco.findIndex(
          (posicao) => posicao !== ultimaPosicao,
        );
        [bloco[0], bloco[indiceTroca]] = [bloco[indiceTroca], bloco[0]];
      }

      const quantidadeRestante = quantidade - posicoes.length;
      posicoes.push(...bloco.slice(0, quantidadeRestante));
    }

    return posicoes;
  }

  private reordenarAlternativas(
    pergunta: SalvarPerguntaGeradaDto,
    posicaoCorreta: number,
  ): SalvarPerguntaGeradaDto {
    const alternativas: Record<AlternativeLetter, string> = {
      A: pergunta.alternativaA,
      B: pergunta.alternativaB,
      C: pergunta.alternativaC,
      D: pergunta.alternativaD,
    };
    const letraCorreta = pergunta.respostaCorreta as AlternativeLetter;
    const respostaCorreta = alternativas[letraCorreta];
    const distratores = this.embaralhar(
      ALTERNATIVE_LETTERS.filter((letra) => letra !== letraCorreta).map(
        (letra) => alternativas[letra],
      ),
    );
    const alternativasReordenadas = [...distratores];
    alternativasReordenadas.splice(posicaoCorreta, 0, respostaCorreta);

    pergunta.alternativaA = alternativasReordenadas[0];
    pergunta.alternativaB = alternativasReordenadas[1];
    pergunta.alternativaC = alternativasReordenadas[2];
    pergunta.alternativaD = alternativasReordenadas[3];
    pergunta.respostaCorreta = ALTERNATIVE_LETTERS[posicaoCorreta];

    return pergunta;
  }

  private embaralhar<T>(valores: readonly T[]): T[] {
    const resultado = [...valores];

    for (let index = resultado.length - 1; index > 0; index -= 1) {
      const indiceAleatorio = Math.floor(Math.random() * (index + 1));
      [resultado[index], resultado[indiceAleatorio]] = [
        resultado[indiceAleatorio],
        resultado[index],
      ];
    }

    return resultado;
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
