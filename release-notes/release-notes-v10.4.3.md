# Release Notes - Counterparty Core v10.4.3 (2024-??-??)


# Upgrading


# ChangeLog

## Protocol Changes


## Bugfixes

- Fix `asset_events` during an asset ownership transfer

## Codebase


## API

## API

- Use of the Github repository for the Blueprint URL
- Addition of the `/v2/routes` route in the `/v2/` result
- Addition of the `addresses` argument for the `/v2/mempool/events` route
- `/v2/transactions/unpack` now supports prefixed data
- `/v2/addresses/<address>/assets` now returns assets issued and owned by `<address>`
- Addition of the following routes:
    - `/v2/addresses/<address>/assets/issued`
    - `/v2/addresses/<address>/assets/owned`

## CLI


# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
