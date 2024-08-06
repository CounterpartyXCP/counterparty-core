# Release Notes - Counterparty Core v10.3.1 (2024-08-06)

This release is a relatively minor update with a large number of improvements to the node API, as well as a few important bugfixes and tweaks to the CLI and telemetry subsystems.

# Upgrading

This release is not a protocol change and does not require any reparsing. 

# ChangeLog

## Bugfixes

* Fix cache for `/v2/bitcoin/*` routes
* Fix queries by `asset_longname`
* Fix capture exception by Sentry
* Be sure not to cache `orders` and dispenser addresses from mempool
* Catch `UnicodeError` in `transactions.unpack()` function

## Codebase

## API

* Add the following routes:
    - Get Balances By Addresses
    - Get Events By Addresses
    - Get Mempool Events By Addresses
    - Get Order Matches By Asset
    - Get Order Matches By Two Assets
    - Get Subassets By Asset
    - Get Unspent Txouts By Addresses
* Capitalize `<asset>` in routes
* Accept `asset_longname` for `GET /v2/assets/<asset>/issuances`
* Add default values for the `locked` and `reset` fields in `issuances` table
* Add XCP to the `assets_info` table
* Remove `timestamp` from events in API results
* Standardize the format of mempool events and confirmed events
* Use strings instead of integers to query `dispensers` by status
* Accept several statuses for querying `dispensers`, `orders` and `order_matches`
* Add `sort` argument for the following routes:
    - `/v2/assets/<asset>/balances`
    - `/v2/addresses/<address>/balances`
    - `/v2/addresses/balances`
* Sort `orders` by `tx_index DESC`
* Insert `return_psbt` argument for compose endpoints
* Insert `market_price` when getting orders or order matches by two assets
* Make queries to get orders or order matches by two assets case-insensitive
* Make unconfirmed objects (`transactions`, `issuances`, `orders`, etc.) accessible via the API with the parameter `?show_unconfirmed=true`
* Inject `fiat_price` and oracle info in dispensers
* Include decoded transaction in the result of `/v2/transactions/info`
* Return `null` when `destination` field is empty
* Support comma-separated addresses for the `<address>` value in API routes
* Catch `CBitcoinAddressError` correctly
* Return a 400 error instead a 503 on `ComposeError` and `UnpackError`

## CLI

* Add `--json-logs` flag for displaying logs in the JSON format
* Send telemetry data after each block
* Reduce Sentry Trace Sample Rate to 10%


# Credits

* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
