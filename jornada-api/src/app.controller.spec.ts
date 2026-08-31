import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';

// Garante que o endpoint de saude continue acessivel apos iniciar o modulo raiz.
describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [AppService],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('retorna a descricao publica da API', () => {
      expect(appController.getHello()).toContain(
        'API do Jornada do Conhecimento esta rodando.',
      );
    });
  });
});
