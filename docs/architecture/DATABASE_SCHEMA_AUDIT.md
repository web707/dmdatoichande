# Database schema audit

Local PostgreSQL 18.1 reported eight public tables and four applied migration files. The counts below were collected before write tests.

| Table | Rows | Integrity and indexes |
| --- | ---: | --- |
| `users` | 1 | UUID primary key, unique email, role check, password hash. |
| `sessions` | 0 | Token digest primary key, expiry index, user FK with delete cascade. |
| `places` | 5 | UUID key, required text, coordinate checks, timestamps. Migration 002 added visit fields and updated the two original seed IDs. |
| `phrases` | 12 | UUID key, category check, nullable owner FK with delete cascade, owner index. Null owner denotes shared content. |
| `foods_restaurants` | 6 | UUID key, food-key index and coordinate checks. Dish text is copied across addresses by the Express write transaction. |
| `events` | 6 | UUID key, names constrained, text dates and optional coordinates. |
| `emergency_contacts` | 15 | UUID key, category check and sort order. |
| `schema_migrations` | 4 | Unique migration filenames. Existing runner uses a transaction and an advisory transaction lock. |

Places, phrases, food and events each have a row-level timestamp trigger and a statement-level `catalog_changed` notification trigger. PostgreSQL NOTIFY delivers only after a successful commit. It carries table names and does not persist replay state.

The dump and restore covered the whole public schema. Count and row fingerprints matched across all eight tables. The destination list requires no schema change. A composite index for the list must be justified by representative query plans, since the current catalog contains only five places. See [runbook](../10_MIGRATION_RUNBOOK.md) and [synchronization design](../06_SYNCHRONIZATION_DESIGN.md).
