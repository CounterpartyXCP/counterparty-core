import logging
import struct

from counterpartycore.lib import backend, config, exceptions, gas, ledger, script, util

logger = logging.getLogger(config.LOGGER_NAME)

ID = 100


def validate(db, source, destination, asset, quantity, block_index=None):
    problems = []

    if asset == config.BTC:
        problems.append("cannot send bitcoins")  # Only for parsing.

    if not isinstance(quantity, int):
        problems.append("quantity must be in satoshis")
        return problems

    if quantity <= 0:
        problems.append("quantity must be greater than zero")

    # For SQLite3
    if quantity > config.MAX_INT:
        problems.append("integer overflow")

    source_is_address = True
    destination_is_address = True
    try:
        script.validate(source)
    except script.AddressError:
        source_is_address = False
    try:
        script.validate(destination)
    except script.AddressError:
        destination_is_address = False

    source_is_utxo = util.is_utxo_format(source)
    destination_is_utxo = util.is_utxo_format(destination)

    # attach to utxo
    if source_is_address and (not destination_is_utxo and destination is not None):
        problems.append("If source is an address, destination must be a UTXO")
    # or detach from utxo
    if source_is_utxo and not destination_is_address:
        problems.append("If source is a UTXO, destination must be an address")

    fee = gas.get_transaction_fee(db, ID, block_index or util.CURRENT_BLOCK_INDEX)

    asset_balance = ledger.get_balance(db, source, asset)
    if source_is_address:
        fee_payer = source
    else:
        fee_payer = destination

    if asset == config.XCP and fee_payer == source:
        if asset_balance < quantity + fee:
            problems.append("insufficient funds for transfer and fee")
    else:
        if asset_balance < quantity:
            problems.append("insufficient funds for transfer")
        xcp_balance = ledger.get_balance(db, fee_payer, config.XCP)
        if xcp_balance < fee:
            problems.append("insufficient funds for fee")

    return problems


def compose(db, source, destination, asset, quantity):
    problems = validate(db, source, destination, asset, quantity)
    if problems:
        raise exceptions.ComposeError(problems)

    # we make an RPC call only at the time of composition
    if (
        destination
        and util.is_utxo_format(destination)
        and not backend.bitcoind.is_valid_utxo(destination)
    ):
        raise exceptions.ComposeError(["destination is not a UTXO"])
    if util.is_utxo_format(source) and not backend.bitcoind.is_valid_utxo(source):
        raise exceptions.ComposeError(["source is not a UTXO"])

    # create message
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    # to optimize the data size (avoiding fixed sizes per parameter) we use a simple
    # string of characters separated by `|`.
    data_content = "|".join(
        [
            str(value)
            for value in [
                source,
                destination or "",
                asset,
                quantity,
            ]
        ]
    ).encode("utf-8")
    data += struct.pack(f">{len(data_content)}s", data_content)

    source_address = source
    if util.is_utxo_format(source):
        source_address, _value = backend.bitcoind.get_utxo_address_and_value(source)

    return (source_address, [], data)


def unpack(message, return_dict=False):
    try:
        data_content = struct.unpack(f">{len(message)}s", message)[0].decode("utf-8").split("|")
        (source, destination_str, asset, quantity) = data_content
        destination = None if destination_str == "" else destination_str

        if return_dict:
            return {
                "source": source,
                "destination": destination,
                "asset": asset,
                "quantity": int(quantity),
            }

        return (source, destination, asset, int(quantity))
    except Exception as e:
        raise exceptions.UnpackError(f"Cannot unpack utxo message: {e}") from e


