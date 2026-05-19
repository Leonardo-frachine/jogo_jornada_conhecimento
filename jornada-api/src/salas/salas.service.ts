import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Professor } from '../professores/professor.entity';
import { Progresso } from '../progresso/progresso.entity';
import { CriarSalaDto } from './dto/criar-sala.dto';
import { Sala } from './sala.entity';

type SalaResumo = {
  id: number;
  professorId: number;
  professorNome: string;
  nome: string;
  codigo: string;
  ativa: boolean;
  criadoEm: Date;
};

@Injectable()
export class SalasService {
  constructor(
    @InjectRepository(Sala)
    private readonly salaRepository: Repository<Sala>,

    @InjectRepository(Professor)
    private readonly professorRepository: Repository<Professor>,

    @InjectRepository(Progresso)
    private readonly progressoRepository: Repository<Progresso>,
  ) {}

  async criar(criarSalaDto: CriarSalaDto): Promise<{
    mensagem: string;
    sala: SalaResumo;
  }> {
    const professor = await this.professorRepository.findOne({
      where: { id: criarSalaDto.professorId },
    });

    if (!professor) {
      throw new NotFoundException('Professor nao encontrado.');
    }

    const codigo = await this.gerarCodigoUnico();
    const nomeSala = criarSalaDto.nome?.trim() || `Sala ${codigo}`;

    const sala = this.salaRepository.create({
      professorId: professor.id,
      professor,
      nome: nomeSala,
      codigo,
      ativa: true,
    });

    const salaSalva = await this.salaRepository.save(sala);

    return {
      mensagem: 'Sala criada com sucesso.',
      sala: this.serializarSala(salaSalva, professor.nome),
    };
  }

  async listarPorProfessor(professorId: number): Promise<SalaResumo[]> {
    const professor = await this.professorRepository.findOne({
      where: { id: professorId },
    });

    if (!professor) {
      throw new NotFoundException('Professor nao encontrado.');
    }

    const salas = await this.salaRepository.find({
      where: { professorId },
      order: {
        criadoEm: 'DESC',
      },
    });

    return salas.map((sala) => this.serializarSala(sala, professor.nome));
  }

  async buscarPorId(id: number): Promise<SalaResumo> {
    const sala = await this.salaRepository.findOne({
      where: { id },
      relations: ['professor'],
    });

    if (!sala) {
      throw new NotFoundException('Sala nao encontrada.');
    }

    return this.serializarSala(sala, sala.professor?.nome);
  }

  async buscarPorCodigo(codigo: string): Promise<SalaResumo> {
    const codigoNormalizado = codigo.trim().toUpperCase();
    const sala = await this.salaRepository.findOne({
      where: { codigo: codigoNormalizado },
      relations: ['professor'],
    });

    if (!sala) {
      throw new NotFoundException('Sala nao encontrada para o codigo informado.');
    }

    return this.serializarSala(sala, sala.professor?.nome);
  }

  async obterDashboard(id: number): Promise<{
    sala: SalaResumo;
    indicadores: {
      totalAlunos: number;
      totalPerguntasRespondidas: number;
      quantidadeAcertos: number;
      quantidadeErros: number;
      percentualAcertoTurma: number;
    };
    desempenhoPorMateria: Array<{
      materia: string;
      respondidas: number;
      acertos: number;
      erros: number;
      percentualAcerto: number;
    }>;
    desempenhoPorDificuldade: Array<{
      dificuldade: string;
      respondidas: number;
      acertos: number;
      erros: number;
      percentualAcerto: number;
    }>;
  }> {
    const sala = await this.salaRepository.findOne({
      where: { id },
      relations: ['professor'],
    });

    if (!sala) {
      throw new NotFoundException('Sala nao encontrada.');
    }

    const respostas = await this.progressoRepository.find({
      where: { salaId: sala.id },
      relations: ['jogador', 'pergunta'],
      order: {
        id: 'DESC',
      },
    });

    const totalPerguntasRespondidas = respostas.length;
    const quantidadeAcertos = respostas.filter((resposta) => resposta.acertou).length;
    const quantidadeErros = totalPerguntasRespondidas - quantidadeAcertos;
    const totalAlunos = new Set(respostas.map((resposta) => resposta.jogadorId)).size;

    return {
      sala: this.serializarSala(sala, sala.professor?.nome),
      indicadores: {
        totalAlunos,
        totalPerguntasRespondidas,
        quantidadeAcertos,
        quantidadeErros,
        percentualAcertoTurma:
          totalPerguntasRespondidas === 0
            ? 0
            : Math.round((quantidadeAcertos / totalPerguntasRespondidas) * 100),
      },
      desempenhoPorMateria: this.agruparDesempenho(respostas, 'materia') as Array<{
        materia: string;
        respondidas: number;
        acertos: number;
        erros: number;
        percentualAcerto: number;
      }>,
      desempenhoPorDificuldade: this.agruparDesempenho(
        respostas,
        'dificuldade',
      ) as Array<{
        dificuldade: string;
        respondidas: number;
        acertos: number;
        erros: number;
        percentualAcerto: number;
      }>,
    };
  }

