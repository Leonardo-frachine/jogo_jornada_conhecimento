import { Transform, Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, Min } from 'class-validator';
import { trimString } from '../../common/transformers';

export class CriarSalaDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsNotEmpty()
  professorId: number;

  @Transform(trimString)
  @IsString()
  @IsOptional()
  nome?: string;
}
