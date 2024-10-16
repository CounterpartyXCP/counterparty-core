# Release Notes - Counterparty Core v10.5.0 (2024-10-18)

This is a hotfix release to fix a non-deterministic bug in asset name generation.

# Upgrading

This update requires an automatic reparse from block 865999.

# ChangeLog

## Bugfixes

- Fix non-deterministic bug in asset name generation
- Fix sub-asset name in `issuances` table when created by a fairminter
- Fix missing index on `address_events.event_index`
- Fix missing balance checking when creating a fairminter
- Fix missing check of locked description
- Fix missing compound index on `status`, `tx_index` and `asset_longname`

## Codebase

- Support several required reparsing by major version
- Optimize database `rowtracer`

## API

## CLI

- Add `--max-log-file-size` and `--max-log-file-rotations` flags


# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
