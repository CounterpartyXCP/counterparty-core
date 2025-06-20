"""
Datastreams are identified by the address that publishes them, and referenced
in transaction outputs.

For CFD leverage, 1x = 5040, 2x = 10080, etc.: 5040 is a superior highly
composite number and a colossally abundant number, and has 1-10, 12 as factors.

All wagers are in XCP.

Expiring a bet match doesn't re‐open the constituent bets. (So all bets may be 'filled.')
"""

import decimal
import logging
import struct
import time

from counterpartycore.lib import (
    config,
    exceptions,
    ledger,
)
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import messagetype, protocol
from counterpartycore.lib.utils import helpers

D = decimal.Decimal

logger = logging.getLogger(config.LOGGER_NAME)

FORMAT = ">HIQQdII"
LENGTH = 2 + 4 + 8 + 8 + 8 + 4 + 4
ID = 40


# For testing purposes
def date_passed(date):
    """Check if the date has already passed."""
    return date <= int(time.time())


def cancel_bet(db, bet, status, tx_index):
    # Update status of bet.
    set_data = {"status": status}
    ledger.other.update_bet(db, bet["tx_hash"], set_data)

    log_data = set_data | {
        "bet_hash": bet["tx_hash"],
    }
    logger.info("Bet %(bet_hash)s canceled [%(status)s]", log_data)

    # Refund wager.
    ledger.events.credit(
        db,
        bet["source"],
        config.XCP,
        bet["wager_remaining"],
        tx_index,
        action="recredit wager remaining",
        event=bet["tx_hash"],
    )


def cancel_bet_match(db, bet_match, status, tx_index):
    # Does not re‐open, re‐fill, etc. constituent bets.
    # Recredit tx0 address.
    ledger.events.credit(
        db,
        bet_match["tx0_address"],
        config.XCP,
        bet_match["forward_quantity"],
        tx_index,
        action="recredit forward quantity",
        event=bet_match["id"],
    )

    # Recredit tx1 address.
    ledger.events.credit(
        db,
        bet_match["tx1_address"],
        config.XCP,
        bet_match["backward_quantity"],
        tx_index,
        action="recredit backward quantity",
        event=bet_match["id"],
    )
    # Update status of bet match.
    ledger.other.update_bet_match_status(db, bet_match["id"], status)

    logger.info(
        "Bet Match %(id)s canceled [%(status)s]",
        {
            "id": bet_match["id"],
            "status": status,
        },
    )


def get_fee_fraction(db, feed_address):
    """Get fee fraction from last broadcast from the feed_address address."""
    broadcasts = ledger.other.get_broadcasts_by_source(db, feed_address, "valid", order_by="ASC")

    if broadcasts:
        last_broadcast = broadcasts[-1]
        fee_fraction_int = last_broadcast["fee_fraction_int"]
        if fee_fraction_int:
            return fee_fraction_int / 1e8
        return 0
    return 0


