# Release Notes - Counterparty Core v11.1.0 (2026-02-??)

This release is focused on hardening the consensus-critical parser, the indexer and the API layers against a series of halt vectors and edge cases identified through fuzzing and audit, as well as fixing several State DB / API migration inaccuracies.

# Upgrading

**Upgrade Instructions:**

To upgrade, download the latest version of `counterparty-core` and restart `counterparty-server`.

With Docker Compose:

```bash
cd counterparty-core
git pull
docker compose stop counterparty-core
docker compose --profile mainnet up -d
```

or use `ctrl-c` to interrupt the server:

```bash
cd counterparty-core
git pull
cd counterparty-rs
pip install -e .
cd ../counterparty-core
pip install -e .
counterparty-server start
```

The State DB is automatically rebuilt on first start of v11.1.0 (migration 0004 fix).

# ChangeLog

## Consensus / Halt vectors (gated)

- Catch `struct.error` in `issuance.unpack` to prevent consensus halt
- Catch `NoPriceError` in `dispense.parse` to prevent consensus halt
- Harden `issuance` and `broadcast` parse against CBOR-crafted halt vectors
- Fix two hand-rolled-tx halt vectors found by fuzzing
- Fix two asset-name halt vectors found by name-generation audit
- Reject non-canonical compacted subasset longname behind a new gate
- Reject non-positive oracle prices in `dispense.get_must_give`
- Reject `btcpay` where tx destination doesn't match order match counterparty
- Fix bet match sort no-op behind new `fix_sort_bet_matches` gate
- Fix Python truthiness bug in `attach` OP_RETURN check (gated)
- Set `transactions_status` and persist invalid record in `sweep.parse`
- Forward `tx["block_index"]` into gated `unpack()` and `protocol.enabled()` calls; hoist fairminter fee to `int` and forward `block_index` to issuance fee gates
- Extend MIME type support for ordinal-style inscriptions behind a new `extended_mime_types_support` gate: tolerate MIME parameters (e.g. `audio/ogg;codecs=opus`), recognise the `+json` structured suffix as textual, and validate against a deterministic hard-coded allow-list (`EXTENDED_MIME_TYPES_VALID`) instead of `mimetypes.types_map`, which read `/etc/mime.types` / the Windows registry and varied per node
- Allow CBOR map under tag `0x05` for ordinals-style provenance metadata in taproot inscriptions, behind a new `ordinals_metadata_support` gate. The Counterparty message is extracted from the `"xcp"` array key; other keys are ordinals metadata ignored by the consensus parser.
- Add support for indefinite DEX orders and fix `expiration` semantics behind a new `indefinite_orders` gate: `expiration=0` now means indefinite (open until filled or cancelled, `expire_index = NULL`), `expiration=N` now means exactly N blocks of life (was N+1 due to a long-standing off-by-one), and `MAX_EXPIRATION` is raised from 8064 (~56 days) to 65535 (the wire-format u16 max, ~455 days). The wire format is unchanged.

## Bugfixes

- `excludes_utxos` supports now `<txid>:<vout>` and `<txid>` alone
- Add missing `max_mint_per_address` parameter in `compose_fairminter()`
- Fix shutdown during rate limit backoff
- Fix missing `limit` parameter validation in API v2 (was not enforced unlike API v1)
- Fix `MalformedPointError` when searching for pubkey in P2WSH multisig witness data
- Fix Rust `BATCH_CLIENT` permanently caching failed parent transaction lookups, which could cause valid Counterparty transactions to be silently skipped
- Add warning log when a parent transaction cannot be found during VIN resolution
- Fix `KeyboardInterrupt` raised in the main thread during shutdown that could break the shutdown sequence half-way through (e.g. while joining the Asset Conservation Checker thread on SIGTERM)
- Fix four `u32` underflow patterns in the Rust indexer
- Fix off-by-one and short-prefix panics in `parse_vout`
- Replace `expect()` in `get_funding_block_entries` with a typed `Error`
- Catch malformed `protocol_changes.json` shape in `software_version()`
- Scope `Decimal` context changes to `localcontext` so precision doesn't leak
- Update `BackendHeight.last_check` in a `finally` so RPC failures don't spam
- Don't let halt-class mempool transactions tear down the `BlockchainWatcher`; harden it against transient operational failures
- Reorg + mempool hygiene: stale events, leak, horizon, reparse cache
- Fix stale `mempool/events` after RPC catch-up paths (`receive_rawblock` previous-block-missing branch and `handle()` ZMQ-late branch): both now sweep the mempool table after `catch_up()`, matching the streamed `receive_rawblock` path
- Clear bitcoind transaction cache on rollback to avoid stale deserialisation; encapsulate in `reset_caches()` helper
- Clean orphaned `transactions_status` rows on rollback and rebuild
- Close ZMQ sockets/context before reconnect; fix `RCVTIMEO` typo
- Make `--api-only` loop honor `api_stop_event` for clean shutdown
- Make `UTXOLocks` intra-worker thread-safe
- Concurrency: `SingletonMeta` double-checked locking; guard `reset_caches` `lru_cache.cache_clear()` with `hasattr`
- Fix `DETACH_FROM_UTXO` source field typo in `EVENTS_ADDRESS_FIELDS`
- Fix `LEFT JOIN` in API migration 0004 supplies query
- Sync `description_locked` and filter `xcp_supply` by status in `apiwatcher`
- Fix `assets_info` State DB population (migration 0004) so that `description`, `divisible`, `mime_type` and `owner` are derived from the latest valid issuance (matching the streamed `apiwatcher` semantics) instead of an implementation-defined row picked by SQLite from the aggregated set, and so that `locked` / `description_locked` are stored as 0/1 booleans (`MAX(...)`) rather than as `SUM(...)` integer counts. Snapshot-bootstrapped nodes will now agree with event-streamed nodes for these columns. The State DB is automatically rebuilt on first start of v11.1.0.

## API

- Block APIv1 SQL injection via `filter_["field"]`; redact secrets in logs

## Codebase

- Add fuzz tests
- Add 10 regression tests for the audit fixes
- Document `expand_subasset_longname` 200-byte cap reasoning
- Document libm cross-platform threshold near `gas.py` sigmoid

## Features

- Support multiple Electrs backends with automatic failover on connection, timeout, or HTTP errors; `--electrs-url` can now be specified multiple times
- Default mainnet Electrs backends to both `blockstream.info` and `mempool.space`
- Print a startup warning when using default Electrs URLs (not recommended for production)

# Credits

- Ouziel Slama
- Adam Krellenstein
- Dan Anderson
