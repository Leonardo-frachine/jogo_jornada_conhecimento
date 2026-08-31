import { Injectable } from '@nestjs/common';
import * as fs from 'node:fs';
import * as path from 'node:path';
import PDFDocument from 'pdfkit';
import type {
  AlunoRelatorioTurma,
  DesempenhoGrupo,
  QuestaoParaRevisarTurma,
  RelatorioTurma,
} from './relatorios.types';

const COLORS = {
  navy: '#16324F',
  blue: '#2F80ED',
  teal: '#21A99A',
  green: '#24976F',
  amber: '#D98A12',
  red: '#C94F5D',
  ink: '#243247',
  muted: '#68788D',
  line: '#DDE5ED',
  soft: '#F3F7FA',
  white: '#FFFFFF',
};

const PAGE_MARGIN = 48;
const CONTENT_WIDTH = 499;
const FOOTER_Y = 800;

@Injectable()
export class RelatorioTurmaPdfService {
  async gerar(relatorio: RelatorioTurma): Promise<Buffer> {
    return new Promise<Buffer>((resolve, reject) => {
      const doc = new PDFDocument({
        size: 'A4',
        margins: {
          top: PAGE_MARGIN,
          right: PAGE_MARGIN,
          bottom: 20,
          left: PAGE_MARGIN,
        },
        bufferPages: true,
        compress: true,
        info: {
          Title: `Relatorio consolidado da turma - ${relatorio.sala.nome}`,
          Author: 'Jornada do Conhecimento',
          Subject: `Visao geral e detalhamento da turma ${relatorio.sala.nome}`,
          Keywords: 'educacao, turma, desempenho, relatorio',
          CreationDate: relatorio.geradoEm,
        },
      });
      const partes: Buffer[] = [];

      doc.on('data', (parte: Buffer) => partes.push(parte));
      doc.on('error', reject);
      doc.on('end', () => resolve(Buffer.concat(partes)));

      this.desenharCabecalhoPrincipal(doc, relatorio);
      this.desenharResumo(doc, relatorio);
      this.desenharDesempenho(doc, relatorio);
      this.desenharLeituraTurma(doc, relatorio);
      this.desenharAlunos(doc, relatorio);
      this.desenharQuestoesParaRevisar(doc, relatorio);
      this.desenharOrientacaoFinal(doc, relatorio);
      this.desenharRodapes(doc, relatorio);
      doc.end();
    });
  }

  private desenharCabecalhoPrincipal(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioTurma,
  ): void {
    doc.save();
    doc.roundedRect(32, 30, 531, 126, 18).fill(COLORS.navy);
    doc.roundedRect(412, 30, 151, 126, 18).fill(COLORS.blue);
    doc.circle(520, 55, 48).fillOpacity(0.12).fill(COLORS.white);
    doc.circle(450, 140, 32).fillOpacity(0.1).fill(COLORS.white);
    doc.fillOpacity(1);

    const logo = this.localizarLogo();
    if (logo) {
      doc.image(logo, 48, 47, {
        fit: [72, 72],
        align: 'center',
        valign: 'center',
      });
    } else {
      doc.circle(84, 84, 34).fill(COLORS.amber);
      doc
        .fillColor(COLORS.white)
        .font('Helvetica-Bold')
        .fontSize(22)
        .text('JC', 62, 76, { width: 44, align: 'center' });
    }

    doc
      .fillColor(COLORS.white)
      .font('Helvetica-Bold')
      .fontSize(9)
      .text('JORNADA DO CONHECIMENTO', 132, 50, { characterSpacing: 1.1 });
    doc.fontSize(18.5).text('Relatório consolidado\nda turma', 132, 68, {
      width: 265,
      lineGap: -1,
    });
    doc
      .font('Helvetica')
      .fontSize(9.5)
      .fillColor('#D9E7F5')
      .text('Visão geral e acompanhamento de todos os alunos', 132, 120, {
        width: 265,
      });
    doc
      .font('Helvetica-Bold')
      .fontSize(12.5)
      .fillColor(COLORS.white)
      .text(relatorio.sala.nome, 420, 66, {
        width: 130,
        align: 'center',
      });
    doc
      .font('Helvetica')
      .fontSize(8.5)
      .fillColor('#E9F3FF')
      .text(`Código ${relatorio.sala.codigo}`, 420, 111, {
        width: 130,
        align: 'center',
      });
    doc.restore();

    const periodo = relatorio.periodo.inicio
      ? `${this.formatarData(relatorio.periodo.inicio)} a ${this.formatarData(relatorio.periodo.fim)}`
      : 'Sem respostas registradas';
    const metadados = [
      ['Professor', relatorio.professor.nome],
      ['Período analisado', periodo],
      ['Gerado em', this.formatarDataHora(relatorio.geradoEm)],
    ];
    const largura = CONTENT_WIDTH / 3;
    metadados.forEach(([rotulo, valor], indice) => {
      const x = PAGE_MARGIN + indice * largura;
      doc
        .font('Helvetica-Bold')
        .fontSize(7.5)
        .fillColor(COLORS.muted)
        .text(rotulo.toUpperCase(), x, 174, { width: largura - 12 });
      doc
        .font('Helvetica')
        .fontSize(9.5)
        .fillColor(COLORS.ink)
        .text(valor, x, 188, { width: largura - 12, ellipsis: true });
    });
    doc
      .moveTo(PAGE_MARGIN, 210)
      .lineTo(PAGE_MARGIN + CONTENT_WIDTH, 210)
      .strokeColor(COLORS.line)
      .lineWidth(0.8)
      .stroke();
    doc.y = 216;
  }

