"""`buybooster`: buy one booster of a fairbooster. The price is paid to the
owner of the fairbooster (the issuer of its asset) right away; the cards are
drawn in the next block (`fairbooster.draw_boosters`), among the cards the
fairbooster had when the booster was bought.

The message carries the terms the buyer accepts: the highest price they pay,
the number of cards of a booster and the number of cards of the fairbooster
(cards can only be added, and never change). An update of the fairbooster that
reaches the chain before the purchase, in an earlier block or earlier in the
same one, makes it invalid rather than changing what the buyer pays or gets."""

import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import fairbooster as fairbooster_mod
from counterpartycore.lib.parser import protocol

logger = logging.getLogger(config.LOGGER_NAME)

ID = 132
# asset id, max_price, cards_per_booster, card_count
FORMAT = ">QQHH"
LENGTH = struct.calcsize(FORMAT)


def validate(db, source, asset, max_price, cards_per_booster, card_count, block_index=None):
    if not protocol.enabled("fairboosters", block_index=block_index):
        return ["fairboosters are not enabled"]
    fairbooster = ledger.fairboosters.get_fairbooster(db, asset) if asset else None
    if fairbooster is None:
        return [f"fairbooster `{asset}` not found"]
    if not all(fairbooster_mod.is_int(term) for term in (max_price, cards_per_booster, card_count)):
        return ["`max_price`, `cards_per_booster` and `card_count` must be integers"]

    problems = []
    if fairbooster["boosters_sold"] >= fairbooster["max_boosters"]:
        problems.append("all boosters are sold")
    # the terms of the purchase
    if fairbooster["price"] > max_price:
        problems.append(
            f"the price of a booster ({fairbooster['price']}) is above `max_price` ({max_price})"
        )
    if fairbooster["cards_per_booster"] != cards_per_booster:
        problems.append(
            f"`cards_per_booster` is {fairbooster['cards_per_booster']}, not {cards_per_booster}"
        )
    if fairbooster["card_count"] != card_count:
        problems.append(f"`card_count` is {fairbooster['card_count']}, not {card_count}")
    if ledger.balances.get_balance(db, source, config.XCP) < fairbooster["price"]:
        problems.append("insufficient XCP balance")
    # `cards_sold` counts the cards drawn and those of the purchases not drawn
    # yet: the cards of a pending purchase are reserved
    supply = ledger.fairboosters.get_card_supply(db, asset)
    if supply is not None and supply - fairbooster["cards_sold"] < fairbooster["cards_per_booster"]:
        problems.append("not enough cards left to fill a booster")
    return problems


def compose(
    db,
    source: str,
    asset: str,
    max_price: int = None,
    cards_per_booster: int = None,
    card_count: int = None,
    skip_validation: bool = False,
):
    """The terms left to None are the current ones of the fairbooster."""
    fairbooster = ledger.fairboosters.get_fairbooster(db, asset) if asset else None
    if fairbooster is not None:
        max_price = fairbooster["price"] if max_price is None else max_price
        if cards_per_booster is None:
            cards_per_booster = fairbooster["cards_per_booster"]
        card_count = fairbooster["card_count"] if card_count is None else card_count
    problems = validate(db, source, asset, max_price, cards_per_booster, card_count)
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    try:
        data += struct.pack(
            FORMAT,
            ledger.issuances.generate_asset_id(asset),
            max_price,
            cards_per_booster,
            card_count,
        )
    except struct.error as e:
        raise exceptions.ComposeError(
            "`max_price`, `cards_per_booster` and `card_count` cannot be encoded"
        ) from e
    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError("invalid buybooster message")
        asset_id, max_price, cards_per_booster, card_count = struct.unpack(FORMAT, message)
        asset = ledger.issuances.generate_asset_name(asset_id)
    except Exception:  # pylint: disable=broad-exception-caught
        asset, max_price, cards_per_booster, card_count = "", 0, 0, 0
    if return_dict:
        return {
            "asset": asset,
            "max_price": max_price,
            "cards_per_booster": cards_per_booster,
            "card_count": card_count,
        }
    return asset, max_price, cards_per_booster, card_count


def parse(db, tx, message):
    asset, max_price, cards_per_booster, card_count = unpack(message)
    if asset == "":
        problems = ["could not unpack"]
    else:
        problems = validate(
            db,
            tx["source"],
            asset,
            max_price,
            cards_per_booster,
            card_count,
            block_index=tx["block_index"],
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
    update_data = {
        "boosters_sold": fairbooster["boosters_sold"] + 1,
        "cards_sold": fairbooster["cards_sold"] + fairbooster["cards_per_booster"],
    }
    update_data["status"] = fairbooster_mod.get_status(
        {**fairbooster, **update_data}, ledger.fairboosters.get_card_supply(db, asset)
    )
    ledger.fairboosters.update_fairbooster(db, fairbooster["tx_hash"], update_data)
    ledger.blocks.set_transaction_status(db, tx["tx_index"], True)
    logger.info("Booster of %s bought by %s for %s XCP.", asset, tx["source"], price)
