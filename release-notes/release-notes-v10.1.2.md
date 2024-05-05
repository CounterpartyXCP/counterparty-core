# Release Notes - Counterparty Core v10.1.2 (2024-05-05)

This release enables the new ReST API and basic node telemetry.

# Upgrading

To continue using the old API you must:
- start `counterparty-server` with the flag `--enable-api-v1`
- use port `4100` for mainnet and port `14100` for testnet
- prefix all endpoints with `/v1/`
To easily migrate to the new API, an equivalence table is available in the documentation.

# ChangeLog

## Bugfixes
* Fix logging of some raw tracebacks (#1715) 
* Retry on `ChunkedEncodingError` with AddrIndexRs; break loop on all errors


## Codebase
* New ReST API
* APIs return ready if the last block is less than 1 minute old
* Add an index on the `block_index` field in the `credits` and `debits` tables
* Add TRACE level to python logging
* Add basic node telemetry

## Command-Line Interface
* Set default and minimum values for Backend Poll Interval to 3.0 seconds
* Update `docker-compose.yml` to use different profiles for `mainnet` and `testnet`
* Checks that another process is not connected to the database before starting the server
* At startup, launches a quick check if the database has not been correctly closed
* The `--verbose` flag can be repeated to increase verbosity, `-vv` is also supported
* Add `--no-telemetry` flag to not send anonymous node telemetry data to telemetry server

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
