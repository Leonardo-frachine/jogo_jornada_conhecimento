import { Transform, Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, Min } from 'class-validator';
import { trimString, trimUppercaseString } from '../../common/transformers';

// Entrada para cadastrar ou localizar o mesmo aluno dentro de uma sala.
export class CriarJogadorDto {
  // Nome sera novamente normalizado pelo servico para deduplicacao segura.
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
  // Clientes autenticados podem usar o ID interno da sala...
  // ...enquanto alunos normalmente entram usando o codigo publico.
