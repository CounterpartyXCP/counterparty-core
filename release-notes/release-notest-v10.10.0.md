# Release Notes - Counterparty Core v10.10.0 (2025-02-13)

This release includes a complete rewrite of the entire test harness for Counterparty Core, as well as both restored and all-new integration tests and GitHub workflows for continuous integration. This release also adds support for Python 3.12 and 3.13, which means significantly improved performance overall. There are of course a number of bugfixes, especially for node stability when Bitcoin Core is overloaded.


# Upgrading

This upgrade does not include a protocol change and is not mandatory. User-facing changes to the API include a decrease in the default output value for `attach` and `move` transactions to 546 satoshis and renaming the `--testnet` flag to `--testnet3`.


**IMPORTANT**
- If you are running a version lower than 10.9.0, you must first update to 10.9.0 and only then install v10.10.0.

Download the latest version of `counterparty-core` and restart `counterparty-server`.

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
- Return `400` error on `TypeError` when composing a transaction
- Fix `bitcoind.search_pubkey_in_transactions()`
- Don't force the existence of a change output
- Fix heavy HealthZ check
- Fix search pubkey for SegWit addresses that have never been used
- Fix Gunicorn shutdown
- Use the same logfile for all Gunicorn processes
- Fix duplicate log entries in the API Access file
- Don't call `getblockcount` from each API thread or process
- Reset all caches on rollback and reparse
- Fix RSFetcher restart on failure
- Fix the `extended_tx_info` param in API v1
- Correctly handle RPC responses with simple strings

## Codebase

- Completely rewrite the test suite. See comments in `test/mocks/conftest.py`.
- Completely rewrite the GitHub Workflow files
- Add support for Python 3.12 and 3.13
- Rename `testnet` to `testnet3` everywhere
- Add `testnet4` and `regtest` profiles to `docker-compose.yaml`
- Restore Docker Compose, Compare Hashes and testnet4 Reparse tests
- Refactor required actions for automatic upgrades

## API

- Change default value for `attach` and `move` to 546 satoshis
- Add `block_index` filter for Get Order Matches endpoints
- Add `block_index` filter for Get Dispenses by Asset endpoint
- Add Get Dispense By Hash endpoint

## CLI

- Rename `--testnet` flag to `--testnet3`
- Add testnet4 bootstrap database
- Add `--api-only` flag

# Credits

- Ouziel Slama
- Adam Krellenstein
