# Release Notes - Counterparty Core v10.6.2 (2024-11-??)



# Upgrading

# ChangeLog

## Protocol Changes

This update includes major changes in UTXOS support. The previous system was designed to have maximum flexibility, in particular to be able to detach only part of the assets attached to a UTXO. However, as OpenStamp pointed out, this feature allows an Atomic Swap to be front runned by a detach. In addition to this vulnerability many interesting suggestions have been made by OpenStamp and the community.
We therefore took advantage of all these updates to separate the `utxo.py` contract (ID 100) into two separate contracts: `attach.py` (ID 101) and `detach.py` (ID 102). Indeed in its original design the two functions had almost the same signature and the same code which is no longer the case.
Messages with ID 100 will be disabled at the same block where messages with IDs 101 and 102 will be enabled.
12 blocks before activation the functions `compose_attach` and `compose_detach` will be deactivated to avoid having transactions with ID 100 confirmed after activation.

Here are the changes that will be active after activating the protocol change:

1. The `attach` function no longer accepts a `destination` parameter. By default, the first non-OP_RETURN output is the destination.
1. The `attach` function now accepts an optional `destination_vout` parameter. This parameter allows you to designate the number of the output to use as the destination. The transaction is invalid if `destination_vout` does not exist or if it is an `OP_RETURN`
1. The `detach` function no longer accepts the `asset` and `quantity` parameters: the UTXO is necessarily part of the transaction inputs and all assets are detached from the UTXO.
1. The `destination` parameter of the `detach` function is now optional. If not provided, the default destination is the address corresponding to the UTXO.
1. The `detach` function detaches the assets attached to all transaction inputs.

The main consequences of this update are:

1. It is no longer possible to front run a swap with a detach.
1. Transaction attach and detach are cheaper and easier to construct. In fact, the size of messages is systematically less than 80 and an OP_RETURN is therefore sufficient.
1. It is possible to make several detachments in a single transaction to save fees.
1. It is no longer possible to make a detach and a UTXO move in the same transaction.

## Bugfixes


## Codebase

- The `transactions.compose()` function accepts a `tx_info` that contains a source in the form of a UTXO instead of an address. If this is the case, this UTXO is mandatory to be used in the transaction.
- Refactor `compose_moveutxo` to use this new `transactions.compose()` feature.


## API

- In compose detach function, make `destination`, `asset` and `quantity` parameters optionals (`asset` and `quantity` will be ignored after protocol change)
- In compose attach function add `destination_vout` parameter (`destination` will be ignored after protocol change)

## CLI


# Credits

* OpenStamp
* DerpHerpenstein
* Ouziel Slama
* Wilfred Denton
* Adam Krellenstein
