"""Fairboosters (`fairboosters`): boosters of trading cards sold for XCP.

A fairbooster is created with its own asset (`<name>`, supply 1, locked) and a
list of cards. Each card has an id, a name, the hash of its image, a draw weight
and a supply (0: unlimited). A `buybooster` pays the fairbooster's price to the
owner of its asset; in the next block, `cards_per_booster` cards are drawn among
the cards the fairbooster had when the booster was bought, and each one becomes
an asset of its own, `<name>.<card_id>.<card_name>.<serial>`, with a supply of 1
and locked quantity and description, issued to the buyer.

Creating a fairbooster costs `ASSET_FEE` when its asset is a named one (a
numeric asset is free, as with `issuance`, and the fee is recorded the same way:
as the `fee_paid` of its issuance), plus a gas fee
(`gas.get_transaction_fee_for_count`, transaction id `ID`) for each card it can
sell: its capacity, the cards of the boosters sold plus `cards_per_booster` for
each booster left. Raising that capacity later with `updatefairbooster` pays
the gas fee of the added cards. Every parameter except the name and the
existing cards can be updated, and cards can be added.

The miner of the block that draws a booster could withhold that block to draw
again, at the cost of its reward.
"""

import bisect
import hashlib
import logging
import re
import struct

import cbor2

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import gas
from counterpartycore.lib.parser import protocol
from counterpartycore.lib.utils import assetnames

logger = logging.getLogger(config.LOGGER_NAME)

ID = 130

# The fee of a named fairbooster asset, as for a named asset issuance.
ASSET_FEE = int(0.5 * config.UNIT)
# Bounds on the work of a fairbooster: a draw scans the cards, and each drawn
# card is an asset creation.
MAX_CARDS = 10000
MAX_CARDS_PER_BOOSTER = 100
IMAGE_HASH_LENGTH = 32
# matched with `fullmatch`: `$` would also accept a trailing newline
IMAGE_EXTENSION_PATTERN = re.compile(r"[A-Za-z0-9]{1,16}")
# Card asset names end with a serial number: room for the largest one.
MAX_SERIAL = "9" * len(str(config.MAX_INT))

# The parameters `updatefairbooster` can change, by wire key.
PARAMETERS = (
    "description",
    "image_url",
    "price",
    "max_boosters",
    "cards_per_booster",
    "cards_base_url",
    "cards_image_extension",
)


def is_int(value):
    return isinstance(value, int) and not isinstance(value, bool)


def card_child_name(name):
    """The asset name form of a card name: spaces become `_`."""
    return name.replace(" ", "_")


def card_asset_longname(fairbooster_asset, card_id, name, serial):
    return f"{fairbooster_asset}.{card_id}.{card_child_name(name)}.{serial}"


def card_image_url(cards_base_url, card_id, cards_image_extension):
    return f"{cards_base_url.rstrip('/')}/{card_id}.{cards_image_extension}"


def parse_cards(cards):
    """Compose-side parsing of a card list: either the string
    `<id>:<name>:<image_hash>:<weight>:<supply>, ...` or a list of such
    5-tuples. Returns the wire form `[[id, name, image_hash_bytes, weight,
    supply], ...]`."""
    if cards is None or cards == "":
        return []
    if isinstance(cards, str):
        entries = [entry.strip() for entry in cards.split(",")]
        entries = [entry.split(":") for entry in entries if entry]
    else:
        entries = list(cards)
    parsed = []
    for entry in entries:
        if len(entry) != 5:
            raise exceptions.ComposeError(
                f"invalid card `{':'.join(str(part) for part in entry)}`: expected "
                "<id>:<name>:<image_hash>:<weight>:<supply>"
            )
        card_id, name, image_hash, weight, max_supply = entry
        try:
            card_id, weight, max_supply = int(card_id), int(weight), int(max_supply)
        except (TypeError, ValueError) as e:
            raise exceptions.ComposeError(
                f"invalid card `{card_id}`: id, weight and supply must be integers"
            ) from e
        try:
            image_hash = bytes.fromhex(str(image_hash).strip())
        except ValueError as e:
            raise exceptions.ComposeError(
                f"invalid card `{card_id}`: image_hash must be hexadecimal"
            ) from e
        parsed.append([card_id, str(name).strip(), image_hash, weight, max_supply])
    return parsed


