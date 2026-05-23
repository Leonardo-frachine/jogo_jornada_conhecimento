# Deploy do `jornada-api` no Render com Render Postgres

Este projeto agora esta preparado para subir o backend `jornada-api` no Render usando um banco `Render Postgres`.

## O que foi configurado

- O `render.yaml` cria um `Web Service` para a API e um banco `Render Postgres`.
- O backend usa `DATABASE_URL` quando ela existir, ativando Postgres automaticamente.
- Em desenvolvimento local, a API continua aceitando `SQLite`.
- Se a tabela `perguntas` estiver vazia no primeiro boot, a API importa o seed `sql/perguntas_teste_25.sql`.

## Como subir com Blueprint

1. Suba o repositorio no GitHub.
2. Entre no Render.
3. Clique em `New` -> `Blueprint`.
4. Selecione este repositorio.
5. Revise o arquivo `render.yaml`.
6. Informe `GEMINI_API_KEY` quando o Render pedir.
7. Confirme a criacao dos recursos.

## Recursos criados

- Web Service: `jornada-api`
- Banco Postgres: `jornada-db`
- Runtime: `node`
- Root directory: `jornada-api`
- Plano do web service: `starter`
- Plano do banco: `basic-256mb`
- Regiao: `virginia`
- Build command: `npm ci --include=dev && npm run build`
- Start command: `npm run start:prod`
- Health check: `/`

## Variaveis usadas no Render

- `NODE_ENV=production`
- `DATABASE_URL` apontando para o `connectionString` interno do banco `jornada-db`
- `DB_SYNCHRONIZE=true`
- `DATABASE_SEED_SQL_PATH=sql/perguntas_teste_25.sql`
- `IA_ENABLED=true`
- `GEMINI_MODEL=gemini-2.5-flash`
- `GEMINI_API_KEY` como segredo

## Se voce ja criou o Web Service antes

Voce pode seguir por um destes caminhos:

1. Recriar a infraestrutura via `Blueprint`, deixando o `render.yaml` gerenciar tudo.
2. Criar manualmente um `Render Postgres` no painel e adicionar a `DATABASE_URL` do banco no servico `jornada-api`.

Se optar pela configuracao manual, use a `Internal Database URL` do banco e mantenha web service e banco na mesma regiao.

## Depois do deploy

Use a URL publica da API:

`https://jornada-api.onrender.com`

Depois ajuste a URL usada pelo Godot em `scripts/ApiClient.gd` ou nas configuracoes do projeto.

## Observacoes importantes

- O seed SQL roda apenas quando a tabela `perguntas` estiver vazia.
- `DB_SYNCHRONIZE=true` simplifica o deploy inicial. Para uma fase posterior, o ideal e migrar para migrations versionadas.
- O `Deploy Hook` do Render continua util para forcar novos deploys sem precisar abrir o painel.
