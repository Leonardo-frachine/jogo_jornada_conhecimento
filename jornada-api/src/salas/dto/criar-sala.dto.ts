import { Transform, Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, Min } from 'class-validator';
import { trimString } from '../../common/transformers';

// Contrato de entrada para criar uma turma sob responsabilidade de um professor.
export class CriarSalaDto {
  // Professor proprietario deve existir e usar um ID positivo.
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
  // Nome e opcional porque o servico pode gerar "Sala CODIGO".
