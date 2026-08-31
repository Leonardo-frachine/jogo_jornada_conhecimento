import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Jogador } from '../jogadores/jogador.entity';
import { PARTIDA_STATUS } from '../jogadores/partida-status';
import type { PartidaStatus } from '../jogadores/partida-status';
import { Pergunta } from '../perguntas/pergunta.entity';
import { Sala } from '../salas/sala.entity';

@Entity('progresso')
// Cada linha representa uma pergunta respondida e deve permanecer como historico.
export class Progresso {
  // Identificador unico do evento de resposta.
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  jogadorId: number;

  @ManyToOne(() => Jogador, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'jogadorId' })
  jogador: Jogador;

  @Column()
  perguntaId: number;

  @ManyToOne(() => Pergunta, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'perguntaId' })
  pergunta: Pergunta;

  @Column({ nullable: true })
  salaId?: number | null;

  @ManyToOne(() => Sala, (sala) => sala.progressos, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'salaId' })
  sala?: Sala | null;

  @Column()
  acertou: boolean;

  @Column({ type: 'varchar', nullable: true })
  respostaEscolhida?: string | null;

  @Column({ type: 'varchar', nullable: true })
  respostaEscolhidaTexto?: string | null;

  @Column({ type: 'varchar', nullable: true })
  respostaCorretaSnapshot?: string | null;

  @Column({ type: 'varchar', nullable: true })
  respostaCorretaTextoSnapshot?: string | null;

  @Column({ type: 'varchar', nullable: true })
  perguntaTituloSnapshot?: string | null;

  @Column({ type: 'text', nullable: true })
  perguntaEnunciadoSnapshot?: string | null;

  @Column({ type: 'varchar', nullable: true })
  materiaSnapshot?: string | null;

  @Column({ type: 'varchar', nullable: true })
  dificuldadeSnapshot?: string | null;

  @Column({ type: 'integer', nullable: true })
  pontuacaoBaseSnapshot?: number | null;

  @Column()
  fase: number;

  @Column({ default: 1 })
  casaAtual: number;

  @Column({ type: 'varchar', default: PARTIDA_STATUS.JOGANDO })
  statusPartida: PartidaStatus;

  @Column({ default: 0 })
  pontuacaoGanha: number;

  @CreateDateColumn()
  criadoEm: Date;
}
// Jogador que respondeu; a coluna permite filtros sem carregar a entidade.
// Ao excluir o jogador, seus eventos deixam de ter significado e sao removidos.
// Pergunta exibida ao aluno neste evento.
// Mantem o vinculo com o enunciado usado nos relatorios.
// Sala da partida, nula somente para dados anteriores ao isolamento por turma.
// Excluir uma sala preserva o evento, mas remove sua associacao direta.
// Resultado objetivo da resposta.
// A escolha e o gabarito ficam congelados para relatorios auditaveis.
// Os demais snapshots impedem que uma edicao futura altere o historico.
// Fase informada no momento em que a pergunta foi respondida.
// Casa alcancada no tabuleiro apos este evento.
// Respostas novas representam jogo em andamento, nunca finalizacao automatica.
// Valor positivo para acerto e negativo para penalidade de erro.
// Momento usado para ordenar historico e construir relatorios posteriores.
