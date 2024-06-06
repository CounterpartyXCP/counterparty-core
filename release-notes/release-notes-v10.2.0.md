# Release Notes - Counterparty Core v10.2.0 (2024-05-??)


# Upgrading

Note: A reparse from block 819250 is automatically launched during the update.

# ChangeLog

## Bugfixes
* Fix circular imports.
* Fix `404` errors for undefined routes.
* Fix redirection to API v1.
* Fix `burned`, `earned` field in API result.
* Fix non-cacheable API v2 routes.
* Fix the execution interval of the `APIStatusPoller` thread.

## Codebase
* Refactors mempool management and block tracking. Catching up is done using RPC and tracking using ZMQ.
* Introduce a new Rust module to fetch blocks from Bitcoin Core over RPC. Calls are now massively parallelized and buffered; block fetching no longer slows down block parsing.
* Refactor the `backend` module. Separate calls to Bitcoin Core and AddrIndexRs into two different modules.
* Add the indexed `tx_hash` field in `messages` table.
* Update `rowtracer` so that `apsw` returns boolean instead of integer for `BOOL` type fields.
* Clean RPS implementation. Introduce `replay_events()` function to reconstruct database from JSON list of events. 
* Add rust test suit to `build_and_test` Github workflow.
* It is possible to start parsing blocks while Bitcoin Core catches up.
* Optimizes `get_pending_dispensers()` by adding the `last_status_tx_source` and `close_block_index` fields in the `dispensers` table.
* Optimizes `is_dispensable()` by caching a list of all dispenser addresses.
* Add `transaction_count` field in `blocks` table.
* Added the following indexes:
    - `credits.calling_function`
    - `debits.action`
    - `transactions.source`
    - `credit.quantity`
    - `debit.quanity`
    - `balance.quantity`
    - `dispenser.give_quantity`
    - `order.get_quantity`
    - `order.give_quantity`
    - `dispense.dispense_quantity`
* Remove checking of impossible edge case in `list_tx()` function.
* Add `EVENT` log level.
* Update Pyo3 to the latest version.
* Disables the quick check if the database is not closed correctly. If this happens, display an error message when exiting and at the next restart.

## API
* Add following routes:
    `/v2/assets/<asset>/dispenses`
    `/v2/addresses/<address>/issuances`
    `/v2/addresses/<address>/assets`
    `/v2/addresses/<address>/transactions`
    `/v2/addresses/<address>/dividends`
    `/v2/addresses/<address>/orders`
    `/v2/addresses/<address>/dispenses/sends`
    `/v2/addresses/<address>/dispenses/receives`
    `/v2/addresses/<address>/dispenses/sends/<asset>`
    `/v2/addresses/<address>/dispenses/receives/<asset>`
    `/v2/blocks/<block_hash>`
    `/v2/blocks/last`
    `/v2/transactions`
    `/v2/transactions/<int:tx_index>/events`
    `/v2/transactions/<tx_hash>/events`
    `/v2/transactions/<int:tx_index>/events/<event>`
    `/v2/transactions/<tx_hash>/events/<event>`
    `/v2/transactions/<int:tx_index>`
    `/v2/dividends`
    `/v2/dividends/<dividend_hash>`
    `/v2/dividends/<dividend_hash>/credits`
    `/v2/mempool/transactions/<tx_hash>/events`
    `/v2/events/<event>/count`
    `/v2/bets`
    `/v2/orders`
    `/v2/dispensers`
* Introduce the `cursor` API argument.
* All responses now contain a `next_cursor` field.
* All responses now contain a `result_count` field.
* All queries that return lists from the database now accept the `cursor`/`offset` and `limit` arguments (see the Pagination paragraph from the API Documentation).
* Document the list of events with an example for each of them.
* The `asset`, `assets`, `give_asset`, and `get_asset` parameters are no longer case-sensitive.
* `/v2/assets` accepts now the paramater `named=true|false` to return only named or numeric assets. 
* Publish events on ZMQ Pub/Sub channel (see Documentation).
* Database connection pooling for API v1 and v2.
* If `verbose=true`, enrich results containing `block_index` with `block_time`.
* Added an `action` filter for the `*/credits` and `*/debits` routes.
* Added an `event_name` filter for the `*/events` routes.
* Add `issuer=None` in XCP and BTC asset information.
* Excludes zero balances in the results of `/v2/addresses/<address>/balances`.
* Excludes zero quantities in the results of `*/credits` and `*/debits`.
* Add BTC sent in `DISPENSE` event.
* Accept trailing slashes in routes.
* Update and improve documentation.
* Add `first_issuance_block_index` and `last_issuance_block_index` in assets information.
* Add normalized quantities for the following fields:
    - `fee_paid`
    - `fee_provided`
    - `fee_required`
    - `fee_required_remaining`
    - `fee_provided_remaining`
    - `fee_fraction_int`
    - `quantity_per_unit`
    - `btc_amount_normalized`
    - `burned`
    - `earned`
* Add `dispense_asset_info`.

## Command-Line Interface
* `-v` for `DEBUG` level, `-vv` for `EVENT` level, `-vvv` for `TRACE` level. It is also possible to repeat the `--verbose` flag as many times as necessary.
* Clean CLI outputs for all commands.

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
