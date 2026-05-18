import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString } from 'class-validator';
import { trimString } from '../../common/transformers';

export class ImportarPerguntasCsvDto {
  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  csv: string;
}
