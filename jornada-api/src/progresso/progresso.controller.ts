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
export class ProgressoController {
  constructor(private readonly progressoService: ProgressoService) {}

  @Post()
  criar(@Body() criarProgressoDto: CriarProgressoDto) {
    return this.progressoService.criar(criarProgressoDto);
  }

  @Get()
  listar() {
    return this.progressoService.listar();
  }

  @Get('relatorios/jogadores')
  relatorioJogadores() {
    return this.progressoService.relatorioJogadores();
  }

  @Get('relatorios/jogador/:jogadorId')
  relatorioPorJogador(@Param('jogadorId', ParseIntPipe) jogadorId: number) {
    return this.progressoService.relatorioPorJogador(jogadorId);
  }

  @Get('jogador/:jogadorId')
  buscarPorJogador(@Param('jogadorId', ParseIntPipe) jogadorId: number) {
    return this.progressoService.buscarPorJogador(jogadorId);
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    return this.progressoService.buscarPorId(id);
  }
}
