# Incremental migration plan

1. Record the baseline and inventory. Audit live PostgreSQL read-only. Restore and verify an isolated copy before running any tests that write.
2. Introduce the additive destination summary contract. Build the independent SSR list and native list. Verify real PostgreSQL reads, ordering, pagination, timeout/retry, and equivalent visible IDs and content.
3. Add backend operational controls in compatible changes. Prove existing client behavior, health checks, request budgets, safe session handling, proxy trust and graceful shutdown.
4. Add durable synchronization to a disposable restore. Prove atomic changes and cursor ordering under concurrent commits. Integrate bounded replay and conflict tests before clients rely on it.
5. Port destination detail/maps, food, phrases, bookmarks, events, emergency, VR360, accounts and tools by feature. Expand the Web Content Studio after auth and versioned writes are validated.
6. Rehearse data, media, preference and signing migrations. Benchmark equivalent release builds and device classes, complete critical scenario tests, and document independently deployable artifacts.
7. Request cutover approval only after production readiness gates. Keep the compatible API and legacy clients available during the rollback window.

Phase 1 focuses on a real read path. Text and photo summaries have a bounded response. Existing clients keep their current request routes and full fields. An official switch requires [the acceptance evidence](../16_FINAL_VERIFICATION.md).
