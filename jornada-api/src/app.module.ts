import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JogadoresModule } from './jogadores/jogadores.module';
import { PerguntasModule } from './perguntas/perguntas.module';
import { ProgressoModule } from './progresso/progresso.module';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'sqlite',
      database: 'jornada_conhecimento.sqlite',
      autoLoadEntities: true,
      synchronize: true,
    }),
    JogadoresModule,
    PerguntasModule,
    ProgressoModule,
  ],
})
export class AppModule {}