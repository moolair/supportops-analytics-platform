-- Migration 0005: validation_errors
-- One row per validation rule failure. Storing errors as data (not just logs)
-- makes data quality queryable and dashboardable — a key portfolio signal.
--
-- Idempotency: the validator deletes all rows for a given batch_id before
-- re-inserting, so re-validating a batch is always safe.
--
-- severity levels:
--   'error'   — row is excluded from tickets (rejected)
--   'warning' — row is loaded into tickets but flagged

CREATE TABLE IF NOT EXISTS validation_errors (
    id                BIGSERIAL    PRIMARY KEY,
    batch_id          BIGINT       NOT NULL REFERENCES import_batches (id) ON DELETE CASCADE,
    source_row_number INT          NOT NULL,
    ticket_id         TEXT,                    -- NULL when ticket_id itself is invalid
    rule_code         TEXT         NOT NULL,   -- e.g. 'REQUIRED_TICKET_ID'
    severity          TEXT         NOT NULL    CHECK (severity IN ('error', 'warning')),
    column_name       TEXT,                    -- which column triggered the rule
    raw_value         TEXT,                    -- the offending raw value for diagnosis
    message           TEXT         NOT NULL,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_validation_errors_batch_id  ON validation_errors (batch_id);
CREATE INDEX IF NOT EXISTS idx_validation_errors_rule_code ON validation_errors (rule_code);
CREATE INDEX IF NOT EXISTS idx_validation_errors_severity  ON validation_errors (severity);
