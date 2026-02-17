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

- Add cancel-all mode to the `cancel` message (type 70): omit `offer_hash` to cancel all open orders and bets for the source address in a single transaction. Gated behind the `cancel_all_offers` protocol change. An anti-spam fee of 0.0002 XCP per cancelled offer is charged.

## Bugfixes

- `excludes_utxos` supports now `<txid>:<vout>` and `<txid>` alone
- Add missing `max_mint_per_address` parameter in `compose_fairminter()`
- Fix shutdown during rate limit backoff
- Fix missing `limit` parameter validation in API v2 (was not enforced unlike API v1)

## Codebase


## Performance & Memory

## API

## CLI

# Credits

- Ouziel Slama
- Adam Krellenstein
