import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString } from 'class-validator';
import { trimString } from '../../common/transformers';

export class ImportarPerguntasPlanilhaDto {
  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  fileName: string;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  contentBase64: string;
}
