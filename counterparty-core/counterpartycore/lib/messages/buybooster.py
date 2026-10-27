"""`buybooster`: buy one booster of a fairbooster. The price is paid to the
owner of the fairbooster (the issuer of its asset) right away; the cards are
drawn in the next block (`fairbooster.draw_boosters`), among the cards the
fairbooster had when the booster was bought.

The message names the `version` of the fairbooster the buyer accepts: its
state, price, cards and card image URL included, as it was when the purchase
was composed. Every valid `updatefairbooster` increments the version, so an
update that reaches the chain before the purchase, in an earlier block or
earlier in the same one, makes it invalid rather than changing what the buyer
pays or gets. The purchase keeps the number of cards of a booster and the card
image URL (`cards_base_url` and `cards_image_extension`) of that version, which
its draw uses whatever later updates change."""

import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import fairbooster as fairbooster_mod
from counterpartycore.lib.parser import protocol

logger = logging.getLogger(config.LOGGER_NAME)

ID = 132
# asset id, version
FORMAT = ">QI"
LENGTH = struct.calcsize(FORMAT)


def validate(db, source, asset, version, block_index=None):
    """Returns `(problems, fairbooster, supply)`: the current row of the
    fairbooster (None when there is none) and the number of copies of its
    cards (None when a card is unlimited)."""
    if not protocol.enabled("fairboosters", block_index=block_index):
        return ["fairboosters are not enabled"], None, None
    fairbooster = ledger.fairboosters.get_fairbooster(db, asset) if asset else None
    if fairbooster is None:
        return [f"fairbooster `{asset}` not found"], None, None
    if not fairbooster_mod.is_int(version):
        return ["`version` must be an integer"], fairbooster, None

    problems = []
    if fairbooster["boosters_sold"] >= fairbooster["max_boosters"]:
        problems.append("all boosters are sold")
    # the terms of the purchase: the fairbooster as it was at `version`
    if fairbooster["version"] != version:
        problems.append(f"the fairbooster is at version {fairbooster['version']}, not {version}")
    if ledger.balances.get_balance(db, source, config.XCP) < fairbooster["price"]:
        problems.append("insufficient XCP balance")
    # `cards_sold` counts the cards drawn and those of the purchases not drawn
    # yet: the cards of a pending purchase are reserved
    supply = ledger.fairboosters.get_card_supply(db, asset)
    if supply is not None and supply - fairbooster["cards_sold"] < fairbooster["cards_per_booster"]:
        problems.append("not enough cards left to fill a booster")
    return problems, fairbooster, supply


def compose(
    db,
    source: str,
    asset: str,
    version: int = None,
    skip_validation: bool = False,
):
    """`version` defaults to the current one of the fairbooster."""
    if version is None:
        fairbooster = ledger.fairboosters.get_fairbooster(db, asset) if asset else None
        if fairbooster is not None:
            version = fairbooster["version"]
    problems, _fairbooster, _supply = validate(db, source, asset, version)
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    try:
        data += struct.pack(FORMAT, ledger.issuances.generate_asset_id(asset), version)
    except struct.error as e:
        raise exceptions.ComposeError("`version` cannot be encoded") from e
    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError("invalid buybooster message")
        asset_id, version = struct.unpack(FORMAT, message)
        asset = ledger.issuances.generate_asset_name(asset_id)
    except Exception:  # pylint: disable=broad-exception-caught
        asset, version = "", 0
    if return_dict:
        return {"asset": asset, "version": version}
    return asset, version


def parse(db, tx, message):
    asset, version = unpack(message)
    if asset == "":
        problems, fairbooster, supply = ["could not unpack"], None, None
    else:
        problems, fairbooster, supply = validate(
            db, tx["source"], asset, version, block_index=tx["block_index"]
        )

    if problems:
        status = "invalid: " + "; ".join(problems)
        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "block_index": tx["block_index"],
            "source": tx["source"],
            "fairbooster": asset if fairbooster else None,
            "version": version,
            "paid_quantity": 0,
            "cards_per_booster": 0,
            "status": status,
        }
        ledger.events.insert_record(
            db, "fairbooster_purchases", bindings, "NEW_FAIRBOOSTER_PURCHASE"
        )
        ledger.blocks.set_transaction_status(db, tx["tx_index"], False)
        logger.info("Booster purchase %s is invalid: %s", tx["tx_hash"], status)
        return

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
        "version": version,
        "paid_quantity": price,
        "cards_per_booster": fairbooster["cards_per_booster"],
        "cards_base_url": fairbooster["cards_base_url"],
        "cards_image_extension": fairbooster["cards_image_extension"],
        "status": "valid",
    }
    ledger.events.insert_record(db, "fairbooster_purchases", bindings, "NEW_FAIRBOOSTER_PURCHASE")
    update_data = {
        "boosters_sold": fairbooster["boosters_sold"] + 1,
        "cards_sold": fairbooster["cards_sold"] + fairbooster["cards_per_booster"],
    }
    update_data["status"] = fairbooster_mod.get_status({**fairbooster, **update_data}, supply)
    ledger.fairboosters.update_fairbooster(db, fairbooster["tx_hash"], update_data)
    ledger.blocks.set_transaction_status(db, tx["tx_index"], True)
    logger.info("Booster of %s bought by %s for %s XCP.", asset, tx["source"], price)
