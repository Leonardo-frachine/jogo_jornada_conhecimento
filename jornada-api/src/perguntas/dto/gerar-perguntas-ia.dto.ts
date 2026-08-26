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

// Parametros controlados pelo professor para gerar um lote de perguntas.
export class GerarPerguntasIaDto {
  // Sala e validada antes de consumir quota da IA.
  @Type(() => Number)
  @IsInt()
  @Min(1)
  salaId: number;

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
  // Tema, materia e dificuldade orientam conteudo e relatorios.
  // Limite de 20 controla custo, latencia e volume de revisao.
  // Pontuacao definida pelo professor substitui qualquer sugestao da IA.
  // Tempo opcional e aplicado igualmente ao lote gerado.
