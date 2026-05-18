import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PerguntasService } from './perguntas.service';
import { PerguntasController } from './perguntas.controller';
import { Pergunta } from './pergunta.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Pergunta])],
  controllers: [PerguntasController],
  providers: [PerguntasService],
})
export class PerguntasModule {}
