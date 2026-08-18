import { Transform, Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, Min } from 'class-validator';
import { trimString, trimUppercaseString } from '../../common/transformers';

export class CriarJogadorDto {
  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  nome: string;

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
