import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Professor } from '../professores/professor.entity';
import { Progresso } from '../progresso/progresso.entity';
import { Pergunta } from '../perguntas/pergunta.entity';

@Entity('salas')
export class Sala {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  professorId: number;

  @ManyToOne(() => Professor, (professor) => professor.salas, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'professorId' })
  professor: Professor;

  @Column()
  nome: string;

  @Column({ unique: true })
  codigo: string;

  @Column({ default: true })
  ativa: boolean;

  @OneToMany(() => Progresso, (progresso) => progresso.sala)
  progressos: Progresso[];

  @OneToMany(() => Pergunta, (pergunta) => pergunta.sala)
  perguntas: Pergunta[];

  @CreateDateColumn()
  criadoEm: Date;
}
