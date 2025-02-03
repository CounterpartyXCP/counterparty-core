# Release Notes - Counterparty Core v10.10.0 (2025-01-??)


# Upgrading

Download the latest version of `counterparty-core` and restart `counterparty-server`.

With Docker Compose:

```bash
cd counterparty-core
git pull
docker compose stop counterparty-core
docker compose --profile mainnet up -d
```

or `ctrl-c` to interrupt the server

```bash
cd counterparty-core
git pull
cd counterparty-rs
pip install -e .
cd ../counterpaty-core
pip install -e .
counterparty-server start
```

# ChangeLog

## Protocol Changes

## Bugfixes

- Don't retry RPC calls in `safe_get_utxo_address()`
- Fix error handling in `safe_rpc()`

## Codebase

- Complete rewrite of the test suite. See comments in `test/mocks/conftest.py`.

## API

- Add `block_index` filter for get order matches endpoints
- Add `block_index` filter for get dispenses by asset endpoint

## CLI


# Credits

- Ouziel Slama
- Adam Krellenstein
