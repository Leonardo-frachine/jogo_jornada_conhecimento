import { Type } from 'class-transformer';
import { IsInt, Min } from 'class-validator';

// Atualizacao isolada da fase atual do jogador.
export class AtualizarFaseDto {
  // Fases comecam em 1 e aceitam apenas inteiros.
  @Type(() => Number)
  @IsInt()
  @Min(1)
  faseAtual: number;
}
