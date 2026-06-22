# Data Dictionary

Column-level reference for all tables in the SupportOps Analytics Platform.
Updated in the same PR as schema changes. Analytics views (`vw_*`) are added in Issue #9.

---

## Table: `import_batches`

Control/lineage table. One row per CSV import run. All other tables reference
`batch_id` here, making every pipeline step batch-scoped and auditable.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | NO | Surrogate primary key. Used as `batch_id` in all downstream tables. |
| `source_file` | `TEXT` | NO | File path or name of the imported CSV. |
| `row_count` | `INT` | YES | Total rows read from the CSV (set when the batch completes). |
| `status` | `TEXT` | NO | Pipeline state: `running` → `completed` or `failed`. |
| `started_at` | `TIMESTAMPTZ` | NO | When the import began. Defaults to `NOW()`. |
| `finished_at` | `TIMESTAMPTZ` | YES | When the import completed or failed. NULL while running. |
| `loaded_by` | `TEXT` | NO | Database user or application name that initiated the import. |

---

## Table: `raw_tickets`

Verbatim CSV landing zone. Every business column is stored as `TEXT` — no
casting, no rejection. The goal is source fidelity: this table is the
replayable source of truth and is never modified after load.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | NO | Surrogate primary key. |
| `batch_id` | `BIGINT` | NO | FK → `import_batches.id`. Links this row to its import run. |
| `source_row_number` | `INT` | NO | 1-based row number in the source CSV (header excluded). Used to trace validation errors back to an exact line. |
| `loaded_at` | `TIMESTAMPTZ` | NO | When this row was bulk-loaded into the database. |
| `ticket_id` | `TEXT` | YES | Raw support ticket identifier (e.g. `INC0012345`). |
| `opened_at` | `TEXT` | YES | Raw ticket creation timestamp as it appeared in the CSV. |
| `resolved_at` | `TEXT` | YES | Raw resolution timestamp. |
| `closed_at` | `TEXT` | YES | Raw closure timestamp. |
| `priority` | `TEXT` | YES | Raw priority value (expected: `P1`–`P4`). |
| `status` | `TEXT` | YES | Raw ticket status (e.g. `Open`, `Resolved`, `Closed`). |
| `category` | `TEXT` | YES | Top-level service category. |
| `subcategory` | `TEXT` | YES | Sub-category under `category`. |
| `assignment_group` | `TEXT` | YES | Team or queue the ticket is assigned to. |
| `assigned_to` | `TEXT` | YES | Individual assignee. |
| `channel` | `TEXT` | YES | Contact channel (e.g. `Email`, `Phone`, `Self-Service`). |
| `requester` | `TEXT` | YES | Person who submitted the ticket. |
| `short_description` | `TEXT` | YES | One-line summary of the issue. |
| `sla_target_hours` | `TEXT` | YES | Raw SLA target in hours (e.g. `4`, `8`). Stored as text; cast during staging. |
| `reopen_count` | `TEXT` | YES | Raw number of times the ticket was reopened. |

---

## Table: `staging_tickets`

Typed and normalised layer. Business columns are cast to their proper types;
failed casts produce rows in `validation_errors` and leave the column `NULL`
here. Each row is marked with a `validation_status` set by the validation engine.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | NO | Surrogate primary key. |
| `batch_id` | `BIGINT` | NO | FK → `import_batches.id`. |
| `source_row_number` | `INT` | NO | Matches `raw_tickets.source_row_number` for traceability. |
| `staged_at` | `TIMESTAMPTZ` | NO | When this row was written to staging. |
| `ticket_id` | `TEXT` | YES | Ticket identifier (text; validated for uniqueness and format). |
| `opened_at` | `TIMESTAMPTZ` | YES | Cast from raw. NULL if the raw value failed timestamp parsing. |
| `resolved_at` | `TIMESTAMPTZ` | YES | Cast from raw. NULL if invalid. |
| `closed_at` | `TIMESTAMPTZ` | YES | Cast from raw. NULL if invalid. |
| `priority` | `TEXT` | YES | Normalised priority. Validated to be one of `P1`–`P4`. |
| `status` | `TEXT` | YES | Normalised status. Validated against the allowed status set. |
| `category` | `TEXT` | YES | Service category. |
| `subcategory` | `TEXT` | YES | Sub-category. |
| `assignment_group` | `TEXT` | YES | Assignment group (warned if missing). |
| `assigned_to` | `TEXT` | YES | Assignee. |
| `channel` | `TEXT` | YES | Contact channel. |
| `requester` | `TEXT` | YES | Requester name. |
| `short_description` | `TEXT` | YES | Ticket summary. |
| `sla_target_hours` | `NUMERIC` | YES | Cast from raw. NULL if not a positive number. |
| `reopen_count` | `INT` | YES | Cast from raw. NULL if not a non-negative integer. |
| `validation_status` | `TEXT` | NO | Set by the validator: `valid`, `warning`, or `rejected`. Only `valid` and `warning` rows are promoted to `tickets`. |

