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
- Fix dividend distribution to UTXO order after a rollback
- Exclude zero balances when getting balances by address and asset
- Remove lock file from RSFetcher
- Handle correctly RSFetcher invalid version
- Clean shutdown; Correctly close the Ledger DB and State DB (ensure that all connections are closed and that the one with write permission is closed last)
- Fix `get_price` and `give_price` fields: returns 0 not null

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
- Remove `compose_utxo()` function and clean `compose_attach()` and `compose_detach`
- Add `transaction_type` field in `transactions` table
- Clean `block.parse_tx()`; One `TRANSACTION_PARSED` event for each `NEW_TRANSACTION` event
- API Watcher checks reorg if no event to parse and not on each block
- Use `multiprocessing.Event` to stop API process when the Ledger process dies
- Catch up with RPC when ZMQ is late
- Restart RSFetcher when it returns None too many times

## API

- Add `description_locked` in asset info
- Tweak `compose_movetoutxo` documentation
- Add `transaction_type` parameter for Get Transactions endpoints
- Add `transaction_types_count` table in State DB
- Add the following routes:
    - `/v2/transactions/counts`
    - `/v2/blocks/<int:block_index>/transactions/counts`
    - `/v2/addresses/<address>/transactions/counts`
- Add sortable field `asset_longname` in `balances` table
- Add the ability to retrieve balances by asset long name
- When composing an attach / move, use 10,000 sats for the value, rather than 546
- Add `send_type` filter for `sends` table (`send`, `attach`, `move` or `detach`)
- Document how mempool events work
- Add `events` field in transactions results when `verbose=true`

## CLI

- Add `build-state-db` command
- `rollback` and `reparse` commands trigger a re-build of the State DB
- Add current process name and current thread name in logging messages
- Add `--log-exclude-filters` and `--log-include-filters` flags


# Credits

* droplister 
* Ouziel Slama
* Adam Krellenstein
