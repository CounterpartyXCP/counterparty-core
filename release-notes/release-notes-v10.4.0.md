# Release Notes - Counterparty Core v10.4.0 (2024-??-??)

This release includes a variety of protocol upgrades.

# Upgrading

# ChangeLog

## Protocol Changes

* Require Dispenser to be Source Address
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2141
    - Spec: https://gist.github.com/adamkrellenstein/04178f3f761ab5826afeb51eec817547
* Make Dispenses Normal Counterparty Transactions
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2141
    - Spec: https://gist.github.com/adamkrellenstein/e9162e89f9dc6521f17c9b2693eda52c
* Be Able to Lock Descriptions
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2153
    - Spec: https://gist.github.com/adamkrellenstein/94bd304ca4e464b6d5db0da2b05e3075
* Fair Minting Protocol
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2142
    - Spec: https://gist.github.com/ouziel-slama/9eb05ff9890eb402cd9adb4e166a5469
* UTXO Support
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2180
    - Spec: https://gist.github.com/ouziel-slama/3b3fa3738063c6390af0d6b692276935
* Gas System
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2180
    - Spec: https://gist.github.com/adamkrellenstein/7c7cab257cee162233fc2ba6682eb8da
* Expire order matches then orders
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/1794
    - Issue: https://github.com/CounterpartyXCP/counterparty-core/pull/1633
* Free Subassets
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2194
    - Issue: https://github.com/CounterpartyXCP/counterparty-core/issues/1840
* Subassets on Numeric Assets
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2195
    - Issue: https://github.com/CounterpartyXCP/counterparty-core/issues/1842
* Fix minimum BTC amount in order contract

## Bugfixes

* Fix adding new transactions in unit test fixtures (`scenarios.py`)
* Fix mempool parsing on testnet and regtest
* Fix `get_dispensers_by_asset` endpoint filtering by query parameter. Numeric statuses can now be used i.e. `status=0`
* Fix `cursor` type in API routes
* Fix `ledger.get_last_db_index()` (server is ready on `BLOCK_PARSED` not on `NEW_BLOCK`)
* Fix `ledger.get_block(block_index)` function
* Check that the previous block is present when a block is received with ZMQ
* Log API v1 responses

## Codebase

* New test suite with `regtest` network
* Delete mempool events older than 24 hours
* User order caching only during catch-up

## API

* Add `return_only_data` argument for composition routes
* Add an `asset_events` field to the `issuances` table. This field contains one or more of the following values ​​separated by spaces: `creation`, `reissuance`, `reset`, `lock_quantity`, `lock_description`, `open_fairminter`, `close_fairminter`, `fairmint`.
* Return only valid issuances
* Generate API blueprint from regtest node
* Run Dredd tests on regtest node
* Add the new following routes:
    - `/v2/order_matches`
    - `/v2/bitcoin/getmempoolinfo`

## CLI

# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
