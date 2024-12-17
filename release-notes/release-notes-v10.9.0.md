# Release Notes - Counterparty Core v10.9.0 (2024-12-??)


# Upgrading

# ChangeLog

## Protocol Changes

## Bugfixes

- Fix endpoint to get info from raw transaction when block index is not provided
- Catch errors correctly when composing MPMA send

## Codebase

- Refactor raw mempool parsing; Don't block following
- Add a timeout to parse mempool transaction from ZMQ
- Add cache for unsupported transactions when parsing raw mempool

## API

- Throw Error if BTC Quantity in Dispense isn't enough to Trigger Dispenser
- Add `get_asset` and `give_asset` parameters for get orders by asset endpoint

## CLI

- Add `--cache-dir` flag

# Credits

- Ouziel Slama
- Warren Puffet
- Adam Krellenstein
