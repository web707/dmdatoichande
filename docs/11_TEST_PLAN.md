# Test plan

Run [TEST_ALL.ps1](../scripts/TEST_ALL.ps1) with the disposable database described in [the runbook](10_MIGRATION_RUNBOOK.md). The Phase 1 matrix covers Flutter regressions, the versioned contract and public read path, and Android and Web builds. Record command, runtime, input, output and artifact location. See [verification](16_FINAL_VERIFICATION.md) for executed results.

| Scenario | Required verification |
| --- | --- |
| TC01, TC02, TC03 | Web admin changes reach native foreground, offline replay catches up and restart after commit still allows recovery. Run against a restored database with both new clients. |
| TC04, TC06, TC07 | Reject stale admin writes, invalid requests and traveler writes, and verify the committed data. |
| TC05, TC11, TC12 | Use a prior mobile artifact while deploying Web separately, induce a Web outage and a Mobile crash, and prove backend integrity. |
| TC08, TC13, TC14, TC17 | Replay duplicates, expire a cursor, delete a record and overlap writes with bootstrap. Assert deterministic final state. |
| TC09, TC18 | Upgrade or import representative bookmarks. Switch accounts and verify removal of private cached data. |
| TC10 | Play both tours and bilingual audio, repeat scene changes and measure memory on a physical device. |
| TC15 | Delay or stop the API. Assert a recoverable error state, then restore it. |
| TC16 | Compare database IDs and visible summaries on both clients for Phase 1. Repeat with matching revisions and change delivery once synchronization exists. |
| TC19 | Inject a failing migration on a disposable restore and verify old API behavior and migration ledger. |
| TC20 | Rebuild from pinned dependencies and verify reproducible artifact configuration and independent release pipelines. |