def validate_parameters(params, creation):
    """Check fairbooster parameters (`PARAMETERS` keys). On an update, a
    missing or None parameter is left unchanged."""
    problems = []
    for name in ("description", "image_url", "cards_base_url", "cards_image_extension"):
        value = params.get(name)
        if value is None and not creation:
            continue
        if not isinstance(value, str):
            problems.append(f"`{name}` must be a string")
    if isinstance(params.get("cards_base_url"), str) and params["cards_base_url"] == "":
        problems.append("`cards_base_url` must not be empty")
    extension = params.get("cards_image_extension")
    if isinstance(extension, str) and not IMAGE_EXTENSION_PATTERN.fullmatch(extension):
        problems.append("`cards_image_extension` must be 1 to 16 letters or digits")
    for name, minimum, maximum in (
        ("price", 0, config.MAX_INT),
        ("max_boosters", 1, config.MAX_INT),
        ("cards_per_booster", 1, MAX_CARDS_PER_BOOSTER),
    ):
        value = params.get(name)
        if value is None and not creation:
            continue
        if not is_int(value):
            problems.append(f"`{name}` must be an integer")
        elif not minimum <= value <= maximum:
            problems.append(f"`{name}` must be between {minimum} and {maximum}")
    return problems


def validate_cards(fairbooster_asset, cards, existing_cards=()):
    """Check new cards (wire form) against each other and against the
    fairbooster's `existing_cards`."""
    if not isinstance(cards, list):
        return ["`cards` must be a list"]
    if len(existing_cards) + len(cards) > MAX_CARDS:
        return [f"too many cards (maximum {MAX_CARDS})"]
    problems = []
    card_ids = {card["card_id"] for card in existing_cards}
    image_hashes = {card["image_hash"] for card in existing_cards}
    total_weight = sum(card["weight"] for card in existing_cards)
    total_supply = sum(card["max_supply"] for card in existing_cards)
    for position, card in enumerate(cards, start=1):
        if not isinstance(card, list) or len(card) != 5:
            problems.append(f"card #{position} must be [id, name, image_hash, weight, supply]")
            continue
        card_id, name, image_hash, weight, max_supply = card
        if not is_int(card_id) or not 0 <= card_id <= config.MAX_INT:
            problems.append(
                f"card #{position}: id must be an integer between 0 and {config.MAX_INT}"
            )
            continue
        label = f"card {card_id}"
        if card_id in card_ids:
            problems.append(f"{label}: duplicate id")
        card_ids.add(card_id)
        if not isinstance(name, str) or name == "" or name != name.strip():
            problems.append(f"{label}: name must be a non-empty string without surrounding spaces")
        elif ":" in name or "," in name:
            problems.append(f"{label}: name must not contain `:` or `,`")
        else:
            try:
                assetnames.validate_subasset_longname(
                    card_asset_longname(fairbooster_asset, card_id, name, MAX_SERIAL)
                )
            except exceptions.AssetNameError as e:
                problems.append(f"{label}: invalid card asset name: {e.args[0]}")
        if not isinstance(image_hash, bytes) or len(image_hash) != IMAGE_HASH_LENGTH:
            problems.append(f"{label}: image_hash must be {IMAGE_HASH_LENGTH} bytes")
        elif image_hash.hex() in image_hashes:
            problems.append(f"{label}: duplicate image_hash")
        else:
            image_hashes.add(image_hash.hex())
        if not is_int(weight) or not 1 <= weight <= config.MAX_INT:
            problems.append(f"{label}: weight must be between 1 and {config.MAX_INT}")
        else:
            total_weight += weight
        if not is_int(max_supply) or not 0 <= max_supply <= config.MAX_INT:
            problems.append(f"{label}: supply must be between 0 and {config.MAX_INT}")
        else:
            total_supply += max_supply
    if total_weight > config.MAX_INT:
        problems.append("total card weight exceeds maximum value")
    if total_supply > config.MAX_INT:
        problems.append("total card supply exceeds maximum value")
    return problems


def asset_fee(asset):
    """The fee of the fairbooster asset: named assets pay, numeric ones are free."""
    return 0 if asset.startswith("A") else ASSET_FEE


def capacity(max_boosters, cards_per_booster, boosters_sold=0, cards_sold=0):
    """The number of cards a fairbooster can sell: those of the boosters sold,
    whatever `cards_per_booster` was when they were bought, plus a full booster
    for each booster left."""
    return cards_sold + (max_boosters - boosters_sold) * cards_per_booster


def capacity_fee(db, block_index, added_capacity, limit=config.MAX_INT):
    """The gas fee of `added_capacity` cards, or None above `limit`."""
    return gas.get_transaction_fee_for_count(db, ID, block_index, added_capacity, limit=limit)


def validate_capacity(db, block_index, new_capacity, paid_capacity, balance, other_fee=0):
    """Check that `new_capacity` is representable and that `balance` pays
    `other_fee` plus the gas fee of the cards above `paid_capacity`. Returns
    `(problems, fee)`, `fee` being the gas fee."""
    if new_capacity > config.MAX_INT:
        return ["`max_boosters` * `cards_per_booster` exceeds maximum value"], 0
    limit = balance - other_fee
    fee = None
    if limit >= 0:
        fee = capacity_fee(db, block_index, new_capacity - paid_capacity, limit=limit)
    if fee is None:
        return ["insufficient XCP balance to pay the fee"], 0
    return [], fee


def get_status(fairbooster, supply):
    """`closed` once no booster can be sold: every booster is sold, or the
    cards left (out of `supply`, None when a card is unlimited) cannot fill
    one."""
    if fairbooster["boosters_sold"] >= fairbooster["max_boosters"]:
        return "closed"
    if supply is not None and supply - fairbooster["cards_sold"] < fairbooster["cards_per_booster"]:
        return "closed"
    return "open"


def card_supply(cards):
    """The number of copies of the wire `cards`, None when one is unlimited
    (see `ledger.fairboosters.get_card_supply`)."""
    supplies = [card[4] for card in cards]
    return None if 0 in supplies else sum(supplies)


def get_fee(db, asset, max_boosters, cards_per_booster, block_index):
    """The XCP fee of creating the fairbooster `asset`: its asset fee plus the
    gas fee of its capacity. None when it exceeds `config.MAX_INT`."""
    new_capacity = capacity(max_boosters, cards_per_booster)
    if new_capacity > config.MAX_INT:
        return None
    fee = capacity_fee(db, block_index, new_capacity)
    if fee is None:
        return None
    return asset_fee(asset) + fee


def earmarked_lp_asset(db, asset):
    """Whether an active fairminter earmarked `asset` as the lp_asset of the
    pool it creates at its soft cap: the name has no issuance yet, but the LP
    issuance would land on whatever asset holds it by then."""
    return ledger.issuances.get_active_fairminter_by_lp_asset(db, asset) is not None


def validate(db, source, asset, params, cards, block_index=None):
    """Returns `(problems, fee)`, `fee` being the gas fee of the capacity."""
    problems = []
    if not protocol.enabled("fairboosters", block_index=block_index):
        return ["fairboosters are not enabled"], 0
    block_index = block_index or CurrentState().current_block_index()

    if not isinstance(asset, str) or asset == "":
        return ["invalid fairbooster name"], 0
    if asset in (config.BTC, config.XCP) or "." in asset:
        problems.append("the fairbooster name must be a named or numeric asset")
    else:
        try:
            ledger.issuances.generate_asset_id(asset)
        except exceptions.AssetNameError as e:
            problems.append(f"invalid fairbooster name: {e}")
    if not problems:
        if ledger.issuances.get_asset(db, asset) is not None:
            problems.append(f"asset `{asset}` already exists")
        elif earmarked_lp_asset(db, asset):
            problems.append(f"`{asset}` is earmarked as lp_asset by an active fairminter")

    problems += validate_parameters(params, creation=True)
    if cards == []:
        problems.append("a fairbooster needs at least one card")
    problems += validate_cards(asset, cards)
    if problems:
        return problems, 0

    balance = ledger.balances.get_balance(db, source, config.XCP)
    return validate_capacity(
        db,
        block_index,
        capacity(params["max_boosters"], params["cards_per_booster"]),
        0,
        balance,
        other_fee=asset_fee(asset),
    )


