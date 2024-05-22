# Release Notes - Counterparty Core v10.2.0 (2024-05-??)


# Upgrading


# ChangeLog

## Bugfixes
* Fix circular imports.
* Fix 404 errors which were never returned due to a route that was too generic.

## Codebase
* Refactors mempool management and block tracking. Catching up is done using RPC and tracking using ZMQ.
* New Rust module to recover blocks with RPC. Massively parallelized and bufferized, block fetching no longer slows down block parsing.
* Refactor the `backend` module. Separation between calls to Bitcoin Core and Addrindexrs in two different modules.
* Add indexed `tx_hash` field in `messages` table.
* Updated `rowtracer` so that `apsw` returns boolean instead of integer for `BOOL` type fields.

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
* Replace `last` arguments by `cursor`.
* All responses contain a `next_cursor` field.
* All responses contain a `result_count` field.
* All queries that return lists from the database accept the `cursor`/`offset` and `limit` arguments (see Pagination paragraph in API Documentation).
* Documents the list of events with an example format for each of them.
* The `asset`, `assets`, `give_asset` and `get_asset` parameters are not case sensitive.

## Command-Line Interface


# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
