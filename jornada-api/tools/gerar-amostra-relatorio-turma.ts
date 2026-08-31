import * as fs from 'node:fs';
import * as path from 'node:path';
import { PARTIDA_STATUS } from '../src/jogadores/partida-status';
import { RelatorioTurmaPdfService } from '../src/relatorios/relatorio-turma-pdf.service';
import type {
  AlunoRelatorioTurma,
  ClassificacaoDesempenho,
  DesempenhoGrupo,
  QuestaoParaRevisarTurma,
  RelatorioTurma,
  RespostaRelatorio,
} from '../src/relatorios/relatorios.types';

const nomes = [
  'Amanda Ribeiro',
  'Bruno Ferreira',
  'Carolina Souza',
  'Diego Martins',
  'Eduarda Gonçalves',
  'Felipe Almeida',
  'Gabriela Nascimento',
  'Henrique Oliveira',
  'Isabela Costa',
  'João Pedro de Carvalho',
  'Larissa Santos',
  'Marcos Vinícius Rocha',
  'Natália Lima',
  'Otávio Rodrigues',
  'Patrícia Alves',
  'Rafael sem atividade',
  'Sofia sem atividade',
  'Vitória sem atividade',
];
const aproveitamentos = [28, 35, 42, 48, 55, 60, 67, 72, 75, 80, 85, 90, 50, 64, 78];
const materias = ['Matemática', 'Ciências', 'Língua Portuguesa', 'História'];
const dificuldades = ['Fácil', 'Médio', 'Difícil'];
const perguntas = Array.from({ length: 8 }, (_, indice) => ({
  id: 501 + indice,
  titulo: `${materias[indice % materias.length]} - desafio ${indice + 1}`,
  enunciado:
    indice === 3
      ? 'Leia a situação apresentada, relacione as informações do enunciado e escolha a alternativa que melhor explica o conceito estudado.'
      : `Qual alternativa resolve corretamente o desafio ${indice + 1}?`,
  materia: materias[indice % materias.length],
  dificuldade: dificuldades[indice % dificuldades.length],
}));
const inicio = new Date('2026-08-20T13:00:00.000Z');

function classificar(
  respondidas: number,
  percentual: number,
): ClassificacaoDesempenho {
  if (respondidas < 3) return 'amostra_insuficiente';
  if (percentual >= 75) return 'ponto_forte';
  if (percentual < 50) return 'ponto_a_desenvolver';
  return 'em_desenvolvimento';
}

const respostas: RespostaRelatorio[] = [];
const alunos: AlunoRelatorioTurma[] = nomes.map((nome, indice) => {
  const possuiRespostas = indice < aproveitamentos.length;
  const respondidas = possuiRespostas ? 8 + (indice % 5) * 2 : 0;
  const acertos = possuiRespostas
    ? Math.round((respondidas * aproveitamentos[indice]) / 100)
    : 0;
  const aproveitamento =
    respondidas === 0 ? 0 : Math.round((acertos / respondidas) * 100);
  const ultimaAtividade = possuiRespostas
    ? new Date(inicio.getTime() + (indice * 20 + respondidas) * 3_600_000)
    : null;

  for (let respostaIndice = 0; respostaIndice < respondidas; respostaIndice += 1) {
    const pergunta = perguntas[(respostaIndice + indice) % perguntas.length];
    const acertou = ((respostaIndice * 7 + indice * 3) % respondidas) < acertos;
    const pontuacaoBase = 100 + (respostaIndice % 3) * 50;
    respostas.push({
      progressoId: respostas.length + 1,
      salaId: 7,
      salaNome: '7º Ano A - Conhecimentos Integrados',
      salaCodigo: 'JORN7A',
      professorId: 3,
      professorNome: 'Professora Helena Martins',
      alunoId: indice + 1,
      alunoNome: nome,
      perguntaId: pergunta.id,
      perguntaTitulo: pergunta.titulo,
      perguntaEnunciado: pergunta.enunciado,
      materia: pergunta.materia,
      dificuldade: pergunta.dificuldade,
      fase: 1 + (respostaIndice % 4),
      casaAtual: Math.min(28, 2 + respostaIndice),
      respostaEscolhidaLetra: acertou ? 'B' : 'A',
      respostaEscolhidaTexto: acertou ? 'Resposta correta' : 'Resposta escolhida',
      respostaCorretaLetra: 'B',
      respostaCorretaTexto: 'Resposta correta',
      acertou,
      pontuacaoBase,
      pontuacaoGanha: acertou ? pontuacaoBase : -Math.round(pontuacaoBase / 2),
      respondidoEm: new Date(
        inicio.getTime() + (indice * 20 + respostaIndice) * 3_600_000,
      ),
    });
  }

  const historico = respostas.filter((resposta) => resposta.alunoId === indice + 1);
  const pontuacao = historico.reduce(
    (total, resposta) => total + resposta.pontuacaoGanha,
    0,
  );
  return {
    id: indice + 1,
    nome,
    statusPartida:
      possuiRespostas && indice % 3 === 0
        ? PARTIDA_STATUS.FINALIZADO
        : possuiRespostas
          ? PARTIDA_STATUS.JOGANDO
          : PARTIDA_STATUS.INICIADO,
    faseAtual: possuiRespostas ? 1 + (indice % 4) : 1,
    casaAtual: possuiRespostas ? Math.min(28, 5 + indice) : 1,
    pontuacao,
    respondidas,
    acertos,
    erros: respondidas - acertos,
    aproveitamento,
    ultimaAtividade,
    classificacao: classificar(respondidas, aproveitamento),
  };
});

