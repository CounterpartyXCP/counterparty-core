# Release Notes - Counterparty Core v10.10.1 (2025-02-?)


# Upgrading

# ChangeLog

## Protocol Changes

## Bugfixes

- Handle correctly errors in subprocess when bootstrapping
- Fix `getrawtransaction_batch()` for batches greater than `config.MAX_RPC_BATCH_SIZE`
- Better error handling for port taken
- Fix ungraceful ZeroMQ Failure
- Fix Conservation Check Failing Ungracefull
- Cleaner Gunicorn Shutdown
- Fix ungraceful Waitress shutdown
- Handle correctly RSFetcher version mismatch error
- Handle correctly errors in Counterparty Server version checking

## Codebase

- Tweak logging Bitcoin Core Catch Up
- Batch getrawtransaction for `get_vin_info()`
- Create events indexes after catch up
- Make RPC calls to get transactions inputs info with RSFetcher
- Make RSFetcher compatible with HTTPS

## API

- Check balance when composing `detach` transaction
- Add `show_unconfirmed` parameter for get transactions endpoints
- Add `count_confirmed` parameter for get transactions count endpoints
- Add `X-LEDGER-STATE` header in all API responses
- Add `ledger_state` field in API v2 root endpoint

## CLI

- Accepts `--catch-up` flag before the command
- Add a locust runner to test local node (`python3 counterpartycore/test/integration/locustrunner.py` will start Locust Web UI on http://localhost:8089/).
- Add `--profile` CLI flag that enables cProfile during catchup and dumps the results to the console after it is complete

# Credits

- Ouziel Slama
- Adam Krellenstein
