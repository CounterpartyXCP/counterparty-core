# Release Notes - Counterparty Core v10.3.2 (2024-08-11)

This release is a minor update with some bugfixes.

# Upgrading

This release is not a protocol change and does not require any reparsing. 

# ChangeLog

## Bugfixes

* Fix `get_value_by_block_index()` on `regtest`
* Fix events hash mismatch after a reparse
* Fix `regtest` default ports
* Fix `/v2/assets/XCP` route
* Fix queries on `messages` table (remove mempool filtering)
* Fix graceful closing of `counterparty.db`
* Fix Get XCP Holders route
* Fix division by zero in API market prices

## Codebase

## API

## CLI

* Move Counterparty Node UUID from `~/counterparty-node-uuid` to `~/.local/state/counterparty/.counterparty-node-uuid`

# Credits

* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello