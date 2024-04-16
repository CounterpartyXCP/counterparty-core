# Release Notes - Counterparty Core v10.1.0 (2024-04-16)

This release includes fixes for a number of bugs as well as a few regressions in v10.0.x.


# Upgrade Procedure

This upgrade is optional but highly recommended. Upgrading from v10.0.x requires an automatic reparse from block 835,500 on `mainnet`, which should take a few minutes. If you are upgrading directly from v9.x.y, then there will be an automatic full database rebuild, which may take a long time (refer to the release notes for v10.0.0.)

In order to perform a manual installation, you must first uninstall all existing Counterparty Core Python packages:

```bash
pip3 uninstall counterparty-rs counterparty-lib counterparty-cli
```


# ChangeLog

## Bugfixes
* Validate non-empty `block_indexes` in call to `api.get_blocks` (fix for #1621)
* Reproduce order expiration bug in v9.61.x (fix for #1631)
* Fix `get_blocks` call when several block indexes are provided (fix for #1629)
* Fix `create_send` when one of the output is a dispenser (fix for #1119)

## Codebase
* Split out `counterparty-cli` package into `counterparty-core` and `counterparty-wallet` packages
* Implement heavy healthz probe (default to light)
* Automatic code checking and correction with Ruff
* Refactor transaction file singleton to class
* Run `PRAGMA optimize` on shutting down
* Run `PRAGMA quick_check` on database initialization
* Temporary disable asset conservation checking after each new block
* Improve `/healthz` node health check
* Add instrumentation for optional Sentry error and performance monitoring 

## Command-Line Interface
* Rename `counterpary-client` to `counterparty-wallet`
* Add `--skip-db-check` flag to skip database quick check
* Add `--no-mempool` flash to disable mempool parsing

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
