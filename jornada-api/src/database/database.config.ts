import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import * as fs from 'node:fs';
import * as path from 'node:path';

function isTestEnvironment(): boolean {
  return process.env.NODE_ENV === 'test';
}

function shouldSynchronizeSchema(): boolean {
  return process.env.DB_SYNCHRONIZE !== 'false';
}

function shouldUsePostgres(): boolean {
  return Boolean(process.env.DATABASE_URL?.trim());
}

function shouldUseDatabaseSsl(): boolean {
  return process.env.DATABASE_SSL === 'true';
}

function resolveSqliteDatabasePath(): string {
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

  if (databasePath === resolvedSeedPath) {
    return;
  }

  if (fs.existsSync(databasePath) || !fs.existsSync(resolvedSeedPath)) {
    return;
  }

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
      db.pragma('busy_timeout = 10000');
    },
    ...createCommonOptions(),
  };
}

export function createDatabaseOptions(): TypeOrmModuleOptions {
  return shouldUsePostgres() ? createPostgresOptions() : createSqliteOptions();
}
