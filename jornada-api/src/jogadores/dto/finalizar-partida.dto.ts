import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, Min } from 'class-validator';

export class FinalizarPartidaDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  casaAtual?: number;

  @IsBoolean()
  @IsOptional()
  venceu?: boolean;
}
