# Release Notes - Counterparty Core v10.6.1 (2024-10-28)


# Upgrading

# ChangeLog

## Protocol Changes

## Bugfixes

- Fix heavy healthz check 
- In `mpma.compose()`, raise a `ComposeError` if `memo` is not a string or `memo_is_hex` is not a boolean
- Update API v2 process to use `config.API_LOG` for log file
- When composing an Attach transaction without a destination address, create a dust output to the source address

## Codebase



## API

- Added `memos` and `memos_are_hex` parameters to the MPMA compose API. When using MPMA sends, one memo must be provided for each destination if these parameters are used.
- Add `/v2/utxos/<utxo>/balances` route
- By default, exclude UTXOs containing balances when composing transactions
- Add `use_utxos_with_balances` and `exclude_utxos_with_balances` parameter to the compose API

## CLI


# Credits

* Ouziel Slama
* Adam Krellenstein
