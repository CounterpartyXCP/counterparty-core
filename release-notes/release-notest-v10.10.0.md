# Release Notes - Counterparty Core v10.10.0 (2025-01-??)


# Upgrading



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
