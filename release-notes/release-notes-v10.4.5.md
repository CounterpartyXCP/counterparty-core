# Release Notes - Counterparty Core v10.4.5 (2024-10-16)

This is a minor release with a number of bugfixes and minor improvements to the API.

# Upgrading

This release is not a protocol change and does not require a database reparse.

# ChangeLog

## Bugfixes

- Fix `TypeError` in `is_server_ready()` function
- Handle `AddressError` in API calls
- Fix RSFetcher pre-fetcher queue
- Fix RSFetcher blockchain reorganization management

## Codebase

## API

- Use UTXOs locks when `unspents_set` is used (formerly `custom_inputs`)
- Tweak and fix `asset_events` field (new events `transfer` and `change_description`; `reissuance` only if `quantity` greater than 0; `lock` also when locked with the `lock` argument)
- Add Waitress wsgi server support and make it the default
- Fix missing parentheses in SQL queries
- Fix `dispenser.close_block_index` type in API database
- Set CORS in preflight requests

## CLI



# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
