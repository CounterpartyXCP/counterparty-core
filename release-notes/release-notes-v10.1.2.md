# Release Notes - Counterparty Core v10.1.2 (2024-05-06)

This version of Counterparty Core marks the release of API v2, a new RESTful API—see the [official project documentation](https://docs.counterparty.io/docs/advanced/api-v2/node-api/). The new API is available at `/v2/`, while the old API is now available at `/v1/` in addition to `/`.


# Upgrading

There is a [guide for migrating from the v1 to the v2 API](https://docs.counterparty.io/docs/advanced/api-v2/v1-to-v2/) in the documentation, which specifies equivalences between old and new functionality. 

This release maintains full backwards-compatibility and includes no protocol changes.


# ChangeLog

## Bugfixes
* Fix logging of some raw tracebacks (#1715) 
* Retry on `ChunkedEncodingError` with AddrIndexRs; break loop on all errors
* Fix bad logging of Rust module panic (#1721)


## Codebase
* Release API v2
* Have both API v1 and v2 return `ready` if the last block is less than one minute old
* Add an index on the `block_index` field in the `credits` and `debits` tables
* Add `TRACE  level to Python logging
* Add basic anonymous node telemetry

## Command-Line Interface
* Set default and minimum values for Backend Poll Interval to 3.0 seconds
* Update `docker-compose.yml` to use different profiles for `mainnet` and `testnet`
* Check that another process is not connected to the database before starting the server
* Launch database quick check on startup if the database has not been correctly shut down
* Support an additional level of verbosity with the CLI flags `-vv`
* Add the `--no-telemetry` flag to disable node telemetry


# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
