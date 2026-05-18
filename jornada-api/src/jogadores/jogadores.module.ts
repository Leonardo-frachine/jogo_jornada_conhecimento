import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JogadoresService } from './jogadores.service';
import { JogadoresController } from './jogadores.controller';
import { Jogador } from './jogador.entity';
import { Progresso } from '../progresso/progresso.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Jogador, Progresso])],
  controllers: [JogadoresController],
  providers: [JogadoresService],
})
export class JogadoresModule {}
