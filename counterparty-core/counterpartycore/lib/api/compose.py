import binascii
import decimal

from counterpartycore.lib import (
    backend,
    composer,
    config,
    deserialize,
    exceptions,
    gas,
    gettxinfo,
    message_type,
    messages,
    util,
)
from counterpartycore.lib.messages.attach import ID as UTXO_ID

D = decimal.Decimal


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
    **construct_params,
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
    return composer.compose_transaction(db, "bet", params, construct_params)


def compose_broadcast(
    db,
    address: str,
    timestamp: int,
    value: float,
    fee_fraction: float,
    text: str,
    **construct_params,
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
    return composer.compose_transaction(db, "broadcast", params, construct_params)


def compose_btcpay(db, address: str, order_match_id: str, **construct_params):
    """
    Composes a transaction to pay for a BTC order match.
    :param address: The address that will be sending the payment (e.g. $ADDRESS_1)
    :param order_match_id: The ID of the order match to pay for (e.g. $LAST_ORDER_MATCH_ID)
    """
    params = {"source": address, "order_match_id": order_match_id}
    return composer.compose_transaction(db, "btcpay", params, construct_params)


def compose_burn(db, address: str, quantity: int, overburn: bool = False, **construct_params):
    """
    Composes a transaction to burn a given quantity of BTC for XCP (on mainnet, possible between blocks 278310 and 283810; on testnet it is still available).
    :param address: The address with the BTC to burn (e.g. $ADDRESS_1)
    :param quantity: The quantities of BTC to burn (in satoshis, hence integer) (1 BTC maximum burn per address) (e.g. 1000)
    :param overburn: Whether to allow the burn to exceed 1 BTC for the address
    """
    params = {"source": address, "quantity": quantity, "overburn": overburn}
    return composer.compose_transaction(db, "burn", params, construct_params)


def compose_cancel(db, address: str, offer_hash: str, **construct_params):
    """
    Composes a transaction to cancel an open order or bet.
    :param address: The address that placed the order/bet to be cancelled (e.g. $ADDRESS_6)
    :param offer_hash: The hash of the order/bet to be cancelled (e.g. $LAST_OPEN_ORDER_TX_HASH)
    """
    params = {"source": address, "offer_hash": offer_hash}
    return composer.compose_transaction(db, "cancel", params, construct_params)


def compose_destroy(db, address: str, asset: str, quantity: int, tag: str, **construct_params):
    """
    Composes a transaction to destroy a quantity of an asset.
    :param address: The address that will be sending the asset to be destroyed (e.g. $ADDRESS_1)
    :param asset: The asset to be destroyed (e.g. XCP)
    :param quantity: The quantity of the asset to be destroyed (in satoshis, hence integer) (e.g. 1000)
    :param tag: A tag for the destruction (e.g. "bugs!")
    """
    params = {"source": address, "asset": asset, "quantity": quantity, "tag": tag}
    return composer.compose_transaction(db, "destroy", params, construct_params)


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
    **construct_params,
):
    """
    Composes a transaction to opens or closes a dispenser for a given asset at a given rate of main chain asset (BTC). Escrowed quantity on open must be equal or greater than give_quantity. It is suggested that you escrow multiples of give_quantity to ease dispenser operation.
    :param address: The address that will be dispensing (must have the necessary escrow_quantity of the specified asset) (e.g. $ADDRESS_9)
    :param asset: The asset or subasset to dispense (e.g. XCP)
    :param give_quantity: The quantity of the asset to dispense (in satoshis, hence integer) (e.g. 1000)
    :param escrow_quantity: The quantity of the asset to reserve for this dispenser (in satoshis, hence integer) (e.g. 1000)
    :param mainchainrate: The quantity of the main chain asset (BTC) per dispensed portion (in satoshis, hence integer) (e.g. 100)
    :param status: The state of the dispenser. 0 for open, 1 for open using open_address, 10 for closed (e.g. 0)
    :param open_address: The address that you would like to open the dispenser on; MUST be equal to `address` from block 866000 onwards
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
    return composer.compose_transaction(db, "dispenser", params, construct_params)


def compose_dividend(
    db, address: str, quantity_per_unit: int, asset: str, dividend_asset: str, **construct_params
):
    """
    Composes a transaction to issue a dividend to holders of a given asset.
    :param address: The address that will be issuing the dividend (must have the ownership of the asset which the dividend is being issued on) (e.g. $ADDRESS_1)
    :param quantity_per_unit: The amount of dividend_asset rewarded (in satoshis, hence integer) (e.g. 1)
    :param asset: The asset or subasset that the dividends are being rewarded on (e.g. MYASSETA)
    :param dividend_asset: The asset or subasset that the dividends are paid in (e.g. XCP)
    """
    params = {
        "source": address,
        "quantity_per_unit": quantity_per_unit,
        "asset": asset,
        "dividend_asset": dividend_asset,
    }
    return composer.compose_transaction(db, "dividend", params, construct_params)


def get_dividend_estimate_xcp_fee(db, address: str, asset: str):  # noqa
    """
    Returns the estimated fee for issuing a dividend.
    :param address: The address that will be issuing the dividend (e.g. $ADDRESS_1)
    :param asset: The asset or subasset that the dividends are being rewarded on (e.g. MYASSETA)
    """
    return messages.dividend.get_estimate_xcp_fee(db, asset, util.CURRENT_BLOCK_INDEX)


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
    **construct_params,
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
    return composer.compose_transaction(db, "issuance", params, construct_params)


def compose_mpma(
    db,
    address: str,
    assets: str,
    destinations: str,
    quantities: str,
    memos: list = None,
    memos_are_hex: bool = None,
    memo: str = None,
    memo_is_hex: bool = False,
    **construct_params,
):
    """
    Composes a transaction to send multiple payments to multiple addresses.
    :param address: The address that will be sending (must have the necessary quantity of the specified asset) (e.g. $ADDRESS_2)
    :param assets: comma-separated list of assets to send (e.g. XCP,FAIRMINTC)
    :param destinations: comma-separated list of addresses to send to (e.g. $ADDRESS_1,$ADDRESS_2)
    :param quantities: comma-separated list of quantities to send (in satoshis, hence integer) (e.g. 1,2)
    :param memos: One `memos` argument by send, if any
    :param memos_are_hex: Whether the memos are in hexadecimal format
    :param memo: The Memo associated with this transaction, used by default for all sends if no `memos` are specified
    :param memo_is_hex: Whether the memo field is a hexadecimal string
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

    if memos:
        if not isinstance(memos, list):
            raise exceptions.ComposeError("Memos must be a list")
        if len(memos) != len(asset_dest_quant_list):
            raise exceptions.ComposeError(
                "The number of memos must be equal to the number of sends"
            )
        for i, send_memo in enumerate(memos):
            if send_memo:
                asset_dest_quant_list[i] += (send_memo, memos_are_hex)

    params = {
        "source": address,
        "asset_dest_quant_list": asset_dest_quant_list,
        "memo": memo,
        "memo_is_hex": memo_is_hex,
    }
    return composer.compose_transaction(db, "versions.mpma", params, construct_params)


