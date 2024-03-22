# Release Notes - Counterparty Core v10.0.0 (2024-03-??)

Counterparty Core v10.0.0 is a very large release comprising many improvements across different portions of the codebase. “Counterparty Core” is also the new name for the codebase and repository that is the result of a merge between `counterparty-lib`, `counterparty-cli` and a new Rust library, `counterparty-rs`.

# Upgrade Procedure
This release does not include any protocol changes, so there is no deadline for upgrading. However it is **strongly recommended** that all users upgrade as soon as possible, in particular to avoid consensus problems due to non-determinism in previous versions. The Counterparty Core API is also unchanged for this release.

Because this release includes numerous changes to the database schema, a full database rebuild is required and the major version number has been bumped from 9 to 10. Follow the updated installation instructions in the [README](/README.md) to download and install the latest version of Counterparty Core, run `counterparty-server kickstart` (while `bitcoind` is not running), then start the server with `counterparty-server start`. The rebuild should happen automatically, and it should take between 8 and 24 hours hours to complete.

**IMPORTANT** Be certain that you are running the latest version of AddrIndexRs (v0.4.4).


# ChangeLog

## Codebase
* Upgrade from Python 3.7 to Python >= 3.10
* Support Ubuntu 22.04 and macOS officially
* Upgrade packaging system: replace `setup.py` with `pyproject.toml` and use Hatchling as a build system
* Upgrade all pip dependencies to the latest available version
* Rename `counterparty-lib` repository to `counterparty-core`. **NOTE:** The normal redirect for GitHub URLs cannot be implemented.
* Merge the `counterparty-cli` repository into the `counterparty-core` repository
* Add Rust library, `counterparty-rs`, for performance-critical code
* Synchronize versions of `counterparty-rs`, `counterparty-lib` and `counterparty-cli`
* Update URL for hosting bootstrap files to <https://bootstrap.counterparty.io/counterparty-*>
* Update URL for hosting notifications for protocol changes to <https://counterparty.io/protocol_changes.json>


## Documentation and Testing
* Fix test suite, with automated builds on supported operating systems
* Add Github Workflows for building, testing and running automated code scanners:
    * PyLint
    * Bandit
    * CodeQL
    * License Scanner
    * Build and publish Docker image
    * Enable `testnet` test book
* Add checkpoints for `mainnet` up to block 834,500 and for `testnet` up to block 2,580,000
* Rewrite README


## Stability and Correctness
* Fix multiple sources of non-determinism caused by generic exception handling
* Fix source of non-determinism in AddrIndexRs caused by `txid_limit` and `get_oldest_tx`
* Fix consensus break due to missing support for segwit transactions in `kickstart` logic
* Fix crash in software version checking caused by a format change of `protocol_changes.json`


## Deployment
* Rewrite Dockerfile and publish new official Docker images
* Create Docker Compose file as an alternative to Federated Node
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
* Accept config args before and after the command


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
* Activate check software version every 24H
* Add the possibility to reparse from a given block on minor version change
* Add warning with confirmation dialogue to bootstrap command, and `--no-confirm` flag

# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
