# Release Notes - Counterparty Core v10.7.0 (2024-11-11)

This is a protocol upgrade that includes a refactor of the UTXO Support feature that fixes some bugs in the original design and simplifies the implementation significantly. It also includes bugfixes for the fair minting functionality in addition to the usual set of miscellaneous improvements to the node API. 

# Upgrading

**This upgrade is mandatory and must be performed before block 871,900 (around November 25th).**
A reparse from the block 869,900 block is mandatory and will be performed automatically.

Composition functions for `attach` and `detach` transactions are disabled between block 871,888 and 871,900.


# ChangeLog

## Protocol Changes

### UTXO Support

This update includes significant changes to the UTXO Support feature, and in particular to address a vulnerability where an atomic swap could be frontrun by a `detach` transaction. Further feedback from the community, in particular the OpenStamps team and DerpHerpenstein, have allowed us to simplify the implementation of this feature significantly. With this protocol change, messages with ID 100 will be disabled at the same block that messages with IDs 101 and 102 are enabled. 12 blocks before this activation block, the functions `compose_attach` and `compose_detach` will be deactivated to avoid having transactions with ID 100 confirmed after activation. The protocol and API have changed as follows:

1. The `attach` function no longer accepts a `destination` parameter. It now accepts an optional `destination_vout` parameter (by default the first non-`OP_RETURN` output). This parameter allows one to designate the index of the output to use as the destination. The transaction is invalid if `destination_vout` does not exist or if it is an `OP_RETURN`.
1. The `destination` parameter of the `detach` function is now optional. If not provided, the default destination is the address corresponding to the UTXO.
1. The `detach` function no longer accepts `asset` and `quantity` parameters. The `detach` function detaches all assets attached to all transaction inputs every time.

In addition to resolving the above frontrunning vulnerability, this update brings a number of improvements:

1. It is now cheaper and easier to construct `attach` and `detach` transactions. The size of messages is always less than 80 bytes, so an `OP_RETURN` output can store all of the necessary data.
1. It is possible to execute several `detach` operations in a single transaction to save fees.
1. It is no longer possible to make a `detach` and a UTXO `move` in the same transaction.
1. A UTXO move with a transaction that contains only a single `OP_RETURN` output behaves like a `detach`
1. Correct the gas calculation for `attach` operations

### Fairminter

1. When there are fewer tokens remaining than `max_mint_per_tx` in a free Fair Minter with a hard cap, the last mint receives whatever remains instead of triggering an error.

1. Fixed a bug that prevents updating an asset's description after a fairminter's automatic closure.


## Bugfixes

- Take Rust fetcher's `rollback_height` into account in the block-height ordering check
- Fix subasset name handling when creating a Fair Minter by preserving the `asset_longname` field when `asset=<subasset_name>` is specified and `asset_parent` is not specified
- Fix `disable_utxo_locks` parameter in compose API
- Fix `gas.get_transaction_count_for_last_period()`
- Fix `update_assets_info()` when a fairmint is parsed into the mempool before the corresponding fairminter
- Fix asset cache initialization
- Takes into account the commission to check if the hard cap is reached
- Soft cap deadline block must be greater than start block
- Fix `legder.get_fairmint_quantities()` function
- Fix `fee_paid`` field when closing fairminter
- Fix `premint_quantity` checking when no hardcap
- Fix `premint_quantity` destruction when soft cap is not reached


## Codebase

- Have `transactions.compose()` accept a `tx_info` that contains a source in the form of a UTXO instead of an address. When a UTXO is used, this UTXO must be spent in the corresponding transaction.
- Refactor `compose_moveutxo()` to use this new `transactions.compose()` feature
- Have the Rust fetcher now only store entries in its database required for Bitcoin reorganization checks. This greatly reduces the size of the database and significantly increases the speed of the catch-up process.
- Support Bitcoin Core 28.0, having updated the Rust Bitcoin dependencies (bitcoin 0.32.4 and bitcoincore-rpc 0.19.0)

## API

- Make the `destination`, `asset` and `quantity` parameters to `compose_detach()` optional (`asset` and `quantity` will be ignored after the protocol change)
- Add a `destination_vout` parameter to the `compose_attach()` endpoint (the `destination` parameter will be ignored after protocol change)
- Add the `validate` argument to compose API
- Add sortable `get_price` and `give_price` fields for orders
- Add sortable `price` field for dispensers
- Fix `locked` in `asset_info` field
- Add `/v2/bitcoin/transaction/decode` route to proxy bitcoin `decoderawtransaction` method
- `inputs_set` now supports UTXOs in the format `<txid>:<vout>:<amount>:<script_pub_key>`
- Skip transaction sanity check when `validate=false`
- Take `asset_longname` into consideration when sorting on `asset` field


## CLI


# Credits

* OpenStamp
* DerpHerpenstein
* Ouziel Slama
* Wilfred Denton
* Adam Krellenstein
