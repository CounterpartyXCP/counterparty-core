# Release Notes - Counterparty Core v10.9.0 (2024-12-??)


# Upgrading

# ChangeLog

## Protocol Changes

## Bugfixes

- Fix endpoint to get info from raw transaction when block index is not provided
- Catch errors correctly when composing MPMA send
- Fix query to fill `issuances.asset_events` field
- Fix `assets_info.supply` field
- Fix `verbose=True` when `give_asset` or `get_asset` contain an `asset_longname`

## Codebase

- Refactor raw mempool parsing; Don't block following
- Add a timeout to parse mempool transaction from ZMQ
- Add cache for unsupported transactions when parsing raw 
- Refactor and optimize bootstrap process, using `zstd` instead of `gzip`
- Remove Addrindexrs dependency: mock `get_oldest_tx()`, use Electrs to get utxos and address history for transaction composition

## API

- Throw Error if BTC Quantity in Dispense isn't enough to Trigger Dispenser
- Add `get_asset` and `give_asset` parameters for get orders by asset endpoint
- Add `forward_asset` and `backward_asset` parameters for get order matches by asset endpoint
- Add `forward_price` and `backward_price` in order matches results
- Add parameter `exclude_with_oracle` for get dispensers routes
- Add `send_type` field in `sends` table
- Use `satoshirate_normalized` and `give_quantity_normalized` to calculate `price_normalized`

## CLI

- Add `--cache-dir` flag
- Add `severity` field to JSON logs for compatibility

# Credits

- Ouziel Slama
- Warren Puffet
- Adam Krellenstein
