import binascii
import decimal

from counterpartycore.lib import (
    backend,
    config,
    deserialize,
    exceptions,
    gettxinfo,
    message_type,
    messages,
    script,
    transaction,
    util,
)

D = decimal.Decimal

COMPOSABLE_TRANSACTIONS = [
    "bet",
    "broadcast",
    "btcpay",
    "burn",
    "cancel",
    "destroy",
    "dispenser",
    "dispense",
    "dividend",
    "issuance",
    "versions.mpma",
    "order",
    "send",
    "sweep",
    "utxo",
    "fairminter",
    "fairmint",
]

COMPOSE_COMMONS_ARGS = {
    "encoding": (str, "auto", "The encoding method to use"),
    "fee_per_kb": (
        int,
        None,
        "The fee per kilobyte of transaction data constant that the server uses when deciding on the dynamic fee to use (in satoshis)",
    ),
    "regular_dust_size": (
        int,
        config.DEFAULT_REGULAR_DUST_SIZE,
        "Specify (in satoshis) to override the (dust) amount of BTC used for each non-(bare) multisig output.",
    ),
    "multisig_dust_size": (
        int,
        config.DEFAULT_MULTISIG_DUST_SIZE,
        "Specify (in satoshis) to override the (dust) amount of BTC used for each (bare) multisig output",
    ),
    "pubkey": (
        str,
        None,
        "The hexadecimal public key of the source address (or a list of the keys, if multi-sig). Required when using encoding parameter values of multisig or pubkeyhash.",
    ),
    "allow_unconfirmed_inputs": (
        bool,
        False,
        "Set to true to allow this transaction to utilize unconfirmed UTXOs as inputs",
    ),
    "fee": (
        int,
        None,
        "If you'd like to specify a custom miners' fee, specify it here (in satoshis). Leave as default for the server to automatically choose",
    ),
    "fee_provided": (
        int,
        0,
        "If you would like to specify a maximum fee (up to and including which may be used as the transaction fee), specify it here (in satoshis). This differs from fee in that this is an upper bound value, which fee is an exact value",
    ),
    "unspent_tx_hash": (
        str,
        None,
        "When compiling the UTXOs to use as inputs for the transaction being created, only consider unspent outputs from this specific transaction hash. Defaults to null to consider all UTXOs for the address. Do not use this parameter if you are specifying custom_inputs",
    ),
    "dust_return_pubkey": (
        str,
        None,
        "The dust return pubkey is used in multi-sig data outputs (as the only real pubkey) to make those the outputs spendable. By default, this pubkey is taken from the pubkey used in the first transaction input. However, it can be overridden here (and is required to be specified if a P2SH input is used and multisig is used as the data output encoding.) If specified, specify the public key (in hex format) where dust will be returned to so that it can be reclaimed. Only valid/useful when used with transactions that utilize multisig data encoding. Note that if this value is set to false, this instructs counterparty-server to use the default dust return pubkey configured at the node level. If this default is not set at the node level, the call will generate an exception",
    ),
    "disable_utxo_locks": (
        bool,
        False,
        "By default, UTXOs utilized when creating a transaction are 'locked' for a few seconds, to prevent a case where rapidly generating create_ calls reuse UTXOs due to their spent status not being updated in bitcoind yet. Specify true for this parameter to disable this behavior, and not temporarily lock UTXOs",
    ),
    "extended_tx_info": (
        bool,
        False,
        "When this is not specified or false, the create_ calls return only a hex-encoded string. If this is true, the create_ calls return a data object with the following keys: tx_hex, btc_in, btc_out, btc_change, and btc_fee",
    ),
    "p2sh_pretx_txid": (
        str,
        None,
        "The previous transaction txid for a two part P2SH message. This txid must be taken from the signed transaction",
    ),
    "segwit": (bool, False, "Use segwit"),
    "confirmation_target": (
        int,
        config.ESTIMATE_FEE_CONF_TARGET,
        "The number of blocks to target for confirmation",
    ),
    "return_psbt": (
        bool,
        False,
        "Construct a PSBT instead of a raw transaction hex",
    ),
    "exclude_utxos": (
        str,
        None,
        "A comma-separated list of UTXO txids to exclude when selecting UTXOs to use as inputs for the transaction being created",
    ),
    "return_only_data": (
        bool,
        False,
        "Return only the data part of the transaction",
    ),
    "custom_inputs": (
        str,
        None,
        "A comma-separated list of UTXOs (`<txid>:<vout>`) to use as inputs for the transaction being created",
    ),
}


