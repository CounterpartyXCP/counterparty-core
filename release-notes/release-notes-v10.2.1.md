# Release Notes - Counterparty Core v10.2.1 (2024-06-??)


# Upgrading


# ChangeLog


## Bugfixes

* Add `quantity_normalized` in Issuances endpoints
* Fix verbose mode for order matches

## Codebase


## API

* Introduce the following new routes:
    - `/v2/transactions/<tx_hash>/sends`
    - `/v2/transactions/<tx_hash>/dispenses`
    - `/v2/dispenses`
    - `/v2/sends`
    - `/v2/issuances`
    - `/v2/issuances/<tx_hash>`
    - `/v2/sweeps`
    - `/v2/sweeps/<tx_hash>`
    - `/v2/broadcasts`
    - `/v2/broadcasts/<tx_hash>`
* More Detailed InsufficientBTC Error
* When `verbose=true`, inject `unpacked_data` into all results containing a `data` field
* Remove `asset_info` from ASSET_ISSUANCE event
* Trailing zeros for divisible quantities
* `/v2/orders/<order_hash>/matches` returns all order matches by default
* Fix cache for `/v2/blocks/last` route
* Clean and enrich `message_data` for MPMA sends
* Supports `dispense` message type
* Add `/assets/<asset>/info` route

## CLI

* Tweak RPS logging

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
