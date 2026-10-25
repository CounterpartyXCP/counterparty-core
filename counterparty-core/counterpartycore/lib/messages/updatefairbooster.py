"""`updatefairbooster`: the owner of a fairbooster (the issuer of its asset)
changes its parameters and/or adds cards. The name and the existing cards
cannot change. Raising the capacity (`max_boosters * cards_per_booster`) above
what was already paid for costs `fairbooster.FEE_PER_CARD` per added card;
lowering it refunds nothing, and `max_boosters` cannot go below the number of
boosters sold."""

import logging
import struct

import cbor2

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import fairbooster as fairbooster_mod
from counterpartycore.lib.messages import gas
from counterpartycore.lib.parser import protocol
from counterpartycore.lib.utils import helpers

logger = logging.getLogger(config.LOGGER_NAME)

ID = 131

PARAMETERS = fairbooster_mod.PARAMETERS


def validate(db, source, asset, params, cards, block_index=None):
    """Returns `(problems, fee, capacity)`."""
    if not protocol.enabled("fairboosters", block_index=block_index):
        return ["fairboosters are not enabled"], 0, 0
    if not isinstance(asset, str) or asset == "":
        return ["invalid fairbooster name"], 0, 0
    fairbooster = ledger.fairboosters.get_fairbooster(db, asset)
    if fairbooster is None:
        return [f"fairbooster `{asset}` not found"], 0, 0

    problems = []
    owner = ledger.issuances.get_asset(db, asset)["issuer"]
    if owner != source:
        problems.append(f"fairbooster `{asset}` is not owned by `{source}`")
    if not isinstance(params, dict) or any(key not in PARAMETERS for key in params):
        return problems + ["invalid parameters"], 0, 0
    params = {key: value for key, value in params.items() if value is not None}
    if not params and cards == []:
        problems.append("nothing to update")
    problems += fairbooster_mod.validate_parameters(params, creation=False)
    problems += fairbooster_mod.validate_cards(
        asset, cards, ledger.fairboosters.get_fairbooster_cards(db, asset)
    )
    if problems:
        return problems, 0, 0

    max_boosters = params.get("max_boosters", fairbooster["max_boosters"])
    cards_per_booster = params.get("cards_per_booster", fairbooster["cards_per_booster"])
    if max_boosters < fairbooster["boosters_sold"]:
        problems.append(
            f"`max_boosters` must be >= the number of boosters sold ({fairbooster['boosters_sold']})"
        )
    balance = ledger.balances.get_balance(db, source, config.XCP)
    capacity_problems, capacity, fee = fairbooster_mod.validate_capacity(
        max_boosters, cards_per_booster, fairbooster["paid_capacity"], balance
    )
    problems += capacity_problems
    return problems, fee, capacity


def compose(
    db,
    source: str,
    asset: str,
    description: str = None,
    image_url: str = None,
    price: int = None,
    max_boosters: int = None,
    cards_per_booster: int = None,
    cards_base_url: str = None,
    cards_image_extension: str = None,
    cards: str = None,
    skip_validation: bool = False,
):
    cards = fairbooster_mod.parse_cards(cards)
    if cards_image_extension is not None:
        cards_image_extension = cards_image_extension.lstrip(".")
    values = {
        "description": description,
        "image_url": image_url,
        "price": price,
        "max_boosters": max_boosters,
        "cards_per_booster": cards_per_booster,
        "cards_base_url": cards_base_url,
        "cards_image_extension": cards_image_extension,
    }
    params = {key: value for key, value in values.items() if value is not None}
    problems, _fee, _capacity = validate(
        db, source, asset, params, cards, block_index=CurrentState().current_block_index()
    )
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    # parameters are keyed by their position in `PARAMETERS`
    wire_params = {PARAMETERS.index(key): value for key, value in params.items()}
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    data += cbor2.dumps([ledger.issuances.generate_asset_id(asset), wire_params, cards])
    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        fields = cbor2.loads(message)
        if not isinstance(fields, list) or len(fields) != 3 or not isinstance(fields[1], dict):
            raise exceptions.UnpackError("invalid updatefairbooster message")
        asset = ledger.issuances.generate_asset_name(fields[0])
        params = {}
        for key, value in fields[1].items():
            if not isinstance(key, int) or isinstance(key, bool) or not 0 <= key < len(PARAMETERS):
                raise exceptions.UnpackError("invalid updatefairbooster parameter")
            params[PARAMETERS[key]] = value
        cards = fields[2]
    except Exception:  # pylint: disable=broad-exception-caught
        asset, params, cards = "", {}, []
    if return_dict:
        return {"asset": asset, **params, "cards": fairbooster_mod.cards_to_dicts(cards)}
    return asset, params, cards


def parse(db, tx, message):
    asset, params, cards = unpack(message)
    if asset == "":
        problems, fee, capacity = ["could not unpack"], 0, 0
    else:
        problems, fee, capacity = validate(
            db, tx["source"], asset, params, cards, block_index=tx["block_index"]
        )

    status = "valid"
    if problems:
        status = "invalid: " + "; ".join(problems)
    fairbooster = ledger.fairboosters.get_fairbooster(db, asset) if asset else None

    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "fairbooster": asset if fairbooster else None,
        **{name: params.get(name) for name in PARAMETERS},
        "cards_added": len(cards) if isinstance(cards, list) else 0,
        "fee_paid": fee,
        "status": status,
    }
    # CBOR values of any type reach the bindings of an invalid update
    helpers.null_unbindable_values(bindings)
    ledger.events.insert_record(db, "fairbooster_updates", bindings, "NEW_FAIRBOOSTER_UPDATE")
    ledger.blocks.set_transaction_status(db, tx["tx_index"], status == "valid")
    if problems:
        logger.info("Fairbooster update %s is invalid: %s", tx["tx_hash"], status)
        return

    if fee > 0:
        gas.pay_fee(db, tx, tx["source"], fee, "fairbooster update fee")
    update_data = {key: value for key, value in params.items() if value is not None}
    update_data["card_count"] = fairbooster["card_count"] + len(cards)
    update_data["paid_capacity"] = max(capacity, fairbooster["paid_capacity"])
    update_data["fee_paid"] = fairbooster["fee_paid"] + fee
    max_boosters = update_data.get("max_boosters", fairbooster["max_boosters"])
    update_data["status"] = "open" if fairbooster["boosters_sold"] < max_boosters else "closed"
    ledger.fairboosters.update_fairbooster(db, fairbooster["tx_hash"], update_data)
    fairbooster_mod.insert_cards(db, tx, asset, cards)
    logger.info("Fairbooster %s updated by %s.", asset, tx["source"])
