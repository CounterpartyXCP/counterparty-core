# Release Notes - Counterparty Core v10.3.0 (2024-07-03)

This version most notably introduces a major performance optimization for node API access: an additional SQLite3 database has been added which tracks the current state of all Counterparty objects (in addition to the primary database that is purely log-structured). Other major changes for this version include the removal of the `kickstart` functionality, which is possible now that `start` is performant, and numerous tweaks and improvements to the v2 API.


# Upgrading

This update requires an automatic full reparse of the Counterparty transactions to populate the new database file.


# ChangeLog

## Bugfixes

* Fix verbose logging of order matches
* Fix the order of `NEW_TRANSACTION` events on reparse
* Check the ZMQ `rawblock` topic more frequently on testnet
* Trigger `NEW_TRANSACTION_OUTPUT` events during a reparse
* Fix incorrect `messages_hash` after a reparse
* Fix silent errors in ZMQ follower

## Codebase

* Remove `UPDATE` query for the `addresses` table
* Add `NEW_ADDRESS_OPTIONS` and `ADDRESS_OPTIONS_UPDATE` events
* Add `tx_hash` to `DISPENSE_UPDATE` event
* Add `event_hash` field to the `messages` table
* Add a new database optimized for the API. This new database is reconstructed only from events by the `API Watcher`, and a new field `messages.event_hash` ensures the correspondence between the two databases in the event of a blockchain reorganization. 
* Parse transactions vouts with Rust

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
    - `/v2/assets/<asset>/info`
* Add `quantity_normalized` to issuances endpoints
* Increase the detail for the `InsufficientBTC` error
* Inject `unpacked_data` into all results containing a `data` field when `verbose=true`
* Remove `asset_info` from the `ASSET_ISSUANCE` event
* Standardize on trailing zeros for divisible quantities
* `/v2/orders/<order_hash>/matches` returns all order matches by default
* Fix cache for `/v2/blocks/last` route
* Clean and enrich `message_data` for MPMA sends
* Support `dispense` message type
* Add `supply_normalized` to asset info object in API responses
* Add `btc_amount` to API responses returning `dispenses` objects
* Use `all` as the default status when returning `orders` objects
* Provide link to Apiary documentation in the root route  for the v2 API

## CLI

* Remove all `kickstart` functionality; `start` is now recommended for the initial catchup.
* Tweak RPS logging
* Fix erroneous Rust Fetcher errors on shutdown 


# Credits

* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
