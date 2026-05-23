# Jornada API

Backend em `NestJS + TypeORM` para o projeto `Jornada do Conhecimento`.

## Banco de dados

- Em desenvolvimento local, a API usa `SQLite` por padrao.
- Em producao, se `DATABASE_URL` estiver definida, a API usa `Postgres`.
- No primeiro boot de um banco vazio, a API importa `sql/perguntas_teste_25.sql`.

## Configuracao local

1. Instale as dependencias:

```bash
npm install
```

2. Opcionalmente, copie a base de exemplo:

```bash
copy .env.example .env
```

3. Inicie em modo desenvolvimento:

```bash
npm run start:dev
```

## Scripts

```bash
npm run build
npm run start
npm run start:dev
npm run start:prod
npm run test
npm run test:e2e
```

## Deploy no Render

O deploy com `Render Postgres` esta documentado em `../docs/RENDER_DEPLOY.md` e automatizado pelo `render.yaml` da raiz do repositorio.
