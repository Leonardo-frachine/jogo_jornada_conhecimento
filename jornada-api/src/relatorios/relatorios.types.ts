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

export type AlunoRelatorioTurma = {
  id: number;
  nome: string;
  statusPartida: PartidaStatus;
  faseAtual: number;
  casaAtual: number;
  pontuacao: number;
  respondidas: number;
  acertos: number;
  erros: number;
  aproveitamento: number;
  ultimaAtividade: Date | null;
  classificacao: ClassificacaoDesempenho;
};

export type QuestaoParaRevisarTurma = {
  perguntaId: number;
  titulo: string;
  enunciado: string;
  materia: string;
  dificuldade: string;
  respondidas: number;
  erros: number;
  percentualErro: number;
};

export type RelatorioTurma = {
  geradoEm: Date;
  sala: RelatorioAluno['sala'];
  professor: RelatorioAluno['professor'];
  periodo: RelatorioAluno['periodo'];
  resumo: {
    totalAlunos: number;
    alunosComRespostas: number;
    alunosSemRespostas: number;
    participacao: number;
    finalizados: number;
    emAndamento: number;
    respondidas: number;
    acertos: number;
    erros: number;
    aproveitamento: number;
    pontuacaoTotal: number;
    pontuacaoMedia: number;
  };
  desempenhoPorMateria: DesempenhoGrupo[];
  desempenhoPorDificuldade: DesempenhoGrupo[];
  alunos: AlunoRelatorioTurma[];
  questoesParaRevisar: QuestaoParaRevisarTurma[];
};
