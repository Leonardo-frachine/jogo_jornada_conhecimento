import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { Jogador } from '../jogadores/jogador.entity';
import { JogadoresService } from '../jogadores/jogadores.service';
import { PARTIDA_STATUS } from '../jogadores/partida-status';
import { Pergunta } from '../perguntas/pergunta.entity';
import { Professor } from '../professores/professor.entity';
import { Sala } from '../salas/sala.entity';
import { SalasService } from '../salas/salas.service';
import { Progresso } from './progresso.entity';
import { ProgressoService } from './progresso.service';

// Exercita as regras integradas de resposta, ranking, status e reinicio do jogador.
describe('ProgressoService status da partida', () => {
  let moduleRef: TestingModule;
  let dataSource: DataSource;
  let jogadoresService: JogadoresService;
  let progressoService: ProgressoService;
  let salasService: SalasService;

  beforeEach(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [
        TypeOrmModule.forRoot({
          type: 'better-sqlite3',
          database: ':memory:',
          entities: [Pergunta, Progresso, Jogador, Sala, Professor],
          synchronize: true,
          retryAttempts: 0,
        }),
        TypeOrmModule.forFeature([Progresso, Jogador, Sala, Professor]),
      ],
      providers: [ProgressoService, JogadoresService, SalasService],
    }).compile();

    dataSource = moduleRef.get(DataSource);
    jogadoresService = moduleRef.get(JogadoresService);
    progressoService = moduleRef.get(ProgressoService);
    salasService = moduleRef.get(SalasService);
  });

  afterEach(async () => {
    await moduleRef.close();
  });

  it('mantem resposta como jogando e finaliza somente pelo encerramento oficial', async () => {
    const sala = await criarSala();
    const pergunta = await criarPergunta(sala);
    const jogador = await jogadoresService.criar({
      nome: 'Aluno Status',
      salaId: sala.id,
    });

    expect(jogador.statusPartida).toBe(PARTIDA_STATUS.INICIADO);

    const progresso = await progressoService.criar({
      jogadorId: jogador.id,
      perguntaId: pergunta.id,
      acertou: true,
      fase: 4,
      salaId: sala.id,
      casaAtual: 28,
      statusPartida: PARTIDA_STATUS.FINALIZADO,
    });

    const jogadorAposResposta = await dataSource
      .getRepository(Jogador)
      .findOneByOrFail({ id: jogador.id });

    expect(progresso.statusPartida).toBe(PARTIDA_STATUS.JOGANDO);
    expect(jogadorAposResposta.statusPartida).toBe(PARTIDA_STATUS.JOGANDO);
    expect(jogadorAposResposta.casaAtual).toBe(28);
    const alunosNaSala = await salasService.listarAlunos(sala.id);
    expect(alunosNaSala).toHaveLength(1);
    expect(alunosNaSala[0].jogadorId).toBe(jogador.id);
    expect(alunosNaSala[0].casaAtual).toBe(28);

    const jogadorFinalizado = await jogadoresService.finalizarPartida(
      jogador.id,
      {
        casaAtual: 28,
        venceu: true,
      },
    );

    expect(jogadorFinalizado.statusPartida).toBe(PARTIDA_STATUS.FINALIZADO);
    expect(jogadorFinalizado.casaAtual).toBe(28);
    expect(jogadorFinalizado.finalizadoEm).toBeInstanceOf(Date);
  });

  it('ordena o ranking da sala e inclui somente partidas finalizadas', async () => {
    const sala = await criarSala('RANK01');
    const pergunta = await criarPergunta(sala);
    const lider = await jogadoresService.criar({
      nome: 'Lider',
      salaId: sala.id,
    });
    const empatePrimeiro = await jogadoresService.criar({
      nome: 'Empate Primeiro',
      salaId: sala.id,
    });
    const empateDepois = await jogadoresService.criar({
      nome: 'Empate Depois',
      salaId: sala.id,
    });
    const aindaJogando = await jogadoresService.criar({
      nome: 'Ainda Jogando',
      salaId: sala.id,
    });

    // Cria o total de acertos necessario para estabelecer lideranca e empate no ranking.
    for (const jogador of [lider, lider, empatePrimeiro, empateDepois]) {
      await progressoService.criar({
        jogadorId: jogador.id,
        perguntaId: pergunta.id,
        acertou: true,
        fase: 1,
        salaId: sala.id,
      });
    }
    // Um jogador ainda ativo recebe mais pontos para confirmar que nao entra no ranking final.
    for (let resposta = 0; resposta < 3; resposta += 1) {
      await progressoService.criar({
        jogadorId: aindaJogando.id,
        perguntaId: pergunta.id,
        acertou: true,
        fase: 1,
        salaId: sala.id,
      });
    }

    await jogadoresService.finalizarPartida(lider.id, {});
    await jogadoresService.finalizarPartida(empatePrimeiro.id, {});
    await jogadoresService.finalizarPartida(empateDepois.id, {});
    await dataSource.getRepository(Jogador).update(lider.id, {
      finalizadoEm: new Date('2026-01-01T10:00:03.000Z'),
    });
    await dataSource.getRepository(Jogador).update(empatePrimeiro.id, {
      finalizadoEm: new Date('2026-01-01T10:00:01.000Z'),
    });
    await dataSource.getRepository(Jogador).update(empateDepois.id, {
      finalizadoEm: new Date('2026-01-01T10:00:02.000Z'),
    });

    const ranking = await salasService.obterRanking(sala.id);
    const dashboard = await salasService.obterDashboard(sala.id);

    expect(ranking.ranking.map((item) => item.nome)).toEqual([
      'Lider',
      'Empate Primeiro',
      'Empate Depois',
    ]);
    expect(ranking.ranking.map((item) => item.posicao)).toEqual([1, 2, 3]);
    expect(
      ranking.ranking.every(
        (item) => item.statusPartida === PARTIDA_STATUS.FINALIZADO,
      ),
    ).toBe(true);
    expect(
      ranking.ranking.some((item) => item.jogadorId === aindaJogando.id),
    ).toBe(false);
    expect(dashboard.ranking).toEqual(ranking.ranking);
  });

  it('reutiliza aluno e preserva o historico ao jogar novamente na mesma sala', async () => {
    const sala = await criarSala();
    const pergunta = await criarPergunta(sala);
    const primeiraEntrada = await jogadoresService.criar({
      nome: '  Aluno   Repetido  ',
      salaId: sala.id,
    });

    await progressoService.criar({
      jogadorId: primeiraEntrada.id,
      perguntaId: pergunta.id,
      acertou: true,
      fase: 4,
      salaId: sala.id,
      casaAtual: 28,
    });
    await jogadoresService.finalizarPartida(primeiraEntrada.id, {
      casaAtual: 28,
      venceu: true,
    });
    expect((await salasService.obterRanking(sala.id)).ranking).toHaveLength(1);

    const segundaEntrada = await jogadoresService.criar({
      nome: 'aluno repetido',
      salaCodigo: sala.codigo.toLowerCase(),
    });

    expect(segundaEntrada.id).toBe(primeiraEntrada.id);
    expect(segundaEntrada.pontuacao).toBe(100);
    expect(segundaEntrada.faseAtual).toBe(1);
    expect(segundaEntrada.casaAtual).toBe(1);
    expect(segundaEntrada.statusPartida).toBe(PARTIDA_STATUS.INICIADO);
    expect(segundaEntrada.finalizadoEm).toBeNull();
    expect((await salasService.obterRanking(sala.id)).ranking).toHaveLength(0);

    const respostaIncorreta = await progressoService.criar({
      jogadorId: segundaEntrada.id,
      perguntaId: pergunta.id,
      acertou: false,
      fase: 2,
      salaId: sala.id,
      casaAtual: 1,
    });

    const jogadorAtualizado = await jogadoresService.buscarPorId(
      primeiraEntrada.id,
    );
    const historico = await progressoService.buscarPorJogador(
      primeiraEntrada.id,
    );
    const dashboard = await salasService.obterDashboard(sala.id);
    const acompanhamento = await salasService.listarRespostas(sala.id);
    const ranking = await jogadoresService.listar();
    const relatorio = await progressoService.relatorioPorJogador(
      primeiraEntrada.id,
    );
    const relatorioJogadores = await progressoService.relatorioJogadores();
    const jogadorRecalculado = await jogadoresService.recalcularPontuacao(
      primeiraEntrada.id,
    );

    expect(respostaIncorreta.pontuacaoGanha).toBe(-50);
    expect(respostaIncorreta.pontuacaoTotal).toBe(50);
    expect(jogadorAtualizado.pontuacao).toBe(50);
    expect(jogadorRecalculado.pontuacao).toBe(50);
    expect(historico).toHaveLength(2);
    expect(new Set(historico.map((item) => item.jogadorId)).size).toBe(1);
    expect(dashboard.indicadores.totalAlunos).toBe(1);
    expect(dashboard.indicadores.totalPerguntasRespondidas).toBe(2);
    expect(dashboard.indicadores.pontuacaoTotalTurma).toBe(50);
    expect(acompanhamento.alunos).toHaveLength(1);
    expect(acompanhamento.respostas).toHaveLength(2);
    expect(acompanhamento.alunos[0].pontuacao).toBe(50);
    expect(acompanhamento.alunos[0].casaAtual).toBe(1);
    expect(
      Math.max(...acompanhamento.respostas.map((item) => item.casaAtual)),
    ).toBe(28);
    expect(relatorio.resumo.pontuacao).toBe(50);
    expect(relatorio.resumo.acertos).toBe(1);
    expect(relatorio.resumo.erros).toBe(1);
    expect(
      relatorioJogadores.find((item) => item.jogadorId === primeiraEntrada.id)
        ?.pontuacao,
    ).toBe(50);
    expect(ranking.filter((item) => item.salaId === sala.id)).toHaveLength(1);

    await jogadoresService.finalizarPartida(segundaEntrada.id, {
      casaAtual: 1,
      venceu: false,
    });
    const rankingAposSegundaPartida = await salasService.obterRanking(sala.id);
    expect(rankingAposSegundaPartida.ranking).toHaveLength(1);
    expect(rankingAposSegundaPartida.ranking[0]).toMatchObject({
      jogadorId: primeiraEntrada.id,
      pontuacao: 50,
      statusPartida: PARTIDA_STATUS.FINALIZADO,
    });
  });

  it('cria registros distintos para o mesmo nome em salas diferentes', async () => {
    const primeiraSala = await criarSala('PRIMEIRA');
    const segundaSala = await criarSala('SEGUNDA');

    const primeiroJogador = await jogadoresService.criar({
      nome: 'Mesmo Nome',
      salaId: primeiraSala.id,
    });
    const segundoJogador = await jogadoresService.criar({
      nome: 'Mesmo Nome',
      salaId: segundaSala.id,
    });

    expect(segundoJogador.id).not.toBe(primeiroJogador.id);
  });

  it('nao duplica o aluno quando duas entradas na sala acontecem juntas', async () => {
    const sala = await criarSala('JUNTOS');

    const [primeiraEntrada, segundaEntrada] = await Promise.all([
      jogadoresService.criar({ nome: 'Aluno Simultaneo', salaId: sala.id }),
      jogadoresService.criar({ nome: 'aluno simultaneo', salaId: sala.id }),
    ]);

    const jogadoresDaSala = (await jogadoresService.listar()).filter(
      (item) => item.salaId === sala.id,
    );

    expect(segundaEntrada.id).toBe(primeiraEntrada.id);
    expect(jogadoresDaSala).toHaveLength(1);
  });

  it('arredonda para cima o desconto de metade de uma pontuacao impar', async () => {
    const sala = await criarSala('IMPAR1');
    const pergunta = await criarPergunta(sala, 101);
    const jogador = await jogadoresService.criar({
      nome: 'Aluno Pontuacao Impar',
      salaId: sala.id,
    });

    const resposta = await progressoService.criar({
      jogadorId: jogador.id,
      perguntaId: pergunta.id,
      acertou: false,
      fase: 1,
      salaId: sala.id,
    });

    expect(resposta.pontuacaoGanha).toBe(-51);
    expect(resposta.pontuacaoTotal).toBe(-51);
  });

  it('impede registrar progresso em uma sala diferente da sala do aluno', async () => {
    const salaDoAluno = await criarSala('ALUNO1');
    const outraSala = await criarSala('OUTRA1');
    const pergunta = await criarPergunta(outraSala);
    const jogador = await jogadoresService.criar({
      nome: 'Aluno Vinculado',
      salaId: salaDoAluno.id,
    });

    await expect(
      progressoService.criar({
        jogadorId: jogador.id,
        perguntaId: pergunta.id,
        acertou: true,
        fase: 1,
        salaId: outraSala.id,
      }),
    ).rejects.toThrow('O jogador nao pertence a sala informada.');
  });

  it('impede responder uma pergunta pertencente a outra sala', async () => {
    const salaDoAluno = await criarSala('QUESTA');
    const salaDaPergunta = await criarSala('QUESTB');
    const pergunta = await criarPergunta(salaDaPergunta);
    const jogador = await jogadoresService.criar({
      nome: 'Aluno Isolado',
      salaId: salaDoAluno.id,
    });

    await expect(
      progressoService.criar({
        jogadorId: jogador.id,
        perguntaId: pergunta.id,
        acertou: true,
        fase: 1,
        salaId: salaDoAluno.id,
      }),
    ).rejects.toThrow('A pergunta nao pertence a sala informada.');
  });

  it('impede novas respostas para uma pergunta eliminada do banco', async () => {
    const sala = await criarSala('INATIVA');
    const pergunta = await criarPergunta(sala);
    const jogador = await jogadoresService.criar({
      nome: 'Aluno Pergunta Inativa',
      salaId: sala.id,
    });
    await dataSource.getRepository(Pergunta).update(pergunta.id, {
      ativa: false,
    });

    await expect(
      progressoService.criar({
        jogadorId: jogador.id,
        perguntaId: pergunta.id,
        acertou: true,
        fase: 1,
        salaId: sala.id,
      }),
    ).rejects.toThrow('Pergunta não encontrada.');
  });

  async function criarSala(codigo = 'STATUS'): Promise<Sala> {
    const professor = await dataSource.getRepository(Professor).save({
      nome: 'Professora',
      email: `professora-${codigo.toLowerCase()}@example.com`,
      senhaHash: 'hash',
    });

    return dataSource.getRepository(Sala).save({
      professorId: professor.id,
      professor,
      nome: 'Sala Status',
      codigo,
      ativa: true,
    });
  }

  async function criarPergunta(sala: Sala, pontuacao = 100): Promise<Pergunta> {
    return dataSource.getRepository(Pergunta).save({
      salaId: sala.id,
      sala,
      titulo: 'Pergunta de status',
      enunciado: 'Qual alternativa esta correta?',
      alternativaA: 'A',
      alternativaB: 'B',
      alternativaC: 'C',
      alternativaD: 'D',
      respostaCorreta: 'A',
      materia: 'Teste',
      dificuldade: '4',
      pontuacao,
      tempoLimite: 30,
    });
  }
});
