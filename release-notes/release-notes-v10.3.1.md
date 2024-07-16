# Release Notes - Counterparty Core v10.3.1 (2024-07-??)


# Upgrading


# ChangeLog

## Bugfixes

* Fix cache for `/v2/bitcoin/*` routes
* Fix queries by `asset_longname`

## Codebase

## API

* Add Get Balances By Addresses route
* Add Get Events Bt Addresses route
* Add Get Mempool Events By Addresses route
* Always capitalize `<asset>` in routes
* `/v2/assets/<asset>/issuances` accepts `asset_longname`
* Add defaul value for `locked` and `reset` fields in `issuances` table
* Add XCP in `assets_info` table
* Remove `timestamp` from events in API results
* Standardize the format of Mempool events and confirmed events
* Use string instead of integers to query `dispensers` by status
* Accepts several statuses to query `dispensers`, `orders` and `order_matches`
* Add `sort` argument for the following routes:
    - `/v2/assets/<asset>/balances`
    - `/v2/addresses/<address>/balances`
    - `/v2/addresses/balances`

## CLI


# Credits

* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
