import { Transform } from 'class-transformer';
import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';
import { trimString } from '../../common/transformers';

// Credenciais necessarias para iniciar uma sessao de professor.
export class LoginProfessorDto {
  // E-mail e aparado antes da validacao e normalizado no servico.
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
  // Senha nunca e transformada em caixa alta/baixa.
