import {
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Query,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { RelatorioPdfService } from './relatorio-pdf.service';
import { RelatoriosService } from './relatorios.service';

@Controller('salas/:salaId/relatorios')
export class RelatoriosController {
  constructor(
    private readonly relatoriosService: RelatoriosService,
    private readonly relatorioPdfService: RelatorioPdfService,
  ) {}

  @Get('alunos/:jogadorId/pdf')
  async exportarPdfAluno(
    @Param('salaId', ParseIntPipe) salaId: number,
    @Param('jogadorId', ParseIntPipe) jogadorId: number,
    @Query('professorId', ParseIntPipe) professorId: number,
    @Res() response: Response,
  ): Promise<void> {
    const relatorio = await this.relatoriosService.obterRelatorioAluno(
      salaId,
      jogadorId,
      professorId,
    );
    const arquivo = await this.relatorioPdfService.gerar(relatorio);
    const nomeArquivo = this.relatoriosService.nomeArquivoPdf(relatorio);

    response.setHeader('Content-Type', 'application/pdf');
    response.setHeader('Content-Length', String(arquivo.length));
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="${nomeArquivo}"`,
    );
    response.send(arquivo);
  }

  @Get('respostas.csv')
  async exportarCsvSala(
    @Param('salaId', ParseIntPipe) salaId: number,
    @Query('professorId', ParseIntPipe) professorId: number,
    @Res() response: Response,
  ): Promise<void> {
    const relatorio = await this.relatoriosService.obterRelatorioSala(
      salaId,
      professorId,
    );
    const arquivo = this.relatoriosService.gerarCsv(relatorio);
    const nomeArquivo = this.relatoriosService.nomeArquivoCsv(relatorio);

    response.setHeader('Content-Type', 'text/csv; charset=utf-8');
    response.setHeader('Content-Length', String(arquivo.length));
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="${nomeArquivo}"`,
    );
    response.send(arquivo);
  }
}
