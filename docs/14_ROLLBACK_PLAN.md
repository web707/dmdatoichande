# Rollback plan

Phase 1 adds separate applications and a read endpoint. Its rollback consists of stopping those applications and restoring the previous Express artifact from `fe2627e7716ec271850f0f43e743fb9a242f2b60` if needed. Keep the legacy client available throughout migration. A source revert should target only the Phase 1 additions and backend mounts. Preserve local modifications and artifacts.

There is no Phase 1 schema change to reverse. Keep the verified backup for recovery rehearsal. Restoring an old snapshot to a live database would lose intervening writes and requires a separate recovery decision. Future migration rollback must state which versions can read both old and new schema shapes and how to preserve writes during a rollback window.
