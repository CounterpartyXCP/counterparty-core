# Release Notes - Counterparty Core v10.10.1 (2025-02-?)


# Upgrading

# ChangeLog

## Protocol Changes

## Bugfixes

- Handle correctly errors in subprocess when bootstrapping
- Fix `getrawtransaction_batch()` for batches greater than `config.MAX_RPC_BATCH_SIZE`
- Better error handling for port taken

## Codebase

- Tweak logging Bitcoin Core Catch Up
- Batch getrawtransaction for `get_vin_info()`

## API


## CLI

- Accepts `--catch-up` flag before the command
- Add a locust runner to test local node (`python3 counterpartycore/test/integration/locustrunner.py` will start Locust Web UI on http://localhost:8089/).

# Credits

- Ouziel Slama
- Adam Krellenstein
