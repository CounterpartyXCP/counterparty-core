# Release Notes - Counterparty Core v10.2.0 (2024-05-??)


# Upgrading

Note: A reparse from block 819250 is automatically launched during the update.

# ChangeLog

## Bugfixes
* Fix circular imports.
* Fix `404` errors for undefined routes.
* Fix redirection to API v1
* Fix `burned` and `earned` field in API result

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
* Added the following indexes: `credits.calling_function`, `debits.action`, `transactions.source`
* Remove checking of impossible edge case in `list_tx()` function.
* Add `EVENT` log level

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
* Database connection pooling.
* If `verbose=true`, enrich results containing `block_index` with `block_time`.
* Added an `action` filter for the `*/credits` and `*/debits` routes.
* Add `issuer=None` in XCP and BTC asset information.
* Excludes zero balances in the results of `/v2/addresses/<address>/balances`.
* Add BTC sent in `DISPENSE` event.

## Command-Line Interface
* `-v` for `DEBUG` level, `-vv` for `EVENT` level, `-vvv` for `TRACE` level

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
