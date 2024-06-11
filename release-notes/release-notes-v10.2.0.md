# Release Notes - Counterparty Core v10.2.0 (2024-05-??)

This is a large release that includes significant refactoring and redesigns of critical node components, including the CLI and logging subsystems, mempool processing, and API database connection management. It also includes numerous updates and extensions to the v2 API, plus new ZeroMQ support. Of course, a large number of bugs have been resolved as well.


# Upgrading

`counterparty-server` now uses ZMQ to track the Blockchain. You must configure Bitcoin Core with:

```
zmqpubrawtx=tcp://0.0.0.0:9332
zmqpubhashtx=tcp://0.0.0.0:9332
zmqpubsequence=tcp://0.0.0.0:9332
zmqpubrawblock=tcp://0.0.0.0:9333
```

and for `testnet` with:

```
zmqpubrawtx=tcp://0.0.0.0:19332
zmqpubhashtx=tcp://0.0.0.0:19332
zmqpubsequence=tcp://0.0.0.0:19332
zmqpubrawblock=tcp://0.0.0.0:19333
```

Note: This update requires a reparse from Block 819250, which will proceed automatically on initialization.


# ChangeLog

## Bugfixes
* Fix circular imports
* Return `404` errors for undefined API routes
* Fix nested `result` value in the v1 API
* Fix `burned`, `earned`, and `btc_amount_normalized` fields in API results
* Do not cache non-cacheable v2 API routes (which could lead to a broken health check, in particular)
* Fix the execution interval of the `APIStatusPoller` thread
* Add `Access-Control-Allow-Headers = *` header to API v2 for CORS

## Codebase
* Refactor mempool management and block tracking—catching up is now done via RPC, and tracking via ZeroMQ
* Introduce a new Rust module to fetch blocks from Bitcoin Core over RPC. Calls are now massively parallelized and buffered; block fetching no longer slows down block parsing
* Refactor the `backend` module; separate calls to Bitcoin Core and AddrIndexRs into two different modules.
* Add the indexed `tx_hash` field to the `messages` table
* Update `rowtracer` so that `apsw` returns a boolean instead of an integer for `BOOL` type fields
* Delete the defunct implementation of rock-paper-scissors; introduce a `replay_events()` function to reconstruct the database from a hard-coded list of historical events
* Enable parsing blocks while Bitcoin Core is still catching up
* Optimize `get_pending_dispensers()` by adding the `last_status_tx_source` and `close_block_index` fields to the `dispensers` table; optimize `is_dispensable()` by caching a list of all dispenser addresses
* Add the `transaction_count` field to the `blocks` table
* Add the following new database indexes:
    - `credits.calling_function`
    - `debits.action`
    - `transactions.source`
    - `credit.quantity`
    - `debit.quantity`
    - `balance.quantity`
    - `dispenser.give_quantity`
    - `order.get_quantity`
    - `order.give_quantity`
    - `dispense.dispense_quantity`
* Add the new `EVENT` log level
* Disable the automatic SQLite ‘quick check’ for when the database has not been closed correctly. Display an error message when exiting and at the next restart.
* `get_oldest_tx()` retries on Addrindexrs timeout.

## API
* Introduce the following new routes:
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
* Introduce the `cursor` API parameter
* Include `next_cursor` and `result_count` fields in all responses
* Accept `cursor`/`offset` and `limit` arguments in all queries that return lists from the database (see the Pagination paragraph of the API Documentation)
* Make the `asset`, `assets`, `give_asset`, and `get_asset` parameters case-insensitive
* Add the `named=true|false` parameter to `/v2/assets` to for returning only named xor numeric assets
* Publish events on the ZeroMQ Pub/Sub channel
* Implement database connection pooling for both API v1 and v2
* Enrich results containing `block_index` with `block_time` when `verbose=true`
* Add an `action` filter for the `*/credits` and `*/debits` routes.
* Add an `event_name` filter for the `*/events` routes
* Specify `issuer=None` within XCP and BTC asset information
* Exclude zero balances in the results of `/v2/addresses/<address>/balances` and zero quantities in the results of `*/credits` and `*/debits`
* Add BTC sent to the `DISPENSE` event
* Accept trailing slashes in routes
* Include `first_issuance_block_index` and `last_issuance_block_index` in asset information
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
    - `dispense_quantity`
* Return asset info for dispenses
* Add `confirmation_target` argument for `compose` endpoints


## CLI
* Use `-v` for the `DEBUG` level, `-vv` for the `EVENT` level, and `-vvv` for the `TRACE` level (it is also possible to repeat the `--verbose` flag)
* Clean up and refactor CLI outputs for all commands
* Clean up log messages and add numerous additional logging statements


# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
