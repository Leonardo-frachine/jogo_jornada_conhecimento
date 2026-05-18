import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { JogadoresModule } from './jogadores/jogadores.module';
import { PerguntasModule } from './perguntas/perguntas.module';
import { ProgressoModule } from './progresso/progresso.module';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'better-sqlite3',
      database:
        process.env.NODE_ENV === 'test'
          ? ':memory:'
          : (process.env.DATABASE_PATH ?? 'jornada_conhecimento.sqlite'),
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
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
