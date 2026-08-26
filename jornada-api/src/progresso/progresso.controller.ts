import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
} from '@nestjs/common';
import { ProgressoService } from './progresso.service';
import { CriarProgressoDto } from './dto/criar-progresso.dto';

@Controller('progresso')
// Expoe eventos de resposta e relatorios derivados do historico.
export class ProgressoController {
  constructor(private readonly progressoService: ProgressoService) {}

  @Post()
  criar(@Body() criarProgressoDto: CriarProgressoDto) {
    // Registra uma resposta e atualiza o resumo do jogador em transacao.
    return this.progressoService.criar(criarProgressoDto);
  }

  @Get()
  listar() {
    // Lista o historico completo para uso administrativo.
    return this.progressoService.listar();
  }

  @Get('relatorios/jogadores')
  relatorioJogadores() {
    // Consolida desempenho de todos os jogadores.
    return this.progressoService.relatorioJogadores();
  }

  @Get('relatorios/jogador/:jogadorId')
  relatorioPorJogador(@Param('jogadorId', ParseIntPipe) jogadorId: number) {
    // Retorna resumo e respostas detalhadas de um aluno.
    return this.progressoService.relatorioPorJogador(jogadorId);
  }

  @Get('jogador/:jogadorId')
  buscarPorJogador(@Param('jogadorId', ParseIntPipe) jogadorId: number) {
    // Consulta somente os eventos vinculados a identidade informada.
    return this.progressoService.buscarPorJogador(jogadorId);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    // Recupera um evento historico especifico.
    return this.progressoService.buscarPorId(id);
  }
}
