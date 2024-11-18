# Release Notes - Counterparty Core v10.7.1 (2024-11-??)



# Upgrading


# ChangeLog

## Protocol Changes

## Bugfixes

- Fix CORS headers for OPTIONS requests
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

## Codebase


## API

- Add `sort` parameter for the get holders endpoint (sortable fields: `quantity`, `holding_type`, and `status`)
- Exclude blocks that are not finished being parsed
- Optimize events counts endpoints with `events_count` table
- Add route `/v2/utxos/withbalances` to check if utxos have balances
- Add `type` parameter for get balances endpoints (`all`, `utxo` or `address`)

## CLI

- Support the `SENTRY_SAMPLE_RATE` environment variable to set the Sentry sample rate
- Show help if no actions are provided
- Fix and rename `--check-asset-conservation` flag to `--skip-asset-conservation-check`

# Credits

* droplister 
* Ouziel Slama
* Adam Krellenstein
