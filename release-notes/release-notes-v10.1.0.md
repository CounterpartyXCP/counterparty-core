# Release Notes - Counterparty Core v10.1.0 (2024-04-??)

# ChangeLog

## Bugfixes
* Validate non-empty `block_indexes` in call to `api.get_blocks` (fix for #1621)
* Reproduce order expiration bug in v9.61 (fix for #1631)
* Fix `get_blocks` call when several block indexes are provided (fix for #1629)

## Codebase
* Split out `counterparty-cli` package into `counterparty-core` and `counterparty-wallet` packages
* Implement light / heavy healthz probes
* Automatic code checking and correction with Ruff
* Refactor transaction file singleton to class

## Command-Line Interface
* Rename `counterpary-client` to `counterparty-wallet`

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