def compose(
    db,
    source: str,
    asset: str,
    price: int,
    max_boosters: int,
    cards_per_booster: int,
    cards_base_url: str,
    cards_image_extension: str,
    cards: str,
    description: str = "",
    image_url: str = "",
    skip_validation: bool = False,
):
    cards = parse_cards(cards)
    params = {
        "description": description,
        "image_url": image_url,
        "price": price,
        "max_boosters": max_boosters,
        "cards_per_booster": cards_per_booster,
        "cards_base_url": cards_base_url,
        "cards_image_extension": (cards_image_extension or "").lstrip("."),
    }
    problems, _fee = validate(
        db, source, asset, params, cards, block_index=CurrentState().current_block_index()
    )
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    data += cbor2.dumps(
        [ledger.issuances.generate_asset_id(asset)]
        + [params[name] for name in PARAMETERS]
        + [cards]
    )
    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        fields = cbor2.loads(message)
        if not isinstance(fields, list) or len(fields) != len(PARAMETERS) + 2:
            raise exceptions.UnpackError("invalid fairbooster message")
        asset = ledger.issuances.generate_asset_name(fields[0])
        params = dict(zip(PARAMETERS, fields[1:-1], strict=True))
        cards = fields[-1]
    except Exception:  # pylint: disable=broad-exception-caught
        asset, params, cards = "", {}, []
    if return_dict:
        return {"asset": asset, **params, "cards": cards_to_dicts(cards)}
    return asset, params, cards


def cards_to_dicts(cards):
    """Readable form of wire cards, for the API."""
    if not isinstance(cards, list):
        return cards
    readable = []
    for card in cards:
        if isinstance(card, list) and len(card) == 5:
            image_hash = card[2].hex() if isinstance(card[2], bytes) else card[2]
            readable.append(
                {
                    "card_id": card[0],
                    "name": card[1],
                    "image_hash": image_hash,
                    "weight": card[3],
                    "max_supply": card[4],
                }
            )
        else:
            readable.append(card)
    return readable


def insert_cards(db, tx, fairbooster_asset, cards):
    for card_id, name, image_hash, weight, max_supply in cards:
        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "block_index": tx["block_index"],
            "fairbooster": fairbooster_asset,
            "card_id": card_id,
            "name": name,
            "image_hash": image_hash.hex(),
            "weight": weight,
            "max_supply": max_supply,
        }
        ledger.events.insert_record(db, "fairbooster_cards", bindings, "NEW_FAIRBOOSTER_CARD")


def issue_locked_asset(
    db,
    tx,
    block_index,
    asset,
    issuer,
    description,
    asset_events,
    action,
    asset_longname=None,
    description_locked=False,
    fee_paid=0,
    msg_index=None,
):
    """Create `asset` with a supply of 1, indivisible and locked, and credit it
    to `issuer`: the asset of a fairbooster (`tx` is its creation) or of a
    drawn card (`tx` is the purchase of its booster)."""
    ledger.events.insert_record(
        db,
        "assets",
        {
            "asset_id": str(ledger.issuances.generate_asset_id(asset)),
            "asset_name": asset,
            "block_index": block_index,
            "asset_longname": asset_longname,
        },
        "ASSET_CREATION",
    )
    bindings = {"tx_index": tx["tx_index"], "tx_hash": tx["tx_hash"]}
    if msg_index is not None:
        bindings["msg_index"] = msg_index
    bindings |= {
        "block_index": block_index,
        "asset": asset,
        "quantity": 1,
        "divisible": False,
        "source": issuer,
        "issuer": issuer,
        "transfer": False,
        "callable": False,
        "call_date": 0,
        "call_price": 0,
        "description": description,
        "fee_paid": fee_paid,
        "locked": True,
        "reset": False,
        "status": "valid",
        "asset_longname": asset_longname,
        "description_locked": description_locked,
        "fair_minting": False,
        "asset_events": asset_events,
        "mime_type": "text/plain",
    }
    ledger.events.insert_record(db, "issuances", bindings, "ASSET_ISSUANCE")
    ledger.events.credit(db, issuer, asset, 1, tx["tx_index"], action=action, event=tx["tx_hash"])


