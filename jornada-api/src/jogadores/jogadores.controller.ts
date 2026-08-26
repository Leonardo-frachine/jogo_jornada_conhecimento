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
// Expoe o ciclo de vida do jogador sem duplicar regras presentes no servico.
export class JogadoresController {
  constructor(private readonly jogadoresService: JogadoresService) {}

  @Post()
  criar(@Body() criarJogadorDto: CriarJogadorDto) {
    // Cadastra ou reutiliza o aluno dentro da sala informada.
    return this.jogadoresService.criar(criarJogadorDto);
  }

  @Get()
  listar() {
    // Lista jogadores pela pontuacao para consultas administrativas/legadas.
    return this.jogadoresService.listar();
  }

  @Get(':id')
  buscarPorId(@Param('id', ParseIntPipe) id: number) {
    // Recupera o estado resumido de um jogador especifico.
    return this.jogadoresService.buscarPorId(id);
  }

  @Patch(':id/pontuacao')
  recalcularPontuacao(@Param('id', ParseIntPipe) id: number) {
    // Reconstroi pontuacao e fase a partir do historico de progresso.
    return this.jogadoresService.recalcularPontuacao(id);
  }

  @Patch(':id/fase')
  atualizarFase(
    @Param('id', ParseIntPipe) id: number,
    @Body() atualizarFaseDto: AtualizarFaseDto,
  ) {
    // Atualiza somente a fase atual apos validacao do DTO.
    return this.jogadoresService.atualizarFase(id, atualizarFaseDto.faseAtual);
  }

  @Patch(':id/finalizar-partida')
  finalizarPartida(
    @Param('id', ParseIntPipe) id: number,
    @Body() finalizarPartidaDto: FinalizarPartidaDto,
  ) {
    // Marca a conclusao oficial; sair da tela nao chama este endpoint automaticamente.
    return this.jogadoresService.finalizarPartida(id, finalizarPartidaDto);
  }
}
