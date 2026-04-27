import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JogadoresService } from './jogadores.service';
import { JogadoresController } from './jogadores.controller';
import { Jogador } from './jogador.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Jogador])],
  controllers: [JogadoresController],
  providers: [JogadoresService],
})
export class JogadoresModule {}