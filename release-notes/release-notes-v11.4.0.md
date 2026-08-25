# Release Notes - Counterparty Core v11.4.0 (TBD)

Counterparty Core v11.4.0 makes State DB rollbacks incremental (#3485).

Until now a Bitcoin reorganization — however shallow — rebuilt the entire State DB. On mainnet a **one-block reorg took ~33 minutes**, during the last ~6 of which the public API returned 5xx, despite the process having ample CPU and memory headroom. The cost had nothing to do with how deep the reorganization was: `rollback_state_db()` deleted the rows of three tables and then re-applied thirteen migrations, each of which dropped its table and repopulated it from the entire ledger history (`parsed_events` alone is a full copy of `messages`).

Rollbacks are now proportional to what the orphaned blocks actually changed. A one-block reorg reverts a handful of rows instead of tens of millions.

The rebuild that remains — at upgrade, and for the deep rollbacks a new release occasionally requires — is no longer silent. It now reports itself: the dedicated health listener starts **before** it, answers `200` on liveness and `503 rebuilding` on readiness throughout, and names the step under way.

# Upgrading

This release **requires a one-time State DB refresh**, applied automatically on first start (`refresh_state_db`). It takes roughly as long as one of the old reorg rebuilds and happens once, at a moment you control, rather than unpredictably at the next reorg. There is no ledger reparse and no protocol change.

**Point your Kubernetes probes at the dedicated health listener before upgrading** (port `4002` on mainnet — `/healthz/live` for liveness, `/healthz/ready` for readiness), if you have not already since v11.3.0. During the refresh the pod reports `200` on liveness and `503 rebuilding` on readiness, so it stays out of rotation and is not restarted. A liveness probe still pointed at the API port would get a connection refusal for the whole refresh and kill the pod, and the next start would begin the work again from zero.

To upgrade, download the latest version of `counterparty-core` and restart `counterparty-server`.

# Changelog

## Incremental State DB rollback (#3485)

`dbbuilder.rollback_state_db()` now reverts the State DB instead of re-deriving it (`counterpartycore/lib/api/staterollback.py`):

- **Append-only tables** (`parsed_events`, `address_events`, `all_expirations`, `pool_matches`) are pruned by `block_index`.
- **Consolidated tables** (`balances`, `orders`, `dispensers`, `fairminters`, the match tables, the AMM pool tables — one row per object holding its latest version) have the rows touched at or after the rollback point deleted and re-inserted from that object's latest Ledger DB version *strictly below* the rollback point. The block bound matters: when the API watcher reacts to a reorganization the Ledger DB has already rolled back and may have re-parsed part of the new chain, and restoring to the ledger's current tip would leave the State DB ahead of `parsed_events` and cause the forward replay to apply those blocks twice.
- **Counters** are adjusted rather than recomputed from scratch: `events_count` is decremented by the orphaned events, and `transaction_types_count` / `assets_info` / the `fairminters` aggregates are re-derived only when the orphaned blocks actually contained the relevant events.
- Views and indexes are no longer dropped and rebuilt, because the tables they cover are no longer dropped and rebuilt.

A single `logger.info` line now reports what a reorganization cost — how many events and objects were reverted, per table. Previously the 33 minutes were entirely silent at INFO level.

**Fallbacks.** The full rebuild is still used, and is still correct, for a rollback deeper than 1,000 blocks, for the `UPGRADE_ACTIONS` rollbacks (where the derivation rules themselves may have changed between releases), and for a State DB that predates this release. That last check is self-healing: such a State DB takes the full path once, which marks it eligible for the incremental path afterwards.

**Verification.** The incremental path is covered by differential tests that roll a fixture back to six different points — from a single active block up to essentially its whole history — and assert, table by table, that the result is identical to a from-scratch rebuild against the same rolled-back ledger, and that a rollback followed by the watcher's forward replay reproduces the State DB exactly. Every optional pass in the rollback (the counters, the `assets_info` re-derivation, the `fairminters` aggregates, the block bound on the ledger lookups) was checked by mutation: removing it makes those tests fail.

## A rebuild that reports itself (#3485)

Every remaining State DB build, refresh or full rollback now publishes its progress (`counterpartycore/lib/api/dbstatus.py`), and two consumers read it:

- **The health listener starts first.** It used to be created after the migration/rebuild block, so for the tens of minutes that block runs there was no socket to probe at all — liveness got a connection refusal, Kubernetes killed the pod mid-rebuild, and the restart began again from zero. It is now started before that block (the WSGI task dispatcher is attached later, once the worker pool exists; until then the pool gauges simply read as unavailable).
- **`rebuilding` is a distinct readiness state.** `/healthz/ready` returns `503` with `reason: "rebuilding"` and a `rebuild` object naming the operation, the current step and the elapsed time; `/healthz/metrics` carries the same. It takes precedence over the lag signal, which reads from tables that are being dropped and repopulated and would otherwise report a misleading `behind_backend`. Liveness stays `200` throughout — the process is healthy and working.
- **Each migration is logged at INFO, with its duration.** Previously the whole rebuild logged nothing above DEBUG, which is why the 33 minutes in the incident report were indistinguishable from a hang.

The health sampler also reopens its own State DB connection after a rebuild: `build_state_db()` unlinks and recreates the file, so a connection held across it would have reported a frozen block height for the rest of the process's life.

**On serving from a second State DB while one is rebuilt** (suggestion 2 in the issue): not implemented, and we think it should not be. Once rollbacks are incremental, a full rebuild only happens at startup, before any listener exists — there are no readers to keep serving. The atomic-swap machinery (a second file, connection-pool epoch invalidation, a swap under live readers) would carry real risk for a case that no longer arises, whereas a correct `rebuilding` readiness state removes the pod from rotation and explains why, which is what suggestion 3 was really after.

## State DB / Ledger DB consistency fixes

The differential tests above surfaced three ways in which a State DB maintained by the event stream drifted from one built from scratch. All three are fixed in `apiwatcher.update_balances()`, and the one-time refresh normalizes existing rows:

- `balances.block_index` and `balances.tx_index` were never written by the event stream, so every balance changed since the last full build carried a stale (or `NULL`) value. This is also what the incremental rollback uses to find which balances an orphaned block touched.
- `balances.asset_longname` was `NULL` for every balance row first created by the event stream, while the same row on a freshly built node carried the real longname.
- A zero-quantity `CREDIT`/`DEBIT` was skipped entirely, where the parser still appends a `balances` row for it (bumping that row's block and transaction index). An existing balance row is now always updated, whatever the quantity, and a zero-quantity debit against a non-existent balance still writes nothing — matching `ledger.events.remove_from_balance()`.

## Refactoring

- The rules for projecting a Ledger DB row into its State DB counterpart — decoding the compact `asset_index` / `address_id` / `(utxo_tx_hash, utxo_vout)` representations — now live in one place, `counterpartycore/lib/api/statetables.py`, shared by the build path (migrations `0004`, `0006`, `0014`) and the rollback path. Two independent copies of these rules would drift, and drift here is a silent divergence no API response would reveal.
- New State DB migration `0016` adds the missing `block_index` indexes on `addresses`, `rps` and `rps_matches`.
