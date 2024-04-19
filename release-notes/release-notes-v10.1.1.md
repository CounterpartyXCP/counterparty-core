# Release Notes - Counterparty Core v10.1.1 (2024-04-19)

This is a relatively small release with a number of bugfixes, one of which is critical---in v10.0.x and v10.1.0 there is a bug which can cause nodes to crash upon a blockchain reorganization.


# Upgrading

To upgrade from v10.1.0 manually, you must first uninstall the following Counterparty Core Python packages:

```bash
pip3 uninstall counterparty-rs counterparty-lib counterparty-cli
```

This release contains no protocol changes. The API is unmodified, except that some parameters to `create_*` RPC calls may be required where before they were optional. (See below.)


# ChangeLog

## Bugfixes
* Don't automatically use `None` for missing arguments during an RPC call to `create_*`. Instead use the default value defined in the signature of the corresponding `*.compose()` function. If no default value is defined, the parameter is mandatory.
* Fix missing events (`NEW_BLOCK` and `NEW_TRANSACTION`) when kickstarting and reparsing. To correct the values in the `messages` table, a full reparse is required.
* Fix the current block index after a blockchain reorganisation.
* Fix database shutdown, which caused a recovery of the WAL file on each startup.

## Codebase
* Merge `counterparty-lib` and `counterparty-core` package into `counterparty-core`
* Integrate telemetry with optional Sentry service

## Command-Line Interface
* Replace `--no-check-asset-conservation` with `--check-asset-conservation`
* Disable automatic DB integrity check on startup

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
