# Deploy do `jornada-api` no Render com SQLite

Este projeto ja esta preparado para subir o backend `jornada-api` no Render usando o banco `SQLite` em um disco persistente.

## O que foi configurado

- O arquivo `render.yaml` na raiz define um `Web Service` para o `jornada-api`.
- O backend aceita `DATABASE_PATH` para gravar o `SQLite` no disco persistente do Render.
- No primeiro boot, se o banco ainda nao existir no disco e `DATABASE_SEED_PATH` existir, a API copia o arquivo inicial para o disco automaticamente.

## Como subir

1. Suba o repositorio no GitHub.
2. Entre no Render.
3. Clique em `New` -> `Blueprint`.
4. Selecione este repositorio.
5. Revise o arquivo `render.yaml`.
6. Informe a variavel secreta `GEMINI_API_KEY` quando o Render pedir.
7. Confirme a criacao do servico.

## Configuracao criada

- Servico: `jornada-api`
- Runtime: `node`
- Root directory: `jornada-api`
- Plano: `starter`
- Regiao: `virginia`
- Build command: `npm install && npm run build`
- Start command: `npm run start:prod`
- Health check: `/`
- Disco persistente: `/opt/render/project/src/data`

## Banco SQLite

No Render, o banco vai ficar em:

`/opt/render/project/src/data/jornada_conhecimento.sqlite`

No primeiro deploy, a API usa este arquivo como semente:

`/opt/render/project/src/jornada_conhecimento.sqlite`

Se o banco do disco ainda nao existir, ele sera copiado automaticamente.

## Depois do deploy

Pegue a URL publica do backend, por exemplo:

`https://jornada-api.onrender.com`

E atualize a URL usada pelo Godot em `scripts/ApiClient.gd` ou nas configuracoes do projeto.

## Observacoes importantes

- `persistent disk` no Render exige plano pago para o web service.
- Com `SQLite` + disco persistente, o backend fica simples para o TCC, mas nao escala para varias instancias.
- Se futuramente voces quiserem multiplayer mais robusto, o proximo passo natural e migrar o banco para `Render Postgres`.
