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
- Resolve the credits, debits, and sends address-history OR branches through
  their existing indexes before ordering the deduplicated row set. This avoids
  reverse-scanning millions of unrelated rows for addresses with old or short
  histories. These routes bound offset pagination, reject arbitrary sorting,
  normalize repeated send-type filters, and compute the exact result count only
  on the initial/offset page so later cursor pages remain bounded.
