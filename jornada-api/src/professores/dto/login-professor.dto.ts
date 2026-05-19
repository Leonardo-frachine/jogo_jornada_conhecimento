import { Transform } from 'class-transformer';
import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';
import { trimString } from '../../common/transformers';

export class LoginProfessorDto {
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
