<div align="center">
  <img src="imagens/logo_jogo/logo_jogo.png" alt="Logo do Jornada do Conhecimento" width="420">

  <h1>Jornada do Conhecimento</h1>

  <p>Jogo educacional de tabuleiro que conecta alunos e professores em uma jornada gamificada de aprendizagem.</p>

  <p>
    <img src="https://img.shields.io/badge/Godot-4.6-478CBF?logo=godot-engine&logoColor=white" alt="Godot 4.6">
    <img src="https://img.shields.io/badge/NestJS-11-E0234E?logo=nestjs&logoColor=white" alt="NestJS 11">
    <img src="https://img.shields.io/badge/TypeScript-5.7-3178C6?logo=typescript&logoColor=white" alt="TypeScript 5.7">
    <img src="https://img.shields.io/badge/SQLite%20%7C%20PostgreSQL-TypeORM-336791" alt="SQLite ou PostgreSQL com TypeORM">
    <img src="https://img.shields.io/badge/status-em%20desenvolvimento-F0A500" alt="Status: em desenvolvimento">
  </p>
</div>

## Sobre o projeto

O **Jornada do Conhecimento** transforma atividades de múltipla escolha em uma partida de tabuleiro digital. O professor cria uma sala, prepara seu banco de perguntas e acompanha a turma; o aluno entra com o código da sala, escolhe um personagem e avança ao responder corretamente.

O repositório reúne duas aplicações integradas:

- um cliente em **Godot 4.6**, responsável pelo jogo e pelo painel do professor;
- uma API REST em **NestJS**, responsável por professores, salas, perguntas, jogadores, progresso, ranking e relatórios.

## Funcionalidades atuais

### Experiência do aluno

- entrada por nome e código de sala;
- escolha entre cinco personagens: cachorro, leão, tartaruga, águia e gato;
- tabuleiro responsivo com 28 casas e quatro níveis de dificuldade;
- dado animado, perguntas com alternativas embaralhadas e contagem regressiva;
- pontuação, XP, fase, acertos, erros e aproveitamento atualizados durante a partida;
- casas-desafio nas posições 5, 10, 15, 20 e 25;
- visualização dos demais participantes da sala no tabuleiro;
- tela final com resumo de desempenho, ranking da sala e opção de jogar novamente.

### Painel do professor

- cadastro e login de professores;
- criação, seleção e exclusão de salas com código único de seis caracteres;
- dashboard atualizado automaticamente com alunos, respostas, acertos, erros, aproveitamento e pontuação da turma;
- acompanhamento do estado, posição e pontuação dos alunos;
- ranking formado por alunos que finalizaram a partida;
- banco de perguntas separado por sala, com busca, filtros, edição e exclusão lógica;
- importação de perguntas em `.csv` ou `.xlsx` e download de um modelo CSV;
- geração de até 20 perguntas por vez com **Google Gemini**, seguida de revisão, edição, aprovação ou rejeição pelo professor;
- exportação de relatório individual em PDF, relatório consolidado da turma em PDF e base detalhada de respostas em CSV.

### Interface e acessibilidade

- layout adaptável a diferentes resoluções e escalas de fonte;
- tamanhos de texto em 100%, 115% e 130%;
- controles com área mínima de toque;
- volume geral e de efeitos sonoros, música, efeitos visuais e legendas configuráveis;
- preferências persistidas localmente entre execuções.

## Regras da partida

1. O aluno rola o dado e recebe uma pergunta correspondente ao nível da casa de destino.
2. Se acertar, recebe a pontuação integral da pergunta e avança o número de casas sorteado.
3. Se errar ou o tempo acabar, perde metade da pontuação da pergunta e permanece na posição atual.
4. Em uma casa-desafio, o peão avança antes da pergunta; em caso de erro, retorna a quantidade sorteada no dado.
5. A dificuldade cresce nas casas 1–7, 8–14, 15–21 e 22–28.
6. A jornada termina ao alcançar a casa 28. A conclusão é registrada na API e libera a participação no ranking final da sala.

Quando uma pergunta não possui tempo configurado, o cliente utiliza 30 segundos como limite padrão.

## Arquitetura

```text
Cliente Godot 4.6
├── fluxo do aluno
├── tabuleiro e HUD
├── painel do professor
└── configurações e acessibilidade
          │ HTTP/JSON
          ▼
API NestJS 11 + TypeORM
├── professores e salas
├── perguntas e importações
├── jogadores e progresso
├── rankings e relatórios
└── integração opcional com Gemini
          │
          ▼
SQLite (desenvolvimento) ou PostgreSQL (produção)
```

