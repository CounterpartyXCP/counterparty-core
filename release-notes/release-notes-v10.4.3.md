# Release Notes - Counterparty Core v10.4.3 (2024-10-05)

This is a minor release with a number of bugfixes and minor improvements to the API.


# Upgrading

This release is not a protocol change and does not require a database reparse.


# ChangeLog

## Bugfixes

- Fix `asset_events` during an asset ownership transfer
- Refresh XCP supply in API DB on startup
- Clean mempool after each block when catching up
- Tweak mempool cleaning in API Watcher
- Fix `AttributeError` on `get_transactions` (API v1)
- Catch `BadRequest` error (API v2)
- Fix off-by-one error in RSFetcher reorg logic

## Codebase

- Add `regtest` and `mainnet` test for the `healthz` endpoint
- Re-enable `check.asset_conservation()` and run it in the background, in a separate thread, both at startup and every 12 hours

## API

- Use the GitHub repository for the Blueprint URL
- Add the `/v2/routes` route in the `/v2/` result
- Add the `addresses` argument to the `/v2/mempool/events` route
- Support prefixed data for `/v2/transactions/unpack`
- Return assets issued and owned by `<address>` in `/v2/addresses/<address>/assets`
- Add the following routes:
    - `/v2/addresses/<address>/assets/issued`
    - `/v2/addresses/<address>/assets/owned`

## CLI


# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
