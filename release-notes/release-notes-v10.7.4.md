# Release Notes - Counterparty Core v10.7.4 (2024-12-??)


# Upgrading


# ChangeLog

## Protocol Changes

## Bugfixes

- Fix `block.close_block_index` field type
- Set `issuances.reset` and `issuances.locked` default value to False instead None 
- Save also `utxo_address` in `address_events` table
- Clean useless indexes
- Don't rollback or reparse to a block index higher than current block index

## Codebase

- Replace `counterparty.api.db` with `state.db`
- Add `issuances.asset_events`, `dispenses.btc_amount` and `mempool.addresses` field in Ledger DB
- Remove duplicate table from `state.db`
- Add `api/dbbuilder.py` module and refactor migrations to build `state.db`
- Use migrations to rollback `state.db`
- Remove rollback event by event in `state.db`
- Add version checking for `state.db`: launch a rollback when a reparse or a rollback is necessary for the Ledger DB
- Use `event_hash` to detect Blockchain reorganization and launch a rollback of `state.db`
- Refactor functions to refresh `util.CURRENT_BLOCK_INDEX` in `wsgi.py`

## API

- Add `description_locked` in asset info
- Tweak `compose_movetoutxo` documentation

## CLI

- Add `build-state-db` command
- `rollback` and `reparse` commands trigger a re-build of the State DB

# Credits

* droplister 
* Ouziel Slama
* Adam Krellenstein
