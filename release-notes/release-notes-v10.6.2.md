# Release Notes - Counterparty Core v10.6.2 (2024-11-??)



# Upgrading

# ChangeLog

## Protocol Changes

## Improvements

- Rust fetcher will now only store entries in its database required for Bitcoin reorganization checks. This greatly reduces the size of the database and significantly increases the speed of the catch-up process.

## Bugfixes

- Rust fetcher "reporter" worker now takes `rollback_height` into account in its block height ordering check.



## Codebase


## API

- Add `validate` argument to compose API
- Add sortable `get_price` and `give_price` fields in orders
- Add sortable `price` field in dispensers
- Fix `locked` in `asset_info` field
- Add `/v2/bitcoin/transaction/decode` route to proxy bitcoin `decoderawtransaction` method

## CLI


# Credits

* OpenStamp
* DerpHerpenstein
* Ouziel Slama
* Wilfred Denton
* Adam Krellenstein