def split_compose_params(**kwargs):
    transaction_args = {}
    common_args = {}
    private_key_wif = None
    for key, value in kwargs.items():
        if key in COMPOSE_COMMONS_ARGS:
            common_args[key] = value
        elif key == "privkey":
            private_key_wif = value
        else:
            transaction_args[key] = value
    return transaction_args, common_args, private_key_wif


def get_key_name(**construct_args):
    if construct_args.get("return_only_data"):
        return "data"
    if construct_args.get("return_psbt"):
        return "psbt"
    return "rawtransaction"


def compose(db, name, params, **construct_args):
    if name not in COMPOSABLE_TRANSACTIONS:
        raise exceptions.TransactionError("Transaction type not composable.")
    rawtransaction, data = transaction.compose_transaction(
        db,
        name=name,
        params=params,
        **construct_args,
    )
    if construct_args.get("return_only_data"):
        return {"data": data}
    return {
        get_key_name(**construct_args): rawtransaction,
        "params": params,
        "name": name.split(".")[-1],
        "data": data,
    }


def compose_bet(
    db,
    address: str,
    feed_address: str,
    bet_type: int,
    deadline: int,
    wager_quantity: int,
    counterwager_quantity: int,
    expiration: int,
    leverage: int = 5040,
    target_value: int = None,
    **construct_args,
):
    """
    Composes a transaction to issue a bet against a feed.
    :param address: The address that will make the bet (e.g. $ADDRESS_1)
    :param feed_address: The address that hosts the feed to be bet on (e.g. $ADDRESS_2)
    :param bet_type: Bet 0 for Bullish CFD (deprecated), 1 for Bearish CFD (deprecated), 2 for Equal, 3 for NotEqual (e.g. 2)
    :param deadline: The time at which the bet should be decided/settled, in Unix time (seconds since epoch) (e.g. 3000000000)
    :param wager_quantity: The quantities of XCP to wager (in satoshis, hence integer) (e.g. 1000)
    :param counterwager_quantity: The minimum quantities of XCP to be wagered against, for the bets to match (in satoshis, hence integer) (e.g. 1000)
    :param expiration: The number of blocks after which the bet expires if it remains unmatched (e.g. 100)
    :param leverage: Leverage, as a fraction of 5040
    :param target_value: Target value for Equal/NotEqual bet (e.g. 1000)
    """
    params = {
        "source": address,
        "feed_address": feed_address,
        "bet_type": bet_type,
        "deadline": deadline,
        "wager_quantity": wager_quantity,
        "counterwager_quantity": counterwager_quantity,
        "target_value": target_value,
        "leverage": leverage,
        "expiration": expiration,
    }
    return compose(db, "bet", params, **construct_args)


def compose_broadcast(
    db, address: str, timestamp: int, value: float, fee_fraction: float, text: str, **construct_args
):
    """
    Composes a transaction to broadcast textual and numerical information to the network.
    :param address: The address that will be sending (must have the necessary quantity of the specified asset) (e.g. $ADDRESS_1)
    :param timestamp: The timestamp of the broadcast, in Unix time (e.g. 4003903985)
    :param value: Numerical value of the broadcast (e.g. 100)
    :param fee_fraction: How much of every bet on this feed should go to its operator; a fraction of 1, (i.e. 0.05 is five percent) (e.g. 0.05)
    :param text: The textual part of the broadcast (e.g. "Hello, world!")
    """
    params = {
        "source": address,
        "timestamp": timestamp,
        "value": value,
        "fee_fraction": fee_fraction,
        "text": text,
    }
    return compose(db, "broadcast", params, **construct_args)


def compose_btcpay(db, address: str, order_match_id: str, **construct_args):
    """
    Composes a transaction to pay for a BTC order match.
    :param address: The address that will be sending the payment (e.g. $ADDRESS_1)
    :param order_match_id: The ID of the order match to pay for (e.g. $LAST_ORDER_MATCH_ID)
    """
    params = {"source": address, "order_match_id": order_match_id}
    return compose(db, "btcpay", params, **construct_args)


