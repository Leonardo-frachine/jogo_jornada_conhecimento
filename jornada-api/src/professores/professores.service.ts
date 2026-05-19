import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomBytes, scryptSync, timingSafeEqual } from 'crypto';
import { Repository } from 'typeorm';
import { CadastrarProfessorDto } from './dto/cadastrar-professor.dto';
import { LoginProfessorDto } from './dto/login-professor.dto';
import { Professor } from './professor.entity';

type ProfessorPublico = {
  id: number;
  nome: string;
  email: string;
  criadoEm: Date;
};

@Injectable()
export class ProfessoresService {
  constructor(
    @InjectRepository(Professor)
    private readonly professorRepository: Repository<Professor>,
  ) {}

  async cadastrar(cadastrarProfessorDto: CadastrarProfessorDto): Promise<{
    mensagem: string;
    professor: ProfessorPublico;
  }> {
    const email = cadastrarProfessorDto.email.trim().toLowerCase();

    const professorExistente = await this.professorRepository.findOne({
      where: { email },
    });

    if (professorExistente) {
      throw new ConflictException(
        'Ja existe um professor cadastrado com este e-mail.',
      );
    }

    const professor = this.professorRepository.create({
      nome: cadastrarProfessorDto.nome.trim(),
      email,
      senhaHash: this.gerarHashSenha(cadastrarProfessorDto.senha),
    });

    const professorSalvo = await this.professorRepository.save(professor);

    return {
      mensagem: 'Professor cadastrado com sucesso.',
      professor: this.serializarProfessor(professorSalvo),
    };
  }

  async login(loginProfessorDto: LoginProfessorDto): Promise<{
    mensagem: string;
    professor: ProfessorPublico;
  }> {
    const email = loginProfessorDto.email.trim().toLowerCase();

    const professor = await this.professorRepository.findOne({
      where: { email },
    });

    if (!professor || !this.validarSenha(loginProfessorDto.senha, professor.senhaHash)) {
      throw new UnauthorizedException('E-mail ou senha invalidos.');
    }

    return {
      mensagem: 'Login realizado com sucesso.',
      professor: this.serializarProfessor(professor),
    };
  }

  async buscarPublicoPorId(id: number): Promise<ProfessorPublico> {
    const professor = await this.professorRepository.findOne({
      where: { id },
    });

    if (!professor) {
      throw new NotFoundException('Professor nao encontrado.');
    }

    return this.serializarProfessor(professor);
  }

  private gerarHashSenha(senha: string): string {
    const salt = randomBytes(16).toString('hex');
    const hash = scryptSync(senha, salt, 64).toString('hex');
    return `${salt}:${hash}`;
  }

  private validarSenha(senha: string, senhaHash: string): boolean {
    const [salt, hashSalvo] = senhaHash.split(':');
    if (!salt || !hashSalvo) {
      return false;
    }

    const hashInformado = scryptSync(senha, salt, 64);
    const hashBuffer = Buffer.from(hashSalvo, 'hex');
    if (hashInformado.length !== hashBuffer.length) {
      return false;
    }

    return timingSafeEqual(hashInformado, hashBuffer);
  }

  private serializarProfessor(professor: Professor): ProfessorPublico {
    return {
      id: professor.id,
      nome: professor.nome,
      email: professor.email,
      criadoEm: professor.criadoEm,
    };
  }
}
