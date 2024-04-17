# Release Notes - Counterparty Core v10.1.1 (2024-04-??)

# ChangeLog

## Bugfixes
* No longer automatically uses `None` for missing arguments during an RPC call to `create_*`. Instead we use the default value defined in the signature of the corresponding `*.compose()` function. If no default value is defined the parameter is mandatory.
* Fix missing events (`NEW_BLOCK` and `NEW_TRANSACTION`) when kickstarting and reparsing. Needs an optional full reparse to update the `messages` table.

## Codebase
* Merge `counterparty-lib` and `counterparty-core` package into `counterparty-core`

## Command-Line Interface
* Replace `--no-check-asset-conservation` by `--check-asset-conservation`

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
