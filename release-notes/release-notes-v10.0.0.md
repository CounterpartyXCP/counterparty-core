# Release Notes - Counterparty Core v10.0.0 (2024-03-??)

Counterparty Core v10.0.0 is a very large release comprising many different improvements across large portions of the codebase. “Counterparty Core” is also the new name for the codebase and repository that is the result of a merge between `counterparty-lib`, `counterparty-cli` and a new Rust library, `counterparty-rs`.

This release does not include any protocol changes, so there is no deadline for upgrading. However it is **strongly recommended** that all users upgrade as soon as possible, in particular to avoid consensus problems due to non-determinism in previous versions. The Counterparty Core API is also unchanged for this release.

# Upgrade Procedure
Because this release includes numerous changes to the database schema, a full database rebuild is required and the major version number has been bumped from 9 to 10. Follow the updated installation instructions in the [../README.md](README) to download and install the latest version of Counterparty Core, run `counterparty-server kickstart`, then start the server with `counterparty-server start`. The rebuild should happen automatically, and it should take between 8 and 24 hours hours to complete.

**IMPORTANT** Be certain that your instance of AddrIndexRs is running with the configuration parameter `TX_LIMIT=100` (the default value). This parameter may be set in an environment variable, in the CLI, or with a config file, and the value that AddrIndexRs is using will be visible on startup when the service is run with the option `-vvv`. This is a *consensus-critical* parameter, and if it is set incorrectly, your Counterparty node will not run.


# ChangeLog

## Codebase
* Upgrade from Python 3.7 to Python >= 3.10
* Officially support Ubuntu 22.04 and macOS
* Upgrade packaging system: replace `setup.py` with `pyproject.toml` and use Hatchling as a build system
* Upgrade all pip dependencies to the latest available version
* Rename `counterparty-lib` repository to `counterparty-core`. **NOTE:** the normal redirect for GitHub URLs cannot be implemented
* Merge the `counterparty-cli` repository into the `counterparty-core` repository
* Add Rust library, `counterparty-rs`, for performance-critical code
* Synchronized versions of `counterparty-rs`, `counterparty-lib` and `counterparty-cli`
* Update URL for hosting bootstrap files to <https://bootstrap.counterparty.io/counterparty-*>
* Update URL for hosting notifications for protocol changes to <https://counterparty.io/protocol_changes.json>


## Documentation and Testing
* Fix test suite, with automated builds on supported operating systems
* Add Github Workflows for building, testing and running automated code scanners:
    * PyLint
    * Bandit
    * CodeQL
    * License Scanner
* Add checkpoints for `mainnet` up to block 825,000 and for `testnet` up to block 2,540,000
* Rewrite README


## Stability and Correctness
* Fix multiple sources of non-determinism caused by generic exception handling
* Fix consensus break due to missing support for segwit transactions in `kickstart` logic
* Fix crash in software version checking caused by a format change of `protocol_changes.json`


## Deployment
* Rewrite Dockerfile and publish new official Docker images
* Implement `simplenode` Docker Compose file, an alternative to Federated Node
* Change default `bitcoind` user from `bitcoinrpc` to `rpc`
* Changed default port for communication with AddrIndexRs to `8432` (and `81432` for `testnet`)


## Command-Line Interface
* Disable console logs except for with `counterparty-server start`
* Show fancy spinners for all discrete operations
* Rename `checkdb` command to `check-db`
* Rename `debugconfig` to `show-config`; clean up output
* Don't log values for transactions except with `--verbose` (for performance)
* Move noisy log messages to `DEBUG`
* Always log to a file, unless `--no-log-files` is set
* Fix and refactor `log.set_up()`
* Improve thread shutdown logic


## Refactoring and Performance Optimizations
* Rewrite `kickstart`, splitting work across two Python processes using shared memory and queue for communication
* Activate write-ahead-log in SQLite and implement `apsw.best_pratices()`, improving performance and fixing crashes from deadlocks
* Fix database version checking which launched a rebuilds instead of rollbacks / reparses
* Add numerous missing database indexes
* Fix collisions between existing database indexes
* DRY and refactor database index creation. 
* DRY and isolate all SQL queries in `ledger.py` (except first insertion still inside contracts)
* Fix database integrity check and re-include assert conservation check
* Migrate to log-structured database for simpler and faster rollback and reparse
    * Add `block_index` field to the `balances` table
    * Remove all `UPDATE` queries—use the `ledger.insert_update()` function, which adds a new row with a new `block_index`
    * Update all `SELECT` queries—always use `MAX(rowid)`
    * Remove the `undolog` completely
    * Implement `rollback` and `reparse` by deleting table rows using the `block_index` field
* Migrate performance-critical logic to Rust library, `counterparty-rs`
    * `b58_encode()` and `b58_decode()`
    * `script_to_asm()`
    * `script_to_address()`
    * `inverse_hash()`
* Refactor connection logic for AddrIndexRs RPC
* Pre-fetch blocks with multiple threads for `start`
* DRY and refactor `get_tx_info*()` functions
    * Isolate transaction parsing inside `gettxinfo.py` module
    * Heavily refactor code; eliminate unused code blocks
    * Isolate dispenser logic in `get_dispensers_outputs()` and `get_dispensers_tx_info()`


# Credits
* Ouziel Slama
* Adam Krellenstein