  private desenharResumo(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioTurma,
  ): void {
    this.tituloSecao(
      doc,
      'Visão geral da turma',
      'Indicadores consolidados de participação e desempenho.',
    );
    const metricas = [
      {
        rotulo: 'Alunos cadastrados',
        valor: this.formatarNumero(relatorio.resumo.totalAlunos),
        detalhe: `${relatorio.resumo.alunosSemRespostas} sem respostas`,
        cor: COLORS.navy,
      },
      {
        rotulo: 'Participação',
        valor: `${relatorio.resumo.participacao}%`,
        detalhe: `${relatorio.resumo.alunosComRespostas} alunos ativos`,
        cor: this.corPercentual(relatorio.resumo.participacao),
      },
      {
        rotulo: 'Aproveitamento',
        valor: `${relatorio.resumo.aproveitamento}%`,
        detalhe: `${relatorio.resumo.acertos} acertos de ${relatorio.resumo.respondidas}`,
        cor: this.corPercentual(relatorio.resumo.aproveitamento),
      },
      {
        rotulo: 'Respostas',
        valor: this.formatarNumero(relatorio.resumo.respondidas),
        detalhe: `${relatorio.resumo.erros} respostas incorretas`,
        cor: COLORS.blue,
      },
      {
        rotulo: 'Pontuação total',
        valor: this.formatarNumero(relatorio.resumo.pontuacaoTotal),
        detalhe: `média ${this.formatarNumero(relatorio.resumo.pontuacaoMedia)} por aluno`,
        cor: COLORS.teal,
      },
      {
        rotulo: 'Jornadas finalizadas',
        valor: this.formatarNumero(relatorio.resumo.finalizados),
        detalhe: `${relatorio.resumo.emAndamento} em andamento`,
        cor: COLORS.green,
      },
    ];
    const espaco = 10;
    const largura = (CONTENT_WIDTH - espaco * 2) / 3;
    const altura = 69;
    const inicioY = doc.y + 8;

    metricas.forEach((metrica, indice) => {
      const coluna = indice % 3;
      const linha = Math.floor(indice / 3);
      const x = PAGE_MARGIN + coluna * (largura + espaco);
      const y = inicioY + linha * (altura + espaco);
      doc
        .roundedRect(x, y, largura, altura, 10)
        .fillAndStroke(COLORS.soft, COLORS.line);
      doc.roundedRect(x, y, 5, altura, 3).fill(metrica.cor);
      doc
        .font('Helvetica-Bold')
        .fontSize(7.5)
        .fillColor(COLORS.muted)
        .text(metrica.rotulo.toUpperCase(), x + 14, y + 11, {
          width: largura - 26,
        });
      doc
        .font('Helvetica-Bold')
        .fontSize(18)
        .fillColor(COLORS.ink)
        .text(metrica.valor, x + 14, y + 26, { width: largura - 26 });
      doc
        .font('Helvetica')
        .fontSize(7.4)
        .fillColor(COLORS.muted)
        .text(metrica.detalhe, x + 14, y + 52, {
          width: largura - 26,
          ellipsis: true,
        });
    });
    doc.y = inicioY + altura * 2 + espaco + 18;
  }

