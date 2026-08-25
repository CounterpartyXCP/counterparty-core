# Release Notes - Counterparty Core v11.3.1

## Operations

- Interrupt shutdown-blocking SQLite reads in the API watcher and node-status
  checker, remove unbounded shutdown waits, and keep all component cleanup
  inside the API child's existing ten-second forced-kill fallback.
- Add phase-level migration startup timings, pending-migration counts, and WAL
  sizes so operators can distinguish database open/recovery time from migration
  discovery, application, and connection close time.
- Reverse-scan the existing `parsed_events.event_index` index to find the
  latest `BLOCK_PARSED` event during API watcher initialization. This preserves
  the prior event-order semantics while avoiding a cold full-result sort that
  added minutes to mainnet API startup.
- Rebuild a replacement State DB alongside the still-serving live database
  after a reorganization, using a temporary online backup of the Ledger DB so
  long-running migrations read a stable snapshot. Verify and checkpoint the
  result against a durable lineage, migration, and builder-commit manifest,
  then restart only the API child to activate it with ordered directory-fsync
  barriers. A parent-owned rebuild gate survives crashes and activation
  restarts and clears only after the replacement catches up. Readiness remains
  routable-but-degraded while pre-reorg cache hits serve eligible public GETs;
  cache misses and all
  compose, mempool, fee, authenticated, POST, and other `no-store` requests
  fail closed until fresh state is active. A restarted cache-cold child, a
  disabled cache, and an authenticated-only API report unready rather than
  overstating availability. One previous State DB is retained for recovery
  and reclaimed only when a subsequent rebuild needs its space. Rebuild backup,
  migration, verification, and vacuum work is cancellable on shutdown; partial
  files and journals are removed. An interrupted, stale, or failed build is
  never activated and falls back to a complete in-place rollback, including
  rebuilding address-event history. A rebuild deadline cancels hung work and
  critical watcher failure triggers an automatic API-child restart.
  Reorg detection and matching-block searches preserve exact event ordering
  through the existing event-index scan so cold State DBs do not sort every
  `BLOCK_PARSED` event first.
