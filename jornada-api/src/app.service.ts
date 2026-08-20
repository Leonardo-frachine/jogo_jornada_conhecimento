import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'API do Jornada do Conhecimento esta rodando. Este backend atende o jogo educacional Jornada do Conhecimento com recursos de salas, jogadores, progresso, professores e perguntas. Para mais informacoes, acesse: https://nathanmariotto.com.br/jornada';
  }
}
