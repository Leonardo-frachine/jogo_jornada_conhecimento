import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Jogador } from '../jogadores/jogador.entity';
import { Professor } from '../professores/professor.entity';
import { Progresso } from '../progresso/progresso.entity';
import { Sala } from './sala.entity';
import { SalasController } from './salas.controller';
import { SalasService } from './salas.service';

@Module({
  imports: [TypeOrmModule.forFeature([Sala, Professor, Progresso, Jogador])],
  controllers: [SalasController],
  providers: [SalasService],
  exports: [TypeOrmModule, SalasService],
})
export class SalasModule {}
