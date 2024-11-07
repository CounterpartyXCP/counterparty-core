# Release Notes - Counterparty Core v10.6.1 (2024-10-28)

This is a minor release to address a few small bugs in the v2 API, especially for MPMA, and to fill out API support for the management of assets attached to UTXOs.


# Upgrading

This upgrade is not a protocol change and no automatic reparse is necessary.


# ChangeLog

## Protocol Changes

## Bugfixes

- Fix heavy `healthz` check 
- Raise a `ComposeError` in `mpma.compose()` if `memo` is not a string or if `memo_is_hex` is not a boolean
- Send API v2 log messages to the `config.API_LOG` logfile
- Create a dust output when attaching an asset to a UTXO without a destination address
- Fix dust value in compose move to UTXO

## Codebase


## API

- Add `memos` and `memos_are_hex` parameters to the MPMA compose API. When using MPMA sends, one memo must be provided for each destination if these parameters are used.
- Add the `/v2/utxos/<utxo>/balances` route
- Exclude UTXOs containing balances by default when composing transactions
- Add `use_utxos_with_balances` and `exclude_utxos_with_balances` parameters to the compose API

## CLI


# Credits

* Ouziel Slama
* Adam Krellenstein
