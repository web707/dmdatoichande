# Target architecture

Next.js renders public travel content and will host Content Studio. Compose Multiplatform owns native navigation, presentation and lifecycle. Both use the versioned HTTP contract through the Express modular monolith. PostgreSQL remains the authority for content, authorization and synchronization.

| Decision | Trade-off and verification |
| --- | --- |
| Add independently built clients beside Flutter | Parallel installation requires additional storage during migration. Build and release each client separately and compare journeys before moving traffic. |
| Add versioned routers inside the current API | One deployment preserves transaction semantics and requires one connection pool. Monitor connection saturation and keep legacy routes under regression tests. |
| Use a bounded summary projection for lists and fetch detail by ID | History, location and visit information use a separate request on navigation. Payloads and all 18 detail fields were checked against the legacy source. |
| Render first Web content on the server and load interactive features per route | The Web process still needs API availability and an explicit caching policy. Measure browser requests, response age and server latency. |
| Load one native page with a shared HTTP client and lifecycle-owned state | Persistent offline availability requires a later storage decision and migrations. Measure on representative Android devices before defining budgets. |
| Reuse existing tour source and Pannellum assets | Viewer isolation and origin validation require platform-specific tests. Gate panorama decoding and audio loading on explicit navigation. |
| Use PostgreSQL for the future durable change log | A commit-ordered cursor needs locking and retention policy. Measure writer throughput before making a decision about external infrastructure. |

Phase 1 adds a destination summary list across the API, Web and Android project. The next read increment adds destination details. Redis, additional database engines, external media storage and separate workers need workload evidence before introduction.
