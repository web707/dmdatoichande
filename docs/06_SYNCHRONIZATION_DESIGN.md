# Synchronization design

Status: proposed after Phase 1. The current service publishes transient PostgreSQL notifications and Flutter retains its 20-second reconciliation path.

Use an additive change-log table and a single transactional revision allocator row initially. A write transaction updates content, assigns a revision and inserts change records while holding the allocator lock until commit. This prevents a later visible revision from overtaking an earlier uncommitted write. A raw sequence would allocate before commit and can skip changes when a reader advances early. The allocator serializes catalog commits, so validate lock time and write throughput. Keep lock order consistent across multi-record writers.

Bootstrap must read content and the corresponding revision in a single repeatable-read transaction. Replay uses a bounded cursor range and authorization-filtered events with deletion markers. The response cursor must make progress over invisible changes without leaking private payloads. Define explicit retention and resynchronization, including transactions that overlap pruning. SSE wakes clients to reconcile. Apply events idempotently and save the cursor atomically with local cached content.

Introduce optimistic version checks on the versioned write routes. Keep legacy behavior until the migration reaches its compatibility gate. Every source of catalog writes must participate in the durable log before new clients depend on it. Tests cover concurrent writers, bootstrap races, restart after commit, duplicate events, lost notifications, account switching, retention and deletions.
