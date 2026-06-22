# CLAUDE.md

Guidance for Claude Code sessions working in this repository.

## Project

SupportOps Analytics Platform is a portfolio project that demonstrates analytics
development for IT support ticket data.

The pipeline imports ticket data from CSV, validates data quality, stores clean
records in PostgreSQL, builds analytics SQL views, and documents metadata and
data lineage. It models a real ITSM (ServiceNow/Jira-style) analytics build —
not a toy CRUD app.

Narrative: *operational support exports are messy; this platform ingests them
safely, validates and cleans them, models them for analysis, surfaces support
KPIs in a BI tool, and documents the data so analysts can trust it.*

## Target Role Alignment

Built for **IT Systems Analyst / Analytics Development** roles. It demonstrates:

- SQL-based reporting
- data troubleshooting
- ETL/ELT-style data processing
- data validation
- data governance documentation (data dictionary + lineage + quality)
- backend development with Go

## Tech Stack

- Go (CLI, ingestion, validation)
- PostgreSQL (processing + serving)
- Docker Compose (Postgres + Metabase)
- SQL migrations (golang-migrate)
- Makefile (task runner)
- Metabase (dashboard / BI)
- GitHub Actions later, only if time allows

## MVP Scope

**Must build:**

- CSV importer (Go CLI)
- `raw_tickets` table (verbatim source landing)
- `staging_tickets` table (typed + normalized)
- clean `tickets` table (validated records)
- `validation_errors` table
- analytics SQL views
- sample CSV data (synthetic, including deliberately dirty rows)
- README
- data dictionary
- data lineage documentation
- Metabase dashboard + screenshots

**Do not build:**

- frontend UI
- authentication or user management
- real client data integration
- cloud deployment / Kubernetes
- complex microservices

If asked to add something from the "do not build" list, pause and confirm — it is
out of scope by design, and that scoping is part of the project's story.

## Coding Standards

- Keep code simple and readable; clarity over cleverness.
- Use clear package boundaries (ingest / validate / transform / quality / db).
- Prefer explicit errors over hidden control flow.
- Use environment variables for database config; never hardcode secrets.
- Match the style of surrounding code; no broad reformatting in unrelated files.
- Keep functions small and single-purpose.

## Go Conventions

- Module layout: `cmd/supportops` (entrypoint), `internal/*` (packages).
- Wrap errors with context: `fmt.Errorf("import batch: %w", err)`.
- Return errors; do not `log.Fatal` outside `main` / command roots.
- Use `pgx/v5`; use `COPY` for bulk loads into raw, not row-by-row inserts.
- Use `context.Context` on all DB calls; respect cancellation.
- Run `gofmt` and `go vet` before considering work done; keep `go build ./...` green.
- Keep dependencies minimal — stdlib first, then `cobra`, `pgx`, `golang-migrate`.

## Database Conventions

- **raw** tables preserve source data verbatim (all columns text + ingestion metadata).
- **staging** tables normalize and type-cast data.
- **clean** tables contain only validated records.
- Each layer carries a `batch_id` so every row traces back to its source file/row.
- Analytics views are prefixed with `vw_` (e.g. `vw_sla_compliance`).
- Validation errors are stored with: rule name, severity, message, and ticket ID
  (plus batch id and source row number for traceability).
- Severity is `error` (row excluded from clean) or `warning` (loaded but flagged).
- All schema changes go through numbered SQL migrations — never hand-edit a live schema.
- Ingestion is idempotent and batch-scoped: re-running an import must be safe.

## Testing Expectations

- Write tests for **validation logic** — this is the core correctness surface.
- Prefer table-driven tests for rules (one case per rule, valid + invalid inputs).
- Unit-test CSV parsing and type-casting edge cases (nulls, bad timestamps, quoting).
- Keep tests fast and deterministic; no reliance on wall-clock or network.
- DB-touching tests should run against the Docker Postgres and clean up after themselves.
- Run `make test` before opening a PR; do not commit failing tests.

## Documentation Expectations

- **README.md** — what the project is, quickstart, architecture summary,
  dashboard screenshots, and the deliberate simplifications (framed as choices).
- **docs/data-dictionary.md** — every table/column: name, type, description, source.
- **docs/data-lineage.md** — CSV → raw → staging → clean → views flow, with
  field-level mapping and a diagram.
- **docs/data-quality.md** — validation rules and how quality is measured/reported.
- Update docs in the same PR as the schema or view change that affects them.
- Keep docs accurate over exhaustive — stale docs are worse than brief ones.

## Commands

Expected Make targets (CLI lives under `cmd/supportops`):

- `make setup`    — install/prepare local dependencies
- `make up`       — start Postgres + Metabase (Docker Compose)
- `make down`     — stop containers
- `make migrate`  — apply SQL migrations
- `make import`   — load a CSV into raw (`supportops import <file>`)
- `make validate` — run validation engine (raw → staging, write errors)
- `make promote`  — load validated rows into clean tables
- `make report`   — generate the data-quality report
- `make test`     — run Go tests

## How to Run

1. `make up` — start Postgres + Metabase.
2. `make migrate` — create schemas, tables, and views.
3. `make import` — load sample CSV from `data/samples/` into raw.
4. `make validate` — quarantine bad rows into `validation_errors`.
5. `make promote` — populate clean `tickets` from valid staging rows.
6. `make report` — emit per-batch data-quality summary.
7. Open Metabase (localhost) to view the analytics dashboard.

## Working Agreement

- This is documentation-first right now; **do not implement the application yet**
  unless explicitly asked.
- Work issue-by-issue (see the roadmap); one branch + PR per issue.
- When in doubt about scope, prefer the smallest change that satisfies the MVP.
