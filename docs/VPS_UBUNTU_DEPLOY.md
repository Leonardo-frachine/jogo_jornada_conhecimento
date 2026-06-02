# Deploy do `jornada-api` em VPS Ubuntu

Este guia sobe o backend `jornada-api` em uma VPS Ubuntu comum, como uma VPS da Hostinger, sem depender do seu PC local.

## Escolha recomendada

Para o primeiro deploy na VPS, o caminho mais simples e confiavel e:

- usar `Node.js 20`
- rodar a API com `systemd`
- manter a API na porta `3000`
- publicar na internet via `Nginx` na porta `80`

Se quiser algo ainda mais simples, voce pode expor direto a porta `3000`, mas `Nginx` costuma evitar dor de cabeca.

## 1. Preparar a VPS

Atualize os pacotes e instale dependencias basicas:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl build-essential python3 make g++ nginx
```

Instale o `Node.js 20`:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v
npm -v
```

## 2. Baixar o projeto

Clone o repositorio e entre na pasta da API:

```bash
git clone <URL_DO_SEU_REPOSITORIO>
cd jogo_jornada_conhecimento/jornada-api
```

Se voce nao usa Git na VPS, pode copiar a pasta do projeto por `scp` ou upload manual.

## 3. Criar o `.env`

Crie um `.env` de producao simples:

```bash
cp .env.example .env
```

Edite para algo assim:

```env
NODE_ENV=production
HOST=0.0.0.0
PORT=3000
DB_SYNCHRONIZE=true

# SQLite local
DATABASE_PATH=./jornada_conhecimento.sqlite
DATABASE_SEED_PATH=./jornada_conhecimento.sqlite
DATABASE_SEED_SQL_PATH=sql/perguntas_teste_25.sql

IA_ENABLED=true
GEMINI_MODEL=gemini-2.5-flash
GEMINI_API_KEY=SUA_CHAVE_AQUI
```

Observacoes:

- Se quiser manter seus dados atuais, copie tambem o arquivo `jornada_conhecimento.sqlite` para a VPS.
- Se nao copiar esse arquivo, a API sobe com banco novo e pode popular o seed SQL quando apropriado.
- Se nao quiser usar IA agora, troque `IA_ENABLED=true` por `IA_ENABLED=false`.

## 4. Instalar dependencias e compilar

```bash
npm ci --include=dev
npm run build
```

Se `better-sqlite3` falhar ao instalar, normalmente falta alguma dependencia nativa. O comando do passo 1 ja cobre os casos mais comuns.

## 5. Testar a API manualmente

Suba a API:

```bash
npm run start:prod
```

Em outro terminal da VPS, teste:

```bash
curl http://127.0.0.1:3000/perguntas
```

Se responder, a API esta funcionando localmente na VPS.

## 6. Rodar como servico com `systemd`

Copie o arquivo de exemplo deste repositorio:

```bash
sudo cp ../deploy/jornada-api.service /etc/systemd/system/jornada-api.service
```

Edite o `WorkingDirectory`, `ExecStart` e `User` se necessario:

```bash
sudo nano /etc/systemd/system/jornada-api.service
```

Depois ative:

```bash
sudo systemctl daemon-reload
sudo systemctl enable jornada-api
sudo systemctl start jornada-api
sudo systemctl status jornada-api
```

Para ver logs:

```bash
journalctl -u jornada-api -f
```

## 7. Liberar firewall

Se estiver usando `ufw`:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw enable
sudo ufw status
```

Se a Hostinger tiver firewall adicional no painel da VPS, libere la tambem.

## 8. Publicar com `Nginx`

Copie o exemplo:

```bash
sudo cp ../deploy/jornada-api.nginx /etc/nginx/sites-available/jornada-api
sudo ln -s /etc/nginx/sites-available/jornada-api /etc/nginx/sites-enabled/jornada-api
sudo nginx -t
sudo systemctl restart nginx
```

Isso faz o `Nginx` receber na porta `80` e encaminhar para `127.0.0.1:3000`.

Depois teste:

```bash
curl http://127.0.0.1/perguntas
```

## 9. Apontar o jogo para a VPS

No cliente Godot, troque a URL base para o IP publico ou dominio da VPS.

Arquivos:

- `project.godot`
- `scripts/ApiClient.gd`

Exemplo:

```txt
http://SEU_IP_DA_VPS:3000
```

Se estiver usando `Nginx`, prefira:

```txt
http://SEU_IP_DA_VPS
```

Ou, se tiver dominio:

```txt
https://api.seudominio.com
```

## 10. Checklist de erro

Se nao subir, verifique nesta ordem:

1. `npm run build` passa sem erro
2. `curl http://127.0.0.1:3000/perguntas` responde dentro da VPS
3. `systemctl status jornada-api` mostra servico ativo
4. `sudo ufw status` mostra a porta liberada
5. `curl http://IP_DA_VPS/perguntas` responde de fora
6. o cliente Godot aponta para a URL correta

## 11. Quando vale migrar para Postgres

SQLite funciona bem para um primeiro deploy leve em uma VPS.

Vale migrar para `Postgres` quando:

- houver varios acessos simultaneos
- voce quiser backup e restauracao mais robustos
- a VPS passar a ser o ambiente principal do projeto
