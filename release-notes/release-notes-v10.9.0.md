# Release Notes - Counterparty Core v10.9.0 (2024-12-??)


# Upgrading

# ChangeLog

# Composer V2

- Replacement of `transaction.py` and `transaction_helper/*` with `composer.py`
- No more dependency on Addrindexrs, prioritizing the use of Bitcoin Core to retrieve UTXOs or search for a public key, and then with Electr if it is configured.
- Does not endlessly retry RPC calls to Bitcoin Core that return an error but immediately returns the error to the user
- Use of the `bitcoin-utils` library to generate transactions
- API backward compatible with the old composer
- Addition of the following parameters:
    * `change_address`: allows defining the change address
    * `more_outputs`: allows adding an arbitrary number of outputs in the form `<value>:<address>` or `<value>:<script_pubkey>`
    * `use_all_inputs_set`: forces the use of all UTXOs provided with `inputs_set`
    * `sat_per_vbyte`: allows defining transaction fees
    * `max_fee`: defines the maximum fees to be paid
    * `verbose`: includes transaction details, notably `data` and `psbt`
    * `multisig_pubkey`: public key allowing the redemption of multisig data outputs
- The following parameters are deprecated but still work: `fee_per_kb`, `fee_provided`, `dust_return_pubkey`, `return_psbt`, `regular_dust_size`, `multisig_dust_size`, `extended_tx_info`, `old_style_api`, `p2sh_pretx_txid`, `segwit`, `unspent_tx_hash`
- Composed transactions no longer contain the `script_pubkey` (lock script) where the `script_sig` (unlock script) should be.
- With `verbose=true`, the composer also returns a `lock_scripts` field that contains the `script_pubkey` of the UTXOs used by the transaction.
- Composed transactions use a version byte 2 instead of version 1
- Error messages for UTXOs now contain the reason for the error in parentheses: `invalid UTXOs: <utxo(s)> (<reason>)`
- Fix fee calculation for Segwit transaction. Use "Adjusted VSize" to calculate fee.


## Protocol Changes

## Bugfixes

- Fix endpoint to get info from raw transaction when block index is not provided
- Catch errors correctly when composing MPMA send
- Fix consensus hashes calculation after a Blockchain reorg
- Fix query to fill `issuances.asset_events` field
- Fix `assets_info.supply` field
- Fix `verbose=True` when `give_asset` or `get_asset` contain an `asset_longname`
- Don't put null values in API cache
- Fix Get Sends By Address endpoint, return also `detach` and `move`
- Fix `transactions.transaction_type` field when destination is `1CounterpartyXXXXXXXXXXXXXXXUWLpVr`
- Catch `OverflowError` on API calls
- Fix `dispensers` table in State DB: include dispensers with same `source` and `asset` but different `tx_hash`

## Codebase

- Refactor raw mempool parsing; Don't block following
- Add a timeout to parse mempool transaction from ZMQ
- Add cache for unsupported transactions when parsing raw 
- Refactor and optimize bootstrap process, using `zstd` instead of `gzip`
- Remove Addrindexrs dependency: mock `get_oldest_tx()`, use Electrs to get utxos and address history for transaction composition
- Be able to trigger automatic State DB refresh on version change
- Use only Rust to deserialize blocks and transactions

## API

- Throw Error if BTC Quantity in Dispense isn't enough to Trigger Dispenser
- Add `get_asset` and `give_asset` parameters for get orders by asset endpoint
- Add `forward_asset` and `backward_asset` parameters for get order matches by asset endpoint
- Add `forward_price` and `backward_price` in order matches results
- Add parameter `exclude_with_oracle` for get dispensers routes
- Add `send_type` field in `sends` table
- Use `satoshirate_normalized` and `give_quantity_normalized` to calculate `price_normalized`
- Add a parameter `utxo_value` to the `attach.compose()` and `move.compose()` functions
- Add `source_address` and `destination_address` in `sends` table
- Use by default Blockstream for Electrs API

## CLI

- Add `--cache-dir` flag
- Add `severity` field to JSON logs for compatibility
- Add `--refresh-state-db` and `--rebuild-state-db` flags for `start` command
- Check if `--electrs-url` is a valid url

# Credits

- Ouziel Slama
- Warren Puffet
- Adam Krellenstein
