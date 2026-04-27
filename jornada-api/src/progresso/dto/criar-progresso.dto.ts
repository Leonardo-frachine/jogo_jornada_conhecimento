import { IsBoolean, IsNotEmpty, IsNumber } from 'class-validator';

export class CriarProgressoDto {
  @IsNumber()
  @IsNotEmpty()
  jogadorId: number;

  @IsNumber()
  @IsNotEmpty()
  perguntaId: number;

  @IsBoolean()
  @IsNotEmpty()
  acertou: boolean;

  @IsNumber()
  @IsNotEmpty()
  fase: number;

  @IsNumber()
  @IsNotEmpty()
  pontuacaoGanha: number;
}