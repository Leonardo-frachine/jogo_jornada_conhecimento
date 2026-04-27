import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('jogadores')
export class Jogador {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  nome: string;

  @Column({ default: 0 })
  pontuacao: number;

  @Column({ default: 1 })
  faseAtual: number;

  @CreateDateColumn()
  criadoEm: Date;
}