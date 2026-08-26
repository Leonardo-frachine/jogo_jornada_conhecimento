import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JogadoresService } from './jogadores.service';
import { JogadoresController } from './jogadores.controller';
import { Jogador } from './jogador.entity';
import { Progresso } from '../progresso/progresso.entity';
import { Sala } from '../salas/sala.entity';

@Module({
  // Jogador depende do historico para recalculo e da sala para validar sua turma.
  imports: [TypeOrmModule.forFeature([Jogador, Progresso, Sala])],
  controllers: [JogadoresController],
  providers: [JogadoresService],
})
// Modulo do estado corrente e encerramento de partidas dos alunos.
export class JogadoresModule {}
