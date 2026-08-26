import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { Jogador } from '../jogadores/jogador.entity';
import { Pergunta } from './pergunta.entity';
import { PerguntasService } from './perguntas.service';
import { Professor } from '../professores/professor.entity';
import { Progresso } from '../progresso/progresso.entity';
import { Sala } from '../salas/sala.entity';

// Valida isolamento por sala, importacao e compatibilidade com perguntas legadas.
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
        TypeOrmModule.forFeature([Pergunta, Sala]),
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
    const jogador = await dataSource
      .getRepository(Jogador)
      .save({ nome: 'Teste' });

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

    const perguntas = await dataSource.query<Array<{ id: number }>>(
      'SELECT id FROM perguntas ORDER BY id ASC',
    );
    const progresso = await dataSource.query<Array<{ perguntaId: number }>>(
      'SELECT perguntaId FROM progresso ORDER BY id ASC',
    );
    const sequencia = await dataSource.query<Array<{ seq: number }>>(
      "SELECT seq FROM sqlite_sequence WHERE name = 'perguntas'",
    );

    expect(perguntas.map((pergunta) => pergunta.id)).toEqual([1, 2, 3, 4]);
    expect(progresso.map((registro) => registro.perguntaId)).toEqual([1, 3]);
    expect(sequencia[0]?.seq).toBe(4);
  });

  it('oculta a pergunta removida sem apagar seu historico', async () => {
    const sala = await criarSala('SEQUENCIA');
    const primeiraPergunta = await service.criar({
      salaId: sala.id,
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

    const jogador = await dataSource.getRepository(Jogador).save({
      nome: 'Aluno Historico',
      salaId: sala.id,
      sala,
    });
    await dataSource.getRepository(Progresso).save({
      jogadorId: jogador.id,
      perguntaId: primeiraPergunta.id,
      salaId: sala.id,
      jogador,
      pergunta: primeiraPergunta,
      sala,
      acertou: true,
      fase: 1,
      pontuacaoGanha: 100,
    });

    await service.remover(primeiraPergunta.id, sala.id);

    expect(await service.listar(sala.id)).toHaveLength(0);
    expect(
      await dataSource.getRepository(Pergunta).findOneByOrFail({
        id: primeiraPergunta.id,
      }),
    ).toMatchObject({ ativa: false });
    expect(await dataSource.getRepository(Progresso).count()).toBe(1);

    const segundaPergunta = await service.criar({
      salaId: sala.id,
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

    expect(segundaPergunta.id).toBe(2);
  });

  it('isola criacao, importacao e listagem por sala', async () => {
    const primeiraSala = await criarSala('BANCO-A');
    const segundaSala = await criarSala('BANCO-B');
    const perguntaPrimeiraSala = await service.criar({
      salaId: primeiraSala.id,
      enunciado: 'Pergunta exclusiva da primeira sala?',
      alternativaA: 'A',
      alternativaB: 'B',
      alternativaC: 'C',
      alternativaD: 'D',
      respostaCorreta: 'A',
      materia: 'Teste',
      dificuldade: '1',
      pontuacao: 100,
    });

    await service.importarPlanilha(
      'modelo_perguntas.csv',
      Buffer.from(
        [
          'enunciado,alternativaA,alternativaB,alternativaC,alternativaD,respostaCorreta,materia,dificuldade,titulo,pontuacao,tempoLimite',
          'Pergunta exclusiva da segunda sala?,A,B,C,D,B,Teste,2,Modelo,200,30',
        ].join('\n'),
      ).toString('base64'),
      segundaSala.id,
    );

    const perguntasPrimeiraSala = await service.listar(primeiraSala.id);
    const perguntasSegundaSala = await service.listar(segundaSala.id);

    expect(perguntasPrimeiraSala).toHaveLength(1);
    expect(perguntasPrimeiraSala[0].salaId).toBe(primeiraSala.id);
    expect(perguntasSegundaSala).toHaveLength(1);
    expect(perguntasSegundaSala[0].salaId).toBe(segundaSala.id);
    expect(perguntasSegundaSala[0]).toMatchObject({
      titulo: 'Modelo',
      pontuacao: 200,
      tempoLimite: 30,
    });
    await expect(
      service.buscarPorId(perguntaPrimeiraSala.id, segundaSala.id),
    ).rejects.toThrow('Pergunta nao encontrada.');

    const resultadoRemocao = await service.removerTodasDaSala(primeiraSala.id);

    expect(resultadoRemocao.total).toBe(1);
    expect(await service.listar(primeiraSala.id)).toHaveLength(0);
    expect(await service.listar(segundaSala.id)).toHaveLength(1);
  });

  it('migra perguntas legadas para cada sala sem apagar historico', async () => {
    const primeiraSala = await criarSala('MIGRA-A');
    const segundaSala = await criarSala('MIGRA-B');
    const jogador = await dataSource.getRepository(Jogador).save({
      nome: 'Aluno com historico',
      salaId: primeiraSala.id,
      sala: primeiraSala,
    });
    const perguntaReferenciada = await dataSource.getRepository(Pergunta).save({
      enunciado: 'Pergunta antiga com historico',
      alternativaA: 'A',
      alternativaB: 'B',
      alternativaC: 'C',
      alternativaD: 'D',
      respostaCorreta: 'A',
      pontuacao: 100,
    });
    await dataSource.getRepository(Pergunta).save({
      enunciado: 'Pergunta antiga sem historico',
      alternativaA: 'A',
      alternativaB: 'B',
      alternativaC: 'C',
      alternativaD: 'D',
      respostaCorreta: 'B',
      pontuacao: 100,
    });
    await dataSource.getRepository(Progresso).save({
      jogadorId: jogador.id,
      perguntaId: perguntaReferenciada.id,
      salaId: primeiraSala.id,
      jogador,
      pergunta: perguntaReferenciada,
      sala: primeiraSala,
      acertou: true,
      fase: 1,
      pontuacaoGanha: 100,
    });

    await service.onModuleInit();

    const perguntasComSala = await dataSource
      .getRepository(Pergunta)
      .createQueryBuilder('pergunta')
      .where('pergunta.salaId IS NOT NULL')
      .getMany();
    const perguntasLegadas = await dataSource
      .getRepository(Pergunta)
      .createQueryBuilder('pergunta')
      .where('pergunta.salaId IS NULL')
      .getMany();
    const historico = await dataSource.getRepository(Progresso).find();

    expect(perguntasComSala).toHaveLength(4);
    expect(
      perguntasComSala.filter(
        (pergunta) => pergunta.salaId === primeiraSala.id,
      ),
    ).toHaveLength(2);
    expect(
      perguntasComSala.filter((pergunta) => pergunta.salaId === segundaSala.id),
    ).toHaveLength(2);
    expect(perguntasLegadas).toHaveLength(1);
    expect(perguntasLegadas[0].id).toBe(perguntaReferenciada.id);
    expect(historico).toHaveLength(1);
    expect(historico[0].perguntaId).toBe(perguntaReferenciada.id);
  });

  async function criarSala(codigo: string): Promise<Sala> {
    const professor = await dataSource.getRepository(Professor).save({
      nome: 'Professora',
      email: `${codigo.toLowerCase()}@example.com`,
      senhaHash: 'hash',
    });

    return dataSource.getRepository(Sala).save({
      professorId: professor.id,
      professor,
      nome: `Sala ${codigo}`,
      codigo,
      ativa: true,
    });
  }
});
