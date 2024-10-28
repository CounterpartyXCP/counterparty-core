# Release Notes - Counterparty Core v10.6.1 (2024-10-??)


# Upgrading

# ChangeLog

## Protocol Changes

## Bugfixes

- Fix heavy healthz check 
- In `mpma.compose()`, raise a `ComposeError` if `memo` is not a string or `memo_is_hex` is not a boolean

## Codebase



## API

- Added `memos` and `memos_are_hex` parameters to the MPMA compose API. When using MPMA sends, one memo must be provided for each destination if these parameters are used.

## CLI


# Credits

* Ouziel Slama
* Adam Krellenstein
