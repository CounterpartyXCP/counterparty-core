# Release Notes - Counterparty Core v10.6.0 (2024-10-24)

This release includes a protocol change to fix a regression for the case when there have been multiple dispensers opened at a single address. The bug prevents users from triggering dispensers at addresses where there have previously been closed dispensers (rather than simply re-opened dispensers). 


# Upgrading

This release is a protocol change from mainnet block 868,200 (in about one week). It also includes a backwards-incompatible change in the API:

- `/v2/addresses/<address>/balances/<asset>` and `/v2/assets/<asset>/balances/<address>` now return a list that may include balances attached to UTXOs of `<address>`.

This release also includes a bugfix for chained UTXO movements within the same block. This bugfix requires an automatic reparse starting from block 867000. Given the current slowdowns in catching up with the API database, we recommend using `counterparty-server bootstrap` before restarting your server.

*IMPORTANT* All wallets should use the `compose_dispense()` call to trigger dispenses rather than the legacy `create_send()`. Due to the above bug, using `create_send()` can make it possible for users to send BTC to an address where the dispenser will fail. All node hosts should migrate to `compose_dispense()` ASAP. 


# ChangeLog

## Protocol Changes

- Block 868200: Dispenses are now triggered if *at least* one dispenser on the address is valid rather than only if all of them are valid.

## Bugfixes

- Catch invalid pubkeys in the compose API correctly
- Run reparse only if necessary
- Fix `message_data` when retrieving information about fairminter or fairmint transactions
- Use `threading.Event()` to cleanly stop threads and subprocesses started by `counterparty-server`
- Don't update UTXOs balances cache on mempool transaction
- Update UTXOs balances cache before transacation parsing to catch chained UTXO moves in the same block

## Codebase

- Use a lock file for RS Fetcher thread
- Add checkpoint for block 867290

## API

- Have `/v2/addresses/<address>/balances/<asset>` and `/v2/assets/<asset>/balances/<address>` now return a list that may include balances attached to UTXOs of `<address>`
- Add the following routes:
    * `/v2/blocks/<int:block_index>/fairminters`
    * `/v2/blocks/<int:block_index>/fairmints`
    * `/v2/compose/attach/estimatexcpfees`
- Add `status` argument for Fairminters routes
- Make `/blocks/last` faster by adding an index to the `ledger_hash` field
- Have `/v2/addresses/<address>/sweeps` now also search by the `destination` field
- Add `asset_events` argument for Issuances routes
- Raise an error on `fairmint.compose()` when the fairminter is free and the quantity is not zero

## CLI

- Add support for `--bootstrap-url` to `start` command

# Credits

* Ouziel Slama
* Adam Krellenstein