def compose_order(
    db,
    address: str,
    give_asset: str,
    give_quantity: int,
    get_asset: str,
    get_quantity: int,
    expiration: int,
    fee_required: int,
    **construct_params,
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
    return composer.compose_transaction(db, "order", params, construct_params)


def compose_send(
    db,
    address: str,
    destination: str,
    asset: str,
    quantity: int,
    memo: str = None,
    memo_is_hex: bool = False,
    use_enhanced_send: bool = True,
    **construct_params,
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
    return composer.compose_transaction(db, "send", params, construct_params)


def compose_dispense(
    db,
    address: str,
    dispenser: str,
    quantity: int,
    **construct_params,
):
    """
    Composes a transaction to send BTC to a dispenser.
    :param address: The address that will be sending (must have the necessary quantity of BTC) (e.g. $ADDRESS_1)
    :param dispenser: The dispenser that will be receiving the asset (e.g. $ADDRESS_4)
    :param quantity: The quantity of BTC to send (in satoshis, hence integer) (e.g. 1000)
    """
    params = {
        "source": address,
        "destination": dispenser,
        "quantity": quantity,
    }
    return composer.compose_transaction(db, "dispense", params, construct_params)


def compose_sweep(db, address: str, destination: str, flags: int, memo: str, **construct_params):
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
    return composer.compose_transaction(db, "sweep", params, construct_params)


def get_sweep_estimate_xcp_fee(db, address: str):
    """
    Returns the estimated fee for sweeping all assets and/or transfer ownerships to a destination address.
    :param address: The address that will be sweeping (e.g. $ADDRESS_1)
    """
    return messages.sweep.get_total_fee(db, address, util.CURRENT_BLOCK_INDEX)


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
    **construct_params,
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
    :param description: The description of the asset. Overrides the current description if the asset already exists.
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
    return composer.compose_transaction(db, "fairminter", params, construct_params)


def compose_fairmint(db, address: str, asset: str, quantity: int = 0, **construct_params):
    """
    Composes a transaction to mint a quantity of an asset using the FairMinter protocol.
    :param address: The address that will be minting the asset (e.g. $ADDRESS_1)
    :param asset: The asset to mint (e.g. OPENFAIR)
    :param quantity: The quantity of the asset to mint (in satoshis, hence integer)
    """
    params = {"source": address, "asset": asset, "quantity": quantity}
    return composer.compose_transaction(db, "fairmint", params, construct_params)


def compose_attach(
    db,
    address: str,
    asset: str,
    quantity: int,
    utxo_value: int = None,
    destination_vout: str = None,
    **construct_params,
):
    """
    Composes a transaction to attach assets from an address to UTXO.
    Warning: after attaching assets to a UTXO, remember to use the `exclude_utxos` parameter to exclude it from subsequent transactions. This is done automatically by the Composer but only once the attach is confirmed.
    :param address: The address from which the assets are attached (e.g. $ADDRESS_1)
    :param asset: The asset or subasset to attach (e.g. XCP)
    :param quantity: The quantity of the asset to attach (in satoshis, hence integer) (e.g. 1000)
    :param utxo_value: The value of the UTXO to attach the assets to (in satoshis, hence integer)
    :param destination_vout: The vout of the destination output
    """
    params = {
        "source": address,
        "asset": asset,
        "quantity": quantity,
        "utxo_value": utxo_value,
        "destination_vout": destination_vout,
    }
    return composer.compose_transaction(db, "attach", params, construct_params)


def get_attach_estimate_xcp_fee(db, address: str = None):  # noqa
    """
    Returns the estimated fee for attaching assets to a UTXO.
    :param address: The address from which the assets are attached (e.g. $ADDRESS_1)
    """
    return gas.get_transaction_fee(db, UTXO_ID, util.CURRENT_BLOCK_INDEX)


def compose_detach(
    db,
    utxo: str,
    destination: str = None,
    **construct_params,
):
    """
    Composes a transaction to detach assets from UTXO to an address.
    :param utxo: The utxo from which the assets are detached (e.g. $UTXO_WITH_BALANCE)
    :param destination: The address to detach the assets to, if not provided the addresse corresponding to the utxo is used (e.g. $ADDRESS_1)
    """
    params = {
        "source": utxo,
        "destination": destination,
    }
    return composer.compose_transaction(db, "detach", params, construct_params)


def compose_movetoutxo(db, utxo: str, destination: str, utxo_value: int = None, **construct_params):
    """
    Composes a transaction like a send but for moving from one UTXO to another, with the destination is specified as an address.
    :param utxo: The utxo from which the assets are moved (e.g. $UTXO_WITH_BALANCE)
    :param destination: the address for which the destination utxo will be created (e.g. $ADDRESS_1)
    :param utxo_value: The value of the UTXO to move the assets from (in satoshis, hence integer)
    """
    params = {
        "source": utxo,
        "destination": destination,
        "utxo_value": utxo_value,
    }
    return composer.compose_transaction(db, "move", params, construct_params)


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
            rawtransaction,
            parse_vouts=True,
            block_index=block_index,
        )
    except Exception as e:
        raise exceptions.ComposeError("Invalid rawtransaction") from e

    try:
        source, destination, btc_amount, fee, data, _dispensers_outs, _utxos_info = (
            gettxinfo.get_tx_info(
                db,
                decoded_tx,
                block_index=block_index or util.CURRENT_BLOCK_INDEX,
            )
        )
    except exceptions.BitcoindRPCError:
        source, destination, btc_amount, fee, data = None, None, None, None, None

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
    try:
        data = binascii.unhexlify(datahex)
    except Exception as e:  # noqa
        raise exceptions.UnpackError("Data must be in hexadecimal format") from e

    if data[: len(config.PREFIX)] == config.PREFIX:
        data = data[len(config.PREFIX) :]
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
            message_data = messages.fairminter.unpack(message, return_dict=True)
        # Fair Mint
        elif message_type_id == messages.fairmint.ID:
            message_type_name = "fairmint"
            message_data = messages.fairmint.unpack(message, return_dict=True)
        # utxo
        elif message_type_id == messages.utxo.ID:
            message_type_name = "utxo"
            message_data = messages.utxo.unpack(message, return_dict=True)
        # Attach
        elif message_type_id == messages.attach.ID:
            message_type_name = "attach"
            message_data = messages.attach.unpack(message, return_dict=True)
        # Detach
        elif message_type_id == messages.detach.ID:
            message_type_name = "detach"
            message_data = messages.detach.unpack(message, return_dict=True)
    except (exceptions.UnpackError, UnicodeDecodeError) as e:
        message_data = {"error": str(e)}

    return {
        "message_type": message_type_name,
        "message_type_id": message_type_id,
        "message_data": message_data,
    }