def validate(
    db,
    feed_address,
    bet_type,
    deadline,
    wager_quantity,
    counterwager_quantity,
    target_value,
    leverage,
    expiration,
    block_index,
):
    problems = []

    if leverage is None:
        leverage = 5040

    # For SQLite3
    if (
        wager_quantity > config.MAX_INT  # pylint: disable=too-many-boolean-expressions
        or counterwager_quantity > config.MAX_INT
        or bet_type > config.MAX_INT
        or deadline > config.MAX_INT
        or leverage > config.MAX_INT
        or block_index + expiration > config.MAX_INT
    ):
        problems.append("integer overflow")

    # Look at feed to be bet on.
    broadcasts = ledger.other.get_broadcasts_by_source(db, feed_address, "valid", order_by="ASC")
    if not broadcasts:
        problems.append("feed doesn't exist")
    elif not broadcasts[-1]["text"]:
        problems.append("feed is locked")
    elif broadcasts[-1]["timestamp"] >= deadline:
        problems.append("deadline in that feed's past")

    if bet_type not in (0, 1, 2, 3):
        problems.append("unknown bet type")

    # Valid leverage level?
    if leverage != 5040 and bet_type in (2, 3):  # Equal, NotEqual
        problems.append("leverage used with Equal or NotEqual")
    if leverage < 5040 and bet_type not in (
        0,
        1,
    ):  # BullCFD, BearCFD (fractional leverage makes sense precisely with CFDs)
        problems.append("leverage level too low")

    if bet_type in (0, 1):  # BullCFD, BearCFD
        if block_index >= 312350:  # Protocol change.
            problems.append("CFDs temporarily disabled")

    if not isinstance(wager_quantity, int):
        problems.append("wager_quantity must be in satoshis")
        return problems, leverage
    if not isinstance(counterwager_quantity, int):
        problems.append("counterwager_quantity must be in satoshis")
        return problems, leverage
    if not isinstance(expiration, int):
        problems.append("expiration must be expressed as an integer block delta")
        return problems, leverage

    if wager_quantity <= 0:
        problems.append("non‐positive wager")
    if counterwager_quantity <= 0:
        problems.append("non‐positive counterwager")
    if deadline < 0:
        problems.append("negative deadline")
    if expiration < 0:
        problems.append("negative expiration")
    if expiration == 0 and not protocol.enabled("no_zero_expiration"):  # Protocol change.
        problems.append("zero expiration")

    if target_value:
        if bet_type in (0, 1):  # BullCFD, BearCFD
            problems.append("CFDs have no target value")
        if target_value < 0:
            problems.append("negative target value")

    if expiration > config.MAX_EXPIRATION:
        problems.append("expiration overflow")

    return problems, leverage


def compose(
    db,
    source: str,
    feed_address: str,
    bet_type: int,
    deadline: int,
    wager_quantity: int,
    counterwager_quantity: int,
    target_value: int,
    leverage: int,
    expiration: int,
    skip_validation: bool = False,
):
    if ledger.balances.get_balance(db, source, config.XCP) < wager_quantity:
        raise exceptions.ComposeError("insufficient funds")

    problems, leverage = validate(
        db,
        feed_address,
        bet_type,
        deadline,
        wager_quantity,
        counterwager_quantity,
        target_value,
        leverage,
        expiration,
        CurrentState().current_block_index(),
    )
    if date_passed(deadline):
        problems.append("deadline passed")
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    data = messagetype.pack(ID)
    data += struct.pack(
        FORMAT,
        bet_type,
        deadline,
        wager_quantity,
        counterwager_quantity,
        target_value,
        leverage,
        expiration,
    )
    return (source, [(feed_address, None)], data)


def unpack(message, return_dict=False):
    # Unpack message.
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        (
            bet_type,
            deadline,
            wager_quantity,
            counterwager_quantity,
            target_value,
            leverage,
            expiration,
        ) = struct.unpack(FORMAT, message)
        status = "open"
    except (exceptions.UnpackError, struct.error):
        (
            bet_type,
            deadline,
            wager_quantity,
            counterwager_quantity,
            target_value,
            leverage,
            expiration,
        ) = 0, 0, 0, 0, 0, 0, 0
        status = "invalid: could not unpack"
    if return_dict:
        return {
            "bet_type": bet_type,
            "deadline": deadline,
            "wager_quantity": wager_quantity,
            "counterwager_quantity": counterwager_quantity,
            "target_value": target_value,
            "leverage": leverage,
            "expiration": expiration,
            "status": status,
        }
    return (
        bet_type,
        deadline,
        wager_quantity,
        counterwager_quantity,
        target_value,
        leverage,
        expiration,
        status,
    )


