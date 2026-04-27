import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProgressoService } from './progresso.service';
import { ProgressoController } from './progresso.controller';
import { Progresso } from './progresso.entity';
import { Jogador } from '../jogadores/jogador.entity';
import { Pergunta } from '../perguntas/pergunta.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Progresso, Jogador, Pergunta])],
  controllers: [ProgressoController],
  providers: [ProgressoService],
})
export class ProgressoModule {}