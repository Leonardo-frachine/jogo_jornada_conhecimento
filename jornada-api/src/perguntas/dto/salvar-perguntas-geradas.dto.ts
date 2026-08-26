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

// Pergunta gerada pela IA depois de revisada e aprovada pelo professor.
export class SalvarPerguntaGeradaDto {
  // Titulo curto e opcional.
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
  // Enunciado e as quatro alternativas sao obrigatorios para jogar.
  // Gabarito e normalizado e limitado as letras existentes.
  // Materia e dificuldade sao obrigatorias para relatorios da geracao por IA.
  // Pontuacao aprovada deve ser inteira e positiva.
  // Tempo e opcional, mas quando presente precisa ser positivo.
