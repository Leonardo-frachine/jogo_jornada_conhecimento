import { Transform } from 'class-transformer';
import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';
import { trimString } from '../../common/transformers';

// Contrato publico do cadastro de professor.
export class CadastrarProfessorDto {
  // Nome exibido no painel e nas salas.
  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  nome: string;

  @Transform(trimString)
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @Transform(trimString)
  @IsString()
  @IsNotEmpty()
  @MinLength(4)
  senha: string;
}
  // E-mail valido funciona como identificador unico de login.
  // Tamanho minimo evita credenciais acidentalmente vazias ou muito curtas.
