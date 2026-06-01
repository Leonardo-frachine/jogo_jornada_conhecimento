import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { configureApp } from './app.config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  configureApp(app);

  const port = Number(process.env.PORT ?? 3000);
  const host = process.env.HOST?.trim() || '0.0.0.0';
  await app.listen(port, host);
}

bootstrap().catch((error) => {
  console.error('Erro ao iniciar a API:', error);
  process.exit(1);
});
