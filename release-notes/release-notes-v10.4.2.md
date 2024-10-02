# Release Notes - Counterparty Core v10.4.2 (2024-??-??)


# Upgrading

This release is not a protocol change and does not require any reparsing.

# ChangeLog


## Protocol Changes


## Bugfixes

* Fix bytes JSON serialization in API v1
* Fix Docker Compose test
* Fix RSFetcher startup
* Fix API v1 regression (rename `unsigned_tx_hex` to `tx_hexh` in `create_*` result)
* Fix JSON serialization of bytes in API v1
* Restart RSFetcher when it stops

## Codebase

* No longer expire mempool entries after 24 hours
* Fetch old mempool entries from Bitcoin Core after node startup

## API

* Expose timestamp field for "first seen in mempool" (for client-side filtering)
* Disable `p2sh` encoding

## CLI


# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
