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
- Fix typo in dispenser error message (`has` -> `have`)
- Fix get balances endpoint when using `sort=asset`

## Codebase


## API

## CLI


# Credits

* OpenStamp
* DerpHerpenstein
* Ouziel Slama
* Wilfred Denton
* Adam Krellenstein
