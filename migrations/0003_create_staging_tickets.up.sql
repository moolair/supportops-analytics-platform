-- Migration 0003: staging_tickets
-- Type-cast and normalised layer. Business columns are properly typed; invalid
-- casts produce validation_errors rows (written by the validator) instead of
-- hard failures. Each row carries a validation_status set by the validator.
-- Re-running validate for a batch is safe: the Go validator deletes staging rows
-- for that batch_id then re-inserts, keeping this table idempotent per batch.

CREATE TABLE IF NOT EXISTS staging_tickets (
    id                BIGSERIAL    PRIMARY KEY,
    batch_id          BIGINT       NOT NULL REFERENCES import_batches (id) ON DELETE CASCADE,
    source_row_number INT          NOT NULL,
    staged_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    -- Business columns (properly typed, nullable — cast failures are recorded
    -- as validation_errors and the column is left NULL here)
    ticket_id         TEXT,
    opened_at         TIMESTAMPTZ,
    resolved_at       TIMESTAMPTZ,
    closed_at         TIMESTAMPTZ,
    priority          TEXT,
    status            TEXT,
    category          TEXT,
    subcategory       TEXT,
    assignment_group  TEXT,
    assigned_to       TEXT,
    channel           TEXT,
    requester         TEXT,
    short_description TEXT,
    sla_target_hours  NUMERIC,
    reopen_count      INT,

    -- Set by the validation engine after all rules are evaluated
    validation_status TEXT         NOT NULL DEFAULT 'valid'
                                   CHECK (validation_status IN ('valid', 'warning', 'rejected'))
);

CREATE INDEX IF NOT EXISTS idx_staging_tickets_batch_id        ON staging_tickets (batch_id);
CREATE INDEX IF NOT EXISTS idx_staging_tickets_validation_status ON staging_tickets (validation_status);
