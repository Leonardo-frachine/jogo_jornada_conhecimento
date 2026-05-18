import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString } from 'class-validator';
import { trimString } from '../../common/transformers';

export class CriarJogadorDto {
  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  nome: string;
}
