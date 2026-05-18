import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('perguntas')
export class Pergunta {
  @PrimaryGeneratedColumn()
  id: number;

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

  @CreateDateColumn()
  criadoEm: Date;
}
