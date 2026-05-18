import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsInt, IsNotEmpty, IsOptional, Min } from 'class-validator';
import { toBoolean } from '../../common/transformers';

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
  @Min(0)
  @IsOptional()
  pontuacaoGanha?: number;
}
