# Release Notes - Counterparty Core v10.7.1 (2024-11-??)



# Upgrading


# ChangeLog

## Protocol Changes

## Bugfixes

- Fix CORS for OPTIONS requests
- Fix rounding error on normalized quantity
- Use `null` instead of '' for `asset_longname` and `asset_parent` fields
- Correctly catch `ValueError` in unpack endpoint
- Correctly catch `InvalidBase58Error` in compose endpoints
- Correctly catch `BitcoindRPCError` in get transaction info endpoint
- Fix typo in dispenser error messages (`has` -> `have`)
- Fix get balances endpoint when using `sort=asset`
- Catch all errors when using unpack endpoint with invalid data
- Restart RSFetcher when it returns None
- Clean up blocks without ledger hash before starting the catch up

## Codebase


## API

- Add `sort` parameter for the get holders endpoint (sortable fields: `quantity`, `holding_type`, and `status`)
- Exclude blocks that are not finished being parsed

## CLI

- Support the `SENTRY_SAMPLE_RATE` environment variable to set the Sentry sample rate

# Credits

* droplister 
* OpenStamp
* DerpHerpenstein
* Ouziel Slama
* Wilfred Denton
* Adam Krellenstein
