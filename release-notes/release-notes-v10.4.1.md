# Release Notes - Counterparty Core v10.4.1 (2024-09-24)

This release is a minor update with miscellaneous bugfixes.

# Upgrading

This release fixes an old bug leading to potential undefined behavior for dispenser refills. No database reparse is required.

# ChangeLog

## Protocol Changes

## Bugfixes

* Fix order cache: update cache when an order is filled
* Fix typo in `protocol_changes.json`
* Fix division by zero in `api.util.divide()`
* Catch invalid raw transaction in `/v2/transactions/info` endpoint
* Fix duplicate command in `xcpcli.py`
* Fix `source` field when refilling a dispenser created by a different source

## Codebase

* Don't report expected errors to Sentry in API v1
* Use `trace` instead of `warning` for "Prefetch queue is empty." message
* Use debug for expected and handled `yoyo` migration error
* Support Python 3.10 and 3.11 only
* Refactor and clean up `transaction.py`. The contents of this file are now distributed across `lib/api/compose.py`, `lib/transaction_helper/transaction_outputs.py`, and `lib/transaction_helper/transaction_inputs.py`.

## API

* Add support for `inputs_set` parameter
* Rename the `fee` argument to `exact_fee` (the `fee` argument is still available in API v1)
* Have the composition API return, in addition to a `rawtransaction` or a `psbt`, the following fields: `data`, `btc_in`, `btc_out`, `btc_change`, and `btc_fee`
* Add `sort` argument for `orders`, `order_matches` and `dispenser`
* Add the following route:
    - `/v2/transactions/<tx_hash>/info` (This route works if the tx is in the mempool of the queried node)

## CLI

# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
