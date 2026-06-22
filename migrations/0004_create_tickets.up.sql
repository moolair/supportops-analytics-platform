-- Migration 0004: tickets (clean layer)
-- Contains only rows whose validation_status is 'valid' or 'warning'.
-- Rejected rows are excluded permanently at promote time.
--
-- Derived columns are computed once on promote and stored here so analytics
-- views can filter/aggregate without re-computing per query.
--
-- ticket_id is UNIQUE so promote can use ON CONFLICT (ticket_id) DO UPDATE,
-- making re-promotion of the same batch safe (idempotent upsert).

CREATE TABLE IF NOT EXISTS tickets (
    id                 BIGSERIAL    PRIMARY KEY,
    batch_id           BIGINT       NOT NULL REFERENCES import_batches (id),
    source_row_number  INT          NOT NULL,
    promoted_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    -- Natural business key — unique across all batches
    ticket_id          TEXT         NOT NULL UNIQUE,

    -- Typed business columns (from staging)
    opened_at          TIMESTAMPTZ,
    resolved_at        TIMESTAMPTZ,
    closed_at          TIMESTAMPTZ,
    priority           TEXT,
    status             TEXT,
    category           TEXT,
    subcategory        TEXT,
    assignment_group   TEXT,
    assigned_to        TEXT,
    channel            TEXT,
    requester          TEXT,
    short_description  TEXT,
    sla_target_hours   NUMERIC,
    reopen_count       INT,

    -- Derived columns (computed on promote, stored for analytics performance)
    -- resolution_minutes: elapsed minutes from opened_at to resolved_at
    resolution_minutes NUMERIC,
    -- sla_breached: true when resolution_minutes > sla_target_hours * 60
    sla_breached       BOOLEAN,
    -- is_reopened: true when reopen_count > 0
    is_reopened        BOOLEAN
);

CREATE INDEX IF NOT EXISTS idx_tickets_batch_id         ON tickets (batch_id);
CREATE INDEX IF NOT EXISTS idx_tickets_priority         ON tickets (priority);
CREATE INDEX IF NOT EXISTS idx_tickets_assignment_group ON tickets (assignment_group);
CREATE INDEX IF NOT EXISTS idx_tickets_opened_at        ON tickets (opened_at);
