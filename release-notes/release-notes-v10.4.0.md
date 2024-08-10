# Release Notes - Counterparty Core v10.4.0 (2024-08-??)

# Upgrading

# ChangeLog

## Bugfixes

* Fix `get_value_by_block_index()` on `regtest`
* Fix events hash mismatch after a reparse
* Fix `regtest` default ports
* Fix `/v2/assets/XCP` route
* Fix queries on `messages` table (remove mempool filtering)
* Fix graceful closing of `counterparty.db`
* Fix Get XCP Holders route

## Codebase

## API

## CLI

* Move Counterparty Node UUID from `~/counterparty-node-uuid` to `~/.local/state/counterparty/.counterparty-node-uuid`

# Credits

* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello