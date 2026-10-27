"""`updatefairbooster`: the owner of a fairbooster (the issuer of its asset)
changes its parameters and/or adds cards. The name and the existing cards
cannot change, and the cards must still fill a booster. Raising the capacity
(`fairbooster.capacity`: the cards of the boosters sold plus
`cards_per_booster` for each booster left) above what was already paid for
pays the gas fee of the added cards, at most `max_xcp_fee`; lowering it refunds
nothing, and `max_boosters` cannot go below the number of boosters sold. A
valid update increments the `version` of the fairbooster: the purchases that
named the previous one are invalid (see `buybooster`)."""

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


def validate(db, source, asset, params, cards, max_xcp_fee, block_index=None):
    """Returns `(problems, fee, capacity, fairbooster)`, `fairbooster` being
    the current row of the fairbooster (None when there is none)."""
    if not protocol.enabled("fairboosters", block_index=block_index):
        return ["fairboosters are not enabled"], 0, 0, None
    block_index = block_index or CurrentState().current_block_index()
    if not isinstance(asset, str) or asset == "":
        return ["invalid fairbooster name"], 0, 0, None
    fairbooster = ledger.fairboosters.get_fairbooster(db, asset)
    if fairbooster is None:
        return [f"fairbooster `{asset}` not found"], 0, 0, None

    problems = []
    owner = ledger.issuances.get_asset(db, asset)["issuer"]
    if owner != source:
        problems.append(f"fairbooster `{asset}` is not owned by `{source}`")
    if not isinstance(params, dict) or any(key not in PARAMETERS for key in params):
        return problems + ["invalid parameters"], 0, 0, fairbooster
    params = {key: value for key, value in params.items() if value is not None}
    if not params and cards == []:
        problems.append("nothing to update")
    problems += fairbooster_mod.validate_parameters(params, creation=False)
    problems += fairbooster_mod.validate_cards(
        asset, cards, ledger.fairboosters.get_fairbooster_cards(db, asset)
    )
    problems += fairbooster_mod.validate_max_xcp_fee(max_xcp_fee)
    if problems:
        return problems, 0, 0, fairbooster

    max_boosters = params.get("max_boosters", fairbooster["max_boosters"])
    cards_per_booster = params.get("cards_per_booster", fairbooster["cards_per_booster"])
    if max_boosters < fairbooster["boosters_sold"]:
        return (
            [
                "`max_boosters` must be >= the number of boosters sold "
                f"({fairbooster['boosters_sold']})"
            ],
            0,
            0,
            fairbooster,
        )
    if "cards_per_booster" in params:
        # adding cards only raises the supply: the check holds otherwise
        problems = fairbooster_mod.validate_booster_size(
            cards_per_booster, card_supply(db, asset, cards)
        )
        if problems:
            return problems, 0, 0, fairbooster
    capacity = fairbooster_mod.capacity(
        max_boosters, cards_per_booster, fairbooster["boosters_sold"], fairbooster["cards_sold"]
    )
    balance = ledger.balances.get_balance(db, source, config.XCP)
    problems, fee = fairbooster_mod.validate_capacity(
        db, block_index, capacity, fairbooster["paid_capacity"], balance, max_xcp_fee
    )
    if problems:
        return problems, 0, 0, fairbooster
    return problems, fee, capacity, fairbooster


def card_supply(db, asset, cards):
    """The number of copies of the cards of the fairbooster `asset` once the
    wire `cards` are added, None when one is unlimited."""
    existing = ledger.fairboosters.get_card_supply(db, asset)
    added = fairbooster_mod.card_supply(cards)
    if existing is None or added is None:
        return None
    return existing + added


