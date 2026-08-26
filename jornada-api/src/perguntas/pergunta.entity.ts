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
// Pergunta representa o conteudo jogavel e sempre deve ser consultada no contexto da sala.
export class Pergunta {
  // Identificador interno usado pelo progresso para registrar qual pergunta foi respondida.
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
  // Sala e opcional somente enquanto existirem dados legados anteriores a migracao.
  // Perguntas sao removidas junto com a sala proprietaria.
  // Titulo curto opcional usado no gerenciamento do banco.
  // Texto principal apresentado ao aluno.
  // Quatro alternativas fixas mantem o formato de multipla escolha do jogo.
  // Letra A-D que identifica a alternativa correta.
  // Materia e dificuldade alimentam filtros e indicadores do professor.
  // Pontos-base concedidos no acerto e usados para calcular penalidade no erro.
  // Limite opcional em segundos para futuras perguntas temporizadas.
  // Exclusao logica oculta a pergunta sem quebrar progressos existentes.
  // Data de cadastro para auditoria e ordenacao quando necessario.