def parse(db, tx, message):
    asset, params, cards = unpack(message)
    if asset == "":
        problems, fee = ["could not unpack"], 0
    else:
        problems, fee = validate(
            db, tx["source"], asset, params, cards, block_index=tx["block_index"]
        )

    if problems:
        status = "invalid: " + "; ".join(problems)
        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "block_index": tx["block_index"],
            "source": tx["source"],
            "status": status,
        }
        ledger.events.insert_record(db, "fairboosters", bindings, "NEW_FAIRBOOSTER")
        logger.info("Fairbooster %s is invalid: %s", tx["tx_hash"], status)
        ledger.blocks.set_transaction_status(db, tx["tx_index"], False)
        return

    new_capacity = capacity(params["max_boosters"], params["cards_per_booster"])
    fee_asset = asset_fee(asset)

    # the fairbooster asset: supply 1, locked, owned by the creator
    issue_locked_asset(
        db,
        tx,
        tx["block_index"],
        asset,
        tx["source"],
        params["description"],
        "open_fairbooster",
        "fairbooster",
        fee_paid=fee_asset,
    )
    if fee_asset > 0:
        # The issuance records the asset fee in its `fee_paid`, which
        # `ledger.supplies.xcp_destroyed` already counts as destroyed, like the
        # fee of an issuance: a `destructions` row would count it twice.
        gas.pay_fee(db, tx, tx["source"], fee_asset, "fairbooster asset fee", destroy=False)
    if fee > 0:
        gas.pay_fee(db, tx, tx["source"], fee, "fairbooster fee")
    gas.increment_counter(db, ID, tx["block_index"], count=new_capacity)

    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "asset": asset,
        **params,
        "card_count": len(cards),
        "boosters_sold": 0,
        "cards_sold": 0,
        "paid_capacity": new_capacity,
        "fee_paid": fee_asset + fee,
    }
    bindings["status"] = get_status(bindings, card_supply(cards))
    ledger.events.insert_record(db, "fairboosters", bindings, "NEW_FAIRBOOSTER")
    insert_cards(db, tx, asset, cards)
    ledger.blocks.set_transaction_status(db, tx["tx_index"], True)
    logger.info("Fairbooster %s created by %s with %s cards.", asset, tx["source"], len(cards))


# Draws


class DrawTable:
    """The weighted draw of the cards of a fairbooster, in the order they were
    added. A Fenwick tree holds the weights, an exhausted card weighing 0, so
    that picking a card and taking an exhausted one out of the draw are
    O(log n): a block can drain thousands of cards of supply 1. `drawn` is
    `{card_id: (copies, last serial)}`, kept up to date by `draw`."""

    def __init__(self, cards, drawn):
        self.cards = cards
        self.drawn = drawn
        size = len(cards)
        self.tree = [0] * (size + 1)
        for position, card in enumerate(cards, start=1):
            if not self.exhausted(card):
                self.tree[position] += card["weight"]
            parent = position + (position & -position)
            if parent <= size:
                self.tree[parent] += self.tree[position]

    def exhausted(self, card):
        copies = self.drawn.get(card["card_id"], (0, 0))[0]
        return 0 < card["max_supply"] <= copies

    def _remove(self, position, weight):
        while position < len(self.tree):
            self.tree[position] -= weight
            position += position & -position

    def total_weight(self, card_count):
        """The weight of the cards left among the first `card_count`."""
        total = 0
        while card_count > 0:
            total += self.tree[card_count]
            card_count -= card_count & -card_count
        return total

    def find(self, position):
        """The index of the first card whose cumulative weight exceeds
        `position`, for 0 <= `position` < the total weight: it is never an
        exhausted card, whose cumulative weight is that of the previous one."""
        index = 0
        step = 1 << (len(self.tree) - 1).bit_length()
        while step:
            if index + step < len(self.tree) and self.tree[index + step] <= position:
                index += step
                position -= self.tree[index]
            step >>= 1
        return index

    def draw(self, block_hash, tx_hash, count, card_count=None):
        """Draw `count` cards for the purchase `tx_hash`, resolved in the block
        `block_hash`, among the first `card_count` cards (all of them by
        default). The i-th card is picked with a probability proportional to
        its weight among those that are not exhausted, from `sha256(block_hash
        || tx_hash || i)` read as a 256-bit integer, so that the modulo bias is
        negligible: unknown when the booster is bought, identical on every
        node. Returns the drawn cards as `(card, copies, serial)`, `copies`
        counting this one."""
        card_count = len(self.cards) if card_count is None else card_count
        seed_prefix = bytes.fromhex(block_hash) + bytes.fromhex(tx_hash)
        result = []
        for i in range(count):
            total_weight = self.total_weight(card_count)
            if total_weight == 0:
                # Unreachable: `buybooster.validate` reserves the cards of every
                # pending purchase. Halt rather than silently drop paid cards.
                raise exceptions.ParseTransactionError(
                    f"booster {tx_hash}: no card left to draw at block {block_hash}"
                )
            digest = hashlib.sha256(seed_prefix + i.to_bytes(4, "big")).digest()
            index = self.find(int.from_bytes(digest, "big") % total_weight)
            card = self.cards[index]
            copies, last_serial = self.drawn.get(card["card_id"], (0, 0))
            self.drawn[card["card_id"]] = (copies + 1, last_serial + 1)
            if self.exhausted(card):
                self._remove(index + 1, card["weight"])
            result.append((card, copies + 1, last_serial + 1))
        return result


