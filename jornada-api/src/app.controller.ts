import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    // Endpoint raiz funciona como verificacao simples de disponibilidade da API.
    return this.appService.getHello();
  }
}
