import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { JogadoresService } from './jogadores.service';
import { AtualizarFaseDto } from './dto/atualizar-fase.dto';
import { CriarJogadorDto } from './dto/criar-jogador.dto';
import { FinalizarPartidaDto } from './dto/finalizar-partida.dto';

@Controller('jogadores')
export class JogadoresController {
  constructor(private readonly jogadoresService: JogadoresService) {}

  @Post()
  criar(@Body() criarJogadorDto: CriarJogadorDto) {
    return this.jogadoresService.criar(criarJogadorDto);
  }

  @Get()
  listar() {
    return this.jogadoresService.listar();
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    return this.jogadoresService.buscarPorId(id);
  }

  @Patch(':id/pontuacao')
  recalcularPontuacao(@Param('id', ParseIntPipe) id: number) {
    return this.jogadoresService.recalcularPontuacao(id);
  }

  @Patch(':id/fase')
  atualizarFase(
    @Param('id', ParseIntPipe) id: number,
    @Body() atualizarFaseDto: AtualizarFaseDto,
  ) {
    return this.jogadoresService.atualizarFase(id, atualizarFaseDto.faseAtual);
  }

  @Patch(':id/finalizar-partida')
  finalizarPartida(
    @Param('id', ParseIntPipe) id: number,
    @Body() finalizarPartidaDto: FinalizarPartidaDto,
  ) {
    return this.jogadoresService.finalizarPartida(id, finalizarPartidaDto);
  }
}
