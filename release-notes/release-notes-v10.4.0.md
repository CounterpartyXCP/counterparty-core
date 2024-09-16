# Release Notes - Counterparty Core v10.4.0 (2024-09-17)

This release includes a variety of protocol upgrades.

# Upgrading

This release does not require any reparsing. 

# ChangeLog

## Protocol Changes

* Require Dispenser to be Source Address
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2141
    - Spec: https://docs.counterparty.io/docs/advanced/specifications/dispenser-must-be-created-by-source/
* Make Dispenses Normal Counterparty Transactions
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2141
    - Spec: https://docs.counterparty.io/docs/advanced/specifications/enable-dispense-tx/
* Be Able to Lock Descriptions
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2153
    - Spec: https://docs.counterparty.io/docs/advanced/specifications/lockable-issuance-descriptions/
* Fair Minting Protocol
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2142
    - Spec: https://docs.counterparty.io/docs/advanced/specifications/fairminter/
* UTXO Support
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2180
    - Spec: https://docs.counterparty.io/docs/advanced/specifications/utxo-support/
* Gas System
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2180
    - Spec: https://docs.counterparty.io/docs/advanced/specifications/gas-system/
* Expire order matches then orders
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/1794
    - Issue: https://github.com/CounterpartyXCP/counterparty-core/pull/1633
* Free Subassets
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2194
    - Spec: https://docs.counterparty.io/docs/advanced/specifications/free-subassets/
* Subassets on Numeric Assets
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2195
    - Spec: https://docs.counterparty.io/docs/advanced/specifications/allow-subassets-on-numerics/
* Fix minimum BTC amount in order contract

## Bugfixes

* Fix adding new transactions in unit test fixtures (`scenarios.py`)
* Fix mempool parsing on testnet and regtest
* Fix `get_dispensers_by_asset` endpoint filtering by query parameter. Numeric statuses can now be used i.e. `status=0`
* Fix `cursor` type in API routes
* Fix `ledger.get_last_db_index()` (server is ready on `BLOCK_PARSED` not on `NEW_BLOCK`)

## Codebase

* New test suite and github workflow with `regtest` network
* Delete mempool events older than 24 hours

## API

* Add `return_only_data` argument for composition routes
* Add an `asset_events` field to the `issuances` table. This field contains one or more of the following values ​​separated by spaces: `creation`, `reissuance`, `reset`, `lock_quantity`, `lock_description`, `open_fairminter`, `close_fairminter`, `fairmint`.
* Return only valid issuances
* Generate API blueprint from regtest node
* Run Dredd tests on regtest node
* Add the new following routes:
    - `/v2/order_matches`

## CLI

# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
