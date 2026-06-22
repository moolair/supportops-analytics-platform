# SupportOps Analytics Platform

> An end-to-end analytics pipeline for IT support ticket data — CSV ingestion,
> data validation, layered PostgreSQL modeling, SQL analytics, and a Metabase
> dashboard, with full data-governance documentation.

> **Status:** 🚧 In development (portfolio project). See
> [`docs/github-issues.md`](docs/github-issues.md) for the roadmap.

---

## The Problem

<!-- TODO: 2–3 sentences. Enterprise support tools export messy CSVs: bad
timestamps, missing priorities, duplicate tickets. Undocumented and not modeled
for analysis, so analysts can't trust the numbers. -->

## What It Does

<!-- TODO: bullet list of outcomes:
- Idempotent ingestion pipeline (CSV -> raw -> staging -> clean)
- Validation engine that quarantines bad rows with reasons
- Analytics SQL views for ITSM KPIs
- Data-quality reporting
- Data dictionary + data lineage docs
- Metabase dashboard -->

## Architecture

<!-- TODO: diagram + short description. CSV -> Go CLI -> PostgreSQL layers
(raw / staging / clean / meta / analytics) -> Metabase. Link to
docs/diagrams/ once added. -->

## Tech Stack

- **Go** — CSV importer + validation engine
- **PostgreSQL** — layered data model + analytics views
- **Docker Compose** — Postgres + Metabase
- **golang-migrate** — versioned SQL migrations
- **Metabase** — BI dashboard
- **Make** — task runner

## Data Model

<!-- TODO: brief overview of the layers and the KPI views. Link to the data
dictionary. -->

| Layer | Purpose |
|-------|---------|
| `raw_tickets` | Verbatim CSV landing (all text + ingest metadata) |
| `staging_tickets` | Typed, normalized, validation-marked |
| `tickets` | Clean, validated records + derived columns |
| `validation_errors` | Quarantined rule failures |
| analytics views (`vw_*`) | ITSM KPIs |

## KPIs

<!-- TODO: list the views: volume, SLA compliance, MTTR, backlog aging, reopen
rate, first-contact resolution, workload by group, data-quality summary. -->

## Local Setup

**Prerequisites:** Docker (with Compose) and Make.

```bash
# 1. Create your local env file (make up does this automatically too)
cp .env.example .env

# 2. Start PostgreSQL
make up

# 3. Open a psql shell to confirm the database is up
make db-shell

# 4. Stop the database when done (data is preserved in the pgdata volume)
make down
```

Postgres listens on `localhost:5432` by default (configurable via `POSTGRES_PORT`
in `.env`). Run `make help` to list all available targets.

> Later steps (`make migrate`, `make import`, `make validate`, `make promote`,
> `make report`) and the Metabase dashboard are added in subsequent issues —
> see [`docs/github-issues.md`](docs/github-issues.md).

## Dashboard

<!-- TODO: embed screenshots from dashboards/screenshots/ -->

## Documentation

- [Data Dictionary](docs/data-dictionary.md) <!-- TODO: create -->
- [Data Lineage](docs/data-lineage.md) <!-- TODO: create -->
- [Architecture Decisions](docs/decisions/) <!-- ADRs -->
- [GitHub Issues / Roadmap](docs/github-issues.md)
- [CLAUDE.md](CLAUDE.md) — contributor + agent guidance

## Deliberate Simplifications

<!-- TODO: framed as choices, not gaps: synthetic data only, no auth, Metabase
over custom frontend, Postgres-only modeling, local Docker (no cloud/k8s). -->

## Repository Layout

```
cmd/importer/      # CSV import binary
cmd/validator/     # validation binary
internal/          # config, db, importer, validator, models, analytics
migrations/        # versioned SQL migrations
data/              # sample CSV data
docs/              # dictionary, lineage, decisions, diagrams
dashboards/        # Metabase exports + screenshots
tests/             # integration tests
```
