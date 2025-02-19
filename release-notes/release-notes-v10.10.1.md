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

## Codebase

- Tweak logging Bitcoin Core Catch Up
- Batch getrawtransaction for `get_vin_info()`
- Create events indexes after catch up

## API


## CLI

- Accepts `--catch-up` flag before the command
- Add a locust runner to test local node (`python3 counterpartycore/test/integration/locustrunner.py` will start Locust Web UI on http://localhost:8089/).

# Credits

- Ouziel Slama
- Adam Krellenstein
