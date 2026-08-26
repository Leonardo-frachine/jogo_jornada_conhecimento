import { INestApplication, ValidationPipe } from '@nestjs/common';

export function configureApp(app: INestApplication): void {
  // Permite que o cliente Godot, inclusive exportado para Web, consuma a API.
  app.enableCors();

  // Valida todos os endpoints, remove campos extras e converte parametros tipados.
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );
}
