import { Transform, Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Min } from 'class-validator';
import { trimString, trimUppercaseString } from '../../common/transformers';

export class AtualizarPerguntaDto {
  @Transform(trimString)
  @IsString()
  @IsOptional()
  titulo?: string;

  @Transform(trimString)
  @IsString()
  @IsOptional()
  enunciado?: string;

  @Transform(trimString)
  @IsString()
  @IsOptional()
  alternativaA?: string;

  @Transform(trimString)
  @IsString()
  @IsOptional()
  alternativaB?: string;

  @Transform(trimString)
  @IsString()
  @IsOptional()
  alternativaC?: string;

  @Transform(trimString)
  @IsString()
  @IsOptional()
  alternativaD?: string;

  @Transform(trimUppercaseString)
  @IsString()
  @IsIn(['A', 'B', 'C', 'D'])
  @IsOptional()
  respostaCorreta?: string;

  @Transform(trimString)
  @IsString()
  @IsOptional()
  materia?: string;

  @Transform(trimString)
  @IsString()
  @IsOptional()
  dificuldade?: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  @IsOptional()
  pontuacao?: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  tempoLimite?: number | null;
}
