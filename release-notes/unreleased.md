# Unreleased

## Consensus Determinism

- Rebuild the UTXO balances cache by replaying the recorded `utxos_info` of
  every parsed transaction, instead of loading the `balances` table plus special
  cases (`KNOWN_SOURCES` descendants and invalid attaches). While parsing, the
  first non-OP_RETURN output of every `attach`, and of every transaction
  spending a cached UTXO, is added to the cache even when no asset reaches that
  output, and a later spend of such a "phantom" UTXO is recorded as a `utxomove`
  transaction that moves nothing. A node that restarted, rolled back or handled
  a reorg in the middle of such a chain rebuilt the cache without the phantom
  entry and silently stopped recording the chain, so its `txlist_hash` and
  `messages_hash` diverged from nodes that kept running. On mainnet, the valid
  `attach` `86a3d0a5…085482` at block 973,405 attached to its third output while
  its first output entered the cache; its first output was spent at block
  973,417 and started a chain of ten `utxomove` transactions, seven of which are
  missing on nodes that restarted after block 973,422. The cache rebuild is now
  a deterministic function of the Ledger DB, and an automatic rollback to block
  973,417 (`UPGRADE_ACTIONS` for v11.6.0, mainnet only) re-parses the chain so
  that every node converges on the freshly synced history. The State DB is
  rebuilt as part of this rollback. No protocol rule changes and no balance is
  affected.

## Protocol

- Record XCP destruction when a nonzero pool deposit, pool withdrawal, or
  fairminter pool-creation fee is charged (`fix_pool_fee_destruction`). This
  keeps XCP supply and asset conservation consistent with the debited balances,
  including the API's supply projection. Trading fees retained in pool reserves
  are unaffected. No such fee has been charged on mainnet, testnet4 or signet,
  so no historical block is affected.

## Upgrade compatibility

- Refresh published minimum-version requirements in a background thread every
  five minutes, including API-only mode. The watcher no longer relies on a
  once-at-startup call to an otherwise unused daily timer.
- Expose cached protocol compatibility in the API root, response headers and
  health readiness. Before activation, report a pending upgrade without blocking
  service. At a known unsupported activation height, stop parsing before writing
  the block and return `503 protocol_upgrade_required` for ordinary API requests;
  diagnostic endpoints remain available and liveness stays separate.
- Retain known upgrade requirements during metadata outages and report stale or
  unknown verification explicitly. `--force` remains an explicit, advertised
  unsafe bypass. No protocol rules, activation heights or ledger formats change.
- Verify upgrade metadata at startup before any `UPGRADE_ACTIONS` reparse, so
  reparsed blocks are checked against the published requirements.

## API

- Return MPMA decoding failures, including malformed address tables and
  recipient indexes past the end of the table, through the existing
  `message_data.error` response (HTTP 200) of `/v2/transactions/unpack` and
  `/v2/transactions/info`, rather than a generic HTTP 503 and unexpected-error
  reports. Verbose `unpacked_data` reports the specific error instead of the
  generic "Could not unpack data". Historical data still requires its original
  `block_index`; omitting it uses the current height's protocol rules. This does
  not change consensus decoding or accept legacy messages under current rules.

## Mempool

- Compact the unsupported-transaction cache to 900,000 entries at its
  1,000,000-entry limit, including when restoring a full cache. New hashes
  append between compactions instead of triggering a full-file rewrite on
  every mempool batch. Snapshots are written to a temporary file and atomically
  replaced, preserving the previous file if writing or replacement fails.
  The cache format and transaction validation rules are unchanged.

## Codebase

- Bump `quinn-proto` to 0.11.19 and `rustls` to 0.23.46 in `counterparty-client`
  (RUSTSEC-2026-0338 to -0342, RUSTSEC-2026-0346 to -0349), and triage the
  unmaintained `unsafe-libyaml` and standalone `zbus` crates in the audit
  configuration.
- Bump `pyo3` to 0.29.3 (RUSTSEC-2026-0176, RUSTSEC-2026-0177), `rustls` to
  0.23.46 and `rustls-webpki` to 0.103.16 (RUSTSEC-2026-0049, -0098, -0099,
  -0104, -0285, -0346, -0348, -0349) in `counterparty-rs`.
- Bump `Werkzeug` to 3.1.9 (GHSA-g6x2-hccm-hh4m). The advisory only affects
  nodes running on Windows.
- Bump `rustls-webpki` to 0.103.16 (RUSTSEC-2026-0382) and `webpki-root-certs`
  to 1.0.10 (RUSTSEC-2026-0383) in `counterparty-client`.

## Bootstrap

- Download signed bootstrap snapshots from `https://bootstrap.counterparty.io`
  so the storage backend can be migrated without another client URL change.
  Snapshot filenames, selected snapshot version, and signature verification
  are unchanged.
