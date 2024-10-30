# Release Notes - Counterparty Core v10.6.2 (2024-11-??)



# Upgrading

# ChangeLog

## Protocol Changes

- Starting from block X, to detach assets from a UTXO, this UTXO must be used in the Detach transaction. Consequently, the `asset` and `quantity` parameters have been removed: during a Detach, all assets attached to the UTXO are moved to the destination address.

## Bugfixes


## Codebase

- The `transactions.compose()` function accepts a `tx_info` that contains a source in the form of a UTXO instead of an address. If this is the case, this UTXO is mandatory to be used in the transaction.


## API

- Removed `asset` and `quantity` parameters from the `/v2/utxos/<utxo>/compose/detach` route

## CLI


# Credits

* OpenStamp
* DerpHerpenstein
* Ouziel Slama
* Wilfred Denton
* Adam Krellenstein
