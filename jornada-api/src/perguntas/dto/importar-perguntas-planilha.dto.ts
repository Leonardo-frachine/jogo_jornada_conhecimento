import { Transform, Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, Min } from 'class-validator';
import { trimString } from '../../common/transformers';

// Upload de uma planilha serializada para transporte em JSON.
export class ImportarPerguntasPlanilhaDto {
  // Sala de destino de todas as linhas importadas.
  @Type(() => Number)
  @IsInt()
  @Min(1)
  salaId: number;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  fileName: string;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  contentBase64: string;
}
  // Nome preserva a extensao usada para selecionar CSV ou XLSX.
  // Conteudo binario convertido em base64 pelo cliente.
