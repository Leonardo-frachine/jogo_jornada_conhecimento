import { Transform, Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, Min } from 'class-validator';
import { trimString } from '../../common/transformers';

export class ImportarPerguntasCsvDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  salaId: number;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  csv: string;
}
