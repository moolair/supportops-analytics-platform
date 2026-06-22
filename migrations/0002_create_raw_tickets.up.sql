-- Migration 0002: raw_tickets
-- Verbatim CSV landing zone. ALL business columns stored as TEXT — no casting,
-- no rejection. Casting failures surface during validation (migration 0003).
-- source_row_number + batch_id trace every row back to an exact CSV line.

CREATE TABLE IF NOT EXISTS raw_tickets (
    id                BIGSERIAL    PRIMARY KEY,
    batch_id          BIGINT       NOT NULL REFERENCES import_batches (id) ON DELETE CASCADE,
    source_row_number INT          NOT NULL,
    loaded_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    -- Business columns (all TEXT — source fidelity preserved)
    ticket_id         TEXT,
    opened_at         TEXT,
    resolved_at       TEXT,
    closed_at         TEXT,
    priority          TEXT,
    status            TEXT,
    category          TEXT,
    subcategory       TEXT,
    assignment_group  TEXT,
    assigned_to       TEXT,
    channel           TEXT,
    requester         TEXT,
    short_description TEXT,
    sla_target_hours  TEXT,
    reopen_count      TEXT
);

CREATE INDEX IF NOT EXISTS idx_raw_tickets_batch_id ON raw_tickets (batch_id);
