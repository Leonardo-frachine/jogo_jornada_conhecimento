import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, Min } from 'class-validator';

// Dados opcionais enviados somente no encerramento oficial da partida.
export class FinalizarPartidaDto {
  // Casa final nunca pode ser anterior ao inicio do tabuleiro.
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  casaAtual?: number;

  @IsBoolean()
  @IsOptional()
  venceu?: boolean;
}
  // Indicador reservado para distinguir conclusao por vitoria em evolucoes futuras.