def parse(db, tx, message):
    bet_parse_cursor = db.cursor()

    # Unpack message.
    (
        bet_type,
        deadline,
        wager_quantity,
        counterwager_quantity,
        target_value,
        leverage,
        expiration,
        status,
    ) = unpack(message)

    odds, fee_fraction = 0, 0
    feed_address = tx["destination"]
    if status == "open":
        try:
            odds = ledger.issuances.price(wager_quantity, counterwager_quantity)
        except ZeroDivisionError:
            odds = 0

        fee_fraction = get_fee_fraction(db, feed_address)

        # Overbet
        balance = ledger.balances.get_balance(db, tx["source"], config.XCP)
        if balance == 0:
            wager_quantity = 0
        else:
            if balance < wager_quantity:
                wager_quantity = balance
                counterwager_quantity = int(ledger.issuances.price(wager_quantity, odds))

        problems, leverage = validate(
            db,
            feed_address,
            bet_type,
            deadline,
            wager_quantity,
            counterwager_quantity,
            target_value,
            leverage,
            expiration,
            tx["block_index"],
        )
        if problems:
            status = "invalid: " + "; ".join(problems)

    # Debit quantity wagered. (Escrow.)
    if status == "open":
        ledger.events.debit(
            db,
            tx["source"],
            config.XCP,
            wager_quantity,
            tx["tx_index"],
            action="bet",
            event=tx["tx_hash"],
        )

    # Add parsed transaction to message-type–specific table.
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "feed_address": feed_address,
        "bet_type": bet_type,
        "deadline": deadline,
        "wager_quantity": wager_quantity,
        "wager_remaining": wager_quantity,
        "counterwager_quantity": counterwager_quantity,
        "counterwager_remaining": counterwager_quantity,
        "target_value": target_value,
        "leverage": leverage,
        "expiration": expiration,
        "expire_index": tx["block_index"] + expiration,
        "fee_fraction_int": fee_fraction * 1e8,
        "status": status,
    }
    if "integer overflow" not in status:
        ledger.events.insert_record(db, "bets", bindings, "OPEN_BET")

    logger.info("Open Bet (%(tx_hash)s) [%(status)s]", bindings)

    # Match.
    if status == "open" and tx["block_index"] != config.MEMPOOL_BLOCK_INDEX:
        match(db, tx)

    bet_parse_cursor.close()


