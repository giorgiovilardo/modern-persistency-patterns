-- Runs before the Pagila dumps. Extensions Pagila itself needs are created by
-- the dump (pgvector); these are the ones we want for measuring things.
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
