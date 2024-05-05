# Release Notes - Counterparty Core v10.1.2 (2024-05-05)

This version of Counterparty Core most importantly marks the release of API v2, a new RESTful API For documentation on the new API, see the [official project documentation](https://docs.counterparty.io/docs/advanced/api-v2/node-api/). 


# Upgrading

The v1 API has been deprecated but not yet removed from the node software. To continue using it, you must: 
- start `counterparty-server` with the flag `--enable-api-v1`
- use port `4100` for mainnet and port `14100` for testnet
- prefix all endpoints with `/v1/`

There is a [migration guide](https://docs.counterparty.io/docs/advanced/api-v2/v1-to-v2/) in the documentation, which specifies equivalences between old and new functionality. 


# ChangeLog

## Bugfixes
* Fix logging of some raw tracebacks (#1715) 
* Retry on `ChunkedEncodingError` with AddrIndexRs; break loop on all errors


## Codebase
* Release API v2; deprecate API v1
* Have API return `ready` if the last block is less than one minute old
* Add an index on the `block_index` field in the `credits` and `debits` tables
* Add `TRACE  level to Python logging
* Add basic anonymous node telemetry

## Command-Line Interface
* Set default and minimum values for Backend Poll Interval to 3.0 seconds
* Update `docker-compose.yml` to use different profiles for `mainnet` and `testnet`
* Check that another process is not connected to the database before starting the server
* Launches database quick check on startup if the database was not been correctly shut down
* Support an additional level of verbosity with the CLI flags `-vv`
* Add the `--no-telemetry` flag to disable node telemetry


# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
