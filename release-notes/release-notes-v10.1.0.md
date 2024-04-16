# Release Notes - Counterparty Core v10.1.0 (2024-04-??)

Note: This update requires a reparse from block 835,500. (If you are upgrading from v9.x.y, then you need a full database rebuild.)

# ChangeLog

## Bugfixes
* Validate non-empty `block_indexes` in call to `api.get_blocks` (fix for #1621)
* Reproduce order expiration bug in v9.61 (fix for #1631)
* Fix `get_blocks` call when several block indexes are provided (fix for #1629)
* Fix `create_send` when one of the output is a dispenser (fix for #1119)

## Codebase
* Split out `counterparty-cli` package into `counterparty-core` and `counterparty-wallet` packages
* Implement light / heavy healthz probes
* Automatic code checking and correction with Ruff
* Refactor transaction file singleton to class
* Run `PRAGMA optimize` on shutting down
* Run `PRAGMA quick_check` on database initialization
* Add `--skip-db-check` flag to skip database quick check

## Command-Line Interface
* Rename `counterpary-client` to `counterparty-wallet`

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
