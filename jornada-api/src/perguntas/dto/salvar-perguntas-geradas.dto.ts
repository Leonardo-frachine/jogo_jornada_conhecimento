import { Transform, Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { trimString, trimUppercaseString } from '../../common/transformers';

export class SalvarPerguntaGeradaDto {
  @Transform(trimString)
  @IsString()
  @IsOptional()
  titulo?: string;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  enunciado: string;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  alternativaA: string;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  alternativaB: string;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  alternativaC: string;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  alternativaD: string;

  @Transform(trimUppercaseString)
  @IsString()
  @IsNotEmpty()
  @IsIn(['A', 'B', 'C', 'D'])
  respostaCorreta: string;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  materia: string;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  dificuldade: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  pontuacao: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  tempoLimite?: number;
}