def compose_burn(db, address: str, quantity: int, overburn: bool = False, **construct_args):
    """
    Composes a transaction to burn a given quantity of BTC for XCP (on mainnet, possible between blocks 278310 and 283810; on testnet it is still available).
    :param address: The address with the BTC to burn (e.g. $ADDRESS_1)
    :param quantity: The quantities of BTC to burn (in satoshis, hence integer) (1 BTC maximum burn per address) (e.g. 1000)
    :param overburn: Whether to allow the burn to exceed 1 BTC for the address
    """
    params = {"source": address, "quantity": quantity, "overburn": overburn}
    return compose(db, "burn", params, **construct_args)


def compose_cancel(db, address: str, offer_hash: str, **construct_args):
    """
    Composes a transaction to cancel an open order or bet.
    :param address: The address that placed the order/bet to be cancelled (e.g. $ADDRESS_1)
    :param offer_hash: The hash of the order/bet to be cancelled (e.g. $LAST_ORDER_TX_HASH)
    """
    params = {"source": address, "offer_hash": offer_hash}
    return compose(db, "cancel", params, **construct_args)


def compose_destroy(db, address: str, asset: str, quantity: int, tag: str, **construct_args):
    """
    Composes a transaction to destroy a quantity of an asset.
    :param address: The address that will be sending the asset to be destroyed (e.g. $ADDRESS_1)
    :param asset: The asset to be destroyed (e.g. XCP)
    :param quantity: The quantity of the asset to be destroyed (in satoshis, hence integer) (e.g. 1000)
    :param tag: A tag for the destruction (e.g. "bugs!")
    """
    params = {"source": address, "asset": asset, "quantity": quantity, "tag": tag}
    return compose(db, "destroy", params, **construct_args)


def compose_dispenser(
    db,
    address: str,
    asset: str,
    give_quantity: int,
    escrow_quantity: int,
    mainchainrate: int,
    status: int,
    open_address: str = None,
    oracle_address: str = None,
    **construct_args,
):
    """
    Composes a transaction to opens or closes a dispenser for a given asset at a given rate of main chain asset (BTC). Escrowed quantity on open must be equal or greater than give_quantity. It is suggested that you escrow multiples of give_quantity to ease dispenser operation.
    :param address: The address that will be dispensing (must have the necessary escrow_quantity of the specified asset) (e.g. $ADDRESS_7)
    :param asset: The asset or subasset to dispense (e.g. XCP)
    :param give_quantity: The quantity of the asset to dispense (in satoshis, hence integer) (e.g. 1000)
    :param escrow_quantity: The quantity of the asset to reserve for this dispenser (in satoshis, hence integer) (e.g. 1000)
    :param mainchainrate: The quantity of the main chain asset (BTC) per dispensed portion (in satoshis, hence integer) (e.g. 100)
    :param status: The state of the dispenser. 0 for open, 1 for open using open_address, 10 for closed (e.g. 0)
    :param open_address: The address that you would like to open the dispenser on; MUST be equal to `address` from block 900000 onwards
    :param oracle_address: The address that you would like to use as a price oracle for this dispenser
    """
    params = {
        "source": address,
        "asset": asset,
        "give_quantity": give_quantity,
        "escrow_quantity": escrow_quantity,
        "mainchainrate": mainchainrate,
        "status": status,
        "open_address": open_address,
        "oracle_address": oracle_address,
    }
    return compose(db, "dispenser", params, **construct_args)


def compose_dividend(
    db, address: str, quantity_per_unit: int, asset: str, dividend_asset: str, **construct_args
):
    """
    Composes a transaction to issue a dividend to holders of a given asset.
    :param address: The address that will be issuing the dividend (must have the ownership of the asset which the dividend is being issued on) (e.g. $ADDRESS_1)
    :param quantity_per_unit: The amount of dividend_asset rewarded (in satoshis, hence integer) (e.g. 1)
    :param asset: The asset or subasset that the dividends are being rewarded on (e.g. $ASSET_1)
    :param dividend_asset: The asset or subasset that the dividends are paid in (e.g. XCP)
    """
    params = {
        "source": address,
        "quantity_per_unit": quantity_per_unit,
        "asset": asset,
        "dividend_asset": dividend_asset,
    }
    return compose(db, "dividend", params, **construct_args)


