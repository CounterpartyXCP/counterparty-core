# Release Notes - Counterparty Core v11.0.5 (2026-02-??)


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

# ChangeLog

## Features

## Bugfixes

- `excludes_utxos` supports now `<txid>:<vout>` and `<txid>` alone
- Add missing `max_mint_per_address` parameter in `compose_fairminter()`
- Fix shutdown during rate limit backoff
- Fix missing `limit` parameter validation in API v2 (was not enforced unlike API v1)
- Fix `MalformedPointError` when searching for pubkey in P2WSH multisig witness data
- Fix Rust `BATCH_CLIENT` permanently caching failed parent transaction lookups, which could cause valid Counterparty transactions to be silently skipped
- Add warning log when a parent transaction cannot be found during VIN resolution
- Fix `KeyboardInterrupt` raised in the main thread during shutdown that could break the shutdown sequence half-way through (e.g. while joining the Asset Conservation Checker thread on SIGTERM)
- Fix `assets_info` State DB population (migration 0004) so that `description`, `divisible`, `mime_type` and `owner` are derived from the latest valid issuance (matching the streamed `apiwatcher` semantics) instead of an implementation-defined row picked by SQLite from the aggregated set, and so that `locked` / `description_locked` are stored as 0/1 booleans (`MAX(...)`) rather than as `SUM(...)` integer counts. Snapshot-bootstrapped nodes will now agree with event-streamed nodes for these columns. The State DB is automatically rebuilt on first start of v11.0.5.

## Codebase


## Performance & Memory

## API

## CLI

# Credits

- Ouziel Slama
- Adam Krellenstein
