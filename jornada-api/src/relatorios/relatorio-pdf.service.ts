import { Injectable } from '@nestjs/common';
import * as fs from 'node:fs';
import * as path from 'node:path';
import PDFDocument from 'pdfkit';
import {
  DesempenhoGrupo,
  RelatorioAluno,
  RespostaRelatorio,
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
export class RelatorioPdfService {
  async gerar(relatorio: RelatorioAluno): Promise<Buffer> {
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
          Title: `Relatorio individual de desempenho - ${relatorio.aluno.nome}`,
          Author: 'Jornada do Conhecimento',
          Subject: `Desempenho do aluno na sala ${relatorio.sala.nome}`,
          Keywords: 'educacao, desempenho, aluno, relatorio',
          CreationDate: relatorio.geradoEm,
        },
      });
      const partes: Buffer[] = [];

      doc.on('data', (parte: Buffer) => partes.push(parte));
      doc.on('error', reject);
      doc.on('end', () => resolve(Buffer.concat(partes)));

      this.desenharCabecalhoPrincipal(doc, relatorio);
      this.desenharResumoExecutivo(doc, relatorio);
      this.desenharSecaoDesempenho(doc, relatorio);
      this.desenharPontosPedagogicos(doc, relatorio);
      this.desenharDetalhamentoErros(doc, relatorio);
      this.desenharRecomendacoes(doc, relatorio);
      this.desenharRodapes(doc, relatorio);
      doc.end();
    });
  }

  private desenharCabecalhoPrincipal(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioAluno,
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
      .text('JORNADA DO CONHECIMENTO', 132, 51, { characterSpacing: 1.1 });
    doc.fontSize(20).text('Relatorio individual\nde desempenho', 132, 68, {
      width: 265,
      lineGap: -2,
    });
    doc
      .font('Helvetica')
      .fontSize(10)
      .fillColor('#D9E7F5')
      .text('Uma leitura clara do percurso de aprendizagem', 132, 121, {
        width: 265,
      });
    doc
      .font('Helvetica-Bold')
      .fontSize(13)
      .fillColor(COLORS.white)
      .text(relatorio.aluno.nome, 420, 69, { width: 130, align: 'center' });
    doc
      .font('Helvetica')
      .fontSize(8.5)
      .fillColor('#E9F3FF')
      .text(
        `${relatorio.sala.nome}\nCodigo ${relatorio.sala.codigo}`,
        420,
        96,
        {
          width: 130,
          align: 'center',
          lineGap: 3,
        },
      );
    doc.restore();

    doc.y = 174;
    this.desenharLinhaMetadados(doc, relatorio);
    doc.y = 216;
  }

  private desenharLinhaMetadados(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioAluno,
  ): void {
    const periodo = relatorio.periodo.inicio
      ? `${this.formatarData(relatorio.periodo.inicio)} a ${this.formatarData(relatorio.periodo.fim)}`
      : 'Sem respostas registradas';
    const itens = [
      ['Professor', relatorio.professor.nome],
      ['Periodo analisado', periodo],
      ['Gerado em', this.formatarDataHora(relatorio.geradoEm)],
    ];
    const largura = CONTENT_WIDTH / 3;

    itens.forEach(([rotulo, valor], indice) => {
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
  }

  private desenharResumoExecutivo(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioAluno,
  ): void {
    this.tituloSecao(
      doc,
      'Visao geral',
      'Os principais numeros do percurso deste aluno.',
    );

    const metricas = [
      {
        rotulo: 'Aproveitamento',
        valor: `${relatorio.resumo.aproveitamento}%`,
        detalhe: this.faixaAproveitamento(relatorio.resumo.aproveitamento),
        cor: this.corPercentual(relatorio.resumo.aproveitamento),
      },
      {
        rotulo: 'Pontuacao',
        valor: this.formatarNumero(relatorio.resumo.pontuacao),
        detalhe: 'saldo acumulado',
        cor: COLORS.blue,
      },
      {
        rotulo: 'Respondidas',
        valor: this.formatarNumero(relatorio.resumo.respondidas),
        detalhe: 'questoes no historico',
        cor: COLORS.navy,
      },
      {
        rotulo: 'Acertos',
        valor: this.formatarNumero(relatorio.resumo.acertos),
        detalhe: 'respostas corretas',
        cor: COLORS.green,
      },
      {
        rotulo: 'Erros',
        valor: this.formatarNumero(relatorio.resumo.erros),
        detalhe: 'oportunidades de revisao',
        cor: relatorio.resumo.erros > 0 ? COLORS.red : COLORS.green,
      },
      {
        rotulo: 'Jornada atual',
        valor: `Casa ${relatorio.aluno.casaAtual}`,
        detalhe: `Fase ${relatorio.aluno.faseAtual} - ${this.statusAluno(relatorio.aluno.statusPartida)}`,
        cor: COLORS.teal,
      },
    ];
    const espaco = 10;
    const largura = (CONTENT_WIDTH - espaco * 2) / 3;
    const altura = 70;
    const inicioY = doc.y + 8;

    metricas.forEach((metrica, indice) => {
      const coluna = indice % 3;
      const linha = Math.floor(indice / 3);
      const x = PAGE_MARGIN + coluna * (largura + espaco);
      const y = inicioY + linha * (altura + espaco);
      this.cartaoMetrica(doc, x, y, largura, altura, metrica);
    });
    doc.y = inicioY + altura * 2 + espaco + 18;
  }

  private cartaoMetrica(
    doc: PDFKit.PDFDocument,
    x: number,
    y: number,
    largura: number,
    altura: number,
    metrica: { rotulo: string; valor: string; detalhe: string; cor: string },
  ): void {
    doc
      .roundedRect(x, y, largura, altura, 10)
      .fillAndStroke(COLORS.soft, COLORS.line);
    doc.roundedRect(x, y, 5, altura, 3).fill(metrica.cor);
    doc
      .font('Helvetica-Bold')
      .fontSize(7.5)
      .fillColor(COLORS.muted)
      .text(metrica.rotulo.toUpperCase(), x + 16, y + 12, {
        width: largura - 27,
      });
    doc
      .font('Helvetica-Bold')
      .fontSize(18)
      .fillColor(COLORS.ink)
      .text(metrica.valor, x + 16, y + 27, {
        width: largura - 27,
        ellipsis: true,
      });
    doc
      .font('Helvetica')
      .fontSize(7.7)
      .fillColor(COLORS.muted)
      .text(metrica.detalhe, x + 16, y + 52, {
        width: largura - 27,
        ellipsis: true,
      });
  }

  private desenharSecaoDesempenho(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioAluno,
  ): void {
    this.garantirEspaco(doc, 135, relatorio);
    this.tituloSecao(
      doc,
      'Desempenho por area',
      'A classificacao considera ao menos tres respostas em cada grupo.',
    );
    this.desenharListaDesempenho(
      doc,
      'Por materia',
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
    relatorio: RelatorioAluno,
  ): void {
    this.garantirEspaco(doc, grupos.length > 0 ? 64 : 75, relatorio);
    doc
      .font('Helvetica-Bold')
      .fontSize(11)
      .fillColor(COLORS.navy)
      .text(titulo, PAGE_MARGIN, doc.y + 5);
    doc.y += 23;

    if (grupos.length === 0) {
      this.caixaMensagem(
        doc,
        'Ainda nao ha respostas para compor este indicador.',
        COLORS.muted,
      );
      return;
    }

    for (const grupo of grupos) {
      const iniciouNovaPagina = this.garantirEspaco(doc, 47, relatorio);
      if (iniciouNovaPagina) {
        doc
          .font('Helvetica-Bold')
          .fontSize(11)
          .fillColor(COLORS.navy)
          .text(`${titulo} - continuacao`, PAGE_MARGIN, doc.y + 3);
        doc.y += 22;
      }
      const y = doc.y;
      const barraX = PAGE_MARGIN + 190;
      const barraLargura = 220;
      const cor = this.corClassificacao(grupo.classificacao);
      doc
        .font('Helvetica-Bold')
        .fontSize(9.5)
        .fillColor(COLORS.ink)
        .text(grupo.nome, PAGE_MARGIN, y + 1, { width: 177, ellipsis: true });
      doc
        .font('Helvetica')
        .fontSize(7.5)
        .fillColor(COLORS.muted)
        .text(
          `${grupo.acertos} acertos de ${grupo.respondidas}`,
          PAGE_MARGIN,
          y + 17,
          {
            width: 177,
          },
        );
      doc.roundedRect(barraX, y + 5, barraLargura, 9, 4.5).fill('#E4EBF1');
      if (grupo.percentualAcerto > 0) {
        doc
          .roundedRect(
            barraX,
            y + 5,
            Math.max(8, (barraLargura * grupo.percentualAcerto) / 100),
            9,
            4.5,
          )
          .fill(cor);
      }
      doc
        .font('Helvetica-Bold')
        .fontSize(10)
        .fillColor(cor)
        .text(`${grupo.percentualAcerto}%`, barraX + barraLargura + 8, y + 2, {
          width: 45,
          align: 'right',
        });
      doc
        .font('Helvetica')
        .fontSize(7.2)
        .fillColor(COLORS.muted)
        .text(this.rotuloClassificacao(grupo.classificacao), barraX, y + 20, {
          width: barraLargura + 53,
          align: 'right',
        });
      doc.y = y + 42;
    }
    doc.y += 8;
  }

  private desenharPontosPedagogicos(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioAluno,
  ): void {
    this.garantirEspaco(doc, 155, relatorio);
    this.tituloSecao(
      doc,
      'Leitura pedagogica',
      'Destaques objetivos calculados a partir do desempenho por materia.',
    );
    const y = doc.y + 6;
    const largura = (CONTENT_WIDTH - 12) / 2;
    const altura = 105;
    this.cartaoLista(
      doc,
      PAGE_MARGIN,
      y,
      largura,
      altura,
      'Pontos fortes',
      relatorio.pontosFortes.map(
        (grupo) => `${grupo.nome} - ${grupo.percentualAcerto}%`,
      ),
      COLORS.green,
      'Nenhuma materia possui amostra suficiente acima de 75%.',
    );
    this.cartaoLista(
      doc,
      PAGE_MARGIN + largura + 12,
      y,
      largura,
      altura,
      'Pontos a desenvolver',
      relatorio.pontosADesenvolver.map(
        (grupo) => `${grupo.nome} - ${grupo.percentualAcerto}%`,
      ),
      COLORS.red,
      'Nenhuma materia com amostra suficiente esta abaixo de 50%.',
    );
    doc.y = y + altura + 20;
  }

  private cartaoLista(
    doc: PDFKit.PDFDocument,
    x: number,
    y: number,
    largura: number,
    altura: number,
    titulo: string,
    itens: string[],
    cor: string,
    vazio: string,
  ): void {
    doc
      .roundedRect(x, y, largura, altura, 10)
      .fillAndStroke(COLORS.soft, COLORS.line);
    doc.circle(x + 18, y + 19, 5).fill(cor);
    doc
      .font('Helvetica-Bold')
      .fontSize(10.5)
      .fillColor(COLORS.ink)
      .text(titulo, x + 31, y + 12, { width: largura - 43 });

    const exibidos = itens.slice(0, 3);
    if (exibidos.length === 0) {
      doc
        .font('Helvetica')
        .fontSize(8)
        .fillColor(COLORS.muted)
        .text(vazio, x + 15, y + 39, {
          width: largura - 30,
          lineGap: 2,
        });
      return;
    }

    exibidos.forEach((item, indice) => {
      doc.circle(x + 18, y + 44 + indice * 18, 2).fill(cor);
      doc
        .font('Helvetica')
        .fontSize(8.5)
        .fillColor(COLORS.ink)
        .text(item, x + 27, y + 38 + indice * 18, {
          width: largura - 42,
          ellipsis: true,
        });
    });
  }

  private desenharDetalhamentoErros(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioAluno,
  ): void {
    this.garantirEspaco(doc, 100, relatorio);
    this.tituloSecao(
      doc,
      'Questoes para revisar',
      'Respostas incorretas, da mais recente para a mais antiga.',
    );

    if (relatorio.erros.length === 0) {
      this.caixaMensagem(
        doc,
        relatorio.resumo.respondidas === 0
          ? 'O aluno ainda nao respondeu perguntas nesta sala.'
          : 'Excelente: nenhuma resposta incorreta foi registrada no periodo.',
        COLORS.green,
      );
      return;
    }

    relatorio.erros.forEach((resposta, indice) => {
      this.desenharErro(doc, resposta, indice + 1, relatorio);
    });
  }

  private desenharErro(
    doc: PDFKit.PDFDocument,
    resposta: RespostaRelatorio,
    indice: number,
    relatorio: RelatorioAluno,
  ): void {
    const larguraTexto = CONTENT_WIDTH - 34;
    doc.font('Helvetica').fontSize(8.5);
    const alturaPergunta = doc.heightOfString(resposta.perguntaEnunciado, {
      width: larguraTexto,
      lineGap: 1,
    });
    const escolhida = resposta.respostaEscolhidaLetra
      ? `${resposta.respostaEscolhidaLetra}) ${resposta.respostaEscolhidaTexto ?? 'Texto nao disponivel'}`
      : 'Nao registrada (dado historico ou tempo esgotado)';
    const correta = `${resposta.respostaCorretaLetra}) ${resposta.respostaCorretaTexto || 'Texto nao disponivel'}`;
    const alturaEscolhida = doc.heightOfString(escolhida, {
      width: larguraTexto - 78,
    });
    const alturaCorreta = doc.heightOfString(correta, {
      width: larguraTexto - 78,
    });
    // A resposta correta termina 73 pontos abaixo do topo, alem das alturas
    // variaveis. Os 84 pontos reservam 11 pontos de margem inferior real.
    const altura = 84 + alturaPergunta + alturaEscolhida + alturaCorreta;
    const iniciouNovaPagina = this.garantirEspaco(
      doc,
      Math.min(altura + 12, 680),
      relatorio,
    );
    if (iniciouNovaPagina) {
      doc
        .font('Helvetica-Bold')
        .fontSize(11)
        .fillColor(COLORS.navy)
        .text('Questoes para revisar - continuacao', PAGE_MARGIN, doc.y + 3);
      doc.y += 23;
    }
    const y = doc.y + 5;

    doc
      .roundedRect(PAGE_MARGIN, y, CONTENT_WIDTH, altura, 10)
      .fillAndStroke('#FFF9F8', '#F1D8D5');
    doc.roundedRect(PAGE_MARGIN, y, 6, altura, 3).fill(COLORS.red);
    doc
      .font('Helvetica-Bold')
      .fontSize(9)
      .fillColor(COLORS.red)
      .text(`REVISAO ${indice}`, PAGE_MARGIN + 18, y + 12, { width: 68 });
    doc
      .font('Helvetica')
      .fontSize(8)
      .fillColor(COLORS.muted)
      .text(
        `${resposta.materia}  |  ${resposta.dificuldade}  |  Fase ${resposta.fase}  |  ${this.formatarDataHora(resposta.respondidoEm)}`,
        PAGE_MARGIN + 91,
        y + 12,
        { width: CONTENT_WIDTH - 109, align: 'right', ellipsis: true },
      );
    doc
      .font('Helvetica-Bold')
      .fontSize(9.5)
      .fillColor(COLORS.ink)
      .text(
        resposta.perguntaTitulo || 'Pergunta respondida',
        PAGE_MARGIN + 18,
        y + 31,
        { width: larguraTexto - 145, ellipsis: true },
      );
    doc
      .font('Helvetica-Bold')
      .fontSize(8)
      .fillColor(COLORS.red)
      .text(
        `${this.formatarNumero(Math.abs(resposta.pontuacaoGanha))} pontos descontados`,
        PAGE_MARGIN + CONTENT_WIDTH - 145,
        y + 32,
        { width: 127, align: 'right' },
      );
    const perguntaY = y + 47;
    doc
      .font('Helvetica')
      .fontSize(8.5)
      .fillColor(COLORS.ink)
      .text(resposta.perguntaEnunciado, PAGE_MARGIN + 18, perguntaY, {
        width: larguraTexto,
        lineGap: 1,
      });
    const respostaY = perguntaY + alturaPergunta + 9;
    this.linhaResposta(
      doc,
      'Escolhida',
      escolhida,
      PAGE_MARGIN + 18,
      respostaY,
      COLORS.red,
      larguraTexto,
    );
    const corretaY = respostaY + alturaEscolhida + 17;
    this.linhaResposta(
      doc,
      'Correta',
      correta,
      PAGE_MARGIN + 18,
      corretaY,
      COLORS.green,
      larguraTexto,
    );
    doc.y = y + altura + 12;
  }

  private linhaResposta(
    doc: PDFKit.PDFDocument,
    rotulo: string,
    texto: string,
    x: number,
    y: number,
    cor: string,
    largura: number,
  ): void {
    doc
      .font('Helvetica-Bold')
      .fontSize(7.5)
      .fillColor(cor)
      .text(rotulo.toUpperCase(), x, y + 1, { width: 70 });
    doc
      .font('Helvetica')
      .fontSize(8.3)
      .fillColor(COLORS.ink)
      .text(texto, x + 76, y, { width: largura - 76, lineGap: 1 });
  }

  private desenharRecomendacoes(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioAluno,
  ): void {
    const altura = 70 + relatorio.recomendacoes.length * 30;
    this.garantirEspaco(doc, altura, relatorio);
    this.tituloSecao(
      doc,
      'Proximos passos',
      'Sugestoes objetivas para orientar o acompanhamento.',
    );
    const y = doc.y + 5;
    const caixaAltura = Math.max(70, relatorio.recomendacoes.length * 34 + 20);
    doc
      .roundedRect(PAGE_MARGIN, y, CONTENT_WIDTH, caixaAltura, 12)
      .fill('#EFF8F6');
    relatorio.recomendacoes.forEach((recomendacao, indice) => {
      const itemY = y + 14 + indice * 34;
      doc.circle(PAGE_MARGIN + 18, itemY + 6, 7).fill(COLORS.teal);
      doc
        .font('Helvetica-Bold')
        .fontSize(7)
        .fillColor(COLORS.white)
        .text(String(indice + 1), PAGE_MARGIN + 13, itemY + 2.5, {
          width: 10,
          align: 'center',
        });
      doc
        .font('Helvetica')
        .fontSize(8.7)
        .fillColor(COLORS.ink)
        .text(recomendacao, PAGE_MARGIN + 33, itemY, {
          width: CONTENT_WIDTH - 48,
          lineGap: 2,
        });
    });
    doc.y = y + caixaAltura + 12;
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
    relatorio: RelatorioAluno,
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
    relatorio: RelatorioAluno,
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
      .text(`${relatorio.aluno.nome}  |  ${relatorio.sala.nome}`, 265, 50, {
        width: 270,
        align: 'right',
        ellipsis: true,
      });
    doc.y = 108;
  }

  private desenharRodapes(
    doc: PDFKit.PDFDocument,
    relatorio: RelatorioAluno,
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
        .text(`Pagina ${indice + 1} de ${paginas.count}`, 438, FOOTER_Y + 6, {
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

  private corClassificacao(value: DesempenhoGrupo['classificacao']): string {
    return {
      ponto_forte: COLORS.green,
      em_desenvolvimento: COLORS.amber,
      ponto_a_desenvolver: COLORS.red,
      amostra_insuficiente: COLORS.muted,
    }[value];
  }

  private corPercentual(percentual: number): string {
    if (percentual >= 75) return COLORS.green;
    if (percentual >= 50) return COLORS.amber;
    return COLORS.red;
  }

  private faixaAproveitamento(percentual: number): string {
    if (percentual >= 75) return 'desempenho consistente';
    if (percentual >= 50) return 'em desenvolvimento';
    return 'requer acompanhamento';
  }

  private statusAluno(status: string): string {
    return (
      {
        iniciado: 'Nao iniciada',
        jogando: 'Em andamento',
        finalizado: 'Finalizada',
      }[status] ?? 'Em acompanhamento'
    );
  }

  private formatarData(value: Date | null): string {
    if (!value) return 'Sem registro';
    return new Intl.DateTimeFormat('pt-BR', {
      timeZone: 'America/Sao_Paulo',
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    }).format(value);
  }

  private formatarDataHora(value: Date): string {
    return new Intl.DateTimeFormat('pt-BR', {
      timeZone: 'America/Sao_Paulo',
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).format(value);
  }

  private formatarNumero(value: number): string {
    return new Intl.NumberFormat('pt-BR').format(value);
  }
}