def parse(db, tx, message):
    (source, destination, asset, quantity) = unpack(message)

    problems = validate(db, source, destination, asset, quantity, tx["block_index"])

    recipient = destination
    if not recipient:
        recipient = tx["utxos_info"].split(" ")[-1]

    if util.is_utxo_format(source):
        source_address, _value = backend.bitcoind.get_utxo_address_and_value(source)
        if source_address != tx["source"]:
            problems.append("source does not match the UTXO source")
        action = "detach from utxo"
        event = "DETACH_FROM_UTXO"
    else:
        if source != tx["source"]:
            problems.append("source does not match the source address")
        action = "attach to utxo"
        event = "ATTACH_TO_UTXO"

    status = "valid"
    if problems:
        status = "invalid: " + "; ".join(problems)

    cursor = db.cursor()
    last_msg_index = cursor.execute(
        """
        SELECT MAX(msg_index) as msg_index FROM sends WHERE tx_hash = ?
    """,
        (tx["tx_hash"],),
    ).fetchone()
    if last_msg_index and last_msg_index["msg_index"] is not None:
        msg_index = last_msg_index["msg_index"] + 1
    else:
        msg_index = 0

    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "msg_index": msg_index,
        "block_index": tx["block_index"],
        "status": status,
    }

    if status == "valid":
        # fee payment
        fee = gas.get_transaction_fee(db, ID, tx["block_index"])
        if fee > 0:
            # fee is always paid by the address
            if action == "attach to utxo":
                fee_payer = source
            else:
                fee_payer = recipient
            # debit fee from the fee payer
            ledger.debit(
                db,
                fee_payer,
                config.XCP,
                fee,
                tx["tx_index"],
                action=f"{action} fee",
                event=tx["tx_hash"],
            )
            # destroy fee
            destroy_bindings = {
                "tx_index": tx["tx_index"],
                "tx_hash": tx["tx_hash"],
                "block_index": tx["block_index"],
                "source": tx["source"],
                "asset": config.XCP,
                "quantity": fee,
                "tag": f"{action} fee",
                "status": "valid",
            }
            ledger.insert_record(db, "destructions", destroy_bindings, "ASSET_DESTRUCTION")
        # debit asset from source and credit to recipient
        ledger.debit(
            db, source, asset, quantity, tx["tx_index"], action=action, event=tx["tx_hash"]
        )
        ledger.credit(
            db,
            recipient,
            asset,
            quantity,
            tx["tx_index"],
            action=action,
            event=tx["tx_hash"],
        )
        # we store parameters only if the transaction is valid
        bindings = bindings | {
            "source": source,
            "destination": recipient,
            "asset": asset,
            "quantity": quantity,
            "fee_paid": fee,
        }
        # update counter
        gas.increment_counter(db, ID, tx["block_index"])

    ledger.insert_record(db, "sends", bindings, event)

    if status == "valid":
        if util.is_utxo_format(source):
            logger.info(
                "Detach %(asset)s from %(source)s to address: %(destination)s (%(tx_hash)s) [%(status)s]",
                bindings,
            )
        else:
            logger.info(
                "Attach %(asset)s from %(source)s to utxo: %(destination)s (%(tx_hash)s) [%(status)s]",
                bindings,
            )


def move_assets(db, tx):
    utxos = tx["utxos_info"].split(" ")
    if len(utxos) < 2:
        return
    destination = utxos.pop()
    sources = utxos
    action = "utxo move"

    msg_index = 0
    for source in sources:
        balances = ledger.get_utxo_balances(db, source)
        for balance in balances:
            if balance["quantity"] == 0:
                continue
            ledger.debit(
                db,
                source,
                balance["asset"],
                balance["quantity"],
                tx["tx_index"],
                action=action,
                event=tx["tx_hash"],
            )
            ledger.credit(
                db,
                destination,
                balance["asset"],
                balance["quantity"],
                tx["tx_index"],
                action=action,
                event=tx["tx_hash"],
            )
            bindings = {
                "tx_index": tx["tx_index"],
                "tx_hash": tx["tx_hash"],
                "block_index": tx["block_index"],
                "status": "valid",
                "source": source,
                "destination": destination,
                "asset": balance["asset"],
                "quantity": balance["quantity"],
                "msg_index": msg_index,
            }

            ledger.insert_record(db, "sends", bindings, "UTXO_MOVE")
            msg_index += 1

            logger.info(
                f"Move {balance['asset']} from utxo: {source} to utxo: {destination} ({tx['tx_hash']})"
            )
