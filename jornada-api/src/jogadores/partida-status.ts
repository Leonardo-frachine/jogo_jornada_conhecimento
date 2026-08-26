// Valores persistidos e compartilhados entre jogador, progresso, ranking e dashboard.
export const PARTIDA_STATUS = {
  INICIADO: 'iniciado',
  JOGANDO: 'jogando',
  FINALIZADO: 'finalizado',
} as const;

export type PartidaStatus =
  (typeof PARTIDA_STATUS)[keyof typeof PARTIDA_STATUS];