def compose_issuance(
    db,
    address: str,
    asset: str,
    quantity: int,
    transfer_destination: str = None,
    divisible: bool = True,
    lock: bool = False,
    reset: bool = False,
    description: str = None,
    **construct_args,
):
    """
    Composes a transaction to Issue a new asset, issue more of an existing asset, lock an asset, reset existing supply, or transfer the ownership of an asset.
    :param address: The address that will be issuing or transfering the asset (e.g. $ADDRESS_1)
    :param asset: The assets to issue or transfer. This can also be a subasset longname for new subasset issuances (e.g. XCPTEST)
    :param quantity: The quantity of the asset to issue (set to 0 if transferring an asset) (in satoshis, hence integer) (e.g. 1000)
    :param transfer_destination: The address to receive the asset (e.g. $ADDRESS_1)
    :param divisible: Whether this asset is divisible or not (if a transfer, this value must match the value specified when the asset was originally issued)
    :param lock: Whether this issuance should lock supply of this asset forever
    :param reset: Wether this issuance should reset any existing supply
    :param description: A textual description for the asset
    """
    params = {
        "source": address,
        "asset": asset,
        "quantity": quantity,
        "transfer_destination": transfer_destination,
        "divisible": divisible,
        "lock": lock,
        "reset": reset,
        "description": description,
    }
    return compose(db, "issuance", params, **construct_args)


def compose_mpma(
    db,
    address: str,
    assets: str,
    destinations: str,
    quantities: str,
    memo: str = None,
    memo_is_hex: bool = False,
    **construct_args,
):
    """
    Composes a transaction to send multiple payments to multiple addresses.
    :param address: The address that will be sending (must have the necessary quantity of the specified asset) (e.g. $ADDRESS_1)
    :param assets: comma-separated list of assets to send (e.g. XCP,$ASSET_5)
    :param destinations: comma-separated list of addresses to send to (e.g. $ADDRESS_1,$ADDRESS_2)
    :param quantities: comma-separated list of quantities to send (in satoshis, hence integer) (e.g. 1,2)
    :param memo: The Memo associated with this transaction (e.g. "Hello, world!")
    :param memo_is_hex: Whether the memo field is a hexadecimal string (e.g. False)
    """
    asset_list = assets.split(",")
    destination_list = destinations.split(",")
    quantity_list = quantities.split(",")
    if len(asset_list) != len(destination_list) or len(asset_list) != len(quantity_list):
        raise exceptions.ComposeError(
            "The number of assets, destinations, and quantities must be equal"
        )
    for quantity in quantity_list:
        if not quantity.isdigit():
            raise exceptions.ComposeError("Quantity must be an integer")
    quantity_list = [int(quantity) for quantity in quantity_list]
    asset_dest_quant_list = list(zip(asset_list, destination_list, quantity_list))

    params = {
        "source": address,
        "asset_dest_quant_list": asset_dest_quant_list,
        "memo": memo,
        "memo_is_hex": memo_is_hex,
    }
    return compose(db, "versions.mpma", params, **construct_args)


def compose_order(
    db,
    address: str,
    give_asset: str,
    give_quantity: int,
    get_asset: str,
    get_quantity: int,
    expiration: int,
    fee_required: int,
    **construct_args,
):
    """
    Composes a transaction to place an order on the distributed exchange.
    :param address: The address that will be issuing the order request (must have the necessary quantity of the specified asset to give) (e.g. $ADDRESS_1)
    :param give_asset: The asset that will be given in the trade (e.g. XCP)
    :param give_quantity: The quantity of the asset that will be given (in satoshis, hence integer) (e.g. 1000)
    :param get_asset: The asset that will be received in the trade (e.g. $ASSET_1)
    :param get_quantity: The quantity of the asset that will be received (in satoshis, hence integer) (e.g. 1000)
    :param expiration: The number of blocks for which the order should be valid (e.g. 100)
    :param fee_required: The miners’ fee required to be paid by orders for them to match this one; in BTC; required only if buying BTC (may be zero, though) (e.g. 100)
    """
    params = {
        "source": address,
        "give_asset": give_asset,
        "give_quantity": give_quantity,
        "get_asset": get_asset,
        "get_quantity": get_quantity,
        "expiration": expiration,
        "fee_required": fee_required,
    }
    return compose(db, "order", params, **construct_args)


