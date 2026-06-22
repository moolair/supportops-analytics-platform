# GitHub Issues — SupportOps Analytics Platform

This is the planned issue backlog for the MVP, grouped into milestones. Each
issue is small enough to be one branch + one PR. Naming follows `CLAUDE.md`:
flat tables (`raw_tickets`, `staging_tickets`, `tickets`, `validation_errors`)
and analytics views prefixed `vw_`.

Suggested labels: `infra`, `data-model`, `ingestion`, `validation`,
`analytics`, `docs`.

---

## Milestone 1 — Project Foundation

### #1 Set up project skeleton and Docker Compose
- **Goal:** Establish the repo layout and a one-command local environment.
- **Acceptance criteria:**
  - `go.mod` initialized; `cmd/supportops` + `internal/*` package folders exist.
  - `Makefile` with `setup`, `up`, `down` targets.
  - `docker-compose.yml` starts Postgres + Metabase with healthchecks and volumes.
  - `.env.example` documents `DATABASE_URL` and Metabase config.
  - `make up` brings both services up healthy; `make down` stops them.
- **Implementation notes:** Postgres 16, Metabase official image. Keep secrets in
  `.env` (gitignored); commit `.env.example` only. No app logic yet.
- **Branch:** `chore/project-skeleton`

### #2 Create PostgreSQL schema and migrations
- **Goal:** Define the layered schema via versioned migrations.
- **Acceptance criteria:**
  - `golang-migrate` wired in; `make migrate` applies all migrations cleanly.
  - Migrations create `raw_tickets`, `staging_tickets`, `tickets`,
    `validation_errors`, and an ingestion batch/control table.
  - Every table carries a `batch_id`; `raw_tickets` columns are all text + ingest metadata.
  - Matching `.down.sql` files exist and reverse cleanly.
- **Implementation notes:** raw = verbatim text; staging = typed/nullable; clean
  `tickets` = validated + derived columns (resolution_minutes, sla_breached).
- **Branch:** `feat/db-migrations`

### #3 Add sample IT ticket CSV data
- **Goal:** Provide realistic synthetic data, including deliberately dirty rows.
- **Acceptance criteria:**
  - `data/samples/tickets_clean.csv` and `data/samples/tickets_dirty.csv` committed.
  - Columns mirror ServiceNow-style fields (priority P1–P4, status, SLA target,
    assignment group, opened/resolved timestamps, reopen count, channel).
  - `tickets_dirty.csv` includes at least one row per planned validation rule
    (missing id, bad timestamp, resolved-before-opened, bad priority, etc.).
- **Implementation notes:** Document the seeded dirty rows so validation tests can
  assert exact error counts. Keep volume small (~200–500 rows) but distributions realistic.
- **Branch:** `data/sample-csv`

---

## Milestone 2 — Data Import MVP

### #4 Implement Go CSV importer
- **Goal:** Read a CSV file reliably into memory/stream with batch tracking.
- **Acceptance criteria:**
  - `internal/ingest` reads CSV via `encoding/csv`, treating all values as text.
  - A new ingestion batch row is created (status `running` → `completed`/`failed`).
  - Unit tests cover header mismatch, quoting, empty fields, and row counting.
- **Implementation notes:** Don't validate here — raw is verbatim. Capture
  `source_file` and `source_row_number` for every row.
- **Branch:** `feat/csv-importer`

### #5 Add raw ticket import command
- **Goal:** Expose import via the CLI and bulk-load into `raw_tickets`.
- **Acceptance criteria:**
  - `supportops import <file>` (and `make import`) loads rows via Postgres `COPY`.
  - Batch is marked `completed` with the correct `row_count`; failures mark `failed`.
  - Re-importing the same file is safe (batch-scoped, no duplication of prior batches).
- **Implementation notes:** Use `pgx` `CopyFrom`. Wrap in a transaction so a failed
  load leaves no partial batch.
- **Branch:** `feat/import-command`

---

## Milestone 3 — Data Validation

### #6 Implement validation rules
- **Goal:** Build a rule engine that evaluates each staging row.
- **Acceptance criteria:**
  - `internal/validate` defines a rule interface and ~8 rules (required id, unique
    id, valid opened_at, resolved_at ≥ opened_at, priority in set, status in set,
    numeric sla/reopen).
  - Each rule has a code, severity (`error`/`warning`), and message.
  - Table-driven tests cover valid + invalid input for every rule.
