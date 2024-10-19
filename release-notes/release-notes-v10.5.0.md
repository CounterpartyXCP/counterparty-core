# Release Notes - Counterparty Core v10.5.0 (2024-10-19)

This is a hotfix release and includes fixes for a number of critical stability bugs in the nodes software as well as significant performance optimizations for parsing Fair Mint transactions.

# Upgrading

This update requires an automatic reparse from block 865999.

# ChangeLog

## Bugfixes

- Fix non-deterministic bug in asset name generation
- Fix subasset name in `issuances` table when created by a fairminter
- Fix missing balance check for fairminter creation
- Fix missing check of locked description
- Fix missing compound index on `status`, `tx_index` and `asset_longname`
- Fix checking when a fairmint reach the hard cap
- Fix divisibility check when creating a fairminter

## Codebase

- Add missing index to `address_events` table
- Add missing compound index to `issuances` table
- Support several required reparsing by major version
- Optimize database `rowtracer`
- Optimize `ledger.get_last_issuance()`, `ledger.asset_issued_total()` and `ledger.asset_destroyed_total()`

## API

- Have `--force` bypass checks that node is caught up
- Have `/v2/blocks/last` return the last parsed block and not the block currently being parsed

## CLI

- Add `--max-log-file-size` and `--max-log-file-rotations` flags


# Credits

* Ouziel Slama
* Adam Krellenstein
