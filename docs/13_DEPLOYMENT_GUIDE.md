# Deployment guide

Phase 1 runs as three separately built processes or artifacts. Express and PostgreSQL form the shared backend. Existing Flutter deployments can stay online during migration.

| Component | Local command | Release preparation |
| --- | --- | --- |
| Express | `scripts/SETUP_BACKEND.ps1`, then `scripts/START_BACKEND.ps1` | Validate the production build, environment, HTTPS proxy, readiness and connection budget. Keep database access limited to the backend. |
| Next.js | `scripts/SETUP_WEB.ps1`, then `scripts/START_WEB.ps1` | Run the Web build and start with `-Production -ApiUrl <origin>`. Set API reachability, HTTPS and error monitoring independently. |
| Android | `scripts/SETUP_MOBILE.ps1`, then `scripts/BUILD_ANDROID.ps1` | Provide `-Release -ApiUrl <https-origin>`. Sign with the release workflow's private key and run a startup smoke test against the release endpoint. |
| iOS | Shared source sets are prepared. | Build and verify separately on macOS/Xcode. |

Do not expose `backend/.env`, local media source archives, database dumps, test traces or Android keystores. Existing local development ports are 8090 for Express and 55432 for PostgreSQL. New and legacy Web can run in parallel on ports 8081 and 8080.

[GitHub checks](../.github/workflows/modernization.yml) define independent backend, Web and Android jobs. The backend job provisions an ephemeral PostgreSQL 18 service. Web tests use an HTTP fixture, and Android tests use the vendored model and the Gradle wrapper. Production publishing and signing are separate release gates.

Use `/api/live` for process liveness and `/api/ready` for a PostgreSQL-backed readiness check. Concurrent readiness and legacy health requests share the in-flight database probe. Routine successful API requests are omitted from structured logs by default. Set `API_LOG_REQUESTS=1` for troubleshooting and correlate responses using `X-Request-Id`.

On termination the backend stops accepting connections, sends the existing reconnecting signal to active SSE clients and closes their streams. HTTP handlers have up to 15 seconds to drain. LISTEN and pool resources close before process exit, with a 20-second process deadline for a stuck resource. Repeated termination signals share the first shutdown.
