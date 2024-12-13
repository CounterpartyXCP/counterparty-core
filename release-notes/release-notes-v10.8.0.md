# Release Notes - Counterparty Core v10.8.0 (2024-12-12)

This release includes some significant architectural changes to the codebase to improve node stability and performance. Most notably, the data storage requirements of the Counterparty database have been reduced from ~50 GB to ~25 GB. Numerous bugs have been fixed, and all node hosts are recommended to upgrade ASAP.


# Upgrading

This upgrade requires a mandatory, automatic reparse from block 871780.


# ChangeLog

## Protocol Changes

## Bugfixes

- Set `issuances.reset` and `issuances.locked` default values to `False` rather than `None`
- Fix `get_price` and `give_price` fields: return `0` rather than `null`
- Store `utxo_address` in the `address_events` table
- Fix order of results during dividend distribution to UTXOs
- Fix XCP price calculation for fair mints
- Handle RSFetcher version mismatches correctly
- Improve shutdown process and correctly close the Ledger DB and State DB
- Always include all outputs in transactions decoded by RSFetcher
- Fix UTXO balances cache: don't cache `detach`; add cache for `attach`; clean the cache when the balance is empty

## Codebase

- Fix `block.close_block_index` field type
- Eliminate unnecessary database indexes
- Don't rollback or reparse to a block index higher than current block index
- Remove the lockfile for the RSFetcher process
- Replace `counterparty.api.db` with `state.db`
- Rollback State DB from Ledger DB rather than rolling back event-by-event
- Remove duplicate tables from State DB
- Add `issuances.asset_events`, `dispenses.btc_amount` and `mempool.addresses` field to the Ledger DB
- Add version checking for State DB: launch a rollback when a reparse or a rollback is necessary for the Ledger DB
- Refactor functions to refresh `util.CURRENT_BLOCK_INDEX` in `wsgi.py`
- Remove `compose_utxo()` function and clean up `compose_attach()` and `compose_detach`
- Add `transaction_type` field to the`transactions` table
- Refactor `block.parse_tx()`
- Include only one `TRANSACTION_PARSED` event for each `NEW_TRANSACTION` event
- Fix API Watcher reorg checks
- Use `multiprocessing.Event` to stop API process when the Ledger process dies
- Catch up with RPC when ZMQ is late
- Restart RSFetcher when it returns `None` too many times
- Exclude transactions by `SIGHASH`
- Be able to trigger a rollback on a minor version change
- Add several new checkpoints
- Parse raw mempool by batch before following
- Set `BACKEND_RAW_TRANSACTIONS_CACHE_SIZE` to 1000

## API

- Exclude zero balances when retreiving balances by address and asset
- Add `description_locked` to the `asset_info` field
- Add `transaction_type` parameter for `Get Transactions` endpoints
- Add `transaction_types_count` table to the State DB
- Add the following routes:
    - `/v2/transactions/counts`
    - `/v2/blocks/<int:block_index>/transactions/counts`
    - `/v2/addresses/<address>/transactions/counts`
- Add sortable field `asset_longname` to the `balances` table
- Add the ability to retrieve balances by asset longname
- When composing an attach / move, use 10,000 sats for the value, rather than 546
- Add the `send_type` filter for `sends` table (`send`, `attach`, `move` or `detach`)
- Add `events` field to transactions results when `verbose=true`

## CLI

- Have `rollback` and `reparse` commands trigger a re-build of the State DB
- Add current process name and current thread name to log messages
- Add `--log-exclude-filters` and `--log-include-filters` flags


# Credits

- Ouziel Slama
- Warren Puffet
- Adam Krellenstein
