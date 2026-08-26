import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { configureApp } from './app.config';
import { AppModule } from './app.module';

async function bootstrap() {
  // Cria a aplicacao, aplica configuracoes globais e escuta em todas as interfaces por padrao.
  const app = await NestFactory.create(AppModule);

  configureApp(app);

  const port = Number(process.env.PORT ?? 3000);
  const host = process.env.HOST?.trim() || '0.0.0.0';
  await app.listen(port, host);
}

bootstrap().catch((error) => {
  // Falha de inicializacao encerra o processo para que o supervisor possa reinicia-lo.
  console.error('Erro ao iniciar a API:', error);
  process.exit(1);
});