O cliente usa por padrão a API publicada em `https://api.nathanmariotto.com.br`. A URL pode ser alterada pela configuração `application/config/api_base_url` do projeto Godot.

## Tecnologias

| Camada | Tecnologias |
| --- | --- |
| Jogo e interface | Godot 4.6, GDScript, Jolt Physics |
| Backend | Node.js, NestJS 11, TypeScript 5.7 |
| Persistência | TypeORM, SQLite (`better-sqlite3`) e PostgreSQL |
| IA generativa | Google Gemini via `@google/genai` |
| Importação | CSV e Excel/XLSX |
| Relatórios | PDFKit e CSV |
| Testes | Jest, Supertest e ts-jest |

## Estrutura do repositório

```text
jogo_jornada_conhecimento/
├── assets/                 # Áudios e recursos visuais do jogo
├── data/                   # Arquivos de exemplo para importação
├── deploy/                 # Modelos de serviço systemd e proxy Nginx
├── docs/                   # Backlog e guias técnicos/deploy
├── documents/              # Diagramas, apresentação e planilha de exemplo
├── entitis/                # Cena do jogador
├── imagens/                # Tabuleiro, personagens, ícones e identidade visual
├── jornada-api/            # API NestJS, banco, testes e ferramentas
├── scene/                  # Cenas principais e componentes do Godot
├── scripts/                # Regras, estado, integração HTTP e controladores de UI
├── ui/settings/            # Menu global de configurações
├── export_presets.cfg      # Preset de exportação para Windows
└── project.godot           # Configuração e ponto de entrada do cliente
```

## Requisitos

