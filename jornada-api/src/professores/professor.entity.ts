import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Sala } from '../salas/sala.entity';

@Entity('professores')
// Professor e a identidade proprietaria das salas e do painel administrativo.
export class Professor {
  // Identificador interno usado pela sessao local e pelas salas.
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  nome: string;

  @Column({ unique: true })
  email: string;

  @Column()
  senhaHash: string;

  @OneToMany(() => Sala, (sala) => sala.professor)
  salas: Sala[];

  @CreateDateColumn()
  criadoEm: Date;

  @UpdateDateColumn()
  atualizadoEm: Date;
}
  // Nome publico exibido no painel.
  // E-mail normalizado e unico usado como credencial de login.
  // Armazena somente salt e hash; a senha original nunca e persistida.
  // Um professor pode administrar varias salas.
  // Datas permitem auditoria basica de criacao e alteracao da conta.