def card_asset_name(db, longname):
    """The numeric asset of a card, derived from its long name like a
    fairminter subasset, skipping the names an active fairminter earmarked as
    its lp_asset: the card names can be computed in advance."""
    return assetnames.deterministic_random_asset_name(
        db, longname, is_reserved=lambda name: earmarked_lp_asset(db, name)
    )


def issue_card(db, purchase, fairbooster, card, copies, serial, msg_index, block_index):
    """Create the asset of a drawn card and credit it to the buyer."""
    longname = card_asset_longname(fairbooster["asset"], card["card_id"], card["name"], serial)
    card_asset = card_asset_name(db, longname)
    issue_locked_asset(
        db,
        purchase,
        block_index,
        card_asset,
        purchase["source"],
        card_image_url(
            fairbooster["cards_base_url"], card["card_id"], fairbooster["cards_image_extension"]
        ),
        "fairbooster_draw",
        "fairbooster draw",
        asset_longname=longname,
        description_locked=True,
        msg_index=msg_index,
    )
    ledger.events.insert_record(
        db,
        "fairbooster_draws",
        {
            "tx_index": purchase["tx_index"],
            "tx_hash": purchase["tx_hash"],
            "block_index": block_index,
            "source": purchase["source"],
            "fairbooster": fairbooster["asset"],
            "card_id": card["card_id"],
            "copy_number": copies,
            "serial": serial,
            "asset": card_asset,
        },
        "NEW_FAIRBOOSTER_DRAW",
    )


def next_free_serial(db, fairbooster_asset, card, serial):
    """`serial`, or the next one whose card asset name is free. Subassets of a
    fairbooster can only be created by its draws, so this is a safety net."""
    while ledger.issuances.get_assets_by_longname(
        db, card_asset_longname(fairbooster_asset, card["card_id"], card["name"], serial)
    ):
        serial += 1
    return serial


def draw_boosters(db, block_index):
    """Draw the cards of every booster bought in the previous block, seeded by
    this block's hash. A booster is drawn among the cards of its fairbooster
    when it was bought: a later transaction of its block cannot add cards to
    its draw."""
    if block_index == config.MEMPOOL_BLOCK_INDEX:
        return
    if not protocol.enabled("fairboosters", block_index=block_index):
        return
    purchases = ledger.fairboosters.get_purchases_to_draw(db, block_index - 1)
    if not purchases:
        return
    block_hash = ledger.blocks.get_block_hash(db, block_index)
    # No transaction is parsed while the boosters are drawn: each fairbooster,
    # its cards and their draw table are loaded once per block and kept up to
    # date in memory.
    loaded = {}
    for purchase in purchases:
        fairbooster_asset = purchase["fairbooster"]
        if fairbooster_asset not in loaded:
            cards = ledger.fairboosters.get_fairbooster_cards(db, fairbooster_asset)
            loaded[fairbooster_asset] = (
                ledger.fairboosters.get_fairbooster(db, fairbooster_asset),
                DrawTable(cards, ledger.fairboosters.get_drawn_cards(db, fairbooster_asset)),
                [card["tx_index"] for card in cards],
            )
        fairbooster, table, card_tx_indexes = loaded[fairbooster_asset]
        # the cards are in the order they were added: those of the purchase are
        # the ones added by an earlier transaction
        card_count = bisect.bisect_left(card_tx_indexes, purchase["tx_index"])
        draws = table.draw(block_hash, purchase["tx_hash"], purchase["card_count"], card_count)
        for msg_index, (card, copies, drawn_serial) in enumerate(draws):
            serial = next_free_serial(db, fairbooster["asset"], card, drawn_serial)
            # keep the highest serial, as `get_drawn_cards` would read it
            last_copies, last_serial = table.drawn[card["card_id"]]
            table.drawn[card["card_id"]] = (last_copies, max(last_serial, serial))
            issue_card(db, purchase, fairbooster, card, copies, serial, msg_index, block_index)
        logger.info(
            "%s card(s) of %s drawn for %s (booster %s)",
            purchase["card_count"],
            fairbooster["asset"],
            purchase["source"],
            purchase["tx_hash"],
        )


# This function is called on each block BEFORE parsing the transactions
def before_block(db, block_index):
    draw_boosters(db, block_index)
