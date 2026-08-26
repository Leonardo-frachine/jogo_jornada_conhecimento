import { TransformFnParams } from 'class-transformer';

export function trimString({ value }: TransformFnParams): unknown {
  const input: unknown = value;

  // Somente strings recebem trim; outros tipos seguem para o validador sem alteracao.
  return typeof input === 'string' ? input.trim() : input;
}

export function trimUppercaseString({ value }: TransformFnParams): unknown {
  const input: unknown = value;

  return typeof input === 'string' ? input.trim().toUpperCase() : input;
}

export function toBoolean({ value }: TransformFnParams): unknown {
  const input: unknown = value;

  // Aceita as representacoes verdadeiras comuns em JSON, formularios e query strings.
  if (input === true || input === 'true' || input === 1 || input === '1') {
    return true;
  }

  // Aceita as representacoes falsas equivalentes sem tratar texto arbitrario como false.
  if (input === false || input === 'false' || input === 0 || input === '0') {
    return false;
  }

  // Valor desconhecido permanece intacto para que class-validator produza o erro correto.
  return input;
}
  // Normaliza codigos e letras de resposta para comparacoes case-insensitive.