def compose_send(
    db,
    address: str,
    destination: str,
    asset: str,
    quantity: int,
    memo: str = None,
    memo_is_hex: bool = False,
    use_enhanced_send: bool = True,
    **construct_args,
):
    """
    Composes a transaction to send a quantity of an asset to another address.
    :param address: The address that will be sending (must have the necessary quantity of the specified asset) (e.g. $ADDRESS_1)
    :param destination: The address that will be receiving the asset (e.g. $ADDRESS_2)
    :param asset: The asset or subasset to send (e.g. XCP)
    :param quantity: The quantity of the asset to send (in satoshis, hence integer) (e.g. 1000)
    :param memo: The Memo associated with this transaction
    :param memo_is_hex: Whether the memo field is a hexadecimal string
    :param use_enhanced_send: If this is false, the construct a legacy transaction sending bitcoin dust
    """
    params = {
        "source": address,
        "destination": destination,
        "asset": asset,
        "quantity": quantity,
        "memo": memo,
        "memo_is_hex": memo_is_hex,
        "use_enhanced_send": use_enhanced_send,
    }
    return compose(db, "send", params, **construct_args)


def compose_dispense(
    db,
    address: str,
    dispenser: str,
    quantity: int,
    **construct_args,
):
    """
    Composes a transaction to send BTC to a dispenser.
    :param address: The address that will be sending (must have the necessary quantity of BTC) (e.g. $ADDRESS_2)
    :param dispenser: The dispenser that will be receiving the asset (e.g. $ADDRESS_4)
    :param quantity: The quantity of BTC to send (in satoshis, hence integer) (e.g. 1000)
    """
    params = {
        "source": address,
        "destination": dispenser,
        "quantity": quantity,
    }
    return compose(db, "dispense", params, **construct_args)


def compose_sweep(db, address: str, destination: str, flags: int, memo: str, **construct_args):
    """
    Composes a transaction to Sends all assets and/or transfer ownerships to a destination address.
    :param address: The address that will be sending (e.g. $ADDRESS_1)
    :param destination: The address to receive the assets and/or ownerships (e.g. $ADDRESS_2)
    :param flags: An OR mask of flags indicating how the sweep should be processed. Possible flags are:
                    - FLAG_BALANCES: (integer) 1, specifies that all balances should be transferred.
                    - FLAG_OWNERSHIP: (integer) 2, specifies that all ownerships should be transferred.
                    - FLAG_BINARY_MEMO: (integer) 4, specifies that the memo is in binary/hex form.
                    (e.g. 7)
    :param memo: The Memo associated with this transaction in hex format (e.g. FFFF)
    """
    params = {
        "source": address,
        "destination": destination,
        "flags": flags,
        "memo": memo,
    }
    return compose(db, "sweep", params, **construct_args)


