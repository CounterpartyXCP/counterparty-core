"""
offer_hash is the hash of either a bet or an order.
When offer_hash is None (cancel-all mode), cancels all open orders and bets
for the source address in a single transaction.
"""

import binascii
import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import gas
from counterpartycore.lib.parser import messagetype, protocol

from . import bet, order

logger = logging.getLogger(config.LOGGER_NAME)

FORMAT = ">32s"
LENGTH = 32
ID = 70
CANCEL_ALL_FLAG = b"\x01"


def validate(db, source, offer_hash):
    problems = []

    if offer_hash is None:
        open_orders = ledger.markets.get_open_orders_by_source(db, source)
        open_bets = ledger.other.get_open_bets_by_source(db, source)
        if not open_orders and not open_bets:
            problems.append("no open offers for this address")
        if not problems:
            fee = gas.get_transaction_fee(db, ID, CurrentState().current_block_index())
            if fee > 0:
                balance = ledger.balances.get_balance(db, source, config.XCP)
                if balance < fee:
                    problems.append("insufficient XCP for fee")
        return problems

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


def compose(db, source: str, offer_hash: str = None, skip_validation: bool = False):
    if offer_hash is None:
        if not protocol.enabled("cancel_all_offers"):
            raise exceptions.ComposeError(["cancel all not yet enabled"])
        problems = validate(db, source, None)
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
    try:
        if len(message) == 1 and message == CANCEL_ALL_FLAG:
            if return_dict:
                return {"offer_hash": None, "status": "valid"}
            return None, "valid"
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
    # Unpack message.
    offer_hash, status = unpack(message)
    offer_type = None

    # Cancel-all mode
    if offer_hash is None and status == "valid":
        if not protocol.enabled("cancel_all_offers", block_index=tx["block_index"]):
            status = "invalid: could not unpack"
        else:
            problems = validate(db, tx["source"], None)
            if problems:
                status = "invalid: " + "; ".join(problems)

        if status == "valid":
            open_orders = ledger.markets.get_open_orders_by_source(db, tx["source"])
            open_bets = ledger.other.get_open_bets_by_source(db, tx["source"])

            limit = protocol.get_value_by_block_index("cancel_all_offers_limit", tx["block_index"])
            to_cancel_orders = open_orders[:limit]
            remaining = max(0, limit - len(to_cancel_orders))
            to_cancel_bets = open_bets[:remaining]
            offer_count = len(to_cancel_orders) + len(to_cancel_bets)

            fee = gas.get_transaction_fee(db, ID, tx["block_index"])
            if fee > 0:
                ledger.events.debit(
                    db,
                    tx["source"],
                    config.XCP,
                    fee,
                    tx["tx_index"],
                    action="cancel all fee",
                    event=tx["tx_hash"],
                )

            gas.increment_counter(db, ID, tx["block_index"], count=offer_count)

            for open_order in to_cancel_orders:
                order.cancel_order(db, open_order, "cancelled", tx["block_index"], tx["tx_index"])
            for open_bet in to_cancel_bets:
                bet.cancel_bet(db, open_bet, "cancelled", tx["tx_index"])

        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "block_index": tx["block_index"],
            "source": tx["source"],
            "offer_hash": "cancel_all",
            "status": status,
        }
        ledger.events.insert_record(
            db, "cancels", bindings, "CANCEL_ALL" if status == "valid" else "INVALID_CANCEL"
        )
        logger.info(
            "Cancel all open offers for %(source)s (%(tx_hash)s) [%(status)s]",
            bindings,
        )
        ledger.blocks.set_transaction_status(db, tx["tx_index"], status == "valid")
        return

    # Single cancel — existing logic
    offer_type = None

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

    ledger.blocks.set_transaction_status(
        db,
        tx["tx_index"],
        status == "valid",
    )
