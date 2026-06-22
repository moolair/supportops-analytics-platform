# Sample Data Notes

## What the dataset represents

`data/sample_tickets.csv` is a synthetic IT support ticket export modelling the
kind of data that would be produced by an enterprise ITSM tool such as
ServiceNow or Jira Service Management.

It represents 3 months of ticket activity (January–March 2024) across a
fictional organisation's internal IT support operation. Tickets span hardware,
software, network, access management, and email categories, with realistic
distributions of priority, status, assignment group, and resolution time.

All names, ticket IDs, and descriptions are entirely fabricated. No real people,
organisations, email addresses, or private data appear anywhere in this file.

---

## Column alignment with the schema

The CSV header maps directly to the business columns in `raw_tickets` and
`staging_tickets`. Pipeline metadata columns (`batch_id`, `source_row_number`,
`loaded_at`, `staged_at`, `validation_status`) are added by the importer and
validator — they never appear in the CSV.

| CSV column | Maps to | Type in staging |
|---|---|---|
| `ticket_id` | `raw_tickets.ticket_id` | `TEXT` |
| `opened_at` | `raw_tickets.opened_at` | cast to `TIMESTAMPTZ` |
| `resolved_at` | `raw_tickets.resolved_at` | cast to `TIMESTAMPTZ` |
| `closed_at` | `raw_tickets.closed_at` | cast to `TIMESTAMPTZ` |
| `priority` | `raw_tickets.priority` | `TEXT` (validated: P1–P4) |
| `status` | `raw_tickets.status` | `TEXT` (validated against allowed set) |
| `category` | `raw_tickets.category` | `TEXT` |
| `subcategory` | `raw_tickets.subcategory` | `TEXT` |
| `assignment_group` | `raw_tickets.assignment_group` | `TEXT` |
| `assigned_to` | `raw_tickets.assigned_to` | `TEXT` |
| `channel` | `raw_tickets.channel` | `TEXT` |
| `requester` | `raw_tickets.requester` | `TEXT` |
| `short_description` | `raw_tickets.short_description` | `TEXT` |
| `sla_target_hours` | `raw_tickets.sla_target_hours` | cast to `NUMERIC` |
| `reopen_count` | `raw_tickets.reopen_count` | cast to `INT` |

---

## Clean data characteristics (rows 1–90)

- **100 total rows** (90 clean + 10 dirty)
- **Date range:** 2024-01-03 to 2024-03-29
- **Priority distribution:** ~5% P1, ~20% P2, ~50% P3, ~25% P4 (realistic enterprise skew)
- **Status mix:** Closed (50), Resolved (10), In Progress (10), Open (10), plus dirty rows
- **Reopen cases:** 12 tickets with `reopen_count > 0` (rows 5, 11, 23, 30, 45, 59, 81–90)
- **SLA targets:** P1=4h, P2=8h, P3=24h, P4=48h
- **Categories:** Hardware, Software, Network, Access Management, Email
- **Assignment groups:** IT Helpdesk, Desktop Support, Network Team, Security Team, Application Support
- **Channels:** Email, Phone, Self-Service
- **All names are fictional** — no real personal data

---

## Intentional dirty data cases (rows 91–100)

Each dirty row targets one validation rule. Row numbers are 1-based, excluding
the header. Tests can assert exact error counts against these rows.

| Row | ticket_id | Problem | Expected rule code | Severity |
|---|---|---|---|---|
| 91 | *(empty)* | `ticket_id` field is blank | `REQUIRED_TICKET_ID` | error |
| 92 | `INC0000001` | Duplicate of row 1 — same `ticket_id` reused | `DUPLICATE_TICKET_ID` | error |
| 93 | `INC0000093` | `priority` = `URGENT` — not in allowed set (P1–P4) | `INVALID_PRIORITY` | error |
| 94 | `INC0000094` | `status` = `Pending Vendor` — not in allowed status set | `INVALID_STATUS` | error |
| 95 | `INC0000095` | `status` = `Closed` but `resolved_at` is empty | `CLOSED_WITHOUT_RESOLVED` | error |
| 96 | `INC0000096` | `resolved_at` (09:00) is earlier than `opened_at` (15:00) on the same day | `RESOLVED_BEFORE_OPENED` | error |
| 97 | `INC0000097` | `requester` field is empty | `MISSING_REQUESTER` | warning |
| 98 | `INC0000098` | `sla_target_hours` = `-4` — negative value is not a valid SLA target | `INVALID_SLA_TARGET` | error |
| 99 | `INC0000099` | `category` = `Cafeteria Services` — outside the expected IT domain | `UNUSUAL_CATEGORY` | warning |
| 100 | `INC0000100` | `reopen_count` = `abc` — cannot be cast to integer | `INVALID_REOPEN_COUNT` | warning |

### Severity rationale

- **error** — the row cannot be meaningfully promoted to the clean `tickets`
  table (missing identity, impossible timestamps, invalid controlled vocabulary).
- **warning** — the row is usable for analytics but has a data quality gap that
  analysts should be aware of (missing optional field, out-of-domain value,
  non-critical cast failure).

### Note on `negative resolution_minutes`

The scope listed "negative resolution_minutes" as a dirty case. That column is
**derived** by the promoter (`resolved_at - opened_at`) and does not exist in the
CSV. Row 96 (`RESOLVED_BEFORE_OPENED`) produces the same logical problem: when
promoted, `resolution_minutes` would compute as a negative number, making it
detectable at both the validation and analytics layers.

---

## Why fake data is used

Real client names, email addresses, ticket descriptions, and internal system
details from any organisation are private. Using them in a public portfolio
repository would be a data-governance violation.

Synthetic data is the correct choice here and is standard practice in analytics
development work. It also gives precise control over the dirty-data scenarios,
which would be much harder to guarantee with a real export.

The deliberate trade-off is acknowledged in the project README under
"Deliberate Simplifications."
