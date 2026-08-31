import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Jogador } from '../jogadores/jogador.entity';
import { Progresso } from '../progresso/progresso.entity';
import { Sala } from '../salas/sala.entity';
import { RelatorioPdfService } from './relatorio-pdf.service';
import { RelatoriosController } from './relatorios.controller';
import { RelatoriosService } from './relatorios.service';

@Module({
  imports: [TypeOrmModule.forFeature([Sala, Jogador, Progresso])],
  controllers: [RelatoriosController],
  providers: [RelatoriosService, RelatorioPdfService],
  exports: [RelatoriosService, RelatorioPdfService],
})
export class RelatoriosModule {}
