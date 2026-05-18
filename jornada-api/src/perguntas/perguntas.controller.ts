import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  Param,
  ParseIntPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { PerguntasService } from './perguntas.service';
import { AtualizarPerguntaDto } from './dto/atualizar-pergunta.dto';
import { CriarPerguntaDto } from './dto/criar-pergunta.dto';
import { ImportarPerguntasCsvDto } from './dto/importar-perguntas-csv.dto';

@Controller('perguntas')
export class PerguntasController {
  constructor(private readonly perguntasService: PerguntasService) {}

  @Post()
  criar(@Body() criarPerguntaDto: CriarPerguntaDto) {
    return this.perguntasService.criar(criarPerguntaDto);
  }

  @Post('importar-csv')
  importarCsv(@Body() importarPerguntasCsvDto: ImportarPerguntasCsvDto) {
    return this.perguntasService.importarCsv(importarPerguntasCsvDto.csv);
  }

  @Get()
  listar() {
    return this.perguntasService.listar();
  }

  @Get('exportar-csv')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  exportarCsv() {
    return this.perguntasService.exportarCsv();
  }

  @Get('aleatoria')
  buscarAleatoria() {
    return this.perguntasService.buscarAleatoria();
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    return this.perguntasService.buscarPorId(id);
  }

  @Patch(':id')
  atualizar(
    @Param('id', ParseIntPipe) id: number,
    @Body() atualizarPerguntaDto: AtualizarPerguntaDto,
  ) {
    return this.perguntasService.atualizar(id, atualizarPerguntaDto);
  }

  @Delete(':id')
  remover(@Param('id', ParseIntPipe) id: number) {
    return this.perguntasService.remover(id);
  }
}
