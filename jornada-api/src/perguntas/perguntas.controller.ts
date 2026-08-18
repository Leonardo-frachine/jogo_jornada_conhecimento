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
  Query,
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
    return this.perguntasService.importarCsv(
      importarPerguntasCsvDto.csv,
      importarPerguntasCsvDto.salaId,
    );
  }

  @Post('importar-planilha')
  importarPlanilha(
    @Body() importarPerguntasPlanilhaDto: ImportarPerguntasPlanilhaDto,
  ) {
    return this.perguntasService.importarPlanilha(
      importarPerguntasPlanilhaDto.fileName,
      importarPerguntasPlanilhaDto.contentBase64,
      importarPerguntasPlanilhaDto.salaId,
    );
  }

  @Post('gerar-ia')
  async gerarComIa(@Body() gerarPerguntasIaDto: GerarPerguntasIaDto) {
    await this.perguntasService.validarSalaExistente(
      gerarPerguntasIaDto.salaId,
    );
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
    @Query('salaId', ParseIntPipe) salaId: number,
  ) {
    return this.perguntasService.salvarGeradas(perguntasGeradas, salaId);
  }

  @Get()
  listar(@Query('salaId', ParseIntPipe) salaId: number) {
    return this.perguntasService.listar(salaId);
  }

  @Get('exportar-csv')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  exportarCsv(@Query('salaId', ParseIntPipe) salaId: number) {
    return this.perguntasService.exportarCsv(salaId);
  }

  @Get('aleatoria')
  buscarAleatoria(@Query('salaId', ParseIntPipe) salaId: number) {
    return this.perguntasService.buscarAleatoria(salaId);
  }

  @Get(':id')
  buscarPorId(
    @Param('id', ParseIntPipe) id: number,
    @Query('salaId', ParseIntPipe) salaId: number,
  ) {
    return this.perguntasService.buscarPorId(id, salaId);
  }

  @Patch(':id')
  atualizar(
    @Param('id', ParseIntPipe) id: number,
    @Query('salaId', ParseIntPipe) salaId: number,
    @Body() atualizarPerguntaDto: AtualizarPerguntaDto,
  ) {
    return this.perguntasService.atualizar(id, salaId, atualizarPerguntaDto);
  }

  @Delete(':id')
  remover(
    @Param('id', ParseIntPipe) id: number,
    @Query('salaId', ParseIntPipe) salaId: number,
  ) {
    return this.perguntasService.remover(id, salaId);
  }

  @Delete()
  removerTodas(@Query('salaId', ParseIntPipe) salaId: number) {
    return this.perguntasService.removerTodasDaSala(salaId);
  }
}
