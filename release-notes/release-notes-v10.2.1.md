# Release Notes - Counterparty Core v10.2.1 (2024-06-??)


# Upgrading

This update introduces a new database dedicated and optimized for the API. This database is reconstructed only from events by the `API Watcher`. A new field `messages.event_hash` ensures the correspondence between the two databases in the event of a Blockchain reorg for example.
This update requires a full reparse automatically launched.

# ChangeLog

## Bugfixes

* Add `quantity_normalized` in Issuances endpoints
* Fix verbose mode for order matches
* Fix `NEW_TRANSACTION` events order on reparse

## Codebase

* Remove Kickstart
* Remove `UPDATE` query for `addresses` table
* Add `NEW_ADDRESS_OPTIONS` and `ADDRESS_OPTIONS_UPDATE` events
* Add tx_hash in `DISPENSE_UPDATE` event
* Add `event_hash` field in `messages` table
* New database dedicated and optimized for the API

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
* Add `supply_normalized` in asset info
* Add `btc_amount` in `dispenses`
* Use `all` for default status when getting orders

## CLI

* Tweak RPS logging
* Fix erroneous Rust Fetcher errors on shutdown 


# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