def compose_fairminter(
    db,
    address: str,
    asset: str,
    asset_parent: str = "",
    price: int = 0,
    quantity_by_price: int = 1,
    max_mint_per_tx: int = 0,
    hard_cap: int = 0,
    premint_quantity: int = 0,
    start_block: int = 0,
    end_block: int = 0,
    soft_cap: int = 0,
    soft_cap_deadline_block: int = 0,
    minted_asset_commission: float = 0.0,
    burn_payment: bool = False,
    lock_description: bool = False,
    lock_quantity: bool = False,
    divisible: bool = True,
    description: str = "",
    **construct_args,
):
    """
    Composes a transaction to issue a new asset using the FairMinter protocol.
    :param address: The address that will be issuing the asset (e.g. $ADDRESS_1)
    :param asset: The asset to issue (e.g. MYASSET)
    :param asset_parent: The parent asset of the asset to issue
    :param price: The price in XCP of the asset to issue (e.g. 10)
    :param quantity_by_price: The quantity of asset to mint per `price` paid
    :param max_mint_per_tx: Amount minted if price is equal to 0; otherwise, maximum amount of asset that can be minted in a single transaction; if 0, there is no limit
    :param hard_cap: The maximum amount of asset that can be minted; if 0 there is no limit
    :param premint_quantity: Amount of asset to be minted when the sale starts, if 0, no premint; preminted assets are sent to the source of the transaction
    :param start_block: The block at which the sale starts
    :param end_block: The block at which the sale ends
    :param soft_cap: Minimum amount of asset to be minted, if None, no minimum; if the soft cap is not reached by the soft_cap_deadline_block, the sale is canceled, asset is revoked from all minters and all payments are refunded
    :param soft_cap_deadline_block: The block at which the soft cap must be reached
    :param minted_asset_commission: Commission to be paid in minted asset, a fraction of 1 (i.e., 0.05 is five percent); the commission is deducted from the asset received by the minter and sent to the Fair Minter owner
    :param burn_payment: If True, the payment asset is burned, otherwise it is sent to the source
    :param lock_description: If True, the description of the asset is locked
    :param lock_quantity: If True, the quantity of the asset cannot be changed after the minting
    :param divisible: If True, the asset is divisible
    :param description: The description of the asset
    """
    params = {
        "source": address,
        "asset": asset,
        "asset_parent": asset_parent,
        "price": price,
        "quantity_by_price": quantity_by_price,
        "max_mint_per_tx": max_mint_per_tx,
        "hard_cap": hard_cap,
        "premint_quantity": premint_quantity,
        "start_block": start_block,
        "end_block": end_block,
        "soft_cap": soft_cap,
        "soft_cap_deadline_block": soft_cap_deadline_block,
        "minted_asset_commission": minted_asset_commission,
        "burn_payment": burn_payment,
        "lock_description": lock_description,
        "lock_quantity": lock_quantity,
        "divisible": divisible,
        "description": description,
    }
    return compose(db, "fairminter", params, **construct_args)


def compose_fairmint(db, address: str, asset: str, quantity: int = 0, **construct_args):
    """
    Composes a transaction to mint a quantity of an asset using the FairMinter protocol.
    :param address: The address that will be minting the asset (e.g. $ADDRESS_1)
    :param asset: The asset to mint (e.g. $ASSET_3)
    :param quantity: The quantity of the asset to mint (in satoshis, hence integer) (e.g. 1)
    """
    params = {"source": address, "asset": asset, "quantity": quantity}
    return compose(db, "fairmint", params, **construct_args)


def compose_utxo(
    db,
    source: str,
    destination: str,
    asset: str,
    quantity: int,
    **construct_args,
):
    params = {
        "source": source,
        "destination": destination,
        "asset": asset,
        "quantity": quantity,
    }
    return compose(db, "utxo", params, **construct_args)


def compose_attach(
    db,
    address: str,
    asset: str,
    quantity: int,
    destination: str = None,
    **construct_args,
):
    """
    Composes a transaction to attach assets from an address to UTXO.
    :param address: The address from which the assets are attached (e.g. $ADDRESS_1)
    :param destination: The utxo to attach the assets to (e.g. $UTXO_1_ADDRESS_1)
    :param asset: The asset or subasset to attach (e.g. XCP)
    :param quantity: The quantity of the asset to attach (in satoshis, hence integer) (e.g. 1000)
    """
    return compose_utxo(
        db,
        source=address,
        destination=destination,
        asset=asset,
        quantity=quantity,
        **construct_args,
    )


def compose_detach(
    db,
    utxo: str,
    destination: str,
    asset: str,
    quantity: int,
    **construct_args,
):
    """
    Composes a transaction to detach assets from UTXO to an address.
    :param utxo: The utxo from which the assets are detached (e.g. $UTXO_WITH_BALANCE)
    :param destination: The address to detach the assets to (e.g. $ADDRESS_1)
    :param asset: The asset or subasset to detach (e.g. XCP)
    :param quantity: The quantity of the asset to detach (in satoshis, hence integer) (e.g. 1000)
    """
    return compose_utxo(
        db,
        source=utxo,
        destination=destination,
        asset=asset,
        quantity=quantity,
        **construct_args,
    )


