import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { JogadoresService } from './jogadores.service';

@Controller('jogadores')
export class JogadoresController {
  constructor(private readonly jogadoresService: JogadoresService) {}

  @Post()
  criar(@Body() body: { nome?: string }) {
    console.log('BODY RECEBIDO:', body);

    const nome = body?.nome?.trim();

    if (!nome) {
      throw new BadRequestException('O campo nome é obrigatório.');
    }

    return this.jogadoresService.criar(nome);
  }

  @Get()
  listar() {
    return this.jogadoresService.listar();
  }

  @Get(':id')
  buscarPorId(@Param('id') id: string) {
    return this.jogadoresService.buscarPorId(Number(id));
  }

  @Patch(':id/pontuacao')
  atualizarPontuacao(
    @Param('id') id: string,
    @Body('pontuacao') pontuacao: number,
  ) {
    return this.jogadoresService.atualizarPontuacao(Number(id), pontuacao);
  }

  @Patch(':id/fase')
  atualizarFase(
    @Param('id') id: string,
    @Body('faseAtual') faseAtual: number,
  ) {
    return this.jogadoresService.atualizarFase(Number(id), faseAtual);
  }
}