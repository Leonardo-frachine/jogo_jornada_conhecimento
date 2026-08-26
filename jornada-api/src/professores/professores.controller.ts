import { Body, Controller, Get, Param, ParseIntPipe, Post } from '@nestjs/common';
import { CadastrarProfessorDto } from './dto/cadastrar-professor.dto';
import { LoginProfessorDto } from './dto/login-professor.dto';
import { ProfessoresService } from './professores.service';

@Controller('professores')
// Expoe apenas contratos publicos; senhaHash nunca e retornada pelo controller.
export class ProfessoresController {
  constructor(private readonly professoresService: ProfessoresService) {}

  @Post('cadastro')
  cadastrar(@Body() cadastrarProfessorDto: CadastrarProfessorDto) {
    // Cria a conta do professor com senha transformada em hash pelo servico.
    return this.professoresService.cadastrar(cadastrarProfessorDto);
  }

  @Post('login')
  login(@Body() loginProfessorDto: LoginProfessorDto) {
    // Valida credenciais e devolve os dados publicos da sessao.
    return this.professoresService.login(loginProfessorDto);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    // Revalida o professor salvo localmente ao restaurar uma sessao.
    return this.professoresService.buscarPublicoPorId(id);
  }
}
