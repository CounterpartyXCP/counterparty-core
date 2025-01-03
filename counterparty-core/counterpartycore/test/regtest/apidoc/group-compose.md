**Notes about fee calculation**

To calculate the fees required for a transaction, we do not know the final size of the transaction before signing it.
So the  composer injects fake script_sig and witnesses into the transaction before calculating the adjusted vsize.

Two remarks:

1. this only works for standard scripts

1. the size of DER signatures can vary by a few bytes and it is impossible to predict it. The composer uses a fixed size of 70 bytes so there may be a discrepancy of a few satoshis with the fees requested with `sat_per_vbyte` (for example if a DER signature is 72 bytes with `sat_per_vbyte=2` there will be an error of 4 sats in the calculated fees).

***Deprecated parameters***

The following parameters are deprecated in the new composer and will no longer be supported in a future version:

- `fee_per_kb`: Use `sat_per_vbyte` instead
- `fee_provided`: Ue `max_fee` instead
- `unspent_tx_hash`: Use `inputs_set` instead
- `dust_return_pubkey`: Use `mutlisig_pubkey` instead
- `return_psbt`: Use `verbose` instead
- `regular_dust_size`: Automatically calculated
- `multisig_dust_size`: Automatically calculated
- `extended_tx_info`: API v1 only, use API v2 instead
- `old_style_api`: API v1 only, use API v2 instead
- `p2sh_pretx_txid`: Ignored, P2SH disabled
- `segwit`: Ignored, Segwit automatically detected
