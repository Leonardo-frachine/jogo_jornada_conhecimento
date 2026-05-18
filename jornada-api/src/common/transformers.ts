import { TransformFnParams } from 'class-transformer';

export function trimString({ value }: TransformFnParams): unknown {
  const input: unknown = value;

  return typeof input === 'string' ? input.trim() : input;
}

export function trimUppercaseString({ value }: TransformFnParams): unknown {
  const input: unknown = value;

  return typeof input === 'string' ? input.trim().toUpperCase() : input;
}

export function toBoolean({ value }: TransformFnParams): unknown {
  const input: unknown = value;

  if (input === true || input === 'true' || input === 1 || input === '1') {
    return true;
  }

  if (input === false || input === 'false' || input === 0 || input === '0') {
    return false;
  }

  return input;
}