---

## Table: `tickets`

Clean, analytics-ready fact table. Contains only rows whose `validation_status`
is `valid` or `warning`. Rows with `rejected` status are permanently excluded.

`ticket_id` is `UNIQUE`, enabling the promoter to upsert by natural key
(`ON CONFLICT (ticket_id) DO UPDATE`) so re-promoting a batch is idempotent.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | NO | Surrogate primary key. |
| `batch_id` | `BIGINT` | NO | FK → `import_batches.id`. Tracks which import produced this row. |
| `source_row_number` | `INT` | NO | Original CSV line number, for end-to-end traceability. |
| `promoted_at` | `TIMESTAMPTZ` | NO | When this row was written to the clean layer. |
| `ticket_id` | `TEXT` | NO | Unique ticket identifier. Natural key for upserts. |
| `opened_at` | `TIMESTAMPTZ` | YES | Ticket creation time. |
| `resolved_at` | `TIMESTAMPTZ` | YES | Resolution time. |
| `closed_at` | `TIMESTAMPTZ` | YES | Closure time. |
| `priority` | `TEXT` | YES | Validated priority (`P1`–`P4`). |
| `status` | `TEXT` | YES | Validated status. |
| `category` | `TEXT` | YES | Service category. |
| `subcategory` | `TEXT` | YES | Sub-category. |
| `assignment_group` | `TEXT` | YES | Assignment group. |
| `assigned_to` | `TEXT` | YES | Assignee. |
| `channel` | `TEXT` | YES | Contact channel. |
| `requester` | `TEXT` | YES | Requester. |
| `short_description` | `TEXT` | YES | Ticket summary. |
| `sla_target_hours` | `NUMERIC` | YES | SLA target in hours. |
| `reopen_count` | `INT` | YES | Number of times the ticket was reopened. |
| `resolution_minutes` | `NUMERIC` | YES | **Derived.** `EXTRACT(EPOCH FROM (resolved_at - opened_at)) / 60`. NULL if either timestamp is missing. |
| `sla_breached` | `BOOLEAN` | YES | **Derived.** `resolution_minutes > sla_target_hours * 60`. NULL if either input is NULL. |
| `is_reopened` | `BOOLEAN` | YES | **Derived.** `reopen_count > 0`. NULL if `reopen_count` is NULL. |

---

## Table: `validation_errors`

One row per rule failure. Storing errors as data (not just logs) makes data
quality queryable and dashboardable. The validator deletes all rows for a
`batch_id` before re-inserting, so re-validating is idempotent.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | NO | Surrogate primary key. |
| `batch_id` | `BIGINT` | NO | FK → `import_batches.id`. |
| `source_row_number` | `INT` | NO | CSV line number of the offending row. |
| `ticket_id` | `TEXT` | YES | Ticket identifier. NULL when `ticket_id` itself is the invalid value. |
| `rule_code` | `TEXT` | NO | Machine-readable rule identifier (e.g. `REQUIRED_TICKET_ID`, `INVALID_PRIORITY`). |
| `severity` | `TEXT` | NO | `error` — row is excluded from `tickets`; `warning` — row is loaded but flagged. |
| `column_name` | `TEXT` | YES | Column that triggered the rule. NULL for cross-column rules. |
| `raw_value` | `TEXT` | YES | The offending value from `raw_tickets` for diagnostic display. |
| `message` | `TEXT` | NO | Human-readable description of the failure. |
| `created_at` | `TIMESTAMPTZ` | NO | When this error was recorded. |

---

## Planned additions (future issues)

| Object | Issue | Notes |
|---|---|---|
| `vw_ticket_volume_daily` | #9 | Daily opened/resolved counts |
| `vw_sla_compliance` | #9 | % within SLA by priority and group |
| `vw_resolution_time` | #9 | MTTR / median by priority and group |
| `vw_backlog_aging` | #9 | Open tickets in age buckets |
| `vw_reopen_rate` | #9 | Reopened ÷ total by group |
| `vw_first_contact_resolution` | #9 | FCR rate |
| `vw_workload_by_group` | #9 | Volume + open backlog per group |
| `vw_data_quality_summary` | #9 | Per-batch pass/warn/reject + completeness |
