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
- Reject issuance and fairminter composition with HTTP 409 when Counterparty's
  parsed mempool already contains a conflicting asset creation, ownership or
  lock/reset change, or active fairminter for the same asset. Compatible valid
  reissuances remain composable unless their cumulative pending quantity can
  overflow the maximum supply. Confirmed and parsed-mempool state are checked
  again after atomically reserving the selected UTXOs (or before returning
  message-only data); failed validation releases that reservation, and any
  refreshed message bytes are used for the returned transaction.
  `validate=false` remains the explicit advanced-user override.
