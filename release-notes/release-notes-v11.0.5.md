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

## Codebase


## Performance & Memory

## API

## CLI

# Credits

- Ouziel Slama
- Adam Krellenstein
