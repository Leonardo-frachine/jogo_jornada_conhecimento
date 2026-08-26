import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProgressoService } from './progresso.service';
import { ProgressoController } from './progresso.controller';
import { Progresso } from './progresso.entity';
import { Jogador } from '../jogadores/jogador.entity';
import { Pergunta } from '../perguntas/pergunta.entity';
import { Sala } from '../salas/sala.entity';

@Module({
  // O registro de resposta precisa validar e relacionar jogador, pergunta e sala.
  imports: [TypeOrmModule.forFeature([Progresso, Jogador, Pergunta, Sala])],
  controllers: [ProgressoController],
  providers: [ProgressoService],
})
// Modulo responsavel pelo historico imutavel e pelos relatorios de desempenho.
export class ProgressoModule {}
