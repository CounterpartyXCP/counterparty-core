# Release Notes - Counterparty Core v10.1.2 (2024-04-??)



# Upgrading

To continue using the old API you must:
- start `counterparty-server` with the flag `--enable-api-v1`
- replace port `4100` with port `4000` for mainnet and port `14000` with port `14100` for testnet
- prefix all endpoints with `/v1/`
To easily migrate to the new API, an equivalence table is available in the documentation

# ChangeLog

## Bugfixes
* Fix logging of some raw tracebacks (#1715) 
* Retry on `ChunkedEncodingError` with AddrIndexRs; break loop on all errors


## Codebase
* New ReST API

## Command-Line Interface
* Set default and minimum values for Backend Poll Interval to 3.0 seconds
* Updates `docker-compose.yml` to be able to run a `mainnet` node and a `testnet` node on the same machine

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