  private desenharDesempenho(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioTurma,
  ): void {
    this.garantirEspaco(doc, 105, relatorio);
    this.tituloSecao(
      doc,
      'Desempenho pedagógico',
      'Distribuição dos resultados de todas as respostas da sala.',
    );
    this.desenharListaDesempenho(
      doc,
      'Por matéria',
      relatorio.desempenhoPorMateria,
      relatorio,
    );
    this.desenharListaDesempenho(
      doc,
      'Por dificuldade',
      relatorio.desempenhoPorDificuldade,
      relatorio,
    );
  }

  private desenharListaDesempenho(
    doc: PDFKit.PDFDocument,
    titulo: string,
    grupos: DesempenhoGrupo[],
    relatorio: RelatorioTurma,
  ): void {
    const novaPagina = this.garantirEspaco(
      doc,
      grupos.length > 0 ? 58 : 70,
      relatorio,
    );
    doc
      .font('Helvetica-Bold')
      .fontSize(10.5)
      .fillColor(COLORS.navy)
      .text(
        novaPagina ? `${titulo} - continuação` : titulo,
        PAGE_MARGIN,
        doc.y,
        {
          width: CONTENT_WIDTH,
        },
      );
    doc.y += 10;

    if (grupos.length === 0) {
      this.caixaMensagem(
        doc,
        'Ainda não há respostas suficientes para apresentar este recorte.',
        COLORS.muted,
      );
      return;
    }

    grupos.forEach((grupo) => {
      const quebrou = this.garantirEspaco(doc, 42, relatorio);
      if (quebrou) {
        doc
          .font('Helvetica-Bold')
          .fontSize(10.5)
          .fillColor(COLORS.navy)
          .text(`${titulo} - continuação`, PAGE_MARGIN, doc.y, {
            width: CONTENT_WIDTH,
          });
        doc.y += 13;
      }
      const y = doc.y + 3;
      const barraX = PAGE_MARGIN + 185;
      const barraLargura = 225;
      const cor = this.corPercentual(grupo.percentualAcerto);
      doc
        .font('Helvetica-Bold')
        .fontSize(9)
        .fillColor(COLORS.ink)
        .text(grupo.nome, PAGE_MARGIN, y, { width: 172, ellipsis: true });
      doc
        .font('Helvetica')
        .fontSize(7.5)
        .fillColor(COLORS.muted)
        .text(
          `${grupo.acertos} acertos, ${grupo.erros} erros em ${grupo.respondidas}`,
          PAGE_MARGIN,
          y + 15,
          { width: 172 },
        );
      doc.roundedRect(barraX, y + 7, barraLargura, 9, 5).fill('#E2E9EF');
      if (grupo.percentualAcerto > 0) {
        doc
          .roundedRect(
            barraX,
            y + 7,
            Math.max(9, barraLargura * (grupo.percentualAcerto / 100)),
            9,
            5,
          )
          .fill(cor);
      }
      doc
        .font('Helvetica-Bold')
        .fontSize(10)
        .fillColor(cor)
        .text(`${grupo.percentualAcerto}%`, PAGE_MARGIN + 420, y + 3, {
          width: 79,
          align: 'right',
        });
      doc
        .font('Helvetica')
        .fontSize(7)
        .fillColor(COLORS.muted)
        .text(
          this.rotuloClassificacao(grupo.classificacao),
          PAGE_MARGIN + 410,
          y + 18,
          {
            width: 89,
            align: 'right',
          },
        );
      doc.y = y + 36;
    });
    doc.y += 9;
  }

  private desenharLeituraTurma(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioTurma,
  ): void {
    this.garantirEspaco(doc, 150, relatorio);
    this.tituloSecao(
      doc,
      'Leitura da turma',
      'Destaques e alunos que merecem acompanhamento mais próximo.',
    );
    const destaques = [...relatorio.alunos]
      .filter((aluno) => aluno.respondidas >= 3 && aluno.aproveitamento >= 75)
      .sort((a, b) => b.aproveitamento - a.aproveitamento)
      .slice(0, 4)
      .map((aluno) => `${aluno.nome} - ${aluno.aproveitamento}%`);
    const atencao = relatorio.alunos
      .filter(
        (aluno) =>
          aluno.respondidas === 0 ||
          (aluno.respondidas >= 3 && aluno.aproveitamento < 50),
      )
      .slice(0, 4)
      .map((aluno) =>
        aluno.respondidas === 0
          ? `${aluno.nome} - sem respostas`
          : `${aluno.nome} - ${aluno.aproveitamento}%`,
      );
    const y = doc.y + 7;
    const largura = (CONTENT_WIDTH - 12) / 2;
    this.cartaoLista(
      doc,
      PAGE_MARGIN,
      y,
      largura,
      'Destaques',
      destaques,
      COLORS.green,
      'Nenhum destaque com amostra suficiente.',
    );
    this.cartaoLista(
      doc,
      PAGE_MARGIN + largura + 12,
      y,
      largura,
      'Acompanhamento prioritário',
      atencao,
      COLORS.red,
      'Nenhum aluno em condição prioritária.',
    );
    doc.y = y + 112;
  }

