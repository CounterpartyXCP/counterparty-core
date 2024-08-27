import logging
import struct

from counterpartycore.lib import backend, config, exceptions, ledger, script, util

logger = logging.getLogger(config.LOGGER_NAME)

ID = 100


def validate(db, source, destination, asset, quantity):
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

    balance = ledger.get_balance(db, source, asset)
    if balance < quantity:
        raise exceptions.ComposeError("insufficient funds")

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
    if source_is_address and not destination_is_utxo:
        problems.append("If source is an address, destination must be a UTXO")
    # or detach from utxo
    if source_is_utxo and not destination_is_address:
        problems.append("If source is a UTXO, destination must be an address")

    return problems


def compose(db, source, destination, asset, quantity):
    problems = validate(db, source, destination, asset, quantity)
    if problems:
        raise exceptions.ComposeError(problems)

    # we make an RPC call only at the time of composition
    if util.is_utxo_format(destination) and not backend.bitcoind.is_valid_utxo(destination):
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
                destination,
                asset,
                quantity,
            ]
        ]
    ).encode("utf-8")
    data += struct.pack(f">{len(data_content)}s", data_content)

    source_address = source
    if util.is_utxo_format(source):
        source_address = backend.bitcoind.get_utxo_address(source)

    return (source_address, [], data)


def unpack(message, return_dict=False):
    try:
        data_content = struct.unpack(f">{len(message)}s", message)[0].decode("utf-8").split("|")
        (source, destination, asset, quantity) = data_content
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
    problems = validate(db, source, destination, asset, quantity)

    if util.is_utxo_format(source):
        if backend.bitcoind.get_utxo_address(source) != tx["source"]:
            problems.append("source does not match the UTXO source")
        action = "detach from utxo"
    else:
        if source != tx["source"]:
            problems.append("source does not match the source address")
        action = "attach to utxo"

    status = "valid"
    if problems:
        status = "invalid: " + "; ".join(problems)

    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "status": status,
    }

    if status == "valid":
        ledger.debit(
            db, source, asset, quantity, tx["tx_index"], action=action, event=tx["tx_hash"]
        )
        ledger.credit(
            db,
            destination,
            asset,
            quantity,
            tx["tx_index"],
            action=action,
            event=tx["tx_hash"],
        )
        # we store parameters only if the transaction is valid
        bindings = bindings | {
            "source": source,
            "destination": destination,
            "asset": asset,
            "quantity": quantity,
        }

    ledger.insert_record(db, "sends", bindings, "SEND")

    if status == "valid":
        if util.is_utxo_format(source):
            logger.info(
                "Attach %(asset)s from %(source)s to utxo: %(destination)s (%(tx_hash)s) [%(status)s]",
                bindings,
            )
        else:
            logger.info(
                "Detach %(asset)s from %(source)s to address: %(destination)s (%(tx_hash)s) [%(status)s]",
                bindings,
            )


def move_assets(db, tx):
    utxos = tx["utxo_moves"].split(" ")
    assert len(utxos) > 1
    destination = utxos.pop()
    sources = utxos
    action = "utxo move"

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
            }

            ledger.insert_record(db, "sends", bindings, "UTXO_MOVE")

            logger.info(
                f"Move {balance['asset']} from utxo: {source} to utxo: {destination} ({tx['tx_hash']})"
            )
