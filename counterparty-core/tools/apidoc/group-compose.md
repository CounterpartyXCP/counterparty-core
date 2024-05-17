**Notes about optional parameter `encoding`.**

By default the default value of the `encoding` parameter detailed above is `auto`, which means that `counterparty-server` automatically determines the best way to encode the Counterparty protocol data into a new transaction. If you know what you are doing and would like to explicitly specify an encoding:

- To return the transaction as an **OP_RETURN** transaction, specify `opreturn` for the `encoding` parameter.
   - **OP_RETURN** transactions cannot have more than 80 bytes of data. If you force OP_RETURN encoding and your transaction would have more than this amount, an exception will be generated.

- To return the transaction as a **multisig** transaction, specify `multisig` for the `encoding` parameter.
    - `pubkey` should be set to the hex-encoded public key of the source address.
    - Note that with the newest versions of Bitcoin (0.12.1 onward), bare multisig encoding does not reliably propagate. More information on this is documented [here](https://github.com/rubensayshi/counterparty-core/pull/9).

- To return the transaction as a **pubkeyhash** transaction, specify `pubkeyhash` for the `encoding` parameter.
    - `pubkey` should be set to the hex-encoded public key of the source address.

- To return the transaction as a 2 part **P2SH** transaction, specify `P2SH` for the encoding parameter.
    - First call the `create_` method with the `encoding` set to `P2SH`.
    - Sign the transaction as usual and broadcast it. It's recommended but not required to wait the transaction to confirm as malleability is an issue here (P2SH isn't yet supported on segwit addresses).
    - The resulting `txid` must be passed again on an identic call to the `create_` method, but now passing an additional parameter `p2sh_pretx_txid` with the value of the previous transaction's id.
    - The resulting transaction is a `P2SH` encoded message, using the redeem script on the transaction inputs as data carrying mechanism.
    - Sign the transaction following the `Bitcoinjs-lib on javascript, signing a P2SH redeeming transaction` section
    - **NOTE**: Don't leave pretxs hanging without transmitting the second transaction as this pollutes the UTXO set and risks making bitcoin harder to run on low spec nodes.
