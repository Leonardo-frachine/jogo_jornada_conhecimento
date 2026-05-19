import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Professor } from './professor.entity';
import { ProfessoresController } from './professores.controller';
import { ProfessoresService } from './professores.service';

@Module({
  imports: [TypeOrmModule.forFeature([Professor])],
  controllers: [ProfessoresController],
  providers: [ProfessoresService],
  exports: [ProfessoresService, TypeOrmModule],
})
export class ProfessoresModule {}
