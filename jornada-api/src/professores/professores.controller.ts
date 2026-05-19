import { Body, Controller, Get, Param, ParseIntPipe, Post } from '@nestjs/common';
import { CadastrarProfessorDto } from './dto/cadastrar-professor.dto';
import { LoginProfessorDto } from './dto/login-professor.dto';
import { ProfessoresService } from './professores.service';

@Controller('professores')
export class ProfessoresController {
  constructor(private readonly professoresService: ProfessoresService) {}

  @Post('cadastro')
  cadastrar(@Body() cadastrarProfessorDto: CadastrarProfessorDto) {
    return this.professoresService.cadastrar(cadastrarProfessorDto);
  }

  @Post('login')
  login(@Body() loginProfessorDto: LoginProfessorDto) {
    return this.professoresService.login(loginProfessorDto);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    return this.professoresService.buscarPublicoPorId(id);
  }
}
