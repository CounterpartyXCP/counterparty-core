# Release Notes - Counterparty Core v10.4.2 (2024-10-02)

This is a small but important release which includes fixes for a number of node stability issues and updates to the API. All node hosts should upgrade as soon as possible.


# Upgrading

This release is not a protocol change and does not require any reparsing. A regression in the v1 API has been resolved.


# ChangeLog

## Protocol Changes


## Bugfixes

* Retry indefinitely when RSFetcher cannot connect to Bitcoin Core
* Fix RSFetcher startup logic
* Restart RSFetcher when it is found to have been stopped 
* Fix JSON serialization of `bytes` in API v1

## Codebase

* Fix Docker Compose test
* Fetch old mempool entries from Bitcoin Core after node startup

## API

* Disable expiration of mempool entries after 24 hours
* Expose timestamp field for mempool transactions (for client-side filtering)
* Revert accidental change in API v1 (renamed `unsigned_tx_hex` to `tx_hex` in `create_*()` result)
* Disable `p2sh` encoding, which no longer works with recent versions of Bitcoin Core

## CLI


# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
