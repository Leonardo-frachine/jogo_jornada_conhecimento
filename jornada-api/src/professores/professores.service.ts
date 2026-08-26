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

/**
 * Concentra as regras de cadastro e autenticacao de professores.
 * A senha nunca deve sair deste servico: toda resposta usa ProfessorPublico.
 */
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

    // E-mail identifica unicamente o professor, independentemente de maiusculas.
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

    // Usa uma mensagem unica para usuario inexistente e senha errada, sem revelar cadastros.
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

    // Impede que uma sessao aponte para um professor removido ou inexistente.
    if (!professor) {
      throw new NotFoundException('Professor nao encontrado.');
    }

    return this.serializarProfessor(professor);
  }

  private gerarHashSenha(senha: string): string {
    // Um salt aleatorio por cadastro impede hashes iguais para senhas iguais.
    const salt = randomBytes(16).toString('hex');
    const hash = scryptSync(senha, salt, 64).toString('hex');
    return `${salt}:${hash}`;
  }

  private validarSenha(senha: string, senhaHash: string): boolean {
    const [salt, hashSalvo] = senhaHash.split(':');
    // Hash fora do formato "salt:hash" e tratado como credencial invalida.
    if (!salt || !hashSalvo) {
      return false;
    }

    const hashInformado = scryptSync(senha, salt, 64);
    const hashBuffer = Buffer.from(hashSalvo, 'hex');
    // timingSafeEqual exige buffers do mesmo tamanho e lancaria erro sem esta guarda.
    if (hashInformado.length !== hashBuffer.length) {
      return false;
    }

    return timingSafeEqual(hashInformado, hashBuffer);
  }

  private serializarProfessor(professor: Professor): ProfessorPublico {
    // A lista explicita evita expor senhaHash caso a entidade ganhe novos campos.
    return {
      id: professor.id,
      nome: professor.nome,
      email: professor.email,
      criadoEm: professor.criadoEm,
    };
  }
}
