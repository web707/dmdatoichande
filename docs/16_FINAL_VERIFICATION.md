# Verification record

This record tracks the incremental migration. The original Flutter and legacy API remain the production-equivalence reference until all gates pass. Source baseline: `fe2627e7716ec271850f0f43e743fb9a242f2b60`.

## Phases 0–2 and destination read increment

| Check | Environment | Result |
| --- | --- | --- |
| `flutter analyze --no-pub` and `flutter test --no-pub --reporter expanded` | Flutter 3.47.3 on Windows 11 | PASS, no analysis issues and 23 tests |
| Read-only schema and count audit | PostgreSQL 18.1 on loopback | PASS, 8 tables and 4 migrations |
| `pg_dump` and `pg_restore` | Separate database on the local cluster | PASS, all 8 row counts and fingerprints matched before and after isolated write tests |
| Contract generation, TypeScript build and backend tests | Node 24 and disposable PostgreSQL restore | PASS, 45 tests including pagination, accent folding, permissions, details, conditional reads, and shutdown |
| Actual source comparison | Original PostgreSQL read only | PASS, five list records and 18 detail fields per record match the legacy API |
| `npm audit --omit=dev` | Backend and Web lockfiles | PASS, zero reported production dependency advisories on 2026-11-08 |
| Browser fixture and live database integration | Playwright Chromium against Next.js production build | PASS, 11 fixture and 2 real API cases, covering list, details, loading, retry, timeout and HTTP 404 |
| Android host tests, debug, lint and release assembly | Windows, JDK 17, SDK 36, Gradle 9.3.1 | PASS, 8 host tests rerun, 0 lint errors and 19 warnings. Debug APK 12,273,241 bytes. R8 release APK 1,339,469 bytes, unsigned and configured with a build-only HTTPS origin |
| Android device list, search, detail and navigation | Android API 34 x86_64 emulator, actual PostgreSQL API on port 8090 | PASS, initial list matched five records, and the final APK found `Hoa Lo Prison`, opened its address section, and restored the same query and result on system Back |
| Request telemetry and health checks | Mock pool, isolated integration tests and original database read only | PASS, redaction, coalesced probes, stable legacy health shape and live request IDs |
| Graceful termination | Throwaway process, real PostgreSQL read only | PASS, reconnecting SSE frame and EOF, repeat shutdown requests and DB connection count 2 to 0. OS signal delivery on Windows was NOT TESTED |
| Hosted CI execution | GitHub Actions | NOT TESTED, workflow authored and YAML parsed locally |

## Acceptance gates

| Gate | Status and evidence |
| --- | --- |
| Next.js and Compose Multiplatform implementations | PASS for destination list, detail and shared API integration. |
| Independent source, UI and build | PASS for both Phase 1 projects and vendored contract models. |
| Existing Express API and PostgreSQL integrity | PASS on focused regression, restored database and live read-only comparisons. |
| Existing users and authentication | PASS for legacy backend auth tests. New client authentication NOT TESTED. |
| Existing destinations and content | PASS for destination list and API detail data. Additional content modules NOT TESTED in new clients. |
| Maps on both platforms | NOT TESTED. |
| Phrasebook and TTS | NOT TESTED on new clients and supported devices. |
| VR360 and audio | PASS for existing fixture and widget tests. New client viewer and device audio NOT TESTED. |
| Bookmarks | PASS for legacy local persistence. Migration and shared account rules NOT TESTED. |
| Content Studio parity | NOT TESTED for new Web. |
| Admin changes reach Web and Mobile | NOT TESTED on new clients. |
| Offline/reconnect synchronization | NOT TESTED on new clients. |
| Concurrent update conflicts | NOT TESTED. |
| API compatibility | PASS for the exercised legacy routes. Full release-to-release mobile compatibility NOT TESTED. |
| Critical backend tests | PASS for Phase 1 scope. Durable change replay and conflict testing remain open. |
| Critical Web tests | PASS for list and detail. Complete feature and admin journeys NOT TESTED. |
| Critical Android tests | PASS for shared list and detail handling, debug build, and real API list/search/detail/system Back on Android emulator. Remaining device journeys NOT TESTED. |
| Android release | PASS for local unsigned assembly. Production signing, installation and HTTPS service verification NOT TESTED. |
| iOS readiness | Documented target and platform source sets. Build and execution NOT TESTED on Windows. |
| Backup and restore | PASS, local database copy verified. |
| Security checks | PASS for scoped API authorization and input checks. Full production security review NOT TESTED. |
| Performance comparison | PASS for scoped transport and payload measurements. Production load, browser vitals and Android frame pacing NOT TESTED. |
| Deployment and rollback procedures | Documented for incremental rollout. Production rollout and recovery rehearsal NOT TESTED. |

See the [test plan](11_TEST_PLAN.md), [performance report](12_PERFORMANCE_REPORT.md), [risk register](migration/RISK_REGISTER.md) and [rollback plan](14_ROLLBACK_PLAN.md).
