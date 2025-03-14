"""
offer_hash is the hash of either a bet or an order.
"""

import binascii
import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.parser import messagetype

from . import bet, order

logger = logging.getLogger(config.LOGGER_NAME)

FORMAT = ">32s"
LENGTH = 32
ID = 70


def validate(db, source, offer_hash):
    problems = []

    orders = ledger.markets.get_order(db, order_hash=offer_hash)
    bets = ledger.other.get_bet(db, bet_hash=offer_hash)

    offer_type = None
    if orders:
        offer_type = "order"
    elif bets:
        offer_type = "bet"
    else:
        problems = ["no open offer with that hash"]

    offer = None
    if offer_type:
        offers = orders + bets
        offer = offers[0]
        if offer["source"] != source:
            problems.append("incorrect source address")
        if offer["status"] != "open":
            problems.append("offer not open")

    return offer, offer_type, problems


def compose(db, source: str, offer_hash: str, skip_validation: bool = False):
    # Check that offer exists.
    _offer, _offer_type, problems = validate(db, source, offer_hash)
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    offer_hash_bytes = binascii.unhexlify(bytes(offer_hash, "utf-8"))
    data = messagetype.pack(ID)
    data += struct.pack(FORMAT, offer_hash_bytes)
    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        offer_hash_bytes = struct.unpack(FORMAT, message)[0]
        offer_hash = binascii.hexlify(offer_hash_bytes).decode("utf-8")
        status = "valid"
    except (exceptions.UnpackError, struct.error):
        offer_hash = None
        status = "invalid: could not unpack"
    if return_dict:
        return {
            "offer_hash": offer_hash,
            "status": status,
        }
    return offer_hash, status


def parse(db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    offer_hash, status = unpack(message)

    if status == "valid":
        offer, offer_type, problems = validate(db, tx["source"], offer_hash)
        if problems:
            status = "invalid: " + "; ".join(problems)

    if status == "valid":
        # Cancel if order.
        if offer_type == "order":
            order.cancel_order(db, offer, "cancelled", tx["block_index"], tx["tx_index"])
        # Cancel if bet.
        elif offer_type == "bet":
            bet.cancel_bet(db, offer, "cancelled", tx["tx_index"])
        # If neither order or bet, mark as invalid.
        else:
            assert False  # noqa: B011

    # Add parsed transaction to message-type–specific table.
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "offer_hash": offer_hash,
        "status": status,
    }
    if "integer overflow" not in status:
        event_name = f"CANCEL_{offer_type.upper()}" if offer_type else "INVALID_CANCEL"
        ledger.events.insert_record(db, "cancels", bindings, event_name)

    log_data = bindings | {
        "offer_type": offer_type.capitalize() if offer_type else "Invalid",
    }
    logger.info("Cancel %(offer_type)s %(offer_hash)s (%(tx_hash)s) [%(status)s]", log_data)

    cursor.close()
