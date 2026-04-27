import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { PerguntasService } from './perguntas.service';
import { CriarPerguntaDto } from './dto/criar-pergunta.dto';

@Controller('perguntas')
export class PerguntasController {
  constructor(private readonly perguntasService: PerguntasService) {}

  @Post()
  criar(@Body() criarPerguntaDto: CriarPerguntaDto) {
    return this.perguntasService.criar(criarPerguntaDto);
  }

  @Get()
  listar() {
    return this.perguntasService.listar();
  }

  @Get('aleatoria')
  buscarAleatoria() {
    return this.perguntasService.buscarAleatoria();
  }

  @Get(':id')
  buscarPorId(@Param('id') id: string) {
    return this.perguntasService.buscarPorId(Number(id));
  }
}