def match(db, tx):
    # Get bet in question.
    bets = ledger.other.get_bet(db, bet_hash=tx["tx_hash"])
    if not bets:
        return

    assert len(bets) == 1
    if bets[0]["status"] != "open":
        return

    tx1 = bets[0]

    # Get counterbet_type.
    if tx1["bet_type"] % 2:
        counterbet_type = tx1["bet_type"] - 1
    else:
        counterbet_type = tx1["bet_type"] + 1

    feed_address = tx1["feed_address"]

    cursor = db.cursor()
    tx1_wager_remaining = tx1["wager_remaining"]
    tx1_counterwager_remaining = tx1["counterwager_remaining"]

    bet_matches = ledger.other.get_matching_bets(db, tx1["feed_address"], counterbet_type)
    if protocol.enabled("sort_bet_matches"):  # Protocol change.
        sorted(bet_matches, key=lambda x: x["tx_index"])  # Sort by tx index second.
        sorted(
            bet_matches,
            key=lambda x: ledger.issuances.price(x["wager_quantity"], x["counterwager_quantity"]),
        )  # Sort by price first.

    tx1_status = tx1["status"]
    for tx0 in bet_matches:
        if tx1_status != "open":
            break

        logger.debug("Considering: %s", tx0["tx_hash"])
        tx0_wager_remaining = tx0["wager_remaining"]
        tx0_counterwager_remaining = tx0["counterwager_remaining"]

        # Bet types must be opposite.
        if counterbet_type != tx0["bet_type"]:
            logger.debug("Skipping: bet types disagree.")
            continue

        # Leverages must agree exactly
        if tx0["leverage"] != tx1["leverage"]:
            logger.debug("Skipping: leverages disagree.")
            continue

        # Target values must agree exactly.
        if tx0["target_value"] != tx1["target_value"]:
            logger.debug("Skipping: target values disagree.")
            continue

        # Fee fractions must agree exactly.
        if tx0["fee_fraction_int"] != tx1["fee_fraction_int"]:
            logger.debug("Skipping: fee fractions disagree.")
            continue

        # Deadlines must agree exactly.
        if tx0["deadline"] != tx1["deadline"]:
            logger.debug("Skipping: deadlines disagree.")
            continue

        # If the odds agree, make the trade. The found order sets the odds,
        # and they trade as much as they can.
        tx0_odds = ledger.issuances.price(tx0["wager_quantity"], tx0["counterwager_quantity"])
        tx0_inverse_odds = ledger.issuances.price(
            tx0["counterwager_quantity"], tx0["wager_quantity"]
        )
        tx1_odds = ledger.issuances.price(tx1["wager_quantity"], tx1["counterwager_quantity"])

        if protocol.enabled("issuance_fee_update_2"):
            tx0_inverse_odds = ledger.issuances.price(1, tx0_odds)  # Protocol change.

        logger.debug(
            "Tx0 Inverse Odds: %(inverse_odds)s; Tx1 Odds: %(tx1_odds)s",
            {"inverse_odds": float(tx0_inverse_odds), "tx1_odds": float(tx1_odds)},
        )
        if tx0_inverse_odds > tx1_odds:
            logger.debug("Skipping: price mismatch.")
        else:
            logger.debug(
                "Potential forward quantities: %(wager)s, %(price)s",
                {
                    "wager": tx0_wager_remaining,
                    "price": int(ledger.issuances.price(tx1_wager_remaining, tx1_odds)),
                },
            )
            forward_quantity = int(
                min(tx0_wager_remaining, int(ledger.issuances.price(tx1_wager_remaining, tx1_odds)))
            )
            logger.debug("Forward Quantity: %(quantity)s", {"quantity": forward_quantity})
            backward_quantity = round(forward_quantity / tx0_odds)
            logger.debug("Backward Quantity: %(quantity)s", {"quantity": backward_quantity})

            if not forward_quantity:
                logger.debug("Skipping: zero forward quantity.")
                continue
            if protocol.enabled("no_backwards_compatibility"):  # Protocol change.
                if not backward_quantity:
                    logger.debug("Skipping: zero backward quantity.")
                    continue

            # Debit the order.
            # Counterwager remainings may be negative.
            tx0_wager_remaining = tx0_wager_remaining - forward_quantity
            tx0_counterwager_remaining = tx0_counterwager_remaining - backward_quantity
            tx1_wager_remaining = tx1_wager_remaining - backward_quantity
            tx1_counterwager_remaining = tx1_counterwager_remaining - forward_quantity

            # tx0
            tx0_status = "open"
            if tx0_wager_remaining <= 0 or tx0_counterwager_remaining <= 0:
                # Fill order, and recredit give_remaining.
                tx0_status = "filled"
                ledger.events.credit(
                    db,
                    tx0["source"],
                    config.XCP,
                    tx0_wager_remaining,
                    tx["tx_index"],
                    event=tx1["tx_hash"],
                    action="filled",
                )

            set_data = {
                "wager_remaining": tx0_wager_remaining,
                "counterwager_remaining": tx0_counterwager_remaining,
                "status": tx0_status,
            }
            ledger.other.update_bet(db, tx0["tx_hash"], set_data)

            log_data = set_data | {
                "tx_hash": tx["tx_hash"],
                "bet_hash": tx0["tx_hash"],
            }
            logger.info("Bet %(bet_hash)s updated (%(tx_hash)s) [%(status)s]", log_data)

            if protocol.enabled("recredit_give_remaining"):  # Protocol change
                if tx1_wager_remaining <= 0 or tx1_counterwager_remaining <= 0:
                    # Fill order, and recredit give_remaining.
                    tx1_status = "filled"
                    ledger.events.credit(
                        db,
                        tx1["source"],
                        config.XCP,
                        tx1_wager_remaining,
                        tx["tx_index"],
                        event=tx1["tx_hash"],
                        action="filled",
                    )
            # tx1
            set_data = {
                "wager_remaining": tx1_wager_remaining,
                "counterwager_remaining": tx1_counterwager_remaining,
                "status": tx1_status,
            }
            ledger.other.update_bet(db, tx1["tx_hash"], set_data)

            log_data = set_data | {
                "tx_hash": tx["tx_hash"],
                "bet_hash": tx1["tx_hash"],
            }
            logger.info("Bet %(bet_hash)s updated (%(tx_hash)s) [%(status)s]", log_data)

            # Get last value of feed.
            broadcasts = ledger.other.get_broadcasts_by_source(
                db, feed_address, "valid", order_by="ASC"
            )
            initial_value = broadcasts[-1]["value"]

            # Record bet fulfillment.
            bindings = {
                "id": helpers.make_id(tx0["tx_hash"], tx["tx_hash"]),
                "tx0_index": tx0["tx_index"],
                "tx0_hash": tx0["tx_hash"],
                "tx0_address": tx0["source"],
                "tx1_index": tx1["tx_index"],
                "tx1_hash": tx1["tx_hash"],
                "tx1_address": tx1["source"],
                "tx0_bet_type": tx0["bet_type"],
                "tx1_bet_type": tx1["bet_type"],
                "feed_address": tx1["feed_address"],
                "initial_value": initial_value,
                "deadline": tx1["deadline"],
                "target_value": tx1["target_value"],
                "leverage": tx1["leverage"],
                "forward_quantity": forward_quantity,
                "backward_quantity": backward_quantity,
                "tx0_block_index": tx0["block_index"],
                "tx1_block_index": tx1["block_index"],
                "block_index": min(tx0["block_index"], tx1["block_index"]),
                "tx0_expiration": tx0["expiration"],
                "tx1_expiration": tx1["expiration"],
                "match_expire_index": min(tx0["expire_index"], tx1["expire_index"]),
                "fee_fraction_int": tx1["fee_fraction_int"],
                "status": "pending",
            }
            ledger.events.insert_record(db, "bet_matches", bindings, "BET_MATCH")
            logger.info(
                "Bet Match: tx0_index=%(tx0_index)s, forward=%(forward_quantity)s XCP, backward=%(backward_quantity)s XCP, feed=%(feed_address)s",
                bindings,
            )

    cursor.close()