- [Godot Engine 4.6](https://godotengine.org/download/);
- [Node.js 20 ou superior](https://nodejs.org/);
- npm;
- Git.

PostgreSQL e uma chave da API Gemini são opcionais. Sem `DATABASE_URL`, a API utiliza SQLite; sem a integração de IA habilitada, todas as demais funcionalidades continuam disponíveis.

## Executando localmente

### 1. Clone o repositório

```bash
git clone https://github.com/Leonardo-frachine/jogo_jornada_conhecimento.git
cd jogo_jornada_conhecimento
```

### 2. Configure e inicie a API

```bash
cd jornada-api
cp .env.example .env
npm ci
npm run start:dev
```

No PowerShell, use `Copy-Item .env.example .env` no lugar de `cp`.

A API ficará disponível em `http://localhost:3000`. O endpoint raiz funciona como verificação de disponibilidade. Em um banco vazio, o seed `sql/perguntas_teste_25.sql` é importado automaticamente quando configurado.

### 3. Aponte o jogo para a API local

No editor do Godot, altere a configuração `application/config/api_base_url` para:

```text
http://127.0.0.1:3000
```

Se quiser utilizar o backend já publicado, mantenha a URL presente em `project.godot`.

### 4. Execute o cliente

Abra `project.godot` no Godot 4.6 e use **Executar Projeto**. A cena inicial permite escolher o fluxo de aluno ou professor.

## Variáveis de ambiente da API

Use `jornada-api/.env.example` como base.

| Variável | Finalidade | Padrão/comportamento |
| --- | --- | --- |
| `PORT` | Porta HTTP da API | `3000` |
| `HOST` | Interface de rede | `0.0.0.0` |
| `NODE_ENV` | Ambiente de execução | `development` no exemplo |
| `DB_SYNCHRONIZE` | Sincronização automática do schema | ativa, exceto quando definida como `false` |
| `DATABASE_PATH` | Caminho do banco SQLite local | `jornada_conhecimento.sqlite` |
| `DATABASE_SEED_PATH` | Banco SQLite opcional usado como base | `jornada_conhecimento.sqlite` |
| `DATABASE_SEED_SQL_PATH` | SQL carregado quando não há perguntas | `sql/perguntas_teste_25.sql` |
| `DATABASE_URL` | Conexão PostgreSQL; quando presente, substitui o SQLite | não definida |
| `DATABASE_SSL` | Habilita SSL no PostgreSQL | `false` |
| `IA_ENABLED` | Habilita geração de perguntas com IA | `false` |
| `GEMINI_MODEL` | Modelo utilizado na geração | `gemini-2.5-flash` |
| `GEMINI_API_KEY` | Chave de acesso ao Gemini | obrigatória apenas com IA habilitada |

Para habilitar a geração assistida:

```env
IA_ENABLED=true
GEMINI_MODEL=gemini-2.5-flash
GEMINI_API_KEY=SUA_CHAVE_AQUI
```

Nunca envie o arquivo `.env` ou uma chave real para o repositório.

## Importação de perguntas

O painel aceita arquivos CSV e XLSX. No formato XLSX, a primeira aba é utilizada. O modelo pode ser baixado diretamente no painel ou consultado em `documents/planilha importacao.xlsx`.

Cabeçalho recomendado:

```csv
enunciado,alternativaA,alternativaB,alternativaC,alternativaD,respostaCorreta,materia,dificuldade,titulo,pontuacao,tempoLimite
```

Exemplo:

```csv
Quanto é 2 + 2?,3,4,5,6,B,Matemática,Facil,Adição básica,100,30
```

Regras principais:

- `enunciado`, as quatro alternativas, `respostaCorreta`, `materia`, `dificuldade` e `pontuacao` são obrigatórios;
- `respostaCorreta` deve ser `A`, `B`, `C` ou `D`;
- `titulo` e `tempoLimite` são opcionais;
- cabeçalhos são comparados sem diferenciar acentos, espaços ou pontuação;
- todas as perguntas importadas ficam vinculadas à sala selecionada.

## Principais endpoints

| Método | Rota | Descrição |
| --- | --- | --- |
| `GET` | `/` | Verificação de disponibilidade |
| `POST` | `/professores/cadastro` | Cadastro de professor |
| `POST` | `/professores/login` | Login de professor |
| `POST` | `/salas` | Criação de sala |
| `GET` | `/salas/codigo/:codigo` | Entrada/consulta por código |
| `GET` | `/salas/:id/dashboard` | Indicadores da turma |
| `GET` | `/salas/:id/alunos` | Alunos e posições atuais |
| `GET` | `/salas/:id/ranking` | Ranking de finalizados |
| `GET/POST/PATCH/DELETE` | `/perguntas` | Banco de perguntas por sala |
| `POST` | `/perguntas/importar-planilha` | Importação CSV/XLSX |
| `POST` | `/perguntas/gerar-ia` | Geração de perguntas com Gemini |
| `POST` | `/jogadores` | Criação ou recuperação do aluno na sala |
| `POST` | `/progresso` | Registro de uma resposta |
| `GET` | `/salas/:salaId/relatorios/alunos/:jogadorId/pdf` | PDF individual |
| `GET` | `/salas/:salaId/relatorios/turma.pdf` | PDF consolidado da turma |
| `GET` | `/salas/:salaId/relatorios/respostas.csv` | CSV detalhado da sala |

## Testes e qualidade

Execute os comandos na pasta `jornada-api`:

```bash
npm run build
npm test
npm run test:e2e
```

Outros comandos úteis:

```bash
npm run lint
npm run format
npm run report:sample
npm run report:class-sample
```

Os dois últimos comandos geram relatórios de amostra para revisão visual sem depender de uma partida local.

## Exportação e deploy

O projeto possui um preset **Windows Desktop** em `export_presets.cfg`. Para gerar o executável, abra **Projeto > Exportar** no Godot, selecione esse preset e escolha o destino do arquivo.

Para hospedar a API em uma VPS Ubuntu com Node.js, systemd e Nginx, consulte o guia [docs/VPS_UBUNTU_DEPLOY.md](docs/VPS_UBUNTU_DEPLOY.md). Os modelos usados no servidor estão em `deploy/`.

## Download e materiais

- [Acessar o site oficial do Jornada do Conhecimento](https://nathanmariotto.com.br/jornada/)
- [Baixar a versão mais recente pelo GitHub Releases](https://github.com/Leonardo-frachine/jogo_jornada_conhecimento/releases/latest)
- [Ver todas as versões publicadas](https://github.com/Leonardo-frachine/jogo_jornada_conhecimento/releases)
- [Apresentação on-line do projeto](https://docs.google.com/presentation/d/1prNslQZFVxaU26V2HwXLBW-e2A2WvyqLVdEKv4Kgrfg/edit?usp=sharing)
- [Apresentação armazenada no repositório](documents/Jornada-do-Conhecimento.pptx)
- [Diagrama de casos de uso](documents/Diagrama%20de%20Caso%20de%20Uso.pdf)
- [Diagrama de classes UML](documents/Diagrama%20de%20Classes%20UML.pdf)
- [Backlog do projeto](docs/BACKLOG.md)

## Status

O projeto está **em desenvolvimento**. A versão atual já cobre o ciclo completo de criação da sala, preparação de conteúdo, partida do aluno, acompanhamento da turma e exportação de resultados.

## Equipe

Desenvolvido como projeto acadêmico por:

- Guilherme Poit Vasconcelos
- Gustavo Henrique de Oliveira
- Leonardo Dias Frachine
- Nathan Henrique Mariotto Ritz
