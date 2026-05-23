import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { JogadoresModule } from './jogadores/jogadores.module';
import { PerguntasModule } from './perguntas/perguntas.module';
import { ProfessoresModule } from './professores/professores.module';
import { ProgressoModule } from './progresso/progresso.module';
import { SalasModule } from './salas/salas.module';

function resolveDatabasePath(): string {
  if (process.env.NODE_ENV === 'test') {
    return ':memory:';
  }

  const configuredPath = process.env.DATABASE_PATH?.trim();
  const databasePath = configuredPath || 'jornada_conhecimento.sqlite';
  const resolvedDatabasePath = path.resolve(databasePath);

  ensureSeedDatabase(resolvedDatabasePath);

  return resolvedDatabasePath;
}

function ensureSeedDatabase(databasePath: string): void {
  const configuredSeedPath = process.env.DATABASE_SEED_PATH?.trim();
  const seedPath = configuredSeedPath || 'jornada_conhecimento.sqlite';
  const resolvedSeedPath = path.resolve(seedPath);

  if (databasePath === resolvedSeedPath) {
    return;
  }

  if (fs.existsSync(databasePath) || !fs.existsSync(resolvedSeedPath)) {
    return;
  }

  fs.mkdirSync(path.dirname(databasePath), { recursive: true });
  fs.copyFileSync(resolvedSeedPath, databasePath);
}

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'better-sqlite3',
      database: resolveDatabasePath(),
      retryAttempts: process.env.NODE_ENV === 'test' ? 0 : 10,
      timeout: process.env.NODE_ENV === 'test' ? 0 : 10000,
      prepareDatabase: (db) => {
        db.pragma('busy_timeout = 10000');
      },
      autoLoadEntities: true,
      synchronize: process.env.DB_SYNCHRONIZE !== 'false',
    }),
    JogadoresModule,
    PerguntasModule,
    ProgressoModule,
    ProfessoresModule,
    SalasModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