def expire(db, block_index, block_time):
    cursor = db.cursor()

    # Expire bets and give refunds for the quantity wager_remaining.
    for bet in ledger.other.get_bets_to_expire(db, block_index):
        # use tx_index=0 for block actions
        cancel_bet(db, bet, "expired", 0)

        # Record bet expiration.
        bindings = {
            "bet_index": bet["tx_index"],
            "bet_hash": bet["tx_hash"],
            "source": bet["source"],
            "block_index": block_index,
        }
        ledger.events.insert_record(db, "bet_expirations", bindings, "BET_EXPIRATION")
        logger.info("Bet expired: %(bet_hash)s", bindings)

    # Expire bet matches whose deadline is more than two weeks before the current block time.
    for bet_match in ledger.other.get_bet_matches_to_expire(db, block_time):
        # use tx_index=0 for block actions
        cancel_bet_match(db, bet_match, "expired", 0)

        # Record bet match expiration.
        bindings = {
            "bet_match_id": bet_match["id"],
            "tx0_address": bet_match["tx0_address"],
            "tx1_address": bet_match["tx1_address"],
            "block_index": block_index,
        }
        ledger.events.insert_record(db, "bet_match_expirations", bindings, "BET_MATCH_EXPIRATION")
        logger.info("Bet Match Expiration %(bet_match_id)s", bindings)

    cursor.close()
