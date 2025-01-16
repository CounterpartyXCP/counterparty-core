import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.parser import utxosinfo
from counterpartycore.lib.utils import address

logger = logging.getLogger(config.LOGGER_NAME)

ID = 102


def validate(source):
    problems = []

    # check if source is a UTXO
    if not utxosinfo.is_utxo_format(source):
        problems.append("source must be a UTXO")

    return problems


def compose(db, source, destination=None, skip_validation=False):
    problems = validate(source)
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    # check if destination is an address
    if destination is not None:
        try:
            address.validate(destination)
        except exceptions.AddressError as e:
            raise exceptions.ComposeError("destination must be an address") from e

    # create message
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    # only the destination is needed
    if destination is not None:
        data_content = destination.encode("utf-8")
    else:
        data_content = b"0"  # not empty to avoid a protocol change in `messagetype.unpack()`
    data += struct.pack(f">{len(data_content)}s", data_content)

    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        if message == b"0":  # no destination
            destination = None
        else:
            destination = struct.unpack(f">{len(message)}s", message)[0].decode("utf-8")

        if return_dict:
            return {
                "destination": destination,
            }
        return destination
    except Exception:
        return None


def detach_assets(db, tx, source, destination=None):
    problems = validate(source)

    status = "valid"
    if problems:
        status = "invalid: " + "; ".join(problems)
        # store the invalid transaction without potentially invalid parameters
        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "msg_index": ledger.ledger.get_send_msg_index(db, tx["tx_hash"]),
            "block_index": tx["block_index"],
            "status": status,
            "send_type": "detach",
        }
        ledger.events.insert_record(db, "sends", bindings, "DETACH_FROM_UTXO")
        # stop here to avoid further processing
        return

    # we detach all the assets from the source UTXO
    balances = ledger.balances.get_utxo_balances(db, source)
    for balance in balances:
        if balance["quantity"] == 0:
            continue
        # debit asset from source and credit to recipient
        action = "detach from utxo"

        # determine the destination
        detach_destination = destination
        # check if destination is an address
        if detach_destination is not None:
            try:
                address.validate(detach_destination)
            except Exception:  # let's catch all exceptions here
                detach_destination = None
        # if no destination is provided, we credit the asset to utxo_address
        if detach_destination is None:
            detach_destination = balance["utxo_address"]

        source_address = ledger.events.debit(
            db,
            source,
            balance["asset"],
            balance["quantity"],
            tx["tx_index"],
            action=action,
            event=tx["tx_hash"],
        )
        ledger.events.credit(
            db,
            detach_destination,
            balance["asset"],
            balance["quantity"],
            tx["tx_index"],
            action=action,
            event=tx["tx_hash"],
        )
        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "msg_index": ledger.ledger.get_send_msg_index(db, tx["tx_hash"]),
            "block_index": tx["block_index"],
            "status": "valid",
            "source": source,
            "source_address": source_address,
            "destination": detach_destination,
            "asset": balance["asset"],
            "quantity": balance["quantity"],
            "fee_paid": 0,
            "send_type": "detach",
        }
        ledger.events.insert_record(db, "sends", bindings, "DETACH_FROM_UTXO")

    logger.info(
        "Detach assets from %(source)s (%(tx_hash)s) [%(status)s]",
        {
            "source": source,
            "tx_hash": tx["tx_hash"],
            "status": status,
        },
    )


def parse(db, tx, message):
    destination = unpack(message)

    # get all inputs with balances
    sources = utxosinfo.get_sources_from_utxos_info(tx["utxos_info"])

    # detach assets from all the sources
    # IMPORTANT: that's mean we can't detach assets and move utxo in th same transaction
    for source in sources:
        detach_assets(db, tx, source, destination)
