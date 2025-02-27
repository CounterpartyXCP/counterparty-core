import logging

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages.detach import detach_assets
from counterpartycore.lib.parser import protocol, utxosinfo
from counterpartycore.lib.utils import address

logger = logging.getLogger(config.LOGGER_NAME)


def compose(db, source, destination, utxo_value=None, skip_validation=False):
    if not skip_validation:
        if not utxosinfo.is_utxo_format(source):
            raise exceptions.ComposeError("Invalid source utxo format")

        balances = ledger.balances.get_utxo_balances(db, source)
        if not balances:
            raise exceptions.ComposeError("No assets attached to the source utxo")

        try:
            address.validate(destination)
        except exceptions.AddressError as e:
            raise exceptions.ComposeError("destination must be an address") from e

    value = config.DEFAULT_UTXO_VALUE
    if utxo_value is not None:
        try:
            value = int(utxo_value)
        except ValueError as e:
            raise exceptions.ComposeError(["utxo_value must be an integer"]) from e

    return (source, [(destination, value)], None)


def move_balances(db, tx, source, destination):
    action = "utxo move"
    msg_index = ledger.other.get_send_msg_index(db, tx["tx_hash"])
    balances = ledger.balances.get_utxo_balances(db, source)
    for balance in balances:
        if balance["quantity"] == 0:
            continue
        # debit asset from source
        source_address = ledger.events.debit(
            db,
            source,
            balance["asset"],
            balance["quantity"],
            tx["tx_index"],
            action=action,
            event=tx["tx_hash"],
        )
        # credit asset to destination
        destination_address = ledger.events.credit(
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
            "source_address": source_address,
            "destination": destination,
            "destination_address": destination_address,
            "asset": balance["asset"],
            "quantity": balance["quantity"],
            "msg_index": msg_index,
            "send_type": "move",
        }

        ledger.events.insert_record(db, "sends", bindings, "UTXO_MOVE")
        msg_index += 1

        # log the move
        logger.info(
            "Move %s %s from utxo: %s to utxo: %s (%s)",
            balance["quantity"],
            balance["asset"],
            source,
            destination,
            tx["tx_hash"],
        )


# call on each transaction
def move_assets(db, tx):
    if "utxos_info" not in tx or not tx["utxos_info"]:
        return False

    sources, destination, _outputs_count, _op_return_output = utxosinfo.parse_utxos_info(
        tx["utxos_info"]
    )

    # do nothing if no vin with attached assets
    if len(sources) == 0:
        return False

    for source in sources:
        if not destination and protocol.enabled(
            "spend_utxo_to_detach"
        ):  # one single OP_RETURN output in the transaction
            # we detach assets from the source
            detach_assets(db, tx, source)
        elif destination:
            # we move all assets from the source to the destination
            move_balances(db, tx, source, destination)

    return True
