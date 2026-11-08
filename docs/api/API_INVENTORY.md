# API inventory

Source of legacy behavior: [app.ts](../../backend/src/app.ts), [validation.ts](../../backend/src/validation.ts) and [vr360.ts](../../backend/src/vr360.ts).

| Endpoint | Access and shape |
| --- | --- |
| `GET /api/health` | Public, checks PostgreSQL and returns status and database. |
| `GET /api/live`, `GET /api/ready` | Additive liveness and PostgreSQL-backed readiness probes. Responses have request IDs and are not cached. |
| `POST /api/auth/register`, `/login` | Public, rate-limited, accepts email and password. Returns bearer token and user. Register assigns traveler. |
| `GET /api/auth/me`, `POST /api/auth/logout` | Valid bearer required. User or HTTP 204; logout revokes the session. |
| `GET /api/{places,foods_restaurants,phrases,events}` | Full arrays with snake_case fields. Phrases combine shared rows with the caller's own rows. Events defaults to JSON. |
| `POST /api/{collection}`, `PUT /api/{collection}/{id}`, `DELETE /api/{collection}/{id}` | Admin writes places, foods, events and shared phrases. Traveler writes only their own phrases. Strict request fields and UUIDs, transactional writes, row lock on existing rows. |
| `GET /api/emergency` | Public read-only array, sorted by `sort_order,category,id`. |
| `GET /api/events` with `Accept: text/event-stream` | Public table-change signals, readiness, reconnect and heartbeat. No replay. Preserve content negotiation with JSON events. |
| `GET /vr360/hoan-kiem/*` | Public viewer, manifest and asset delivery. Viewer and local assets have distinct CSP and cache treatment. |
| `GET /api/v1/destinations` | Additive public summary list, bounded cursor pagination and optional search. See [OpenAPI](../../hanoi-guide-contracts/openapi/destinations-v1.json). |
| `GET /api/v1/destinations/{id}` | Additive public detail by UUID, with original destination history, location and visit fields. |

Legacy failures return `{ "error": "…" }`. Existing route names, permissions, field casing, shapes and media URLs remain the compatibility baseline. PostgreSQL `numeric` fields can appear as strings in legacy JSON.
