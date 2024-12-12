# Release Notes - Counterparty Core v10.7.2 (2024-11-24)

This is a minor release with a large number of bugfixes and quality-of-life improvements.


# Upgrading

This upgrade is not a protocol change and does not require an automatic reparse.


# ChangeLog

## Protocol Changes

## Bugfixes

- Fix CORS headers for `OPTIONS` requests
- Fix rounding error on normalized quantity
- Use `null` instead of `''` for `asset_longname` and `asset_parent` fields
- Correctly catch `ValueError` in unpack endpoint
- Correctly catch `InvalidBase58Error` in compose endpoints
- Correctly catch `BitcoindRPCError` in get transaction info endpoint
- Fix typo in dispenser error messages (`has` -> `have`)
- Fix get balances endpoint when using `sort=asset`
- Catch all errors when using unpack endpoint with invalid data
- Restart RSFetcher when it returns `None`
- Clean up blocks without ledger hash before starting catch-up
- Don't inject details before publishing events with ZMQ
- Populate `address_events` also with UTXO events (attach, detach and move)
- Fix `compose_movetoutxo` documentation
- Fix `block.close_block_index` field type
- Set `issuances.reset` and `issuances.locked` default value to False instead None 
- Fix error message when trying to compose a dispense with the dispenser address as the source
- Fix utxo balances checking

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

- Add `sort` parameter for the get holders endpoint (sortable fields: `quantity`, `holding_type`, and `status`)
- Exclude blocks that are not finished being parsed
- Optimize events counts endpoints with `events_count` table
- Add route `/v2/utxos/withbalances` to check if utxos have balances
- Add `type` parameter for get balances endpoints (`all`, `utxo` or `address`)
- Add `description_locked` in asset info
- Return a list of invalid UTXOs when possible

## CLI

- Support the `SENTRY_SAMPLE_RATE` environment variable to set the Sentry sample rate
- Show help if no actions are provided
- Fix and rename `--check-asset-conservation` flag to `--skip-asset-conservation-check`
- Add `build-state-db` command
- `rollback` and `reparse` commands trigger a re-build of the State DB

# Credits

* droplister 
* Ouziel Slama
* Adam Krellenstein
