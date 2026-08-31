import type { PartidaStatus } from '../jogadores/partida-status';

export type ClassificacaoDesempenho =
  | 'ponto_forte'
  | 'em_desenvolvimento'
  | 'ponto_a_desenvolver'
  | 'amostra_insuficiente';

export type DesempenhoGrupo = {
  nome: string;
  respondidas: number;
  acertos: number;
  erros: number;
  percentualAcerto: number;
  classificacao: ClassificacaoDesempenho;
};

export type RespostaRelatorio = {
  progressoId: number;
  salaId: number;
  salaNome: string;
  salaCodigo: string;
  professorId: number;
  professorNome: string;
  alunoId: number;
  alunoNome: string;
  perguntaId: number;
  perguntaTitulo: string;
  perguntaEnunciado: string;
  materia: string;
  dificuldade: string;
  fase: number;
  casaAtual: number;
  respostaEscolhidaLetra: string | null;
  respostaEscolhidaTexto: string | null;
  respostaCorretaLetra: string;
  respostaCorretaTexto: string;
  acertou: boolean;
  pontuacaoBase: number;
  pontuacaoGanha: number;
  respondidoEm: Date;
};

export type RelatorioAluno = {
  geradoEm: Date;
  sala: {
    id: number;
    nome: string;
    codigo: string;
  };
  professor: {
    id: number;
    nome: string;
  };
  aluno: {
    id: number;
    nome: string;
    statusPartida: PartidaStatus;
    faseAtual: number;
    casaAtual: number;
    finalizadoEm: Date | null;
  };
  periodo: {
    inicio: Date | null;
    fim: Date | null;
  };
  resumo: {
    pontuacao: number;
    respondidas: number;
    acertos: number;
    erros: number;
    aproveitamento: number;
    ultimaAtividade: Date | null;
  };
  desempenhoPorMateria: DesempenhoGrupo[];
  desempenhoPorDificuldade: DesempenhoGrupo[];
  pontosFortes: DesempenhoGrupo[];
  pontosADesenvolver: DesempenhoGrupo[];
  recomendacoes: string[];
  respostas: RespostaRelatorio[];
  erros: RespostaRelatorio[];
};

export type RelatorioSala = {
  geradoEm: Date;
  sala: RelatorioAluno['sala'];
  professor: RelatorioAluno['professor'];
  respostas: RespostaRelatorio[];
};
