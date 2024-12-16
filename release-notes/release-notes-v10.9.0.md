# Release Notes - Counterparty Core v10.9.0 (2024-12-??)


# Upgrading

# ChangeLog

## Protocol Changes

## Bugfixes

- Fix endpoint to get info from raw transaction when block index is not provided
- Catch errors correctly when composing MPMA send

## Codebase

- Refactor raw mempool parsing; Don't block following
- Add a timeout to parse mempool transaction from ZMQ

## API

- Throw Error if BTC Quantity in Dispense isn't enough to Trigger Dispenser

## CLI

# Credits

- Ouziel Slama
- Warren Puffet
- Adam Krellenstein
