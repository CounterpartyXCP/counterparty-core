# Release Notes - Counterparty Core v10.4.5 (2024-10-16)

This is a minor release with a number of bugfixes and minor improvements to the API.

# Upgrading

This release is not a protocol change and does not require a database reparse. However a minor bug in the reorg-handling logic was detected and fixed. If your node hashes for block 865699 were not equal to L: 6d64717, TX: f71fa92, M: 8734a58, then you should either rollback to 865690 or restart with the latest bootstrap file. This bug is not believed to have affected node consensus.

# ChangeLog

## Bugfixes

- Fix `TypeError` in `is_server_ready()` function
- Handle `AddressError` in API calls
- Fix RSFetcher pre-fetcher queue
- Fix RSFetcher blockchain reorganization management

## Codebase

- Retry when Bitcon Core returns a 503 error

## API

- Use UTXOs locks when `unspents_set` is used (formerly `custom_inputs`)
- Tweak and fix `asset_events` field (new events `transfer` and `change_description`; `reissuance` only if `quantity` greater than 0; `lock` also when locked with the `lock` argument)
- Add Waitress WSGI server support and make it the default
- Fix missing parentheses in SQL queries
- Fix `dispenser.close_block_index` type in API database
- Set CORS in pre-flight requests

## CLI



# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
