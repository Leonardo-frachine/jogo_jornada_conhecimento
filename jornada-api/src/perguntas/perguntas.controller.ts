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
// Reune rotas de CRUD, importacao, exportacao e geracao assistida de perguntas.
export class PerguntasController {
  constructor(
    private readonly perguntasService: PerguntasService,
    private readonly perguntasAiService: PerguntasAiService,
  ) {}

  @Post()
  criar(@Body() criarPerguntaDto: CriarPerguntaDto) {
    // Cadastra manualmente uma pergunta na sala indicada pelo DTO.
    return this.perguntasService.criar(criarPerguntaDto);
  }

  @Post('importar-csv')
  importarCsv(@Body() importarPerguntasCsvDto: ImportarPerguntasCsvDto) {
    // Importa texto CSV legado associado a uma sala especifica.
    return this.perguntasService.importarCsv(
      importarPerguntasCsvDto.csv,
      importarPerguntasCsvDto.salaId,
    );
  }

  @Post('importar-planilha')
  importarPlanilha(
    @Body() importarPerguntasPlanilhaDto: ImportarPerguntasPlanilhaDto,
  ) {
    // Decodifica e importa CSV/XLSX enviado como base64.
    return this.perguntasService.importarPlanilha(
      importarPerguntasPlanilhaDto.fileName,
      importarPerguntasPlanilhaDto.contentBase64,
      importarPerguntasPlanilhaDto.salaId,
    );
  }

  @Post('gerar-ia')
  async gerarComIa(@Body() gerarPerguntasIaDto: GerarPerguntasIaDto) {
    // Valida a sala antes de consumir quota do provedor de IA.
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
    // Persiste apenas o subconjunto de perguntas revisado e aprovado pelo professor.
    return this.perguntasService.salvarGeradas(perguntasGeradas, salaId);
  }

  @Get()
  listar(@Query('salaId', ParseIntPipe) salaId: number) {
    // O salaId obrigatorio evita misturar bancos de perguntas.
    return this.perguntasService.listar(salaId);
  }

  @Get('exportar-csv')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  exportarCsv(@Query('salaId', ParseIntPipe) salaId: number) {
    // Exporta o banco ativo da sala em formato reutilizavel.
    return this.perguntasService.exportarCsv(salaId);
  }

  @Get('aleatoria')
  buscarAleatoria(@Query('salaId', ParseIntPipe) salaId: number) {
    // Sorteia exclusivamente entre perguntas ativas da turma.
    return this.perguntasService.buscarAleatoria(salaId);
  }

  @Get(':id')
  buscarPorId(
    @Param('id', ParseIntPipe) id: number,
    @Query('salaId', ParseIntPipe) salaId: number,
  ) {
    // Combina ID da pergunta e sala para bloquear acesso cruzado.
    return this.perguntasService.buscarPorId(id, salaId);
  }

  @Patch(':id')
  atualizar(
    @Param('id', ParseIntPipe) id: number,
    @Query('salaId', ParseIntPipe) salaId: number,
    @Body() atualizarPerguntaDto: AtualizarPerguntaDto,
  ) {
    // Atualiza parcialmente uma pergunta pertencente a sala.
    return this.perguntasService.atualizar(id, salaId, atualizarPerguntaDto);
  }

  @Delete(':id')
  remover(
    @Param('id', ParseIntPipe) id: number,
    @Query('salaId', ParseIntPipe) salaId: number,
  ) {
    // Faz exclusao logica individual para preservar historico.
    return this.perguntasService.remover(id, salaId);
  }

  @Delete()
  removerTodas(@Query('salaId', ParseIntPipe) salaId: number) {
    // Desativa em lote somente as perguntas da sala selecionada.
    return this.perguntasService.removerTodasDaSala(salaId);
  }
}
