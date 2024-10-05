# Release Notes - Counterparty Core v10.4.3 (2024-10-05)


# Upgrading

This release is not a protocol change and does not require any reparsing. A regression in the v1 API has been resolved.

# ChangeLog


## Bugfixes

- Fix `asset_events` during an asset ownership transfer
- Refresh XCP supply in API DB on startup
- Clean mempool after each block when catching up
- Tweak mempool cleaning in API Watcher
- Fix `AttributeError` on `get_transactions` (API v1)
- Catch `BadRequest` error (API v2)

## Codebase

- Add `regtest` and `mainnet` test for `healthz` endpoint
- Execute `check.asset_conservation()` in the background in a separate thread, at startup, and then every 12 hours

## API

- Use of the Github repository for the Blueprint URL
- Addition of the `/v2/routes` route in the `/v2/` result
- Addition of the `addresses` argument for the `/v2/mempool/events` route
- `/v2/transactions/unpack` now supports prefixed data
- `/v2/addresses/<address>/assets` now returns assets issued or owned by `<address>`
- Addition of the following routes:
    - `/v2/addresses/<address>/assets/issued`
    - `/v2/addresses/<address>/assets/owned`

## CLI


# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
