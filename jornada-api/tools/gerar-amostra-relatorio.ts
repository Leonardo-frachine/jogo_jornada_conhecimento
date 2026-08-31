import * as fs from 'node:fs';
import * as path from 'node:path';
import { PARTIDA_STATUS } from '../src/jogadores/partida-status';
import { RelatorioPdfService } from '../src/relatorios/relatorio-pdf.service';
import type {
  DesempenhoGrupo,
  RelatorioAluno,
  RespostaRelatorio,
} from '../src/relatorios/relatorios.types';

const materias = ['Matematica', 'Ciencias', 'Lingua Portuguesa'];
const dificuldades = ['Facil', 'Medio', 'Dificil'];
const baseDate = new Date('2026-08-25T13:00:00.000Z');

const respostas: RespostaRelatorio[] = Array.from(
  { length: 24 },
  (_, indice) => {
    const materia = materias[indice % materias.length];
    const dificuldade = dificuldades[indice % dificuldades.length];
    const acertou =
      materia === 'Matematica'
        ? indice % 6 !== 0
        : materia === 'Ciencias'
          ? indice % 4 !== 1
          : indice % 3 === 0;
    const correta = ['A', 'B', 'C', 'D'][indice % 4];
    const escolhida = acertou
      ? correta
      : ['A', 'B', 'C', 'D'][(indice + 1) % 4];
    const pontuacaoBase = 100 + (indice % 3) * 50;
    return {
      progressoId: indice + 1,
      salaId: 7,
      salaNome: '7 Ano A - Conhecimentos Integrados',
      salaCodigo: 'JORN7A',
      professorId: 3,
      professorNome: 'Professora Helena Martins',
      alunoId: 42,
      alunoNome: 'Ana Clara de Oliveira',
      perguntaId: 100 + indice,
      perguntaTitulo: `${materia} - atividade ${indice + 1}`,
      perguntaEnunciado:
        indice === 17
          ? 'Leia atentamente a situacao apresentada e identifique a alternativa que melhor explica a relacao entre as informacoes do enunciado, considerando os conceitos estudados em sala de aula.'
          : `Qual alternativa resolve corretamente a atividade ${indice + 1} de ${materia}?`,
      materia,
      dificuldade,
      fase: 1 + (indice % 4),
      casaAtual: Math.min(28, indice + 2),
      respostaEscolhidaLetra: escolhida,
      respostaEscolhidaTexto: `Alternativa escolhida pelo aluno para a atividade ${indice + 1}`,
      respostaCorretaLetra: correta,
      respostaCorretaTexto: `Alternativa correta explicada para a atividade ${indice + 1}`,
      acertou,
      pontuacaoBase,
      pontuacaoGanha: acertou ? pontuacaoBase : -Math.round(pontuacaoBase / 2),
      respondidoEm: new Date(baseDate.getTime() + indice * 3_600_000),
    };
  },
);

function agrupar(
  valores: RespostaRelatorio[],
  selecionar: (item: RespostaRelatorio) => string,
): DesempenhoGrupo[] {
  const grupos = new Map<string, RespostaRelatorio[]>();
  valores.forEach((item) => {
    const nome = selecionar(item);
    grupos.set(nome, [...(grupos.get(nome) ?? []), item]);
  });
  return Array.from(grupos.entries()).map(([nome, itens]) => {
    const acertos = itens.filter((item) => item.acertou).length;
    const percentualAcerto = Math.round((acertos / itens.length) * 100);
    return {
      nome,
      respondidas: itens.length,
      acertos,
      erros: itens.length - acertos,
      percentualAcerto,
      classificacao:
        percentualAcerto >= 75
          ? 'ponto_forte'
          : percentualAcerto < 50
            ? 'ponto_a_desenvolver'
            : 'em_desenvolvimento',
    };
  });
}

async function main(): Promise<void> {
  const desempenhoPorMateria = agrupar(respostas, (item) => item.materia);
  const desempenhoPorDificuldade = agrupar(
    respostas,
    (item) => item.dificuldade,
  );
  const acertos = respostas.filter((item) => item.acertou).length;
  const relatorio: RelatorioAluno = {
    geradoEm: new Date('2026-08-31T18:30:00.000Z'),
    sala: {
      id: 7,
      nome: '7 Ano A - Conhecimentos Integrados',
      codigo: 'JORN7A',
    },
    professor: { id: 3, nome: 'Professora Helena Martins' },
    aluno: {
      id: 42,
      nome: 'Ana Clara de Oliveira',
      statusPartida: PARTIDA_STATUS.FINALIZADO,
      faseAtual: 4,
      casaAtual: 28,
      finalizadoEm: respostas.at(-1)?.respondidoEm ?? null,
    },
    periodo: {
      inicio: respostas[0].respondidoEm,
      fim: respostas.at(-1)?.respondidoEm ?? null,
    },
    resumo: {
      pontuacao: respostas.reduce(
        (total, item) => total + item.pontuacaoGanha,
        0,
      ),
      respondidas: respostas.length,
      acertos,
      erros: respostas.length - acertos,
      aproveitamento: Math.round((acertos / respostas.length) * 100),
      ultimaAtividade: respostas.at(-1)?.respondidoEm ?? null,
    },
    desempenhoPorMateria,
    desempenhoPorDificuldade,
    pontosFortes: desempenhoPorMateria.filter(
      (grupo) => grupo.classificacao === 'ponto_forte',
    ),
    pontosADesenvolver: desempenhoPorMateria.filter(
      (grupo) => grupo.classificacao === 'ponto_a_desenvolver',
    ),
    recomendacoes: [
      'Priorizar a revisao de Lingua Portuguesa, retomando as questoes incorretas e registrando as estrategias de leitura utilizadas.',
      'Manter o bom desempenho em Ciencias com desafios de dificuldade progressiva e explicacao do raciocinio empregado.',
      'Realizar uma nova verificacao curta apos a revisao para acompanhar a evolucao do aproveitamento.',
    ],
    respostas,
    erros: respostas.filter((item) => !item.acertou).reverse(),
  };

  const output = process.env.REPORT_SAMPLE_OUTPUT
    ? path.resolve(process.env.REPORT_SAMPLE_OUTPUT)
    : path.resolve(
        process.cwd(),
        '..',
        'output',
        'pdf',
        'relatorio_modelo_ana_clara.pdf',
      );
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, await new RelatorioPdfService().gerar(relatorio));
  process.stdout.write(`${output}\n`);
}

void main();
