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

// Contrato completo para cadastro manual de uma pergunta.
export class CriarPerguntaDto {
  // Pergunta nova sempre nasce dentro de uma sala existente.
  @Type(() => Number)
  @IsInt()
  @Min(1)
  salaId: number;

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
  tempoLimite?: number;
}
  // Titulo e metadado opcional de gerenciamento.
  // Enunciado e quatro alternativas compoem o conteudo jogavel obrigatorio.
  // Gabarito aceita somente uma das quatro letras apresentadas.
  // Materia e dificuldade sao opcionais no fluxo manual legado.
  // Pontuacao zero e permitida; ausencia usa o calculo padrao do servico.
  // Tempo limite so e persistido quando for inteiro positivo.
