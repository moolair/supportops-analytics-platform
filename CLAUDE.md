# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

SupportOps Analytics Platform — a portfolio project that models an enterprise
ITSM (ServiceNow/Jira-style) analytics pipeline. It imports IT support tickets
from CSV, validates data quality, models the data through layered PostgreSQL
tables, exposes analytics SQL views, and documents metadata and lineage. Target
audience: **IT Systems Analyst / Analytics Development** roles, so the value is
in the data modeling, validation, and governance — not in app features.

It is built **issue by issue**. The full backlog (13 issues across 5 milestones)
lives in `docs/github-issues.md` and as GitHub issues. Match the issue's scope;
prefer the smallest change that satisfies the MVP.

## Current State (read before assuming)

This repo is early. As of now: Docker Compose Postgres works; the folder skeleton
and docs exist; **there is no `go.mod` and no Go code yet** — `cmd/` and
`internal/` are empty placeholders. `make migrate/import/validate/promote/test`
are intentional TODO stubs that echo their issue number until implemented. Verify
what exists before referencing files in suggestions.

## Commands

```bash
make help        # list all targets
make up          # start PostgreSQL (auto-creates .env from .env.example)
make down        # stop containers (pgdata volume is preserved)
make db-shell    # psql shell into the postgres container
make logs        # tail postgres logs
```

Local DB is `postgres:16` on `localhost:5432`, configured entirely from `.env`
(see `.env.example`: `POSTGRES_*` + a `DATABASE_URL` DSN). `make up` requires the
Docker daemon to be running.

Pipeline / Go commands (wired as their issues land): `make migrate` (golang-migrate),
`make import` / `make validate` / `make promote`, `make test` (`go test ./...`).
Once `go.mod` exists, run a single test with
`go test ./internal/validator/ -run TestName`.

## Architecture (the big picture)

**Layered ELT, driven by Go CLIs, with PostgreSQL as the processing + serving
engine and Metabase as the BI layer.** Data moves through named stages, each a
table/layer:

```
CSV → raw_tickets → staging_tickets → tickets → vw_* (analytics views) → Metabase
                         │ (rules)
                         └→ validation_errors
```

- **`raw_tickets`** — verbatim CSV landing. **All columns are text**, plus
  ingestion metadata. Nothing is rejected here; raw is the replayable source of
  truth. Loaded via Postgres `COPY` (`pgx CopyFrom`), not row-by-row inserts.
- **`staging_tickets`** — typed/cast, normalized, deduped. Casting failures are
  themselves validation errors. Each row is marked `valid` / `warning` / `rejected`.
- **`tickets`** (clean) — only `valid`/`warning` rows, with derived columns
  (`resolution_minutes`, `sla_breached`, `is_reopened`). `ticket_id` is unique.
- **`validation_errors`** — every rule failure as a queryable row (rule name,
  severity, message, ticket id, batch id, source row number). Validation is data,
  not just logs — this is what makes data quality dashboardable.
- **`vw_*` views** — ITSM KPIs (volume, SLA compliance, MTTR, backlog aging,
  reopen rate, FCR, workload by group, data-quality summary).

**Two cross-cutting invariants worth understanding before editing the pipeline:**
- **Batch lineage:** every row in every layer carries a `batch_id` (+ source row
  number) tracing back to one CSV line, recorded in an ingestion-batch control
  table. This is what makes errors explainable and re-runs auditable.
- **Idempotency:** import, validate, and promote are all safe to re-run for a
  batch (re-validating clears that batch's prior errors; promote upserts by
  `ticket_id`). Don't introduce steps that break batch-scoped re-runs.

## Structure & Conventions

- Two binaries: `cmd/importer` (CSV → raw) and `cmd/validator` (raw → staging →
  validation_errors). Packages under `internal/`: `config`, `db`, `importer`,
  `validator`, `models`, `analytics`. Treat `make import` / `make validate` as
  the stable interface regardless of binary wiring.
- Tables use flat names (`raw_tickets`, `staging_tickets`, `tickets`,
  `validation_errors`); analytics views are prefixed `vw_`.
- All schema changes go through numbered migrations in `migrations/` — never
  hand-edit a live schema.
- Validation severity: `error` excludes the row from `tickets`; `warning` loads
  but flags it.
- Go: wrap errors with context (`fmt.Errorf("...: %w", err)`); return errors
  rather than `log.Fatal` outside command roots; use `context.Context` on DB
  calls; stdlib first, then `cobra` / `pgx/v5` / `golang-migrate`. Config comes
  from environment variables only.

## Testing & Docs Expectations

- The **validation rules are the core correctness surface** — cover them with
  table-driven tests (valid + invalid per rule), plus CSV parsing / type-cast
  edge cases (nulls, bad timestamps, quoting). Keep tests deterministic.
- The sample data (`data/`) deliberately includes dirty rows, one per rule;
  tests can assert exact error counts against it.
- Keep `docs/data-dictionary.md` and `docs/data-lineage.md` in sync **in the same
  PR** as any schema or view change. Architecture decisions go in `docs/decisions/`.

## Out of Scope (by design — confirm before adding)

Frontend UI · authentication / user management · real client data · cloud
deployment / Kubernetes · complex microservices. These omissions are part of the
project's story; if asked to add one, pause and confirm.
