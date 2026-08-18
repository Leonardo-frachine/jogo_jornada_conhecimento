import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  JoinColumn,
  ManyToOne,
} from 'typeorm';
import { Sala } from '../salas/sala.entity';

@Entity('perguntas')
export class Pergunta {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'integer', nullable: true })
  salaId?: number | null;

  @ManyToOne(() => Sala, (sala) => sala.perguntas, {
    onDelete: 'CASCADE',
    nullable: true,
  })
  @JoinColumn({ name: 'salaId' })
  sala?: Sala | null;

  @Column({ nullable: true })
  titulo?: string;

  @Column()
  enunciado: string;

  @Column()
  alternativaA: string;

  @Column()
  alternativaB: string;

  @Column()
  alternativaC: string;

  @Column()
  alternativaD: string;

  @Column()
  respostaCorreta: string;

  @Column({ nullable: true })
  materia: string;

  @Column({ nullable: true })
  dificuldade: string;

  @Column({ default: 100 })
  pontuacao: number;

  @Column({ type: 'integer', nullable: true })
  tempoLimite?: number | null;

  @Column({ default: true })
  ativa: boolean;

  @CreateDateColumn()
  criadoEm: Date;
}
