# Current architecture

| Boundary | Source | Observed behavior |
| --- | --- | --- |
| Flutter entry and navigation | [main.dart](../../lib/main.dart), [app.dart](../../lib/app/app.dart) | One Web and Android source tree, responsive shell and hash-based web routing. Returning to the foreground requests a refresh. |
| API client and state | [api.dart](../../lib/core/api.dart), [store.dart](../../lib/core/store.dart), [catalog.dart](../../lib/core/catalog.dart) | Startup loads four catalog lists and emergency contacts. Catalog refreshes repeat every 20 seconds, after reconnect and after a debounced SSE notification. The in-memory snapshot survives a failed request. |
| Public content and CMS | [features](../../lib/features), [app.ts](../../backend/src/app.ts), [validation.ts](../../backend/src/validation.ts) | Express validates and authorizes mutations. The Flutter CMS exposes places, shared phrases and foods. Events can be written by an admin via the API. Emergency contacts are read-only. |
| Realtime | [events.ts](../../backend/src/events.ts), [server.ts](../../backend/src/server.ts) | A dedicated PostgreSQL listener forwards table names via an in-process hub. Clients can receive `ready`, `reconnecting`, heartbeat and table events. Notifications are transient and contain no record contents. |
| Identity | [security.ts](../../backend/src/security.ts), [app.ts](../../backend/src/app.ts) | scrypt, SHA-256 token digest, PostgreSQL expiry and revocation. Bearer token lives in Flutter memory. Private phrases are scoped to their owner. |
| Storage | [migrations](../../backend/migrations), [catalog.json](../../backend/seed/catalog.json), [db.ts](../../backend/src/db.ts) | One PostgreSQL database, one capped API pool and an additional LISTEN connection. Static assets and bookmarks have separate storage. |
| Operations | [scripts](../../scripts), [backend tests](../../backend/test), [Flutter tests](../../test) | Windows local startup, Vitest/Supertest, Flutter tests and an optional Playwright/ADB path. Original checked-in CI validates PR titles. |

The README contains historical paths and an older table count. The migration files, route registration and live schema inspection are authoritative for this audit. No evidence of an existing Next.js or Kotlin Multiplatform project was found at the baseline commit.
