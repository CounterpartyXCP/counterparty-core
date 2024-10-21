# Release Notes - Counterparty Core v10.5.0 (2024-10-20)

This is a hotfix release and includes fixes for a number of critical stability bugs in the node software as well as significant performance optimizations for parsing Fair Mint transactions. We have also made numerous other bugfixes and tweaks to the API and CLI in response to user feedback.

# Upgrading

This update requires an automatic reparse from block 865999.

# ChangeLog

## Bugfixes

- Fix critical non-determinism in asset name generation
- Fix subasset name in `issuances` table when created by a fairminter
- Fix check for when a fairmint reachs its hard cap
- Fix missing check for locked asset descriptions
- Fix missing balance check for fairminter creation
- Fix divisibility check for fairminter creation
- Fix description check for fairminter creation
- Use a different log file for each Gunicorn worker
- Populate `address_events` table on new fairmint and fairminter
- Bootstrap respects `--data-dir` flag
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


# Credits

* Ouziel Slama
* Adam Krellenstein


seq 1 30 | xargs -n1 -P10  curl "http://localhost:4000/v2/"