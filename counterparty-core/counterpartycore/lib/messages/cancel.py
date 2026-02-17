"""
offer_hash is the hash of either a bet or an order.
"""

import binascii
import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.parser import messagetype, protocol

from . import bet, order

logger = logging.getLogger(config.LOGGER_NAME)

FORMAT = ">32s"
LENGTH = 32
ID = 70
CANCEL_ALL_FLAG = b"\x01"
CANCEL_ALL_FEE_PER_OFFER = int(0.0002 * config.UNIT)  # 0.0002 XCP per cancelled offer


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


def validate_cancel_all(db, source):
    problems = []
    open_orders = ledger.markets.get_open_orders_by_source(db, source)
    open_bets = ledger.other.get_open_bets_by_source(db, source)
    if not open_orders and not open_bets:
        problems.append("no open offers for this address")

    offer_count = len(open_orders) + len(open_bets)
    fee = CANCEL_ALL_FEE_PER_OFFER * offer_count
    if not problems and fee:
        balance = ledger.balances.get_balance(db, source, config.XCP)
        if balance < fee:
            problems.append(f"insufficient funds ({config.XCP})")

    return open_orders, open_bets, problems, fee


def compose(db, source: str, offer_hash: str = None, skip_validation: bool = False):
    if offer_hash is None:
        # Cancel all open orders and bets
        if not protocol.enabled("cancel_all_offers"):
            raise exceptions.ComposeError(["cancel all not yet enabled"])
        _open_orders, _open_bets, problems, _fee = validate_cancel_all(db, source)
        if problems and not skip_validation:
            raise exceptions.ComposeError(problems)
        data = messagetype.pack(ID)
        data += CANCEL_ALL_FLAG
        return (source, [], data)

    # Check that offer exists.
    _offer, _offer_type, problems = validate(db, source, offer_hash)
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    offer_hash_bytes = binascii.unhexlify(bytes(offer_hash, "utf-8"))
    data = messagetype.pack(ID)
    data += struct.pack(FORMAT, offer_hash_bytes)
    return (source, [], data)


def unpack(message, return_dict=False):
    cancel_all = False
    try:
        if len(message) == 1 and message == CANCEL_ALL_FLAG:
            offer_hash = None
            status = "valid"
            cancel_all = True
        elif len(message) == LENGTH:
            offer_hash_bytes = struct.unpack(FORMAT, message)[0]
            offer_hash = binascii.hexlify(offer_hash_bytes).decode("utf-8")
            status = "valid"
        else:
            raise exceptions.UnpackError
    except (exceptions.UnpackError, struct.error):
        offer_hash = None
        status = "invalid: could not unpack"
    if return_dict:
        return {
            "offer_hash": offer_hash,
            "status": status,
            "cancel_all": cancel_all,
        }
    return offer_hash, status, cancel_all


def parse(db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    offer_hash, status, cancel_all = unpack(message)

    offer_type = None

    # Before the protocol change, treat cancel_all as an invalid unpack
    # to preserve identical behavior with the original code.
    if cancel_all and not protocol.enabled("cancel_all_offers"):
        offer_hash = None
        status = "invalid: could not unpack"
        cancel_all = False

    if cancel_all:
        open_orders, open_bets, problems, fee = validate_cancel_all(db, tx["source"])
        if problems:
            status = "invalid: " + "; ".join(problems)
        else:
            # Debit anti-spam fee.
            if fee:
                ledger.events.debit(
                    db,
                    tx["source"],
                    config.XCP,
                    fee,
                    tx["tx_index"],
                    action="cancel all fee",
                    event=tx["tx_hash"],
                )
            for o in open_orders:
                order.cancel_order(db, o, "cancelled", tx["block_index"], tx["tx_index"])
            for b in open_bets:
                bet.cancel_bet(db, b, "cancelled", tx["tx_index"])

        # Add parsed transaction to message-type–specific table.
        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "block_index": tx["block_index"],
            "source": tx["source"],
            "offer_hash": "all",
            "status": status,
        }
        event_name = "CANCEL_ALL" if status == "valid" else "INVALID_CANCEL"
        ledger.events.insert_record(db, "cancels", bindings, event_name)

        logger.info(
            "Cancel All open offers for %(source)s (%(tx_hash)s) [%(status)s]",
            bindings,
        )
    else:
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

    ledger.blocks.set_transaction_status(
        db,
        tx["tx_index"],
        status == "valid",
    )