  private cartaoLista(
    doc: PDFKit.PDFDocument,
    x: number,
    y: number,
    largura: number,
    titulo: string,
    itens: string[],
    cor: string,
    vazio: string,
  ): void {
    const altura = 96;
    doc
      .roundedRect(x, y, largura, altura, 10)
      .fillAndStroke(COLORS.soft, COLORS.line);
    doc.circle(x + 18, y + 19, 5).fill(cor);
    doc
      .font('Helvetica-Bold')
      .fontSize(10)
      .fillColor(COLORS.ink)
      .text(titulo, x + 31, y + 12, {
        width: largura - 43,
        ellipsis: true,
      });
    const exibidos = itens.slice(0, 4);
    if (exibidos.length === 0) {
      doc
        .font('Helvetica')
        .fontSize(7.8)
        .fillColor(COLORS.muted)
        .text(vazio, x + 15, y + 39, { width: largura - 30, lineGap: 2 });
      return;
    }
    exibidos.forEach((item, indice) => {
      doc.circle(x + 18, y + 43 + indice * 13, 2).fill(cor);
      doc
        .font('Helvetica')
        .fontSize(7.8)
        .fillColor(COLORS.ink)
        .text(item, x + 27, y + 37 + indice * 13, {
          width: largura - 42,
          ellipsis: true,
        });
    });
  }

  private desenharAlunos(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioTurma,
  ): void {
    this.garantirEspaco(doc, 95, relatorio);
    this.tituloSecao(
      doc,
      'Detalhamento por aluno',
      'Alunos com menor aproveitamento aparecem primeiro; sem respostas ficam ao final.',
    );
    if (relatorio.alunos.length === 0) {
      this.caixaMensagem(
        doc,
        'Nenhum aluno está cadastrado nesta sala.',
        COLORS.muted,
      );
      return;
    }

    this.cabecalhoTabelaAlunos(doc);
    relatorio.alunos.forEach((aluno, indice) => {
      if (doc.y + 44 > FOOTER_Y - 16) {
        doc.addPage();
        this.desenharCabecalhoContinuacao(doc, relatorio);
        doc
          .font('Helvetica-Bold')
          .fontSize(11)
          .fillColor(COLORS.navy)
          .text('Detalhamento por aluno - continuação', PAGE_MARGIN, doc.y);
        doc.y += 18;
        this.cabecalhoTabelaAlunos(doc);
      }
      this.linhaAluno(doc, aluno, indice);
    });
    doc.y += 14;
  }

  private cabecalhoTabelaAlunos(doc: PDFKit.PDFDocument): void {
    const y = doc.y + 6;
    const colunas = [
      ['Aluno / última atividade', 153, 'left'],
      ['Jornada', 78, 'left'],
      ['Resp.', 48, 'center'],
      ['A / E', 58, 'center'],
      ['Aprov.', 62, 'center'],
      ['Pontos', 80, 'right'],
    ] as const;
    doc.roundedRect(PAGE_MARGIN, y, CONTENT_WIDTH, 25, 6).fill(COLORS.navy);
    let x = PAGE_MARGIN + 10;
    colunas.forEach(([rotulo, largura, alinhamento]) => {
      doc
        .font('Helvetica-Bold')
        .fontSize(7)
        .fillColor(COLORS.white)
        .text(rotulo.toUpperCase(), x, y + 9, {
          width: largura - 8,
          align: alinhamento,
        });
      x += largura;
    });
    doc.y = y + 25;
  }

