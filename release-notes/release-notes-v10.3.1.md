# Release Notes - Counterparty Core v10.3.1 (2024-07-??)


# Upgrading


# ChangeLog

## Bugfixes

* Fix cache for `/v2/bitcoin/*` routes
* Fix queries by `asset_longname`
* Fix capture exception by Sentry

## Codebase

## API

* Add the following routes:
    - Get Balances By Addresses
    - Get Events Bt Addresses
    - Get Mempool Events By Addresses
    - Get Order Matches By Asset
    - Get Order Matches By Two Assets
    - Get Subassets By Asset
    - Get Unspent Txouts By Addresses
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
* Add `return_psbt` argument for compose endpoints
* Add `market_price` when getting orders or order matches by two assets
* Make queries to get orders or order matches by two assets not case sensitive
* Unconfirmed objects (`transactions`, `issuances`, `orders`, etc.) are accessible in the API with the parameter `?show_unconfirmed=true`
* Inject `fiat_price` and oracle info in dispensers
* Include decoded transaction in the result of `/v2/transactions/info`
* Return `null` when `destination` field is empty
* `<address>` in API routes supports several addresses (comma separated)

## CLI

* Add `--json-logs` flag to show logs in JSON format
* Send telemetry data after each block
* Reduce Sentry Trace Sample Rate to 10%
* Enable Sentry Caches and Queries pages

# Credits

* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
