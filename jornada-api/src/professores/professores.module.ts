import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Professor } from './professor.entity';
import { ProfessoresController } from './professores.controller';
import { ProfessoresService } from './professores.service';

@Module({
  // Registra o repositorio de professor e os pontos de entrada de autenticacao.
  imports: [TypeOrmModule.forFeature([Professor])],
  controllers: [ProfessoresController],
  providers: [ProfessoresService],
  exports: [ProfessoresService, TypeOrmModule],
})
// Exporta o servico para modulos que precisam validar o proprietario de uma sala.
export class ProfessoresModule {}
