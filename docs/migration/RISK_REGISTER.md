# Risk register

| Risk and evidence | Impact | Control and exit gate |
| --- | --- | --- |
| Legacy catalog refresh loads four whole responses every 20 seconds and after notifications. | Bandwidth, repeated SQL and avoidable render work. | Baseline requests, then bounded reads and targeted invalidation. Retire fallback only after restart and offline/reconnect tests. |
| `NOTIFY` is transient and SSE has no revision identifier. | Offline clients can miss intermediate changes. | Transactional log, deterministic cursor order, reconciliation and stale-cursor test. |
| Admin update locks the row and then applies the latest write without a precondition. | Silent lost edits. | Versioned conditional writes and a test with two concurrent editors. |
| Browser and native releases have different origins and security models. | Auth leaks or denied legitimate requests after rollout. | Keep bearer compatibility and test HttpOnly cookie, CSRF, CORS and secure storage on new clients. |
| Android package IDs, signing and preference serialization determine upgrade access. | Existing bookmarks stranded after cutover. | Co-install during development, preserve legacy installation, test migration before replacing it. |
| Pannellum media depends on ignored local data; bundled panoramas are significant. | Missing tours or high peak memory. | Validate asset manifest and availability at deployment, test scene transitions on a representative device. |
| Snapshot database is small. | Local latency can hide scan, concurrency and pool problems. | Collect query plans and load tests against a disposable dataset before choosing indexes or budgets. |
| Critical browser and device journeys exceed Phase 1 coverage. | Functional regression if traffic moves prematurely. | Keep parallel clients and gate cutover on [parity](FEATURE_PARITY_MATRIX.md) and [verification](../16_FINAL_VERIFICATION.md). |
