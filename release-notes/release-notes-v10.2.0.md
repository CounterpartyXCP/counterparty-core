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
* Add route to get events by transactions: `/v2/transactions/<tx_hash>/events`.


## Command-Line Interface


# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
