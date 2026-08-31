import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { toBoolean, trimUppercaseString } from '../../common/transformers';
import { PARTIDA_STATUS } from '../../jogadores/partida-status';
import type { PartidaStatus } from '../../jogadores/partida-status';

// Contrato do evento enviado quando o aluno responde uma pergunta.
export class CriarProgressoDto {
  // Identifica quem respondeu.
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsNotEmpty()
  jogadorId: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsNotEmpty()
  perguntaId: number;

  @Transform(toBoolean)
  @IsBoolean()
  @IsNotEmpty()
  acertou: boolean;

  @Transform(trimUppercaseString)
  @IsIn(['A', 'B', 'C', 'D'])
  @IsOptional()
  respostaEscolhida?: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsNotEmpty()
  fase: number;

  @Type(() => Number)
  @IsInt()
  @IsOptional()
  pontuacaoGanha?: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  casaAtual?: number;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsIn([PARTIDA_STATUS.JOGANDO, PARTIDA_STATUS.FINALIZADO])
  @IsOptional()
  statusPartida?: PartidaStatus;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  salaId?: number;

  @Transform(trimUppercaseString)
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  salaCodigo?: string;
}
// Identifica qual pergunta foi exibida.
// Resultado calculado pelo jogo e normalizado para booleano.
// Alternativa original escolhida; opcional apenas para clientes legados e timeout.
// Fase em que a resposta ocorreu.
// Campo legado aceito, mas a pontuacao oficial e recalculada no servidor.
// Posicao que o aluno alcancou no tabuleiro.
// Status enviado e validado, embora uma resposta nova seja normalizada como jogando.
// Sala pode ser resolvida pelo ID interno...
// ...ou pelo codigo publico digitado pelo aluno.
