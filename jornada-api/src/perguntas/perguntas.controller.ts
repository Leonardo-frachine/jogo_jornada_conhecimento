import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  Param,
  ParseArrayPipe,
  ParseIntPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { GerarPerguntasIaDto } from './dto/gerar-perguntas-ia.dto';
import { PerguntasService } from './perguntas.service';
import { PerguntasAiService } from './perguntas-ai.service';
import { AtualizarPerguntaDto } from './dto/atualizar-pergunta.dto';
import { CriarPerguntaDto } from './dto/criar-pergunta.dto';
import { ImportarPerguntasCsvDto } from './dto/importar-perguntas-csv.dto';
import { ImportarPerguntasPlanilhaDto } from './dto/importar-perguntas-planilha.dto';
import { SalvarPerguntaGeradaDto } from './dto/salvar-perguntas-geradas.dto';

@Controller('perguntas')
export class PerguntasController {
  constructor(
    private readonly perguntasService: PerguntasService,
    private readonly perguntasAiService: PerguntasAiService,
  ) {}

  @Post()
  criar(@Body() criarPerguntaDto: CriarPerguntaDto) {
    return this.perguntasService.criar(criarPerguntaDto);
  }

  @Post('importar-csv')
  importarCsv(@Body() importarPerguntasCsvDto: ImportarPerguntasCsvDto) {
    return this.perguntasService.importarCsv(importarPerguntasCsvDto.csv);
  }

  @Post('importar-planilha')
  importarPlanilha(
    @Body() importarPerguntasPlanilhaDto: ImportarPerguntasPlanilhaDto,
  ) {
    return this.perguntasService.importarPlanilha(
      importarPerguntasPlanilhaDto.fileName,
      importarPerguntasPlanilhaDto.contentBase64,
    );
  }

  @Post('gerar-ia')
  gerarComIa(@Body() gerarPerguntasIaDto: GerarPerguntasIaDto) {
    return this.perguntasAiService.gerarPerguntas(gerarPerguntasIaDto);
  }

  @Post('salvar-geradas')
  salvarGeradas(
    @Body(
      new ParseArrayPipe({
        items: SalvarPerguntaGeradaDto,
      }),
    )
    perguntasGeradas: SalvarPerguntaGeradaDto[],
  ) {
    return this.perguntasService.salvarGeradas(perguntasGeradas);
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
