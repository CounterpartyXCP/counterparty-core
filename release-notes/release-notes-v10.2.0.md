# Release Notes - Counterparty Core v10.2.0 (2024-05-??)


# Upgrading


# ChangeLog

## Bugfixes
* Fix circular imports.
* Fix `404` errors for undefined routes.

## Codebase
* Refactors mempool management and block tracking. Catching up is done using RPC and tracking using ZMQ.
* Introduce a new Rust module to fetch blocks from Bitcoin Core over RPC. Calls are now massively parallelized and buffered; block fetching no longer slows down block parsing.
* Refactor the `backend` module. Separate calls to Bitcoin Core and AddrIndexRs into two different modules.
* Add the indexed `tx_hash` field in `messages` table.
* Update `rowtracer` so that `apsw` returns boolean instead of integer for `BOOL` type fields.
* Clean RPS implementation. Introduce `replay_events()` function to reconstruct database from JSON list of events. 

## API
* Add following routes:
    `/v2/assets/<asset>/dispenses`
    `/v2/addresses/<address>/dispenses/sends`
    `/v2/addresses/<address>/dispenses/receives`
    `/v2/addresses/<address>/dispenses/sends/<asset>`
    `/v2/addresses/<address>/dispenses/receives/<asset>`
    `/v2/transactions/<int:tx_index>/events`
    `/v2/transactions/<tx_hash>/events`
    `/v2/transactions/<int:tx_index>/events/<event>`
    `/v2/transactions/<tx_hash>/events/<event>`
    `/v2/transactions/<int:tx_index>`
    `/v2/blocks/<block_hash>`
    `/v2/blocks/last`
    `/v2/mempool/transactions/<tx_hash>/events`
    `/v2/addresses/<address>/issuances`
    `/v2/events/<event>/count`
* Introduce the `cursor` API argument.
* All responses now contain a `next_cursor` field.
* All responses now contain a `result_count` field.
* All queries that return lists from the database now accept the `cursor`/`offset` and `limit` arguments (see the Pagination paragraph from the API Documentation).
* Document the list of events with an example for each of them.
* The `asset`, `assets`, `give_asset`, and `get_asset` parameters are no longer case-sensitive.
* Publish events on ZMQ Pub/Sub channel (see Documentation)

## Command-Line Interface


# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
