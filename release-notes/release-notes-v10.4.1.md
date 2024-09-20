# Release Notes - Counterparty Core v10.4.1 (2024-??-??)


# Upgrading

# ChangeLog

## Protocol Changes

## Bugfixes

* Fix order cache: update cache when an order is filled
* Fix typo in `protocol_changes.json`
* Fix division by zero in `api.util.divide()`
* Catch invalid raw transaction in `/v2/transactions/info` endpoint

## Codebase

* Don't report expected errors to Sentry in API v1
* Use `trace` instead of `warning` for "Prefetch queue is empty." message
* Use debug for expected and handled `yoyo` migration error
* Support Python 3.10 and 3.11 only
* Move Compose API to `api/compose.py` module

## API

* Add support for `inputs_set` parameter
* Add the following route:
    - `/v2/transactions/<tx_hash>/info` (This route works if the tx is in the mempool of the queried node)

## CLI

# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
