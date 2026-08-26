import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { createDatabaseOptions } from './database/database.config';
import { JogadoresModule } from './jogadores/jogadores.module';
import { PerguntasModule } from './perguntas/perguntas.module';
import { ProfessoresModule } from './professores/professores.module';
import { ProgressoModule } from './progresso/progresso.module';
import { SalasModule } from './salas/salas.module';

@Module({
  // Inicializa o banco antes dos modulos que dependem de repositorios TypeORM.
  imports: [
    TypeOrmModule.forRoot(createDatabaseOptions()),
    JogadoresModule,
    PerguntasModule,
    ProgressoModule,
    ProfessoresModule,
    SalasModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
// Modulo raiz que compoe todos os dominios do backend.
export class AppModule {}
