# Release Notes - Counterparty Core v10.6.2 (2024-11-??)



# Upgrading

# ChangeLog

## Protocol Changes

### UTXO Support

This update includes significant changes to the UTXO Support feature, and in particular to address a vulnerability where an atomic swap could be frontrun by a `detach` transaction. Further feedback from the community, in particular the OpenStamps team and DerpHerpenstein have allowed us to simplify the implementation of this feature significantly. With the protocol change, messages with ID 100 will be disabled at the same block that messages with IDs 101 and 102 will be enabled. 12 blocks before this activation block, the functions `compose_attach` and `compose_detach` will be deactivated to avoid having transactions with ID 100 confirmed after activation. The protocol and API have changed as follows:

1. The `attach` function no longer accepts a `destination` parameter. It now accepts an optional `destination_vout` parameter (by default the first non-`OP_RETURN` output). This parameter allows one to designate the index of the output to use as the destination. The transaction is invalid if `destination_vout` does not exist or if it is an `OP_RETURN`.
1. The `destination` parameter of the `detach` function is now optional. If not provided, the default destination is the address corresponding to the UTXO.
1. The `detach` function no longer accepts `asset` and `quantity` parameters: the UTXO is necessarily part of the transaction inputs and all assets are detached from the UTXO.
1. The `detach` function detaches all assets attached to all transaction inputs every time.

In addition to resolving the above frontrunning vulnerability, this update brings a number of improvements:

1. It is now cheaper and easier to construct `attach` and `detach` transactions. The size of messages is always less than 80 bytes, so an `OP_RETURN` output can store all of the necessary data.
1. It is possible to execute several `detach` operations in a single transaction to save fees.
1. It is no longer possible to make a `detach` and a UTXO `move` in the same transaction.
1. A UTXO move with a transaction that contains only a single OP_RETURN output behaves like a `detach`

### Fairminter

When there are fewer tokens remaining than `max_mint_per_tx` in a free Fairminter with hard cap, the last mint receives what remains instead of triggering an error.

## Bugfixes

- Rust fetcher "reporter" worker now takes `rollback_height` into account in its block height ordering check.
- Fixed subasset name handling when creating a fairminter by preserving the `asset_longname` field when `asset=<subasset_name>` is specified and `asset_parent` is not specified.
- Fix `disable_utxo_locks` parameter in compose API
- Fix `gas.get_transaction_count_for_last_period()`

## Codebase

- The `transactions.compose()` function accepts a `tx_info` that contains a source in the form of a UTXO instead of an address. When a UTXO is used, this UTXO must be spent in the corresponding transaction.
- Refactor `compose_moveutxo()` to use this new `transactions.compose()` feature.
- Rust fetcher will now only store entries in its database required for Bitcoin reorganization checks. This greatly reduces the size of the database and significantly increases the speed of the catch-up process.

## API

- For the `compose_detach()` endpoint, the `destination`, `asset` and `quantity` parameters are now optional (`asset` and `quantity` will be ignored after the protocol change).
- For the `compose_attach()` endpoint, there is now a `destination_vout` parameter (and the `destination` parameter will be ignored after protocol change).
- Add `validate` argument to compose API
- Add sortable `get_price` and `give_price` fields in orders
- Add sortable `price` field in dispensers
- Fix `locked` in `asset_info` field
- Add `/v2/bitcoin/transaction/decode` route to proxy bitcoin `decoderawtransaction` method
- `inputs_set` now supports UTXOs in the format `<txid>:<vout>:<amount>:<script_pub_key>`
- Skip transaction sanity check when `validate=false`


## CLI

- Change verbosity of log messages related to blockchain following.


# Credits

* OpenStamp
* DerpHerpenstein
* Ouziel Slama
* Wilfred Denton
* Adam Krellenstein