- **Implementation notes:** Casting raw → staging happens as part of validation;
  cast failures are themselves validation errors.
- **Branch:** `feat/validation-rules`

### #7 Store validation errors in database
- **Goal:** Persist rule failures as queryable data.
- **Acceptance criteria:**
  - `supportops validate <batch>` (and `make validate`) writes one row per failure
    to `validation_errors` with rule name, severity, message, ticket id, batch id,
    and source row number.
  - Each `staging_tickets` row is marked `valid` / `warning` / `rejected`.
  - Running validate on the dirty sample produces the documented error counts.
- **Implementation notes:** Idempotent per batch — re-validating clears prior
  errors for that batch first.
- **Branch:** `feat/validation-errors`

### #8 Create clean tickets table
- **Goal:** Promote validated rows into the analytics-ready `tickets` table.
- **Acceptance criteria:**
  - `supportops promote <batch>` (and `make promote`) inserts `valid`/`warning`
    rows into `tickets`; `rejected` rows are excluded.
  - Derived columns populated: `resolution_minutes`, `sla_breached`, `is_reopened`.
  - `ticket_id` is unique in `tickets`; re-promoting is safe (upsert by ticket id).
- **Implementation notes:** Promotion reads only from staging — never re-parses CSV.
- **Branch:** `feat/clean-tickets`

---

## Milestone 4 — Analytics SQL Views

### #9 Create analytics SQL views
- **Goal:** Compute recognizable ITSM KPIs over the clean table.
- **Acceptance criteria:**
  - Views created (as a migration): `vw_ticket_volume_daily`, `vw_sla_compliance`,
    `vw_resolution_time`, `vw_backlog_aging`, `vw_reopen_rate`,
    `vw_first_contact_resolution`, `vw_workload_by_group`, `vw_data_quality_summary`.
  - Each view returns sensible, non-null results against the sample data.
  - View DDL also kept under `sql/views/` for readability.
- **Implementation notes:** Backlog aging buckets <1d/1–3d/3–7d/>7d; SLA compliance
  = within-target ÷ total by priority and group; data-quality view reads from
  `validation_errors` + batch metadata.
- **Branch:** `feat/analytics-views`

---

## Milestone 5 — Dashboard & Documentation

### #10 Add data dictionary documentation
- **Goal:** Document every table and column.
- **Acceptance criteria:**
  - `docs/data-dictionary.md` lists each table (raw/staging/clean/meta) and view
    with column name, type, description, and source.
  - Derived columns note their formula.
- **Implementation notes:** Keep in sync with migrations; update in the same PR as
  schema changes going forward.
- **Branch:** `docs/data-dictionary`

### #11 Add data lineage documentation
- **Goal:** Show how data flows and transforms end to end.
- **Acceptance criteria:**
  - `docs/data-lineage.md` describes CSV → raw → staging → clean → views.
  - Includes a field-level mapping and a simple diagram (Mermaid or ASCII).
- **Implementation notes:** Call out where rows can be dropped (rejected) and where
  columns are derived.
- **Branch:** `docs/data-lineage`

### #12 Add dashboard screenshots
- **Goal:** Build and capture the Metabase dashboard.
- **Acceptance criteria:**
  - Metabase connected to Postgres; a dashboard with cards for volume, SLA
    compliance, MTTR, backlog aging, reopen rate, and data quality.
  - Screenshots committed to `docs/screenshots/` and referenced in the README.
- **Implementation notes:** Time-box polish — six clear cards on one screen beats
  pixel-perfection. Document the connection steps in `deploy/metabase/`.
- **Branch:** `docs/dashboard-screenshots`

### #13 Polish README for portfolio
- **Goal:** Make the repo readable and compelling to a hiring manager.
- **Acceptance criteria:**
  - `README.md` covers: what it is, architecture diagram, quickstart, the KPI set,
    dashboard screenshots, and the deliberate simplifications (framed as choices).
  - Links to the data dictionary and lineage docs.
- **Implementation notes:** Lead with the problem and outcome, not the tech list.
  Keep the quickstart copy-pasteable.
- **Branch:** `docs/readme-polish`
