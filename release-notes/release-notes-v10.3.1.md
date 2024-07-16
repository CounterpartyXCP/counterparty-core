# Release Notes - Counterparty Core v10.3.1 (2024-07-??)


# Upgrading


# ChangeLog

## Bugfixes

* Fix cache for `/v2/bitcoin/*` routes
* Fix queries by `asset_longname`

## Codebase

## API

* Add the following routes:
    - Get Balances By Addresses
    - Get Events Bt Addresses
    - Get Mempool Events By Addresses
    - Get Order Matches By Asset
    - Get Order Matches By Two Assets
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
* Sort `orders` by `tx_index DESC`

## CLI


# Credits

* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
