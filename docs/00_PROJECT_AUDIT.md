# Hanoi Guide project audit

The migration started from clean `main` at `fe2627e7716ec271850f0f43e743fb9a242f2b60`. This is the recovery reference for the original Flutter app and Express API. The baseline API was also started from that commit on port 8092 to compare reads against the same local PostgreSQL database.

| Area | Evidence |
| --- | --- |
| Application and platform boundaries | [Current architecture](architecture/CURRENT_ARCHITECTURE.md) |
| Legacy features and coverage | [Feature parity matrix](migration/FEATURE_PARITY_MATRIX.md) |
| Runtime, dependencies and risks | [Risk register](migration/RISK_REGISTER.md) |
| HTTP and data compatibility | [API inventory](api/API_INVENTORY.md), [database audit](architecture/DATABASE_SCHEMA_AUDIT.md) |
| Packaged and locally served media | [Asset inventory](architecture/ASSET_INVENTORY.md) |
| Cutover gates | [Migration plan](migration/MIGRATION_PLAN.md), [verification record](16_FINAL_VERIFICATION.md) |

Phase 0 verified Flutter 3.47.3 with `flutter analyze --no-pub` and `flutter test --no-pub --reporter expanded` (23 passing). PostgreSQL 18.1 returned five destinations, six food rows, twelve phrases, six events and fifteen emergency contacts. The backup was restored to a separate database and the row counts and fingerprints of all eight tables matched before write tests.
