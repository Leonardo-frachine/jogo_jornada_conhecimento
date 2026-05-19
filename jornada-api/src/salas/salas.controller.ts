import { Body, Controller, Get, Param, ParseIntPipe, Post } from '@nestjs/common';
import { CriarSalaDto } from './dto/criar-sala.dto';
import { SalasService } from './salas.service';

@Controller('salas')
export class SalasController {
  constructor(private readonly salasService: SalasService) {}

  @Post()
  criar(@Body() criarSalaDto: CriarSalaDto) {
    return this.salasService.criar(criarSalaDto);
  }

  @Get('codigo/:codigo')
  buscarPorCodigo(@Param('codigo') codigo: string) {
    return this.salasService.buscarPorCodigo(codigo);
  }

  @Get('professor/:professorId')
  listarPorProfessor(@Param('professorId', ParseIntPipe) professorId: number) {
    return this.salasService.listarPorProfessor(professorId);
  }

  @Get(':id/dashboard')
  obterDashboard(@Param('id', ParseIntPipe) id: number) {
    return this.salasService.obterDashboard(id);
  }

  @Get(':id/respostas')
  listarRespostas(@Param('id', ParseIntPipe) id: number) {
    return this.salasService.listarRespostas(id);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    return this.salasService.buscarPorId(id);
  }
}
