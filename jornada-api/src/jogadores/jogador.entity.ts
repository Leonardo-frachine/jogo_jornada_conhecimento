import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Sala } from '../salas/sala.entity';
import { PARTIDA_STATUS } from './partida-status';
import type { PartidaStatus } from './partida-status';

@Entity('jogadores')
// Impede duplicar o mesmo nome normalizado dentro de uma sala.
@Index('UQ_jogadores_sala_nome_normalizado', ['salaId', 'nomeNormalizado'], {
  unique: true,
})
export class Jogador {
  // Identificador persistente reutilizado quando o aluno joga novamente.
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  nome: string;

  @Column({ type: 'varchar', nullable: true, select: false })
  nomeNormalizado?: string | null;

  @Column({ default: 0 })
  pontuacao: number;

  @Column({ default: 1 })
  faseAtual: number;

  @Column({ type: 'integer', nullable: true })
  salaId?: number | null;

  @ManyToOne(() => Sala, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'salaId' })
  sala?: Sala | null;

  @Column({ default: 1 })
  casaAtual: number;

  @Column({ type: 'varchar', default: PARTIDA_STATUS.INICIADO })
  statusPartida: PartidaStatus;

  @Column({
    type: 'text',
    nullable: true,
    transformer: {
      to: (value?: Date | null) => value?.toISOString() ?? null,
      from: (value?: string | null) => (value ? new Date(value) : null),
    },
  })
  finalizadoEm?: Date | null;

  @CreateDateColumn()
  criadoEm: Date;
}
  // Nome de exibicao preserva a grafia informada mais recentemente.
  // Versao normalizada usada somente em busca/deduplicacao, por isso select e false.
  // Total corrente mostrado no tabuleiro e usado pelo ranking.
  // Maior fase alcancada no estado resumido do jogador.
  // Sala pode ser nula apenas para compatibilidade com cadastros antigos.
  // A exclusao da sala nao apaga automaticamente a identidade do jogador.
  // Posicao corrente persistida para acompanhamento do professor.
  // Estado da partida diferencia entrada, jogo ativo e encerramento oficial.
  // Data nula significa que a partida ainda nao foi finalizada.
  // Momento original do cadastro da identidade do jogador.
