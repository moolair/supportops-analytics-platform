-- Migration 0001: import_batches
-- Lineage control table. Every raw/staging/clean/validation row references
-- a batch_id here, making all pipeline steps batch-scoped and auditable.

CREATE TABLE IF NOT EXISTS import_batches (
    id          BIGSERIAL    PRIMARY KEY,
    source_file TEXT         NOT NULL,
    row_count   INT,
    status      TEXT         NOT NULL DEFAULT 'running'
                             CHECK (status IN ('running', 'completed', 'failed')),
    started_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    loaded_by   TEXT         NOT NULL DEFAULT CURRENT_USER
);