  async listarRespostas(id: number): Promise<{
    sala: SalaResumo;
    respostas: Array<{
      progressoId: number;
      jogadorId: number;
      aluno: string;
      perguntaId: number;
      enunciado: string;
      materia: string;
      dificuldade: string;
      acertou: boolean;
      fase: number;
      pontuacaoGanha: number;
      respondidoEm: Date;
    }>;
  }> {
    const sala = await this.salaRepository.findOne({
      where: { id },
      relations: ['professor'],
    });

    if (!sala) {
      throw new NotFoundException('Sala nao encontrada.');
    }

    const respostas = await this.progressoRepository.find({
      where: { salaId: sala.id },
      relations: ['jogador', 'pergunta'],
      order: {
        id: 'DESC',
      },
    });

    return {
      sala: this.serializarSala(sala, sala.professor?.nome),
      respostas: respostas.map((resposta) => ({
        progressoId: resposta.id,
        jogadorId: resposta.jogadorId,
        aluno: resposta.jogador?.nome ?? 'Aluno',
        perguntaId: resposta.perguntaId,
        enunciado: resposta.pergunta?.enunciado ?? '',
        materia: resposta.pergunta?.materia ?? 'Nao informada',
        dificuldade: resposta.pergunta?.dificuldade ?? `Nivel ${resposta.fase}`,
        acertou: resposta.acertou,
        fase: resposta.fase,
        pontuacaoGanha: resposta.pontuacaoGanha,
        respondidoEm: resposta.criadoEm,
      })),
    };
  }

  private async gerarCodigoUnico(): Promise<string> {
    const caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    for (let tentativa = 0; tentativa < 20; tentativa += 1) {
      let codigo = '';

      for (let indice = 0; indice < 6; indice += 1) {
        const posicao = Math.floor(Math.random() * caracteres.length);
        codigo += caracteres[posicao];
      }

      const salaExistente = await this.salaRepository.findOne({
        where: { codigo },
      });

      if (!salaExistente) {
        return codigo;
      }
    }

    throw new Error('Nao foi possivel gerar um codigo unico para a sala.');
  }

  private serializarSala(sala: Sala, professorNome?: string): SalaResumo {
    return {
      id: sala.id,
      professorId: sala.professorId,
      professorNome: professorNome ?? 'Professor',
      nome: sala.nome,
      codigo: sala.codigo,
      ativa: sala.ativa,
      criadoEm: sala.criadoEm,
    };
  }

  private agruparDesempenho(
    respostas: Progresso[],
    chave: 'materia' | 'dificuldade',
  ): Array<{
    materia?: string;
    dificuldade?: string;
    respondidas: number;
    acertos: number;
    erros: number;
    percentualAcerto: number;
  }> {
    const grupos = new Map<
      string,
      {
        respondidas: number;
        acertos: number;
      }
    >();

    for (const resposta of respostas) {
      const valorBruto =
        chave === 'materia'
          ? resposta.pergunta?.materia
          : resposta.pergunta?.dificuldade;
      const nomeGrupo =
        valorBruto && String(valorBruto).trim() !== ''
          ? String(valorBruto).trim()
          : chave === 'materia'
            ? 'Nao informada'
            : `Nivel ${resposta.fase}`;

      if (!grupos.has(nomeGrupo)) {
        grupos.set(nomeGrupo, {
          respondidas: 0,
          acertos: 0,
        });
      }

      const grupo = grupos.get(nomeGrupo)!;
      grupo.respondidas += 1;
      if (resposta.acertou) {
        grupo.acertos += 1;
      }
    }

    return Array.from(grupos.entries()).map(([nomeGrupo, grupo]) => {
      const payload = {
        respondidas: grupo.respondidas,
        acertos: grupo.acertos,
        erros: grupo.respondidas - grupo.acertos,
        percentualAcerto:
          grupo.respondidas === 0
            ? 0
            : Math.round((grupo.acertos / grupo.respondidas) * 100),
      };

      return chave === 'materia'
        ? { materia: nomeGrupo, ...payload }
        : { dificuldade: nomeGrupo, ...payload };
    });
  }
}
