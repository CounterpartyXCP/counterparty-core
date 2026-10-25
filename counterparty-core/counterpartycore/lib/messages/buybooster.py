"""`buybooster`: buy one booster of a fairbooster. The price is paid to the
owner of the fairbooster (the issuer of its asset) right away; the cards are
drawn in the next block (`fairbooster.draw_boosters`)."""

import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import fairbooster as fairbooster_mod
from counterpartycore.lib.parser import protocol

logger = logging.getLogger(config.LOGGER_NAME)

ID = 132
FORMAT = ">Q"
LENGTH = 8


def validate(db, source, asset, pending_block_index, block_index=None):
    """`pending_block_index` is the block whose purchases are not drawn yet."""
    if not protocol.enabled("fairboosters", block_index=block_index):
        return ["fairboosters are not enabled"]
    fairbooster = ledger.fairboosters.get_fairbooster(db, asset) if asset else None
    if fairbooster is None:
        return [f"fairbooster `{asset}` not found"]

    problems = []
    if fairbooster["boosters_sold"] >= fairbooster["max_boosters"]:
        problems.append("all boosters are sold")
    if ledger.balances.get_balance(db, source, config.XCP) < fairbooster["price"]:
        problems.append("insufficient XCP balance")
    cards = ledger.fairboosters.get_fairbooster_cards(db, asset)
    remaining = fairbooster_mod.remaining_supply(
        cards, ledger.fairboosters.get_drawn_cards(db, asset)
    )
    if remaining is not None:
        remaining -= ledger.fairboosters.get_pending_card_count(db, asset, pending_block_index)
        if remaining < fairbooster["cards_per_booster"]:
            problems.append("not enough cards left to fill a booster")
    return problems


def compose(db, source: str, asset: str, skip_validation: bool = False):
    problems = validate(db, source, asset, ledger.blocks.last_db_index(db))
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, ledger.issuances.generate_asset_id(asset))
    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError("invalid buybooster message")
        asset = ledger.issuances.generate_asset_name(struct.unpack(FORMAT, message)[0])
    except Exception:  # pylint: disable=broad-exception-caught
        asset = ""
    if return_dict:
        return {"asset": asset}
    return asset


def parse(db, tx, message):
    asset = unpack(message)
    if asset == "":
        problems = ["could not unpack"]
    else:
        problems = validate(
            db, tx["source"], asset, tx["block_index"], block_index=tx["block_index"]
        )

    if problems:
        status = "invalid: " + "; ".join(problems)
        fairbooster = ledger.fairboosters.get_fairbooster(db, asset) if asset else None
        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "block_index": tx["block_index"],
            "source": tx["source"],
            "fairbooster": asset if fairbooster else None,
            "paid_quantity": 0,
            "card_count": 0,
            "status": status,
        }
        ledger.events.insert_record(
            db, "fairbooster_purchases", bindings, "NEW_FAIRBOOSTER_PURCHASE"
        )
        ledger.blocks.set_transaction_status(db, tx["tx_index"], False)
        logger.info("Booster purchase %s is invalid: %s", tx["tx_hash"], status)
        return

    fairbooster = ledger.fairboosters.get_fairbooster(db, asset)
    price = fairbooster["price"]
    if price > 0:
        owner = ledger.issuances.get_asset(db, asset)["issuer"]
        ledger.events.debit(
            db, tx["source"], config.XCP, price, tx["tx_index"], "buy booster", tx["tx_hash"]
        )
        ledger.events.credit(
            db, owner, config.XCP, price, tx["tx_index"], "booster payment", tx["tx_hash"]
        )

    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "fairbooster": asset,
        "paid_quantity": price,
        "card_count": fairbooster["cards_per_booster"],
        "status": "valid",
    }
    ledger.events.insert_record(db, "fairbooster_purchases", bindings, "NEW_FAIRBOOSTER_PURCHASE")
    boosters_sold = fairbooster["boosters_sold"] + 1
    ledger.fairboosters.update_fairbooster(
        db,
        fairbooster["tx_hash"],
        {
            "boosters_sold": boosters_sold,
            "status": "open" if boosters_sold < fairbooster["max_boosters"] else "closed",
        },
    )
    ledger.blocks.set_transaction_status(db, tx["tx_index"], True)
    logger.info("Booster of %s bought by %s for %s XCP.", asset, tx["source"], price)