def compose_movetoutxo(db, utxo: str, destination: str, more_utxos: str = ""):
    """
    Composes a transaction to move assets from UTXO to another UTXO.
    :param utxo: The utxo from which the assets are moved
    :param destination: The address to move the assets to
    :param more_utxos: The additional utxos to fund the transaction
    """
    decimal.getcontext().prec = 8

    more_utxos_list = []
    input_count = 1
    total_value = D("0")
    try:
        source_address, source_value = backend.bitcoind.get_utxo_address_and_value(utxo)
        total_value += D(source_value)
        for more_utxo in more_utxos.split(","):
            if more_utxo == "":
                continue
            _more_utxo_address, more_utxo_value = backend.bitcoind.get_utxo_address_and_value(
                more_utxo
            )
            more_utxo_tx_hash, more_utxo_vout = more_utxo.split(":")
            more_utxos_list.append({"txid": more_utxo_tx_hash, "vout": int(more_utxo_vout)})
            input_count += 1
            total_value += D(more_utxo_value)
    except exceptions.InvalidUTXOError as e:
        raise exceptions.ComposeError("Invalid UTXO for source") from e

    try:
        script.validate(destination)
    except Exception as e:
        raise exceptions.ComposeError("Invalid address for destination") from e

    tx_hash, vout = utxo.split(":")

    fee_per_kb = backend.bitcoind.fee_per_kb()
    # Transaction Size (in bytes) = (Number of Inputs x 148) + (Number of Outputs x 34) + 10
    tx_size = (input_count * 148) + (2 * 34) + 10
    fee = (D(fee_per_kb) / config.UNIT) * (D(tx_size) / 1024)

    dust = D("0.0000546")
    change = D(total_value) - dust - fee

    if change < 0:
        raise exceptions.ComposeError("Insufficient funds for fee")

    inputs = [{"txid": tx_hash, "vout": int(vout)}] + more_utxos_list
    outputs = [{destination: str(dust)}, {source_address: str(change)}]
    rawtransaction = backend.bitcoind.createrawtransaction(inputs, outputs)

    return {
        "rawtransaction": rawtransaction,
        "params": {
            "source": utxo,
            "destination": destination,
        },
        "name": "movetoutxo",
        "data": None,
    }


def info_by_tx_hash(db, tx_hash: str):
    """
    Returns Counterparty information from a transaction hash.
    :param tx_hash: Transaction hash (e.g. $LAST_MEMPOOL_TX_HASH)
    """
    try:
        rawtransaction = backend.bitcoind.getrawtransaction(tx_hash)
    except Exception as e:
        raise exceptions.ComposeError("Invalid transaction") from e
    return info(db, rawtransaction)


def info(db, rawtransaction: str, block_index: int = None):
    """
    Returns Counterparty information from a raw transaction in hex format.
    :param rawtransaction: Raw transaction in hex format (e.g. $RAW_TRANSACTION_1)
    :param block_index: Block index mandatory for transactions before block 335000
    """
    try:
        decoded_tx = deserialize.deserialize_tx(
            rawtransaction, use_txid=util.enabled("correct_segwit_txids", block_index)
        )
    except Exception as e:
        raise exceptions.ComposeError("Invalid rawtransaction") from e

    source, destination, btc_amount, fee, data, _dispensers_outs, _utxos_info = (
        gettxinfo.get_tx_info(
            db,
            decoded_tx,
            block_index=block_index,
        )
    )
    del decoded_tx["__data__"]
    result = {
        "source": source,
        "destination": destination if destination else None,
        "btc_amount": btc_amount,
        "fee": fee,
        "data": util.hexlify(data) if data else "",
        "decoded_tx": decoded_tx,
    }
    if data:
        result["data"] = util.hexlify(data)
        result["unpacked_data"] = unpack(db, result["data"], block_index)
    return result


