import { Transform, Type } from 'class-transformer';
import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';
import { trimString } from '../../common/transformers';

export class GerarPerguntasIaDto {
  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  tema: string;

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
  @Max(20)
  quantidade: number;

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
