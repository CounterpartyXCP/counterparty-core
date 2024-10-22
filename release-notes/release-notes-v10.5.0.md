# Release Notes - Counterparty Core v10.5.0 (2024-10-21)

This release includes fixes for a number of critical stability bugs as well as significant performance optimizations for parsing Fair Mint transactions. We have also made many other bugfixes and tweaks to the API and CLI in response to user feedback.

# Upgrading

IMPORTANT: This update requires an automatic reparse from block 865999. However, reparses have become very slow recently due to the high transaction volume. We recommend that users upgrade to this version (even if they were running a pre-release version) either by bootstrapping their databases or by rebuilding them from scratch. You can bootstrap either by running `counterparty-server bootstrap` (if your node is not Dockerized) or by temporarily adding `--catch-up=bootstrap-always` as an argument to `counterparty-server` in your Docker Compose file. If you would like to rebuild your node from scratch, simply delete your existing database and restart the server.


# ChangeLog

## Bugfixes

- Fix critical non-determinism in asset name generation
- Fix subasset name in `issuances` table when created by a fairminter
- Fix check for when a fairmint reachs its hard cap
- Fix missing check for locked asset descriptions
- Fix missing balance check for fairminter creation
- Fix divisibility check for fairminter creation
- Fix description check for fairminter creation
- Fix null fields in fairminters API (`earned_quantity`, `paid_quantity` and `commission`)
- Fix Gunicorn stability issue due to bad signal handling 
- Use a different log file for each Gunicorn worker
- Populate `address_events` table on new fairmint and fairminter
- Have bootstrap respect the `--data-dir` flag
- Add normalized quantities to fairminters and fairmints API

## Codebase

- Redo mandatory reparses for all pre-release versions
- Add missing index to `address_events` table
- Add missing compound index to `issuances` table
- Add missing compound index on `status`, `tx_index` and `asset_longname`
- Optimize database `rowtracer`
- Optimize `ledger.get_last_issuance()`, `ledger.asset_issued_total()` and `ledger.asset_destroyed_total()`

## API

- Have `--force` properly bypass checks that node is caught up
- Have `/v2/blocks/last` return the last-parsed block and not the block currently being parsed
- Change route `/v2/fairminters/<tx_hash>/mints` to `/v2/fairminters/<tx_hash>/fairmints`
- Add the following new routes:
    - `/v2/fairmints`
    - `/v2/fairmints/<tx_hash>`

## CLI

- Add `--max-log-file-size` and `--max-log-file-rotations` flags
- Disable mempool synchronization when `--no-mempool` is passed
- Make the number of Waitress threads configurable
- Make the number of Gunicorn threads per worker configurable
- Log all configuration options on startup at the `DEBUG` level
- Have `--force` skip mandatory reparses
- Add `bootstrap-always` option for the `--catch-up` flag
- Replace `--database-file` flag by `--data-dir` flag
- Have GUnicorn log `TRACE`


# Credits

* Ouziel Slama
* Adam Krellenstein
