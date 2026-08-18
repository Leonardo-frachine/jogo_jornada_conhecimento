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
@Index('UQ_jogadores_sala_nome_normalizado', ['salaId', 'nomeNormalizado'], {
  unique: true,
})
export class Jogador {
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
