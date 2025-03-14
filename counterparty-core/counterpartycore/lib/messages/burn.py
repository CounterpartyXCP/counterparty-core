import csv
import decimal
import logging
import os
from fractions import Fraction

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import protocol

D = decimal.Decimal

logger = logging.getLogger(config.LOGGER_NAME)

ID = 60

MAINNET_BURNS = {}
CURR_DIR = os.path.dirname(os.path.realpath(__file__))
with open(CURR_DIR + "/data/mainnet_burns.csv", "r", encoding="utf-8") as f:
    mainnet_burns_reader = csv.DictReader(f)
    for line in mainnet_burns_reader:
        MAINNET_BURNS[line["tx_hash"]] = line


def validate(destination, quantity, block_index):
    problems = []

    # Check destination address.
    if destination != config.UNSPENDABLE:
        problems.append("wrong destination address")

    if not isinstance(quantity, int):
        problems.append("quantity must be in satoshis")
        return problems

    if quantity < 0:
        problems.append("negative quantity")

    # Try to make sure that the burned funds won't go to waste.
    if block_index < config.BURN_START - 1:
        problems.append("too early")
    elif block_index > config.BURN_END:
        problems.append("too late")

    return problems


def compose(db, source: str, quantity: int, overburn: bool = False, skip_validation: bool = False):
    cursor = db.cursor()
    destination = config.UNSPENDABLE
    problems = validate(destination, quantity, CurrentState().current_block_index())
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    # Check that a maximum of 1 BTC total is burned per address.
    burns = ledger.other.get_burns(db, source)
    already_burned = sum(burn["burned"] for burn in burns)

    if quantity > (1 * config.UNIT - already_burned) and not overburn:
        raise exceptions.ComposeError(f"1 {config.BTC} may be burned per address")

    cursor.close()
    return (source, [(destination, quantity)], None)


def parse(db, tx):
    burn_parse_cursor = db.cursor()

    if protocol.is_test_network():
        problems = []
        status = "valid"

        if status == "valid":
            problems = validate(
                tx["destination"],
                tx["btc_amount"],
                tx["block_index"],
            )
            if problems:
                status = "invalid: " + "; ".join(problems)

            if tx["btc_amount"] is not None:  # noqa: E711
                sent = tx["btc_amount"]
            else:
                sent = 0

        if status == "valid":
            # Calculate quantity of XCP earned. (Maximum 1 BTC in total, ever.)
            burns = ledger.other.get_burns(db, tx["source"])
            already_burned = sum(burn["burned"] for burn in burns)
            one = 1 * config.UNIT
            max_burn = one - already_burned
            if sent > max_burn:
                burned = max_burn  # Exceeded maximum burn; earn what you can.
            else:
                burned = sent

            total_time = config.BURN_END - config.BURN_START
            partial_time = config.BURN_END - tx["block_index"]
            multiplier = 1000 + (500 * Fraction(partial_time, total_time))
            earned = round(burned * multiplier)

            # Credit source address with earned XCP.
            ledger.events.credit(
                db,
                tx["source"],
                config.XCP,
                earned,
                tx["tx_index"],
                action="burn",
                event=tx["tx_hash"],
            )
        else:
            burned = 0
            earned = 0

        tx_index = tx["tx_index"]
        tx_hash = tx["tx_hash"]
        block_index = tx["block_index"]
        source = tx["source"]

    else:
        # Mainnet burns are hard‐coded.

        try:
            row = MAINNET_BURNS[tx["tx_hash"]]
        except KeyError:
            return

        ledger.events.credit(
            db,
            row["source"],
            config.XCP,
            int(row["earned"]),
            tx["tx_index"],
            action="burn",
            event=row["tx_hash"],
        )

        tx_index = int(tx["tx_index"])
        tx_hash = row["tx_hash"]
        block_index = int(row["block_index"])
        source = row["source"]
        burned = int(row["burned"])
        earned = int(row["earned"])
        status = "valid"

    # Add parsed transaction to message-type–specific table.
    bindings = {
        "tx_index": tx_index,
        "tx_hash": tx_hash,
        "block_index": block_index,
        "source": source,
        "burned": burned,
        "earned": earned,
        "status": status,
    }
    if "integer overflow" not in status:
        ledger.events.insert_record(db, "burns", bindings, "BURN")

    logger.info(
        "%(source)s burned %(burned)s BTC for %(earned)s XCP (%(tx_hash)s) [%(status)s]", bindings
    )

    burn_parse_cursor.close()


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
