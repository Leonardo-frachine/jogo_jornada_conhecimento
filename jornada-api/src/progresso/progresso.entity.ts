import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Jogador } from '../jogadores/jogador.entity';
import { Pergunta } from '../perguntas/pergunta.entity';
import { Sala } from '../salas/sala.entity';

@Entity('progresso')
export class Progresso {
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

  @Column()
  fase: number;

  @Column({ default: 0 })
  pontuacaoGanha: number;

  @CreateDateColumn()
  criadoEm: Date;
}
