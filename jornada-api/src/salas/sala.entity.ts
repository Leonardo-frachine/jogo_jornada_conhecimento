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
// Sala representa a turma que isola alunos, perguntas e respostas de um professor.
export class Sala {
  // Chave interna usada nos relacionamentos do banco.
  @PrimaryGeneratedColumn()
  id: number;

  // Professor proprietario; a coluna explicita simplifica consultas sem carregar a relacao.
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
  // Excluir o professor remove suas salas para nao deixar turmas sem responsavel.
  // Nome amigavel exibido no painel do professor.
  // Codigo publico unico digitado pelos alunos para entrar na turma.
  // Permite desativacao logica da turma sem excluir imediatamente seus dados.
  // Historico de respostas pertencente exclusivamente a esta sala.
  // Banco de perguntas exclusivo desta sala.
  // Data usada para ordenar salas recentes no painel.
