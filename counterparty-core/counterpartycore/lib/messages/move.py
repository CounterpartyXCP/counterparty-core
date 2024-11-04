import logging

from counterpartycore.lib import config, exceptions, ledger, script, util
from counterpartycore.lib.messages.detach import detach_assets

logger = logging.getLogger(config.LOGGER_NAME)


def compose(db, source, destination):
    # We don't check if the source has attached assets
    # to allow transaction chaining in the same block

    if not util.is_utxo_format(source):
        raise exceptions.ComposeError("Invalid source utxo format")

    try:
        script.validate(destination)
    except script.AddressError as e:
        raise exceptions.ComposeError("destination must be an address") from e

    return (source, [(destination, None)], None)


def move_balances(db, tx, source, destination):
    action = "utxo move"
    msg_index = ledger.get_send_msg_index(db, tx["tx_hash"])
    balances = ledger.get_utxo_balances(db, source)
    for balance in balances:
        if balance["quantity"] == 0:
            continue
        # debit asset from source
        ledger.debit(
            db,
            source,
            balance["asset"],
            balance["quantity"],
            tx["tx_index"],
            action=action,
            event=tx["tx_hash"],
        )
        # credit asset to destination
        ledger.credit(
            db,
            destination,
            balance["asset"],
            balance["quantity"],
            tx["tx_index"],
            action=action,
            event=tx["tx_hash"],
        )
        # store the move in the `sends` table
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

        # log the move
        logger.info(
            f"Move {balance['asset']} from utxo: {source} to utxo: {destination} ({tx['tx_hash']})"
        )


# call on each transaction
def move_assets(db, tx):
    if "utxos_info" not in tx or not tx["utxos_info"]:
        return

    sources, destination, _outputs_count, _op_return_output = util.parse_utxos_info(
        tx["utxos_info"]
    )

    # do nothing if no vin with attached assets
    if len(sources) == 0:
        return

    for source in sources:
        if not destination and util.enabled(
            "spend_utxo_to_detach"
        ):  # one single OP_RETURN output in the transaction
            # we detach assets from the source
            detach_assets(db, tx, source)
        elif destination:
            # we move all assets from the source to the destination
            move_balances(db, tx, source, destination)
