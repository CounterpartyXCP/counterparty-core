# Release Notes - Counterparty Core v10.5.1 (2024-10-??)

TODO

# Upgrading

TODO

Backwards-incompatible change
- `/v2/addresses/<address>/balances/<asset>` and `/v2/assets/<asset>/balances/<address>` now return a list that may include balances attached to UTXOs of `<address>`


# ChangeLog

## Bugfixes

## Codebase


## API

- `/v2/addresses/<address>/balances/<asset>` and `/v2/assets/<asset>/balances/<address>` now return a list that may include balances attached to UTXOs of `<address>`
- Add the following routes:
    * `/v2/blocks/<int:block_index>/fairminters`
    * `/v2/blocks/<int:block_index>/fairmints`
- Add `status` argument for Fairminters routes
- Made `/blocks/last` faster by adding an index to the `ledger_hash` field
- `/v2/addresses/<address>/sweeps` now also searches by the `destination` field
- Add `asset_events` argument for Issuances routes

## CLI

- `start` command supports now `--bootstrap-url`

# Credits

* Ouziel Slama
* Adam Krellenstein
