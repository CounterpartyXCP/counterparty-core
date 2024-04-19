# Release Notes - Counterparty Core v10.1.1 (2024-04-19)

# ChangeLog

## Bugfixes
* Don't automatically use `None` for missing arguments during an RPC call to `create_*`. Instead use the default value defined in the signature of the corresponding `*.compose()` function. If no default value is defined, the parameter is mandatory.
* Fix missing events (`NEW_BLOCK` and `NEW_TRANSACTION`) when kickstarting and reparsing. To correct the `messages` table, a full reparse is required.
* Fix current block index after a Blockchain reorganisation.
* Fix database shutdown which caused a recovery of the WAL file on each startup.

## Codebase
* Merge `counterparty-lib` and `counterparty-core` package into `counterparty-core`
* Integrate telemetry with Sentry

## Command-Line Interface
* Replace `--no-check-asset-conservation` by `--check-asset-conservation`

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