function agrupar(
  selecionar: (resposta: RespostaRelatorio) => string,
): DesempenhoGrupo[] {
  const grupos = new Map<string, RespostaRelatorio[]>();
  respostas.forEach((resposta) => {
    const nome = selecionar(resposta);
    grupos.set(nome, [...(grupos.get(nome) ?? []), resposta]);
  });
  return Array.from(grupos.entries())
    .map(([nome, itens]) => {
      const acertos = itens.filter((item) => item.acertou).length;
      const percentualAcerto = Math.round((acertos / itens.length) * 100);
      return {
        nome,
        respondidas: itens.length,
        acertos,
        erros: itens.length - acertos,
        percentualAcerto,
        classificacao: classificar(itens.length, percentualAcerto),
      };
    })
    .sort((a, b) => b.percentualAcerto - a.percentualAcerto);
}

function questoesParaRevisar(): QuestaoParaRevisarTurma[] {
  return perguntas
    .map((pergunta) => {
      const itens = respostas.filter(
        (resposta) => resposta.perguntaId === pergunta.id,
      );
      const erros = itens.filter((resposta) => !resposta.acertou).length;
      return {
        perguntaId: pergunta.id,
        titulo: pergunta.titulo,
        enunciado: pergunta.enunciado,
        materia: pergunta.materia,
        dificuldade: pergunta.dificuldade,
        respondidas: itens.length,
        erros,
        percentualErro:
          itens.length === 0 ? 0 : Math.round((erros / itens.length) * 100),
      };
    })
    .filter((questao) => questao.erros > 0)
    .sort(
      (a, b) =>
        b.erros - a.erros || b.percentualErro - a.percentualErro,
    );
}

async function main(): Promise<void> {
  const acertos = respostas.filter((resposta) => resposta.acertou).length;
  const alunosComRespostas = alunos.filter(
    (aluno) => aluno.respondidas > 0,
  ).length;
  const pontuacaoTotal = alunos.reduce(
    (total, aluno) => total + aluno.pontuacao,
    0,
  );
  const ordenados = [...alunos].sort(
    (a, b) =>
      Number(a.respondidas === 0) - Number(b.respondidas === 0) ||
      a.aproveitamento - b.aproveitamento ||
      b.respondidas - a.respondidas ||
      a.nome.localeCompare(b.nome, 'pt-BR'),
  );
  const relatorio: RelatorioTurma = {
    geradoEm: new Date('2026-08-31T18:30:00.000Z'),
    sala: { id: 7, nome: '7º Ano A - Conhecimentos Integrados', codigo: 'JORN7A' },
    professor: { id: 3, nome: 'Professora Helena Martins' },
    periodo: {
      inicio: respostas[0]?.respondidoEm ?? null,
      fim: respostas.at(-1)?.respondidoEm ?? null,
    },
    resumo: {
      totalAlunos: alunos.length,
      alunosComRespostas,
      alunosSemRespostas: alunos.length - alunosComRespostas,
      participacao: Math.round((alunosComRespostas / alunos.length) * 100),
      finalizados: alunos.filter(
        (aluno) => aluno.statusPartida === PARTIDA_STATUS.FINALIZADO,
      ).length,
      emAndamento: alunos.filter(
        (aluno) => aluno.statusPartida !== PARTIDA_STATUS.FINALIZADO,
      ).length,
      respondidas: respostas.length,
      acertos,
      erros: respostas.length - acertos,
      aproveitamento: Math.round((acertos / respostas.length) * 100),
      pontuacaoTotal,
      pontuacaoMedia: Math.round(pontuacaoTotal / alunos.length),
    },
    desempenhoPorMateria: agrupar((resposta) => resposta.materia),
    desempenhoPorDificuldade: agrupar((resposta) => resposta.dificuldade),
    alunos: ordenados,
    questoesParaRevisar: questoesParaRevisar(),
  };
  const output = process.env.REPORT_CLASS_SAMPLE_OUTPUT
    ? path.resolve(process.env.REPORT_CLASS_SAMPLE_OUTPUT)
    : path.resolve(
        process.cwd(),
        '..',
        'output',
        'pdf',
        'relatorio_modelo_turma_7_ano_a.pdf',
      );
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, await new RelatorioTurmaPdfService().gerar(relatorio));
  process.stdout.write(`${output}\n`);
}

void main();