def unpack(db, datahex: str, block_index: int = None):
    """
    Unpacks Counterparty data in hex format and returns the message type and data.
    :param datahex: Data in hex format (e.g. 020000000001016a65c1624e53f4d33ce02e726a6606faed60cc014d5b1a578ba3e09b4b3f8f890100000000ffffffff020000000000000000176a150d55e8b6118808b7b663b365473f142274028b8af60245092701000000160014a3df8a5a83d4e2827b59b43f5ce6ce5d2e52093f0247304402204b7a2859cbce34e725a1132fec2dd4b075503dadff0a0c407ae7c22a7712fe4d0220563ceb2ceebdf649343bb24819fc808639cce7781305b4588ffbe4a20390d2780121020ace9adf60fe4ec05dab922ccdc5727cbf664cafc7cdb845de534855266314c800000000)
    :param block_index: Block index of the transaction containing this data
    """
    data = binascii.unhexlify(datahex)
    message_type_id, message = message_type.unpack(data)
    block_index = block_index or util.CURRENT_BLOCK_INDEX

    issuance_ids = [
        messages.issuance.ID,
        messages.issuance.LR_ISSUANCE_ID,
        messages.issuance.SUBASSET_ID,
        messages.issuance.LR_SUBASSET_ID,
    ]

    # Unknown message type
    message_data = {"error": "Unknown message type"}
    message_type_name = "unknown"
    try:
        # Bet
        if message_type_id == messages.bet.ID:
            message_type_name = "bet"
            message_data = messages.bet.unpack(message, return_dict=True)
        # Broadcast
        elif message_type_id == messages.broadcast.ID:
            message_type_name = "broadcast"
            message_data = messages.broadcast.unpack(message, block_index, return_dict=True)
        # BTCPay
        elif message_type_id == messages.btcpay.ID:
            message_type_name = "btcpay"
            message_data = messages.btcpay.unpack(message, return_dict=True)
        # Cancel
        elif message_type_id == messages.cancel.ID:
            message_type_name = "cancel"
            message_data = messages.cancel.unpack(message, return_dict=True)
        # Destroy
        elif message_type_id == messages.destroy.ID:
            message_type_name = "destroy"
            message_data = messages.destroy.unpack(db, message, return_dict=True)
        # Dispenser
        elif message_type_id == messages.dispenser.ID:
            message_type_name = "dispenser"
            message_data = messages.dispenser.unpack(message, return_dict=True)
        elif message_type_id == messages.dispenser.DISPENSE_ID:
            message_type_name = "dispense"
            message_data = messages.dispense.unpack(message, return_dict=True)
        # Dividend
        elif message_type_id == messages.dividend.ID:
            message_type_name = "dividend"
            message_data = messages.dividend.unpack(db, message, block_index, return_dict=True)
        # Issuance
        elif message_type_id in issuance_ids:
            message_type_name = "issuance"
            message_data = messages.issuance.unpack(
                db, message, message_type_id, block_index, return_dict=True
            )
        # Order
        elif message_type_id == messages.order.ID:
            message_type_name = "order"
            message_data = messages.order.unpack(db, message, block_index, return_dict=True)
        # Send
        elif message_type_id == messages.send.ID:
            message_type_name = "send"
            message_data = messages.send.unpack(db, message, block_index)
        # Enhanced send
        elif message_type_id == messages.versions.enhanced_send.ID:
            message_type_name = "enhanced_send"
            message_data = messages.versions.enhanced_send.unpack(message, block_index)
        # MPMA send
        elif message_type_id == messages.versions.mpma.ID:
            message_type_name = "mpma_send"
            mpma_message_data = messages.versions.mpma.unpack(message, block_index)
            message_data = []
            for asset_name, send_info in mpma_message_data.items():
                message_data.append(
                    {
                        "asset": asset_name,
                        "destination": send_info[0][0],
                        "quantity": send_info[0][1],
                        "memo": send_info[0][2] if len(send_info[0]) > 2 else None,
                        "memo_is_hex": send_info[0][3] if len(send_info[0]) > 3 else None,
                    }
                )
        # RPS
        elif message_type_id == messages.rps.ID:
            message_type_name = "rps"
            message_data = messages.rps.unpack(message, return_dict=True)
        # RPS Resolve
        elif message_type_id == messages.rpsresolve.ID:
            message_type_name = "rpsresolve"
            message_data = messages.rpsresolve.unpack(message, return_dict=True)
        # Sweep
        elif message_type_id == messages.sweep.ID:
            message_type_name = "sweep"
            message_data = messages.sweep.unpack(message)
        # Fair Minter
        elif message_type_id == messages.fairminter.ID:
            message_type_name = "fairminter"
            message_data = messages.fairminter.unpack(message)
        # Fair Mint
        elif message_type_id == messages.fairmint.ID:
            message_type_name = "fairmint"
            message_data = messages.fairmint.unpack(message)
    except (exceptions.UnpackError, UnicodeDecodeError) as e:
        message_data = {"error": str(e)}

    return {
        "message_type": message_type_name,
        "message_type_id": message_type_id,
        "message_data": message_data,
    }