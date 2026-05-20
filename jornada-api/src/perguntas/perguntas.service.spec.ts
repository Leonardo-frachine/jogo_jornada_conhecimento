import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { Jogador } from '../jogadores/jogador.entity';
import { Pergunta } from './pergunta.entity';
import { PerguntasService } from './perguntas.service';
import { Professor } from '../professores/professor.entity';
import { Progresso } from '../progresso/progresso.entity';
import { Sala } from '../salas/sala.entity';

describe('PerguntasService', () => {
  let moduleRef: TestingModule;
  let service: PerguntasService;
  let dataSource: DataSource;

  beforeEach(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [
        TypeOrmModule.forRoot({
          type: 'better-sqlite3',
          database: ':memory:',
          entities: [Pergunta, Progresso, Jogador, Sala, Professor],
          synchronize: true,
        }),
        TypeOrmModule.forFeature([Pergunta]),
      ],
      providers: [PerguntasService],
    }).compile();

    service = moduleRef.get(PerguntasService);
    dataSource = moduleRef.get(DataSource);
  });

  afterEach(async () => {
    await moduleRef.close();
  });

  it('normaliza ids de perguntas e atualiza referencias em progresso', async () => {
    const jogador = await dataSource.getRepository(Jogador).save({ nome: 'Teste' });

    await dataSource.query(
      `
        INSERT INTO perguntas (
          id,
          enunciado,
          alternativaA,
          alternativaB,
          alternativaC,
          alternativaD,
          respostaCorreta,
          pontuacao
        ) VALUES
          (46, 'Pergunta 46', 'A1', 'B1', 'C1', 'D1', 'A', 100),
          (47, 'Pergunta 47', 'A2', 'B2', 'C2', 'D2', 'B', 100),
          (48, 'Pergunta 48', 'A3', 'B3', 'C3', 'D3', 'C', 100),
          (49, 'Pergunta 49', 'A4', 'B4', 'C4', 'D4', 'D', 100)
      `,
    );

    await dataSource.query(
      `
        INSERT INTO progresso (
          jogadorId,
          perguntaId,
          acertou,
          fase,
          pontuacaoGanha
        ) VALUES
          (?, 46, 1, 1, 100),
          (?, 48, 0, 2, 0)
      `,
      [jogador.id, jogador.id],
    );

    await service.onModuleInit();

    const perguntas = await dataSource.query(
      'SELECT id FROM perguntas ORDER BY id ASC',
    );
    const progresso = await dataSource.query(
      'SELECT perguntaId FROM progresso ORDER BY id ASC',
    );
    const sequencia = await dataSource.query(
      "SELECT seq FROM sqlite_sequence WHERE name = 'perguntas'",
    );

    expect(perguntas.map((pergunta: { id: number }) => pergunta.id)).toEqual([
      1, 2, 3, 4,
    ]);
    expect(
      progresso.map((registro: { perguntaId: number }) => registro.perguntaId),
    ).toEqual([1, 3]);
    expect(sequencia[0]?.seq).toBe(4);
  });

  it('reinicia a sequencia quando todas as perguntas sao removidas', async () => {
    const primeiraPergunta = await service.criar({
      titulo: 'Primeira',
      enunciado: 'Quanto e 1 + 1?',
      alternativaA: '1',
      alternativaB: '2',
      alternativaC: '3',
      alternativaD: '4',
      respostaCorreta: 'B',
      materia: 'Matematica',
      dificuldade: '1',
      pontuacao: 100,
      tempoLimite: 30,
    });

    expect(primeiraPergunta.id).toBe(1);

    await service.remover(primeiraPergunta.id);

    const segundaPergunta = await service.criar({
      titulo: 'Segunda',
      enunciado: 'Quanto e 2 + 2?',
      alternativaA: '2',
      alternativaB: '3',
      alternativaC: '4',
      alternativaD: '5',
      respostaCorreta: 'C',
      materia: 'Matematica',
      dificuldade: '1',
      pontuacao: 100,
      tempoLimite: 30,
    });

    expect(segundaPergunta.id).toBe(1);
  });
});
