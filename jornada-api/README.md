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
npm run report:sample
```

## Relatorios de desempenho

O painel do professor permite exportar dois formatos complementares dentro da sala selecionada:

- PDF individual, visual e paginado, com resumo, acertos, erros, desempenho por materia e dificuldade, pontos fortes, pontos a desenvolver e recomendacoes;
- CSV da sala, com uma linha por resposta e colunas estaveis para conferencia, Excel, Google Sheets ou Power BI.

Endpoints:

```text
GET /salas/:salaId/relatorios/alunos/:jogadorId/pdf?professorId=:professorId
GET /salas/:salaId/relatorios/respostas.csv?professorId=:professorId
```

O backend confirma que a sala pertence ao professor informado e que o aluno pertence a sala antes de gerar o arquivo. Ambos os formatos usam o mesmo servico de normalizacao; por isso, os eventos e totais permanecem consistentes.

Novas respostas guardam um snapshot da pergunta, da alternativa escolhida e da resposta correta. Registros antigos continuam exportaveis: os dados atuais da pergunta sao usados como fallback e uma escolha historica desconhecida permanece vazia no CSV e aparece como nao registrada no PDF.

O script `npm run report:sample` gera uma amostra longa em `../output/pdf/relatorio_modelo_ana_clara.pdf`, util para revisar o layout sem depender de dados locais.

Quando `DB_SYNCHRONIZE` estiver habilitado, o TypeORM cria as novas colunas de snapshot automaticamente. Ambientes que desabilitam a sincronizacao devem aplicar uma migracao equivalente antes do deploy.

## Deploy no Render

O deploy com `Render Postgres` esta documentado em `../docs/RENDER_DEPLOY.md` e automatizado pelo `render.yaml` da raiz do repositorio.
