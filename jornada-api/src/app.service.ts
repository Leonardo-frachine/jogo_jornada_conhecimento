import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'Api ta no ar bem vindo ao jornada do conhecimento para mais informações acesse o link: https://nathanmariotto.com.br/jornada';
  }
}
