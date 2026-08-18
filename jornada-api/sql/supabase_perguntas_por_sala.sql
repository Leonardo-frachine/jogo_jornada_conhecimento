BEGIN;

ALTER TABLE perguntas
ADD COLUMN IF NOT EXISTS "salaId" integer;

ALTER TABLE perguntas
ADD COLUMN IF NOT EXISTS ativa boolean NOT NULL DEFAULT true;

WITH migration_needed AS (
  SELECT NOT EXISTS (
    SELECT 1
    FROM perguntas
    WHERE "salaId" IS NOT NULL
  ) AS should_migrate
)
INSERT INTO perguntas (
  "salaId",
  titulo,
  enunciado,
  "alternativaA",
  "alternativaB",
  "alternativaC",
  "alternativaD",
  "respostaCorreta",
  materia,
  dificuldade,
  pontuacao,
  "tempoLimite"
)
SELECT
  sala.id,
  pergunta.titulo,
  pergunta.enunciado,
  pergunta."alternativaA",
  pergunta."alternativaB",
  pergunta."alternativaC",
  pergunta."alternativaD",
  pergunta."respostaCorreta",
  pergunta.materia,
  pergunta.dificuldade,
  pergunta.pontuacao,
  pergunta."tempoLimite"
FROM perguntas pergunta
CROSS JOIN salas sala
CROSS JOIN migration_needed migration
WHERE pergunta."salaId" IS NULL
  AND migration.should_migrate;

DELETE FROM perguntas pergunta
WHERE pergunta."salaId" IS NULL
  AND NOT EXISTS (
    SELECT 1
    FROM progresso
    WHERE progresso."perguntaId" = pergunta.id
  );

CREATE INDEX IF NOT EXISTS "IDX_perguntas_salaId"
ON perguntas ("salaId");

ALTER TABLE perguntas
DROP CONSTRAINT IF EXISTS "FK_perguntas_sala";

ALTER TABLE perguntas
ADD CONSTRAINT "FK_perguntas_sala"
FOREIGN KEY ("salaId") REFERENCES salas(id) ON DELETE CASCADE;

COMMIT;
