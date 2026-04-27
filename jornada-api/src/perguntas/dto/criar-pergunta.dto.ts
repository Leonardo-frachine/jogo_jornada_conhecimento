import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CriarPerguntaDto {
  @IsString()
  @IsNotEmpty()
  enunciado: string;

  @IsString()
  @IsNotEmpty()
  alternativaA: string;

  @IsString()
  @IsNotEmpty()
  alternativaB: string;

  @IsString()
  @IsNotEmpty()
  alternativaC: string;

  @IsString()
  @IsNotEmpty()
  alternativaD: string;

  @IsString()
  @IsNotEmpty()
  respostaCorreta: string;

  @IsString()
  @IsOptional()
  materia?: string;

  @IsString()
  @IsOptional()
  dificuldade?: string;
}