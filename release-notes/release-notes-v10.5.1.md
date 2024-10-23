# Release Notes - Counterparty Core v10.5.1 (2024-10-??)

TODO

# Upgrading

TODO

Backwards-incompatible change
- `/v2/addresses/<address>/balances/<asset>` and `/v2/assets/<asset>/balances/<address>` now return a list that may include balances attached to UTXOs of `<address>`


# ChangeLog

## Bugfixes

- Correctly catch invalid pubkey in compose API
- Don't run reparse if unnecessary
- Fix `message_data` when retrieving information about fairminter or fairmint transactions
- Use `threading.Event()` to cleanly stop Threads and subprocesses started by `counterparty-server`

## Codebase


## API

- `/v2/addresses/<address>/balances/<asset>` and `/v2/assets/<asset>/balances/<address>` now return a list that may include balances attached to UTXOs of `<address>`
- Add the following routes:
    * `/v2/blocks/<int:block_index>/fairminters`
    * `/v2/blocks/<int:block_index>/fairmints`
    * `/v2/compose/attach/estimatexcpfees`
- Add `status` argument for Fairminters routes
- Made `/blocks/last` faster by adding an index to the `ledger_hash` field
- `/v2/addresses/<address>/sweeps` now also searches by the `destination` field
- Add `asset_events` argument for Issuances routes
- Raise an error on fairmint compose when the fairminter is free and the quantity is not zero

## CLI

- `start` command supports now `--bootstrap-url`

# Credits

* Ouziel Slama
* Adam Krellenstein
