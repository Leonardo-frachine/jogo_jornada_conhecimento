import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('perguntas')
export class Pergunta {
  @PrimaryGeneratedColumn()
  id: number;

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

  @CreateDateColumn()
  criadoEm: Date;
}