def get_fee(db, asset, max_boosters=None, cards_per_booster=None, block_index=None, ahead=0):
    """The gas fee of setting the fairbooster `asset` to `max_boosters` and
    `cards_per_booster` (None: unchanged), that of the cards it adds above the
    paid capacity (`ahead`: see `fairbooster.capacity_fee`). None when the
    capacity or the fee exceeds `config.MAX_INT`."""
    fairbooster = ledger.fairboosters.get_fairbooster(db, asset)
    if fairbooster is None:
        return 0
    capacity = fairbooster_mod.capacity(
        fairbooster["max_boosters"] if max_boosters is None else max_boosters,
        fairbooster["cards_per_booster"] if cards_per_booster is None else cards_per_booster,
        fairbooster["boosters_sold"],
        fairbooster["cards_sold"],
    )
    if capacity > config.MAX_INT:
        return None
    return fairbooster_mod.capacity_fee(
        db,
        block_index or CurrentState().current_block_index(),
        capacity - fairbooster["paid_capacity"],
        ahead=ahead,
    )


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
    max_xcp_fee: int = None,
    skip_validation: bool = False,
):
    """`max_xcp_fee` defaults to `fairbooster.default_max_xcp_fee`."""
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
    block_index = CurrentState().current_block_index()
    if max_xcp_fee is None:
        max_xcp_fee = fairbooster_mod.default_max_xcp_fee(
            get_fee, db, asset, max_boosters, cards_per_booster, block_index
        )
    problems, _fee, _capacity, _fairbooster = validate(
        db, source, asset, params, cards, max_xcp_fee, block_index=block_index
    )
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    # parameters are keyed by their position in `PARAMETERS`
    wire_params = {PARAMETERS.index(key): value for key, value in params.items()}
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    data += cbor2.dumps(
        [ledger.issuances.generate_asset_id(asset), wire_params, cards, max_xcp_fee]
    )
    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        fields = cbor2.loads(message)
        # asset id, the parameters by position in `PARAMETERS`, cards, max_xcp_fee
        if not isinstance(fields, list) or len(fields) != 4 or not isinstance(fields[1], dict):
            raise exceptions.UnpackError("invalid updatefairbooster message")
        asset = ledger.issuances.generate_asset_name(fields[0])
        params = {}
        for key, value in fields[1].items():
            if not isinstance(key, int) or isinstance(key, bool) or not 0 <= key < len(PARAMETERS):
                raise exceptions.UnpackError("invalid updatefairbooster parameter")
            params[PARAMETERS[key]] = value
        cards, max_xcp_fee = fields[2], fields[3]
    except Exception:  # pylint: disable=broad-exception-caught
        asset, params, cards, max_xcp_fee = "", {}, [], 0
    if return_dict:
        return {
            "asset": asset,
            **params,
            "cards": fairbooster_mod.cards_to_dicts(cards),
            "max_xcp_fee": fairbooster_mod.readable_amount(max_xcp_fee),
        }
    return asset, params, cards, max_xcp_fee


def parse(db, tx, message):
    asset, params, cards, max_xcp_fee = unpack(message)
    if asset == "":
        problems, fee, capacity, fairbooster = ["could not unpack"], 0, 0, None
    else:
        problems, fee, capacity, fairbooster = validate(
            db, tx["source"], asset, params, cards, max_xcp_fee, block_index=tx["block_index"]
        )

    status = "valid"
    if problems:
        status = "invalid: " + "; ".join(problems)

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
    if capacity > fairbooster["paid_capacity"]:
        gas.increment_counter(
            db, fairbooster_mod.ID, tx["block_index"], count=capacity - fairbooster["paid_capacity"]
        )
    fairbooster_mod.insert_cards(db, tx, asset, cards)
    update_data = {key: value for key, value in params.items() if value is not None}
    update_data["card_count"] = fairbooster["card_count"] + len(cards)
    update_data["version"] = fairbooster["version"] + 1
    update_data["paid_capacity"] = max(capacity, fairbooster["paid_capacity"])
    update_data["fee_paid"] = fairbooster["fee_paid"] + fee
    update_data["status"] = fairbooster_mod.get_status(
        {**fairbooster, **update_data}, ledger.fairboosters.get_card_supply(db, asset)
    )
    ledger.fairboosters.update_fairbooster(db, fairbooster["tx_hash"], update_data)
    logger.info("Fairbooster %s updated by %s.", asset, tx["source"])
