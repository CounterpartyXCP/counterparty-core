# Release Notes - Counterparty Core v10.9.0 (2025-01-??)

This release represents a major technical milestone in the development of Counterparty Core: Counterparty no longer has AddrIndexRs as an external dependency. Originally, AddrIndexRs was used for transaction construction, and at the end of 2023 it was accidentally turned into a consensus-critical dependency (causing a number of subsequent consensus breaks and reliability issues). As of today, the only external dependency for a Counterparty node is Bitcoin Core itself.

Counterparty Core will rely on Bitcoin Core by default to provide all of the information it needs for transaction construction (which is not consensus-critical). However this operation will only succeed if the `source` address for the transaction is present in the Bitcoin Core wallet. If it isn't, then Counterparty Core will use some service (either local or remote) which implements the Electrum server API to gather the information it needs. If the address isn't in Bitcoin Core, Counterparty will by default connect to the Blockstream public API. This server is configurable using the `--electrs-url` CLI argument, however, and users can run their own instance of this service locally if they like. A public instance of Electrs is also available at <https://api.counterparty.io:3000>. This service does not need to be trusted in any way, and no private information is ever sent to it.

As a consequence of the removal of the AddrIndexRs dependency, the node storage requirements have effectively decreased from ~300 GB to ~30 GB, dramatically decreasing the cost of node operation. Nodes should also be more reliable and performant generally.

This upgrade notably includes support for `testnet4`, since `testnet3` is no longer usable for testing purposes. A public server is available at <https://testnet4.counterparty.io:44000>.

Finally, this upgrade includes a completely rewritten transaction composition module in preparation for future testing work. The new composer API is fully backwards-compatible, but it now includes additional parameters which make constructing a transaction much more natural. Transactions composed with the new API will use a version byte of `2` instead of `1`.


# Upgrading

This upgrade does not include a protocol change and is not mandatory. After upgrading you can simply delete AddrIndexRs and shrink your disk.

The following transaction construction parameters have been deprecated (but remain functional for now): `fee_per_kb`, `fee_provided`, `dust_return_pubkey`, `return_psbt`, `regular_dust_size`, `multisig_dust_size`, `extended_tx_info`, `old_style_api`, `p2sh_pretx_txid`, `segwit`, `unspent_tx_hash`. These parameters have been superceded by `change_address`, `more_outputs`, `use_all_inputs_set`, `sat_per_vbyte`, `max_fee`, `verbose`, `multisig_pubkey`.


# ChangeLog

## Protocol Changes

## Bugfixes

- Catch errors correctly when composing MPMA sends
- Fix fee calculation for SegWit transactions.
- Fix consensus hashes calculation after a blockchain reorg
- Fix query to fill `issuances.asset_events` field
- Fix `assets_info.supply` field
- Fix `verbose=True` when `give_asset` or `get_asset` contains `asset_longname`
- Don't put null values in API cache
- Fix the Get Sends By Address endpoint, return also `detach` and `move`
- Fix `transactions.transaction_type` field when destination is `1CounterpartyXXXXXXXXXXXXXXXUWLpVr`
- Catch `OverflowError` on API calls
- Fix the `dispensers` table in State DB: include dispensers with same the `source` and `asset` but a different `tx_hash`
- Fix endpoint to get info from raw transaction when block index is not provided
- Fix issue where composed transactions contained `script_pubkey` (lock script) where the `script_sig` (unlock script) should be
- Fix bootstrap when using `--bootstrap-url` flag and don't clean other networks files
- Fix logic for blockchain reorgs of several blocks
- Have the node terminate when the `follow` loop raises an error
- Don't stop the server on "No such mempool or blockchain" error
- Handle correctly RPC call errors from the API
- Don't clean mempool on catchup
- Retry 5 times when getting invalid Json with status 200 from Bitcoin Core


## Codebase

- Remove the AddrIndexRs dependency
- Replace `transaction.py` and `transaction_helper/*` with `composer.py`
- Use the `bitcoin-utils` library for generating transactions
- No longer block the follow process on mempool parsing
- Add a timeout when parsing mempool transaction from ZMQ
- Add a cache for unsupported transactions when parsing raw mempool transactions
- Refactor and optimize bootstrap process, use `zstd` instead of `gzip`
- Trigger State DB refreshes automatically on version bumps
- Use only Rust to deserialize blocks and transactions
- Add `testnet4` support
- Repeat the RPC call to Bitcoin Core indefinitely until it succeeds
- Raise a specific `BlockOutOfRange` error when querying an unknown block
- Add mainnet checkoint for block 879058 and testnet4 checkpoint for block 64493

## API

- Add the following parameters to the transaction composition API:
    * `change_address`: allows defining the change address
    * `more_outputs`: allows adding an arbitrary number of outputs in the form `<value>:<address>` or `<value>:<script_pubkey>`
    * `use_all_inputs_set`: forces the use of all UTXOs provided with `inputs_set`
    * `sat_per_vbyte`: allows defining transaction fees
    * `max_fee`: defines the maximum fees to be paid
    * `verbose`: includes transaction details, notably `data` and `psbt`
    * `multisig_pubkey`: public key allowing the redemption of multisig data outputs
- With `verbose=true` with the transaction constuction API, return a `lock_scripts` field that contains the `script_pubkey` of the UTXOs used by the transaction
- Use the adjusted virtual size to calculate transaction fees
- Do not endlessly retry RPC calls to Bitcoin Core that return an error---immediately return the error to the user
- Throw an error if the BTC quantity in a dispense isn't enough to trigger the dispenser
- Add `get_asset` and `give_asset` parameters for the Get Orders by Asset endpoint
- Add `forward_asset` and `backward_asset` parameters for the Get Order Matches by Asset endpoint
- Add `forward_price` and `backward_price` to order matches results
- Add parameter `exclude_with_oracle` for the Get Dispensers routes
- Add `send_type` field to the `sends` table
- Use `satoshirate_normalized` and `give_quantity_normalized` to calculate `price_normalized`
- Add a parameter `utxo_value` to the `attach.compose()` and `move.compose()` functions
- Add `source_address` and `destination_address` in `sends` table
- Add the following routes:
    * `/v2/addresses/<address>/compose/dividend/estimatexcpfees`
    * `/v2/addresses/<address>/compose/sweep/estimatexcpfees`
    * `/v2/addresses/<address>/compose/attach/estimatexcpfees` (alias of `/v2/compose/attach/estimatexcpfees`)
    * `/v2/destructions`
    * `/v2/addresses/<address>/destructions`
    * `/v2/assets/<asset>/destructions`
- Error messages for UTXOs now contain the reason for the error in parentheses: `invalid UTXOs: <utxo(s)> (<reason>)`

## CLI

- Add `--cache-dir` flag
- Add `severity` field to JSON logs for compatibility
- Add `--refresh-state-db` and `--rebuild-state-db` flags to the `start` command
- Add `--testnet4` flag
- Add the `--electrs-url` parameter for transaction construction
- Temporarily remove `--testcoin` and `--customnet` flags


# Credits

- Ouziel Slama
- Warren Puffet
- Adam Krellenstein
