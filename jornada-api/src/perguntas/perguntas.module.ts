import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PerguntasService } from './perguntas.service';
import { PerguntasController } from './perguntas.controller';
import { Pergunta } from './pergunta.entity';
import { PerguntasAiService } from './perguntas-ai.service';
import { Sala } from '../salas/sala.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Pergunta, Sala])],
  controllers: [PerguntasController],
  providers: [PerguntasService, PerguntasAiService],
})
export class PerguntasModule {}
