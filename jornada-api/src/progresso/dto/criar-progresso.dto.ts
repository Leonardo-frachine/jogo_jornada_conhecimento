import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { toBoolean, trimUppercaseString } from '../../common/transformers';
import { PARTIDA_STATUS } from '../../jogadores/partida-status';
import type { PartidaStatus } from '../../jogadores/partida-status';

export class CriarProgressoDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsNotEmpty()
  jogadorId: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsNotEmpty()
  perguntaId: number;

  @Transform(toBoolean)
  @IsBoolean()
  @IsNotEmpty()
  acertou: boolean;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsNotEmpty()
  fase: number;

  @Type(() => Number)
  @IsInt()
  @IsOptional()
  pontuacaoGanha?: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  casaAtual?: number;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsIn([PARTIDA_STATUS.JOGANDO, PARTIDA_STATUS.FINALIZADO])
  @IsOptional()
  statusPartida?: PartidaStatus;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  salaId?: number;

  @Transform(trimUppercaseString)
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  salaCodigo?: string;
}