  private linhaAluno(
    doc: PDFKit.PDFDocument,
    aluno: AlunoRelatorioTurma,
    indice: number,
  ): void {
    const y = doc.y;
    const altura = 44;
    const fundo = indice % 2 === 0 ? '#F8FAFC' : COLORS.white;
    doc.rect(PAGE_MARGIN, y, CONTENT_WIDTH, altura).fill(fundo);
    doc
      .moveTo(PAGE_MARGIN, y + altura)
      .lineTo(PAGE_MARGIN + CONTENT_WIDTH, y + altura)
      .strokeColor(COLORS.line)
      .lineWidth(0.5)
      .stroke();

    const colunas = [153, 78, 48, 58, 62, 80];
    let x = PAGE_MARGIN + 10;
    doc
      .font('Helvetica-Bold')
      .fontSize(8.5)
      .fillColor(COLORS.ink)
      .text(aluno.nome, x, y + 7, {
        width: colunas[0] - 12,
        ellipsis: true,
      });
    doc
      .font('Helvetica')
      .fontSize(6.8)
      .fillColor(COLORS.muted)
      .text(
        aluno.ultimaAtividade
          ? this.formatarDataHora(aluno.ultimaAtividade)
          : 'Sem atividade',
        x,
        y + 24,
        { width: colunas[0] - 12, ellipsis: true },
      );
    x += colunas[0];
    doc
      .font('Helvetica-Bold')
      .fontSize(7.6)
      .fillColor(COLORS.ink)
      .text(this.statusAluno(aluno.statusPartida), x, y + 7, {
        width: colunas[1] - 8,
        ellipsis: true,
      });
    doc
      .font('Helvetica')
      .fontSize(6.8)
      .fillColor(COLORS.muted)
      .text(`F${aluno.faseAtual} - Casa ${aluno.casaAtual}`, x, y + 24, {
        width: colunas[1] - 8,
      });
    x += colunas[1];
    this.celulaNumero(doc, String(aluno.respondidas), x, y, colunas[2]);
    x += colunas[2];
    this.celulaNumero(
      doc,
      `${aluno.acertos} / ${aluno.erros}`,
      x,
      y,
      colunas[3],
    );
    x += colunas[3];
    doc
      .font('Helvetica-Bold')
      .fontSize(9)
      .fillColor(
        aluno.respondidas === 0
          ? COLORS.muted
          : this.corPercentual(aluno.aproveitamento),
      )
      .text(
        aluno.respondidas === 0 ? '-' : `${aluno.aproveitamento}%`,
        x,
        y + 15,
        {
          width: colunas[4] - 8,
          align: 'center',
        },
      );
    x += colunas[4];
    doc
      .font('Helvetica-Bold')
      .fontSize(9)
      .fillColor(COLORS.ink)
      .text(this.formatarNumero(aluno.pontuacao), x, y + 15, {
        width: colunas[5] - 8,
        align: 'right',
      });
    doc.y = y + altura;
  }

  private celulaNumero(
    doc: PDFKit.PDFDocument,
    valor: string,
    x: number,
    y: number,
    largura: number,
  ): void {
    doc
      .font('Helvetica')
      .fontSize(8)
      .fillColor(COLORS.ink)
      .text(valor, x, y + 15, { width: largura - 8, align: 'center' });
  }

  private desenharQuestoesParaRevisar(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioTurma,
  ): void {
    this.garantirEspaco(doc, 95, relatorio);
    this.tituloSecao(
      doc,
      'Questões para revisar com a turma',
      'Itens com mais erros, considerando todas as respostas registradas.',
    );
    if (relatorio.questoesParaRevisar.length === 0) {
      this.caixaMensagem(
        doc,
        relatorio.resumo.respondidas === 0
          ? 'Ainda não há respostas para identificar questões prioritárias.'
          : 'Nenhum erro foi registrado nas questões respondidas.',
        COLORS.green,
      );
      return;
    }

    relatorio.questoesParaRevisar.forEach((questao, indice) => {
      this.cartaoQuestao(doc, questao, indice + 1, relatorio);
    });
    doc.y += 8;
  }

