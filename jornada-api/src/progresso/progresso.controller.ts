import { Body, Controller, Get, Param, Post } from '@nestjs/common';
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

  @Get('jogador/:jogadorId')
  buscarPorJogador(@Param('jogadorId') jogadorId: string) {
    return this.progressoService.buscarPorJogador(Number(jogadorId));
  }

  @Get(':id')
  buscarPorId(@Param('id') id: string) {
    return this.progressoService.buscarPorId(Number(id));
  }
}