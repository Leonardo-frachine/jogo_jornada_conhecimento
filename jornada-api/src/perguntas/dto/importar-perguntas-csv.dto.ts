import { Transform, Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, Min } from 'class-validator';
import { trimString } from '../../common/transformers';

// Importacao direta de CSV textual mantida por compatibilidade.
export class ImportarPerguntasCsvDto {
  // Isola a importacao no banco de perguntas da sala.
  @Type(() => Number)
  @IsInt()
  @Min(1)
  salaId: number;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  csv: string;
}
  // Texto integral que sera interpretado pelo parser de CSV.