  private cartaoQuestao(
    doc: PDFKit.PDFDocument,
    questao: QuestaoParaRevisarTurma,
    indice: number,
    relatorio: RelatorioTurma,
  ): void {
    doc.font('Helvetica').fontSize(8.2);
    const alturaEnunciado = doc.heightOfString(questao.enunciado, {
      width: CONTENT_WIDTH - 36,
      lineGap: 1,
    });
    const altura = 61 + alturaEnunciado;
    const novaPagina = this.garantirEspaco(doc, altura + 12, relatorio);
    if (novaPagina) {
      doc
        .font('Helvetica-Bold')
        .fontSize(11)
        .fillColor(COLORS.navy)
        .text('Questões para revisar - continuação', PAGE_MARGIN, doc.y);
      doc.y += 20;
    }
    const y = doc.y + 4;
    doc
      .roundedRect(PAGE_MARGIN, y, CONTENT_WIDTH, altura, 9)
      .fillAndStroke('#FFF9F8', '#F1D8D5');
    doc.roundedRect(PAGE_MARGIN, y, 6, altura, 3).fill(COLORS.red);
    doc
      .font('Helvetica-Bold')
      .fontSize(8.5)
      .fillColor(COLORS.red)
      .text(`PRIORIDADE ${indice}`, PAGE_MARGIN + 18, y + 11, { width: 80 });
    doc
      .font('Helvetica')
      .fontSize(7.5)
      .fillColor(COLORS.muted)
      .text(
        `${questao.materia}  |  ${questao.dificuldade}`,
        PAGE_MARGIN + 102,
        y + 11,
        { width: 180, ellipsis: true },
      );
    doc
      .font('Helvetica-Bold')
      .fontSize(8)
      .fillColor(COLORS.red)
      .text(
        `${questao.erros} erros em ${questao.respondidas} respostas (${questao.percentualErro}%)`,
        PAGE_MARGIN + 292,
        y + 11,
        { width: 187, align: 'right' },
      );
    doc
      .font('Helvetica-Bold')
      .fontSize(9)
      .fillColor(COLORS.ink)
      .text(questao.titulo || 'Pergunta sem título', PAGE_MARGIN + 18, y + 29, {
        width: CONTENT_WIDTH - 36,
        ellipsis: true,
      });
    doc
      .font('Helvetica')
      .fontSize(8.2)
      .fillColor(COLORS.ink)
      .text(questao.enunciado, PAGE_MARGIN + 18, y + 45, {
        width: CONTENT_WIDTH - 36,
        lineGap: 1,
      });
    doc.y = y + altura + 10;
  }

  private desenharOrientacaoFinal(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioTurma,
  ): void {
    this.garantirEspaco(doc, 105, relatorio);
    this.tituloSecao(
      doc,
      'Orientação de leitura',
      'Como utilizar este documento no acompanhamento pedagógico.',
    );
    const y = doc.y + 5;
    doc.roundedRect(PAGE_MARGIN, y, CONTENT_WIDTH, 72, 11).fill('#EFF8F6');
    doc.circle(PAGE_MARGIN + 22, y + 25, 7).fill(COLORS.teal);
    doc
      .font('Helvetica-Bold')
      .fontSize(8)
      .fillColor(COLORS.white)
      .text('i', PAGE_MARGIN + 19, y + 20, { width: 6, align: 'center' });
    doc
      .font('Helvetica')
      .fontSize(8.5)
      .fillColor(COLORS.ink)
      .text(
        'Use a visão geral para observar a sala, o detalhamento para acompanhar cada aluno e as questões prioritárias para planejar retomadas coletivas. Grupos e alunos com menos de três respostas devem ser interpretados como amostra insuficiente.',
        PAGE_MARGIN + 40,
        y + 16,
        { width: CONTENT_WIDTH - 58, lineGap: 2 },
      );
    doc.y = y + 84;
  }

  private tituloSecao(
    doc: PDFKit.PDFDocument,
    titulo: string,
    subtitulo: string,
  ): void {
    doc
      .font('Helvetica-Bold')
      .fontSize(15)
      .fillColor(COLORS.navy)
      .text(titulo, PAGE_MARGIN, doc.y, { width: CONTENT_WIDTH });
    doc
      .font('Helvetica')
      .fontSize(8.5)
      .fillColor(COLORS.muted)
      .text(subtitulo, PAGE_MARGIN, doc.y + 3, {
        width: CONTENT_WIDTH,
        lineGap: 1,
      });
    doc.y += 16;
  }

  private caixaMensagem(
    doc: PDFKit.PDFDocument,
    mensagem: string,
    cor: string,
  ): void {
    const y = doc.y + 6;
    doc.roundedRect(PAGE_MARGIN, y, CONTENT_WIDTH, 52, 10).fill(COLORS.soft);
    doc.circle(PAGE_MARGIN + 20, y + 26, 5).fill(cor);
    doc
      .font('Helvetica')
      .fontSize(9)
      .fillColor(COLORS.ink)
      .text(mensagem, PAGE_MARGIN + 35, y + 18, {
        width: CONTENT_WIDTH - 52,
        lineGap: 2,
      });
    doc.y = y + 66;
  }

