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
- Raise `ValueError` instead of `PanicException` when an error occurs in Rust deserialization
- Return 400 error on TypeError when composing a transaction
- Fix `bitcoind.search_pubkey_in_transactions()`
- Don't force output change
- Fix heavy healthz check
- Fix search pubkey for never spent segwit address
- Fix shutdown with Gunicorn
- Same log file for all Gunicorn processes
- Fix double log in access file on API query
- Don't call `getblockcount` from each API thread or process
- Reset all caches on rolloback and reparse
- Fix RSFetcher restart on failure
- Fix `extended_tx_info` param in API v1

## Codebase

- Complete rewrite of the test suite. See comments in `test/mocks/conftest.py`
- Change default value for `attach` and `move` to 546
- Add support for Python 3.12 and 3.13
- Rename everywhere `testnet` to `testnet3`
- Add `testnet4` and `regtest` profile in `docker-compose.yaml`
- Restore Docker Composer, Compare Hashes and Tesnet4 Reparse tests
- Refactor how required actions are triggered on upgrade
- Complete rewrite of the Github workflows files

## API

- Add `block_index` filter for get order matches endpoints
- Add `block_index` filter for get dispenses by asset endpoint
- Add Get Dispense By Hash endpoint

## CLI

- rename `--testnet` flag to `--testnet3`
- Add Testnet4 bootstrap database
- Add `--api-only` flag

# Credits

- Ouziel Slama
- Adam Krellenstein
