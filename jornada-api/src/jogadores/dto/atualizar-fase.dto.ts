import { Type } from 'class-transformer';
import { IsInt, Min } from 'class-validator';

export class AtualizarFaseDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  faseAtual: number;
}
