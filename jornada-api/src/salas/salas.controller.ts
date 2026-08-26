import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
} from '@nestjs/common';
import { CriarSalaDto } from './dto/criar-sala.dto';
import { SalasService } from './salas.service';

@Controller('salas')
// Traduz rotas HTTP de sala em chamadas do servico que contem as regras de isolamento.
export class SalasController {
  constructor(private readonly salasService: SalasService) {}

  @Post()
  criar(@Body() criarSalaDto: CriarSalaDto) {
    // Cria uma turma vinculada ao professor informado no corpo.
    return this.salasService.criar(criarSalaDto);
  }

  @Get('codigo/:codigo')
  buscarPorCodigo(@Param('codigo') codigo: string) {
    // Resolve o codigo curto digitado pelo aluno antes de entrar na partida.
    return this.salasService.buscarPorCodigo(codigo);
  }

  @Get('professor/:professorId')
  listarPorProfessor(@Param('professorId', ParseIntPipe) professorId: number) {
    // Lista apenas as salas pertencentes ao professor selecionado.
    return this.salasService.listarPorProfessor(professorId);
  }

  @Get(':id/dashboard')
  obterDashboard(@Param('id', ParseIntPipe) id: number) {
    // Entrega indicadores agregados usados pelo painel em tempo real.
    return this.salasService.obterDashboard(id);
  }

  @Get(':id/respostas')
  listarRespostas(@Param('id', ParseIntPipe) id: number) {
    // Entrega alunos e historico detalhado da turma.
    return this.salasService.listarRespostas(id);
  }

  @Get(':id/alunos')
  listarAlunos(@Param('id', ParseIntPipe) id: number) {
    // Fornece posicao e pontuacao atuais para representar os alunos no tabuleiro.
    return this.salasService.listarAlunos(id);
  }

  @Get(':id/ranking')
  obterRanking(@Param('id', ParseIntPipe) id: number) {
    // Retorna a classificacao final separada do dashboard completo.
    return this.salasService.obterRanking(id);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    // Busca os metadados de uma sala pelo identificador interno.
    return this.salasService.buscarPorId(id);
  }

  @Delete(':id')
  remover(@Param('id', ParseIntPipe) id: number) {
    // Remove a sala e os dados vinculados conforme as regras do servico.
    return this.salasService.remover(id);
  }
}
