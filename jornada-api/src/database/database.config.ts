import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import * as fs from 'node:fs';
import * as path from 'node:path';

function isTestEnvironment(): boolean {
  // Os testes usam banco em memoria e nao devem disputar o arquivo da aplicacao.
  return process.env.NODE_ENV === 'test';
}

function shouldSynchronizeSchema(): boolean {
  // Mantem o comportamento historico: apenas o valor literal "false" desativa o synchronize.
  return process.env.DB_SYNCHRONIZE !== 'false';
}

function shouldUsePostgres(): boolean {
  // A presenca da URL e a chave que seleciona Postgres; sem ela o projeto usa SQLite.
  return Boolean(process.env.DATABASE_URL?.trim());
}

function shouldUseDatabaseSsl(): boolean {
  // SSL so e ativado explicitamente para nao dificultar o desenvolvimento local.
  return process.env.DATABASE_SSL === 'true';
}

function resolveSqliteDatabasePath(): string {
  // Cada teste recebe uma base descartavel, evitando dados residuais entre execucoes.
  if (isTestEnvironment()) {
    return ':memory:';
  }

  const configuredPath = process.env.DATABASE_PATH?.trim();
  const databasePath = configuredPath || 'jornada_conhecimento.sqlite';
  const resolvedDatabasePath = path.resolve(databasePath);

  ensureSeedSqliteDatabase(resolvedDatabasePath);

  return resolvedDatabasePath;
}

function ensureSeedSqliteDatabase(databasePath: string): void {
  const configuredSeedPath = process.env.DATABASE_SEED_PATH?.trim();
  const seedPath = configuredSeedPath || 'jornada_conhecimento.sqlite';
  const resolvedSeedPath = path.resolve(seedPath);

  // Nao copia o seed sobre ele mesmo, pois origem e destino representam o mesmo banco.
  if (databasePath === resolvedSeedPath) {
    return;
  }

  // Preserva bancos existentes e tambem aceita uma instalacao sem arquivo de seed.
  if (fs.existsSync(databasePath) || !fs.existsSync(resolvedSeedPath)) {
    return;
  }

  // Na primeira inicializacao, cria a pasta e parte de uma copia segura do banco-base.
  fs.mkdirSync(path.dirname(databasePath), { recursive: true });
  fs.copyFileSync(resolvedSeedPath, databasePath);
}

function createCommonOptions(): Pick<
  TypeOrmModuleOptions,
  'autoLoadEntities' | 'synchronize' | 'retryAttempts'
> {
  return {
    autoLoadEntities: true,
    synchronize: shouldSynchronizeSchema(),
    retryAttempts: isTestEnvironment() ? 0 : 10,
  };
}

function createPostgresOptions(): TypeOrmModuleOptions {
  const databaseUrl = process.env.DATABASE_URL?.trim();

  // Falha cedo quando o modo Postgres foi selecionado sem uma URL utilizavel.
  if (!databaseUrl) {
    throw new Error('DATABASE_URL nao foi configurada para o modo Postgres.');
  }

  return {
    type: 'postgres',
    url: databaseUrl,
    ssl: shouldUseDatabaseSsl() ? { rejectUnauthorized: false } : false,
    ...createCommonOptions(),
  };
}

function createSqliteOptions(): TypeOrmModuleOptions {
  return {
    type: 'better-sqlite3',
    database: resolveSqliteDatabasePath(),
    timeout: isTestEnvironment() ? 0 : 10000,
    prepareDatabase: (db) => {
      // Aguarda liberacao de escrita em vez de falhar imediatamente com SQLITE_BUSY.
      db.pragma('busy_timeout = 10000');
    },
    ...createCommonOptions(),
  };
}

export function createDatabaseOptions(): TypeOrmModuleOptions {
  // Centraliza a escolha do driver para que os modulos nao dependam do banco ativo.
  return shouldUsePostgres() ? createPostgresOptions() : createSqliteOptions();
}
