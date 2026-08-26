import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PerguntasService } from './perguntas.service';
import { PerguntasController } from './perguntas.controller';
import { Pergunta } from './pergunta.entity';
import { PerguntasAiService } from './perguntas-ai.service';
import { Sala } from '../salas/sala.entity';

@Module({
  // Registra pergunta e sala para CRUD/importacao e o cliente de geracao por IA.
  imports: [TypeOrmModule.forFeature([Pergunta, Sala])],
  controllers: [PerguntasController],
  providers: [PerguntasService, PerguntasAiService],
})
// Modulo do banco de perguntas isolado por sala.
export class PerguntasModule {}