  private garantirEspaco(
    doc: PDFKit.PDFDocument,
    altura: number,
    relatorio: RelatorioTurma,
  ): boolean {
    if (doc.y + altura <= FOOTER_Y - 16) {
      return false;
    }
    doc.addPage();
    this.desenharCabecalhoContinuacao(doc, relatorio);
    return true;
  }

  private desenharCabecalhoContinuacao(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioTurma,
  ): void {
    doc.roundedRect(36, 32, 523, 55, 12).fill(COLORS.navy);
    doc
      .font('Helvetica-Bold')
      .fontSize(12)
      .fillColor(COLORS.white)
      .text('Jornada do Conhecimento', PAGE_MARGIN, 49, { width: 210 });
    doc
      .font('Helvetica')
      .fontSize(8.5)
      .fillColor('#D9E7F5')
      .text(`${relatorio.sala.nome}  |  Relatório da turma`, 265, 50, {
        width: 270,
        align: 'right',
        ellipsis: true,
      });
    doc.y = 108;
  }

  private desenharRodapes(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioTurma,
  ): void {
    const paginas = doc.bufferedPageRange();
    for (
      let indice = paginas.start;
      indice < paginas.start + paginas.count;
      indice += 1
    ) {
      doc.switchToPage(indice);
      doc
        .moveTo(PAGE_MARGIN, FOOTER_Y - 4)
        .lineTo(PAGE_MARGIN + CONTENT_WIDTH, FOOTER_Y - 4)
        .strokeColor(COLORS.line)
        .lineWidth(0.7)
        .stroke();
      doc
        .font('Helvetica')
        .fontSize(7.5)
        .fillColor(COLORS.muted)
        .text(
          `${relatorio.sala.nome} - ${relatorio.sala.codigo}  |  Gerado em ${this.formatarDataHora(relatorio.geradoEm)}`,
          PAGE_MARGIN,
          FOOTER_Y + 6,
          { width: 370, lineBreak: false },
        );
      doc
        .font('Helvetica-Bold')
        .text(`Página ${indice + 1} de ${paginas.count}`, 438, FOOTER_Y + 6, {
          width: 109,
          align: 'right',
          lineBreak: false,
        });
    }
  }

  private localizarLogo(): string | null {
    const candidatos = [
      path.join(__dirname, 'assets', 'jornada_exe_icon.png'),
      path.resolve(
        process.cwd(),
        'src',
        'relatorios',
        'assets',
        'jornada_exe_icon.png',
      ),
      path.resolve(
        process.cwd(),
        '..',
        'imagens',
        'logo_jogo',
        'jornada_exe_icon.png',
      ),
    ];
    return candidatos.find((candidato) => fs.existsSync(candidato)) ?? null;
  }

  private rotuloClassificacao(value: DesempenhoGrupo['classificacao']): string {
    return {
      ponto_forte: 'Ponto forte',
      em_desenvolvimento: 'Em desenvolvimento',
      ponto_a_desenvolver: 'Ponto a desenvolver',
      amostra_insuficiente: 'Amostra insuficiente',
    }[value];
  }

  private corPercentual(percentual: number): string {
    if (percentual >= 75) return COLORS.green;
    if (percentual >= 50) return COLORS.amber;
    return COLORS.red;
  }

  private statusAluno(status: string): string {
    return (
      {
        iniciado: 'Não iniciada',
        jogando: 'Em andamento',
        finalizado: 'Finalizada',
      }[status] ?? 'Em andamento'
    );
  }

  private formatarData(value: Date | null): string {
    if (!value) return 'Sem registro';
    return new Intl.DateTimeFormat('pt-BR', {
      timeZone: 'America/Sao_Paulo',
    }).format(value);
  }

  private formatarDataHora(value: Date): string {
    return new Intl.DateTimeFormat('pt-BR', {
      dateStyle: 'short',
      timeStyle: 'short',
      timeZone: 'America/Sao_Paulo',
    }).format(value);
  }

  private formatarNumero(value: number): string {
    return new Intl.NumberFormat('pt-BR').format(value);
  }
}
