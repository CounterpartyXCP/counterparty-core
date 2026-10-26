"""Fairboosters: boosters of trading cards sold for XCP, drawn in the block that
follows each purchase (`fairboosters`)."""

import hashlib

import apsw
import cbor2
import pytest
from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.api import compose, queries
from counterpartycore.lib.messages import buybooster, fairbooster, updatefairbooster
from counterpartycore.test.mocks import bitcoind as bitcoind_mock_module
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled, run_scenario
from hypothesis import HealthCheck, given, settings
from hypothesis import strategies as st

HASH_1 = "11" * 32
HASH_2 = "22" * 32
HASH_3 = "33" * 32
# <id>:<name>:<image_hash>:<weight>:<supply> (supply 0: unlimited)
CARDS = f"1:Common Card:{HASH_1}:70:0, 2:Rare Card:{HASH_2}:25:5, 3:Legend:{HASH_3}:5:1"
ASSET_FEE = fairbooster.ASSET_FEE
BOOSTER_ID = 481982037  # generate_asset_id("BOOSTER")
DIVISIBLE_ID = 697326324582  # generate_asset_id("DIVISIBLE")
PRICE = 1000


def send(ledger_db, name, params):
    """Compose, sign and mine `name` in its own block, like the fixtures do.
    `skip_validation` composes an invalid transaction."""
    params = dict(params)
    construct_params = {"encoding": "multisig"}
    if params.pop("skip_validation", False):
        construct_params["validate"] = False
    run_scenario(ledger_db, bitcoind_mock_module, [[name, params, construct_params]])


def mine_empty_block(ledger_db):
    bitcoind_mock_module.mine_block(ledger_db, [])


def rows(ledger_db, sql, *bindings):
    return ledger_db.execute(sql, bindings).fetchall()


def last_row(ledger_db, table):
    return rows(ledger_db, f"SELECT * FROM {table} ORDER BY rowid DESC LIMIT 1")[0]  # noqa: S608


def wire_cards(cards=CARDS):
    return fairbooster.parse_cards(cards)


def creation_params(**overrides):
    params = {
        "description": "my booster",
        "image_url": "https://example.com/booster.png",
        "price": PRICE,
        "max_boosters": 10,
        "cards_per_booster": 3,
        "cards_base_url": "https://example.com/cards/",
        "cards_image_extension": "png",
    }
    params.update(overrides)
    return params


def validate(ledger_db, defaults, asset="BOOSTER", cards=None, **overrides):
    return fairbooster.validate(
        ledger_db,
        defaults["addresses"][0],
        asset,
        creation_params(**overrides),
        wire_cards() if cards is None else cards,
    )


def create(ledger_db, defaults, asset="BOOSTER", cards=CARDS, **overrides):
    params = creation_params(**overrides)
    send(
        ledger_db,
        "fairbooster",
        {"source": defaults["addresses"][0], "asset": asset, "cards": cards, **params},
    )
    return ledger.fairboosters.get_fairbooster(ledger_db, asset)


def test_parse_cards():
    assert wire_cards() == [
        [1, "Common Card", bytes.fromhex(HASH_1), 70, 0],
        [2, "Rare Card", bytes.fromhex(HASH_2), 25, 5],
        [3, "Legend", bytes.fromhex(HASH_3), 5, 1],
    ]
    assert fairbooster.parse_cards("") == []
    with pytest.raises(exceptions.ComposeError, match="expected <id>:<name>"):
        fairbooster.parse_cards("1:Common:aa:1")
    with pytest.raises(exceptions.ComposeError, match="must be integers"):
        fairbooster.parse_cards(f"x:Common:{HASH_1}:1:0")
    with pytest.raises(exceptions.ComposeError, match="hexadecimal"):
        fairbooster.parse_cards("1:Common:zz:1:0")


def test_card_names():
    assert fairbooster.card_asset_longname("BOOSTER", 2, "Rare Card", 7) == "BOOSTER.2.Rare_Card.7"
    assert fairbooster.card_image_url("https://x.io/cards/", 2, "png") == "https://x.io/cards/2.png"
    assert fairbooster.card_image_url("https://x.io/cards", 2, "svg") == "https://x.io/cards/2.svg"


def test_validate(ledger_db, defaults):
    assert validate(ledger_db, defaults) == []

    with ProtocolChangesDisabled(["fairboosters"]):
        assert validate(ledger_db, defaults) == ["fairboosters are not enabled"]

    # the name: a free named or numeric asset
    assert validate(ledger_db, defaults, asset="DIVISIBLE") == ["asset `DIVISIBLE` already exists"]
    assert validate(ledger_db, defaults, asset="A95428956661682178") == []
    assert validate(ledger_db, defaults, asset="PARENT.child") == [
        "the fairbooster name must be a named or numeric asset"
    ]
    assert validate(ledger_db, defaults, asset="XCP") == [
        "the fairbooster name must be a named or numeric asset"
    ]
    assert validate(ledger_db, defaults, asset="BOO") == ["invalid fairbooster name: too short"]

    # parameters
    assert validate(ledger_db, defaults, price=-1) == [
        f"`price` must be between 0 and {config.MAX_INT}"
    ]
    assert validate(ledger_db, defaults, max_boosters=0) == [
        f"`max_boosters` must be between 1 and {config.MAX_INT}"
    ]
    assert validate(ledger_db, defaults, cards_per_booster=101) == [
        "`cards_per_booster` must be between 1 and 100"
    ]
    assert validate(ledger_db, defaults, cards_per_booster="3") == [
        "`cards_per_booster` must be an integer"
    ]
    assert validate(ledger_db, defaults, cards_base_url="") == [
        "`cards_base_url` must not be empty"
    ]
    assert validate(ledger_db, defaults, cards_image_extension=".png") == [
        "`cards_image_extension` must be 1 to 16 letters or digits"
    ]
    assert validate(ledger_db, defaults, description=None) == ["`description` must be a string"]
    assert validate(ledger_db, defaults, max_boosters=config.MAX_INT) == [
        "`max_boosters` * `cards_per_booster` exceeds maximum value"
    ]
    # the gas fee of a huge capacity cannot be paid
    assert validate(ledger_db, defaults, max_boosters=config.MAX_INT // 3) == [
        "insufficient XCP balance to pay the fee"
    ]
    # a named asset pays ASSET_FEE, a numeric one is free
    assert fairbooster.asset_fee("BOOSTER") == ASSET_FEE
    assert fairbooster.asset_fee("A95428956661682178") == 0
    block_index = ledger.blocks.last_db_index(ledger_db) + 1
    assert fairbooster.validate_capacity(ledger_db, block_index, 30, 0, ASSET_FEE, ASSET_FEE) == (
        [],
        0,
    )
    assert fairbooster.validate_capacity(
        ledger_db, block_index, 30, 0, ASSET_FEE - 1, ASSET_FEE
    ) == (["insufficient XCP balance to pay the fee"], 0)

    # cards
    assert validate(ledger_db, defaults, cards=[]) == ["a fairbooster needs at least one card"]
    assert validate(ledger_db, defaults, cards="1:x") == ["`cards` must be a list"]
    assert validate(ledger_db, defaults, cards=[[1, "x"]]) == [
        "card #1 must be [id, name, image_hash, weight, supply]"
    ]
    assert validate(
        ledger_db, defaults, cards=wire_cards(f"1:A:{HASH_1}:1:0, 1:B:{HASH_2}:1:0")
    ) == ["card 1: duplicate id"]
    assert validate(
        ledger_db, defaults, cards=wire_cards(f"1:A:{HASH_1}:1:0, 2:B:{HASH_1}:1:0")
    ) == ["card 2: duplicate image_hash"]
    # two cards may share a name
    assert (
        validate(ledger_db, defaults, cards=wire_cards(f"1:A:{HASH_1}:1:0, 2:A:{HASH_2}:1:0")) == []
    )
    assert validate(ledger_db, defaults, cards=wire_cards(f"1:Bad#Name:{HASH_1}:1:0")) == [
        "card 1: invalid card asset name: subasset name contains invalid character:"
    ]
    assert validate(ledger_db, defaults, cards=wire_cards(f"1:a..b:{HASH_1}:1:0")) == [
        "card 1: invalid card asset name: subasset name contains consecutive periods"
    ]
    assert validate(ledger_db, defaults, cards=[[1, " A", bytes.fromhex(HASH_1), 1, 0]]) == [
        "card 1: name must be a non-empty string without surrounding spaces"
    ]
    assert validate(ledger_db, defaults, cards=[[1, "A:B", bytes.fromhex(HASH_1), 1, 0]]) == [
        "card 1: name must not contain `:` or `,`"
    ]
    assert validate(ledger_db, defaults, cards=[[1, "A" * 230, bytes.fromhex(HASH_1), 1, 0]]) == [
        "card 1: invalid card asset name: subasset name too long"
    ]
    assert validate(ledger_db, defaults, cards=wire_cards(f"1:A:{'11' * 31}:1:0")) == [
        "card 1: image_hash must be 32 bytes"
    ]
    assert validate(ledger_db, defaults, cards=wire_cards(f"1:A:{HASH_1}:0:0")) == [
        f"card 1: weight must be between 1 and {config.MAX_INT}"
    ]
    assert validate(ledger_db, defaults, cards=wire_cards(f"1:A:{HASH_1}:1:-1")) == [
        f"card 1: supply must be between 0 and {config.MAX_INT}"
    ]
    assert validate(ledger_db, defaults, cards=wire_cards(f"-1:A:{HASH_1}:1:0")) == [
        f"card #1: id must be an integer between 0 and {config.MAX_INT}"
    ]
    big = 2**62
    assert validate(
        ledger_db, defaults, cards=wire_cards(f"1:A:{HASH_1}:{big}:0, 2:B:{HASH_2}:{big}:0")
    ) == ["total card weight exceeds maximum value"]
    assert validate(
        ledger_db, defaults, cards=wire_cards(f"1:A:{HASH_1}:1:{big}, 2:B:{HASH_2}:1:{big}")
    ) == ["total card supply exceeds maximum value"]


def test_compose_unpack(ledger_db, defaults):
    source, destinations, data = fairbooster.compose(
        ledger_db,
        defaults["addresses"][0],
        "BOOSTER",
        cards=CARDS,
        **(creation_params(cards_image_extension=".png")),
    )
    assert source == defaults["addresses"][0]
    assert destinations == []
    assert data[0] == fairbooster.ID
    unpacked = fairbooster.unpack(data[1:], return_dict=True)
    assert unpacked == {
        "asset": "BOOSTER",
        **creation_params(),
        "cards": [
            {
                "card_id": 1,
                "name": "Common Card",
                "image_hash": HASH_1,
                "weight": 70,
                "max_supply": 0,
            },
            {
                "card_id": 2,
                "name": "Rare Card",
                "image_hash": HASH_2,
                "weight": 25,
                "max_supply": 5,
            },
            {"card_id": 3, "name": "Legend", "image_hash": HASH_3, "weight": 5, "max_supply": 1},
        ],
    }
    assert fairbooster.unpack(b"garbage") == ("", {}, [])
    assert compose.unpack(ledger_db, data.hex(), 100000000)["message_type"] == "fairbooster"

    with pytest.raises(exceptions.ComposeError, match="already exists"):
        fairbooster.compose(
            ledger_db, defaults["addresses"][0], "DIVISIBLE", cards=CARDS, **creation_params()
        )

    _source, _destinations, data = updatefairbooster.compose(
        ledger_db, defaults["addresses"][0], "BOOSTER", price=5, skip_validation=True
    )
    assert updatefairbooster.unpack(data[1:]) == ("BOOSTER", {"price": 5}, [])
    assert updatefairbooster.unpack(b"garbage") == ("", {}, [])

    _source, _destinations, data = buybooster.compose(
        ledger_db, defaults["addresses"][1], "BOOSTER", skip_validation=True
    )
    assert buybooster.unpack(data[1:]) == "BOOSTER"
    assert buybooster.unpack(b"garbage") == ""


def test_draw_cards():
    cards = [
        {"card_id": 1, "weight": 1, "max_supply": 0},
        {"card_id": 2, "weight": 1, "max_supply": 2},
        {"card_id": 3, "weight": 2, "max_supply": 0},
    ]
    block_hash, tx_hash = "aa" * 32, "bb" * 32

    def draw(cards, count, drawn=None, block_hash=block_hash):
        return [
            (card["card_id"], serial)
            for card, serial in fairbooster.draw_cards(
                block_hash, tx_hash, cards, drawn if drawn is not None else {}, count
            )
        ]

    drawn = draw(cards, 100)
    assert len(drawn) == 100
    # the capped card leaves the draw once exhausted
    assert [serial for card_id, serial in drawn if card_id == 2] == [1, 2]
    # serials number the copies of each card
    for card_id in (1, 3):
        serials = [serial for drawn_id, serial in drawn if drawn_id == card_id]
        assert serials == list(range(1, len(serials) + 1))
    # deterministic: same seed, same draws; another seed, other draws
    assert draw(cards, 100) == drawn
    assert draw(cards, 100, block_hash="cc" * 32) != drawn
    # first draw: sha256(block_hash || tx_hash || 0) modulo the total weight
    digest = hashlib.sha256(bytes.fromhex(block_hash + tx_hash) + (0).to_bytes(4, "big")).digest()
    position = int.from_bytes(digest, "big") % 4
    expected_first = 1 if position < 1 else 2 if position < 2 else 3
    assert draw(cards, 1) == [(expected_first, 1)]
    # copies drawn before continue the serials and count against the supply
    assert draw(cards[1:2], 1, drawn={2: (1, 1)}) == [(2, 2)]
    with pytest.raises(exceptions.ParseTransactionError, match="no card left to draw"):
        draw(cards[1:2], 1, drawn={2: (2, 2)})
    assert fairbooster.card_supply(wire_cards()) is None
    assert fairbooster.card_supply(wire_cards(f"1:A:{HASH_1}:1:2, 2:B:{HASH_2}:1:3")) == 5


def test_create_buy_and_draw(ledger_db, defaults):
    owner, buyer = defaults["addresses"][0], defaults["addresses"][1]
    owner_xcp = ledger.balances.get_balance(ledger_db, owner, config.XCP)
    row = create(ledger_db, defaults)
    assert row["status"] == "open"
    assert row["source"] == owner
    assert row["card_count"] == 3
    assert row["boosters_sold"] == 0
    assert row["cards_sold"] == 0
    assert row["paid_capacity"] == 30
    # the asset fee; the gas fee of 30 cards is 0 while few cards are sold
    assert row["fee_paid"] == ASSET_FEE
    assert row["price"] == PRICE
    assert ledger.balances.get_balance(ledger_db, owner, config.XCP) == owner_xcp - ASSET_FEE
    destruction = last_row(ledger_db, "destructions")
    assert destruction["asset"] == config.XCP
    assert destruction["quantity"] == ASSET_FEE
    assert destruction["tag"] == "fairbooster asset fee"
    assert last_row(ledger_db, "transaction_count")["transaction_id"] == fairbooster.ID
    assert last_row(ledger_db, "transaction_count")["count"] == 30

    # the fairbooster asset: supply 1, locked, owned by the creator
    asset = ledger.issuances.get_asset(ledger_db, "BOOSTER")
    assert asset["supply"] == 1
    assert asset["locked"] is True
    assert asset["divisible"] is False
    assert asset["issuer"] == owner
    assert asset["description"] == "my booster"
    assert asset["asset_events"] == "open_fairbooster"
    assert asset["fee_paid"] == ASSET_FEE
    assert ledger.balances.get_balance(ledger_db, owner, "BOOSTER") == 1

    cards = ledger.fairboosters.get_fairbooster_cards(ledger_db, "BOOSTER")
    assert [
        (c["card_id"], c["name"], c["image_hash"], c["weight"], c["max_supply"]) for c in cards
    ] == [
        (1, "Common Card", HASH_1, 70, 0),
        (2, "Rare Card", HASH_2, 25, 5),
        (3, "Legend", HASH_3, 5, 1),
    ]
    assert all(c["fairbooster"] == "BOOSTER" for c in cards)

    # buy a booster: paid now, drawn in the next block
    buyer_xcp = ledger.balances.get_balance(ledger_db, buyer, config.XCP)
    owner_xcp = ledger.balances.get_balance(ledger_db, owner, config.XCP)
    send(ledger_db, "buybooster", {"source": buyer, "asset": "BOOSTER"})
    purchase = last_row(ledger_db, "fairbooster_purchases")
    assert purchase["status"] == "valid"
    assert purchase["fairbooster"] == "BOOSTER"
    assert purchase["paid_quantity"] == PRICE
    assert purchase["card_count"] == 3
    assert ledger.balances.get_balance(ledger_db, buyer, config.XCP) == buyer_xcp - PRICE
    assert ledger.balances.get_balance(ledger_db, owner, config.XCP) == owner_xcp + PRICE
    assert ledger.fairboosters.get_fairbooster(ledger_db, "BOOSTER")["boosters_sold"] == 1
    assert ledger.fairboosters.get_fairbooster(ledger_db, "BOOSTER")["cards_sold"] == 3
    assert rows(ledger_db, "SELECT * FROM fairbooster_draws") == []

    mine_empty_block(ledger_db)
    draws = rows(ledger_db, "SELECT * FROM fairbooster_draws ORDER BY rowid")
    assert len(draws) == 3
    block_index = ledger.blocks.last_db_index(ledger_db)
    names = {c["card_id"]: c["name"].replace(" ", "_") for c in cards}
    for msg_index, draw in enumerate(draws):
        assert draw["tx_hash"] == purchase["tx_hash"]
        assert draw["tx_index"] == purchase["tx_index"]
        assert draw["block_index"] == block_index
        assert draw["source"] == buyer
        assert draw["fairbooster"] == "BOOSTER"
        card_asset = ledger.issuances.get_asset(ledger_db, draw["asset"])
        assert card_asset["asset_longname"] == (
            f"BOOSTER.{draw['card_id']}.{names[draw['card_id']]}.{draw['serial']}"
        )
        assert card_asset["asset"].startswith("A")
        assert card_asset["supply"] == 1
        assert card_asset["locked"] is True
        assert card_asset["description_locked"] is True
        assert card_asset["divisible"] is False
        assert card_asset["issuer"] == buyer
        assert card_asset["description"] == f"https://example.com/cards/{draw['card_id']}.png"
        assert card_asset["asset_events"] == "fairbooster_draw"
        assert card_asset["msg_index"] == msg_index
        assert card_asset["tx_hash"] == purchase["tx_hash"]
        assert ledger.balances.get_balance(ledger_db, buyer, draw["asset"]) == 1
    # serials number the copies of each card
    for card_id in {d["card_id"] for d in draws}:
        serials = [d["serial"] for d in draws if d["card_id"] == card_id]
        assert serials == list(range(1, len(serials) + 1))

    # the API
    cards_api = queries.get_fairbooster_cards(ledger_db, "BOOSTER").result
    assert sum(card["drawn"] for card in cards_api) == 3
    assert [card["card_id"] for card in cards_api] == [1, 2, 3]
    assert len(queries.get_fairbooster_draws(ledger_db, "BOOSTER").result) == 3
    assert (
        len(queries.get_fairbooster_draws_by_purchase(ledger_db, purchase["tx_hash"]).result) == 3
    )
    assert len(queries.get_fairbooster_draws_by_address(ledger_db, buyer).result) == 3
    assert (
        queries.get_fairbooster_purchase(ledger_db, purchase["tx_hash"]).result["status"] == "valid"
    )
    assert len(queries.get_fairbooster_purchases(ledger_db, "BOOSTER").result) == 1
    assert len(queries.get_fairbooster_purchases_by_address(ledger_db, buyer).result) == 1


def test_buy_validation(ledger_db, defaults):
    owner, buyer = defaults["addresses"][0], defaults["addresses"][1]
    # 4 copies in all, 2 cards per booster
    create(
        ledger_db,
        defaults,
        cards=f"1:A:{HASH_1}:1:1, 2:B:{HASH_2}:1:3",
        max_boosters=5,
        cards_per_booster=2,
    )
    assert buybooster.validate(ledger_db, buyer, "BOOSTER") == []
    assert buybooster.validate(ledger_db, buyer, "NOPE") == ["fairbooster `NOPE` not found"]
    create(ledger_db, defaults, asset="PRICEY", price=config.MAX_INT)
    assert buybooster.validate(ledger_db, buyer, "PRICEY") == ["insufficient XCP balance"]
    with ProtocolChangesDisabled(["fairboosters"]):
        assert buybooster.validate(ledger_db, buyer, "BOOSTER") == ["fairboosters are not enabled"]

    send(ledger_db, "buybooster", {"source": buyer, "asset": "BOOSTER"})
    # the cards of the first booster are not drawn yet but are reserved
    assert rows(ledger_db, "SELECT * FROM fairbooster_draws") == []
    assert ledger.fairboosters.get_fairbooster(ledger_db, "BOOSTER")["cards_sold"] == 2
    send(ledger_db, "buybooster", {"source": buyer, "asset": "BOOSTER"})
    assert len(rows(ledger_db, "SELECT * FROM fairbooster_draws")) == 2
    # the deck is exhausted: the fairbooster closes
    row = ledger.fairboosters.get_fairbooster(ledger_db, "BOOSTER")
    assert row["cards_sold"] == 4
    assert row["boosters_sold"] == 2
    assert row["status"] == "closed"
    assert buybooster.validate(ledger_db, buyer, "BOOSTER") == [
        "not enough cards left to fill a booster"
    ]
    with pytest.raises(exceptions.ComposeError, match="not enough cards left"):
        send(ledger_db, "buybooster", {"source": buyer, "asset": "BOOSTER"})
    mine_empty_block(ledger_db)
    draws = rows(ledger_db, "SELECT * FROM fairbooster_draws")
    assert sorted(d["card_id"] for d in draws) == [1, 2, 2, 2]

    # adding a card makes room for another booster and reopens the fairbooster
    send(
        ledger_db,
        "updatefairbooster",
        {"source": owner, "asset": "BOOSTER", "cards": f"3:C:{HASH_3}:1:0"},
    )
    assert ledger.fairboosters.get_fairbooster(ledger_db, "BOOSTER")["status"] == "open"
    assert buybooster.validate(ledger_db, buyer, "BOOSTER") == []


def test_sold_out(ledger_db, defaults):
    owner, buyer = defaults["addresses"][0], defaults["addresses"][1]
    create(ledger_db, defaults, max_boosters=1, price=0)
    send(ledger_db, "buybooster", {"source": buyer, "asset": "BOOSTER"})
    row = ledger.fairboosters.get_fairbooster(ledger_db, "BOOSTER")
    assert row["boosters_sold"] == 1
    assert row["status"] == "closed"
    assert buybooster.validate(ledger_db, buyer, "BOOSTER") == ["all boosters are sold"]
    # an invalid purchase is recorded
    send(
        ledger_db,
        "buybooster",
        {"source": buyer, "asset": "BOOSTER", "skip_validation": True},
    )
    purchase = last_row(ledger_db, "fairbooster_purchases")
    assert purchase["status"] == "invalid: all boosters are sold"
    assert purchase["fairbooster"] == "BOOSTER"
    # reopened by raising max_boosters
    send(ledger_db, "updatefairbooster", {"source": owner, "asset": "BOOSTER", "max_boosters": 2})
    assert ledger.fairboosters.get_fairbooster(ledger_db, "BOOSTER")["status"] == "open"


def test_update(ledger_db, defaults):
    owner, other = defaults["addresses"][0], defaults["addresses"][1]
    create(ledger_db, defaults)

    def validate_update(source=owner, cards=None, **params):
        return updatefairbooster.validate(
            ledger_db, source, "BOOSTER", params, wire_cards(cards) if cards else []
        )[0]

    assert validate_update(price=1) == []
    assert validate_update() == ["nothing to update"]
    assert validate_update(source=other, price=1) == [
        f"fairbooster `BOOSTER` is not owned by `{other}`"
    ]
    assert updatefairbooster.validate(ledger_db, owner, "NOPE", {"price": 1}, [])[0] == [
        "fairbooster `NOPE` not found"
    ]
    assert validate_update(price=-1) == [f"`price` must be between 0 and {config.MAX_INT}"]
    assert validate_update(cards=f"1:Again:{'44' * 32}:1:0") == ["card 1: duplicate id"]
    assert validate_update(cards=f"4:Again:{HASH_1}:1:0") == ["card 4: duplicate image_hash"]
    assert validate_update(cards=f"4:New:{'44' * 32}:1:0") == []
    assert updatefairbooster.validate(ledger_db, owner, "BOOSTER", {"name": "X"}, [])[0] == [
        "invalid parameters"
    ]

    # raising the capacity pays the gas fee of the added cards only, 0 while
    # few cards are sold
    assert updatefairbooster.validate(ledger_db, owner, "BOOSTER", {"max_boosters": 20}, []) == (
        [],
        0,
        60,
    )
    assert updatefairbooster.validate(ledger_db, owner, "BOOSTER", {"max_boosters": 5}, []) == (
        [],
        0,
        15,
    )
    assert updatefairbooster.validate(
        ledger_db, owner, "BOOSTER", {"max_boosters": config.MAX_INT // 3}, []
    ) == (["insufficient XCP balance to pay the fee"], 0, 0)

    owner_xcp = ledger.balances.get_balance(ledger_db, owner, config.XCP)
    send(
        ledger_db,
        "updatefairbooster",
        {
            "source": owner,
            "asset": "BOOSTER",
            "description": "new description",
            "price": 2 * PRICE,
            "max_boosters": 20,
            "cards_base_url": "ipfs://cards",
            "cards_image_extension": ".svg",
            "cards": f"4:New Card:{'44' * 32}:10:0",
        },
    )
    update = last_row(ledger_db, "fairbooster_updates")
    assert update["status"] == "valid"
    assert update["fairbooster"] == "BOOSTER"
    assert update["price"] == 2 * PRICE
    assert update["cards_per_booster"] is None
    assert update["cards_added"] == 1
    assert update["fee_paid"] == 0
    assert ledger.balances.get_balance(ledger_db, owner, config.XCP) == owner_xcp
    # the 30 added cards are counted for the gas fee
    assert last_row(ledger_db, "transaction_count")["count"] == 30
    row = ledger.fairboosters.get_fairbooster(ledger_db, "BOOSTER")
    assert row["description"] == "new description"
    assert row["price"] == 2 * PRICE
    assert row["max_boosters"] == 20
    assert row["cards_per_booster"] == 3
    assert row["cards_base_url"] == "ipfs://cards"
    assert row["cards_image_extension"] == "svg"
    assert row["card_count"] == 4
    assert row["paid_capacity"] == 60
    assert row["fee_paid"] == ASSET_FEE
    assert [
        c["card_id"] for c in ledger.fairboosters.get_fairbooster_cards(ledger_db, "BOOSTER")
    ] == [
        1,
        2,
        3,
        4,
    ]

    # lowering then raising the capacity back is free up to what was paid
    send(ledger_db, "updatefairbooster", {"source": owner, "asset": "BOOSTER", "max_boosters": 1})
    assert updatefairbooster.validate(ledger_db, owner, "BOOSTER", {"max_boosters": 20}, []) == (
        [],
        0,
        60,
    )

    # max_boosters cannot go below the boosters sold
    send(ledger_db, "updatefairbooster", {"source": owner, "asset": "BOOSTER", "max_boosters": 3})
    send(ledger_db, "buybooster", {"source": other, "asset": "BOOSTER"})
    send(ledger_db, "buybooster", {"source": other, "asset": "BOOSTER"})
    assert validate_update(max_boosters=1) == [
        "`max_boosters` must be >= the number of boosters sold (2)"
    ]
    assert validate_update(max_boosters=2) == []

    # an invalid update is recorded
    send(
        ledger_db,
        "updatefairbooster",
        {"source": other, "asset": "BOOSTER", "price": 1, "skip_validation": True},
    )
    update = last_row(ledger_db, "fairbooster_updates")
    assert update["status"] == f"invalid: fairbooster `BOOSTER` is not owned by `{other}`"

    # the owner is the issuer of the fairbooster asset: transferring it moves
    # the payments and the right to update
    send(
        ledger_db,
        "issuance",
        {
            "source": owner,
            "asset": "BOOSTER",
            "quantity": 0,
            "divisible": False,
            "transfer_destination": other,
        },
    )
    assert validate_update(source=other, price=1) == []
    other_xcp = ledger.balances.get_balance(ledger_db, other, config.XCP)
    buyer = defaults["addresses"][2]
    send(ledger_db, "updatefairbooster", {"source": other, "asset": "BOOSTER", "max_boosters": 5})
    other_xcp = ledger.balances.get_balance(ledger_db, other, config.XCP)
    send(ledger_db, "buybooster", {"source": buyer, "asset": "BOOSTER"})
    assert ledger.balances.get_balance(ledger_db, other, config.XCP) == other_xcp + 2 * PRICE


def test_capacity_counts_the_cards_sold(ledger_db, defaults):
    """Lowering `cards_per_booster` after a sale frees no capacity: the cards of
    the boosters sold stay counted, so the cards drawn never exceed the paid
    capacity."""
    owner, buyer = defaults["addresses"][0], defaults["addresses"][1]
    create(
        ledger_db,
        defaults,
        cards=f"1:Common:{HASH_1}:1:0",
        max_boosters=1,
        cards_per_booster=10,
        price=0,
    )
    send(ledger_db, "buybooster", {"source": buyer, "asset": "BOOSTER"})
    mine_empty_block(ledger_db)
    params = {"max_boosters": 10, "cards_per_booster": 1}
    problems, _fee, capacity = updatefairbooster.validate(ledger_db, owner, "BOOSTER", params, [])
    assert (problems, capacity) == ([], 10 + 9)
    send(ledger_db, "updatefairbooster", {"source": owner, "asset": "BOOSTER", **params})
    assert ledger.fairboosters.get_fairbooster(ledger_db, "BOOSTER")["paid_capacity"] == 19
    # the 9 added cards are counted for the gas fee
    assert last_row(ledger_db, "transaction_count")["count"] == 9
    for _ in range(9):
        send(ledger_db, "buybooster", {"source": buyer, "asset": "BOOSTER"})
    mine_empty_block(ledger_db)
    row = ledger.fairboosters.get_fairbooster(ledger_db, "BOOSTER")
    assert row["status"] == "closed"
    assert row["cards_sold"] == 19
    assert len(rows(ledger_db, "SELECT * FROM fairbooster_draws")) == row["paid_capacity"]


def test_draws_of_one_block(ledger_db, defaults):
    """The purchases of a block are drawn in transaction order, each one after
    the draws of the previous ones."""
    buyer = defaults["addresses"][1]
    create(ledger_db, defaults, cards=f"1:A:{HASH_1}:1:3, 2:B:{HASH_2}:1:0", cards_per_booster=2)
    block_index = ledger.blocks.last_db_index(ledger_db)
    # three transactions that issued nothing: the draws are issuances of their tx_hash
    purchases = rows(
        ledger_db,
        """
        SELECT tx_index, tx_hash FROM transactions
        WHERE tx_hash NOT IN (SELECT tx_hash FROM issuances)
        ORDER BY tx_index LIMIT 3
        """,
    )
    for purchase in purchases:
        ledger.events.insert_record(
            ledger_db,
            "fairbooster_purchases",
            {
                "tx_index": purchase["tx_index"],
                "tx_hash": purchase["tx_hash"],
                "block_index": block_index,
                "source": buyer,
                "fairbooster": "BOOSTER",
                "paid_quantity": 0,
                "card_count": 2,
                "status": "valid",
            },
            "NEW_FAIRBOOSTER_PURCHASE",
        )
    mine_empty_block(ledger_db)
    draws = rows(ledger_db, "SELECT * FROM fairbooster_draws ORDER BY rowid")
    assert [d["tx_index"] for d in draws] == [p["tx_index"] for p in purchases for _ in range(2)]
    # the supply of card 1 holds and the serials of each card follow each
    # other across the purchases
    assert len([d for d in draws if d["card_id"] == 1]) <= 3
    for card_id in (1, 2):
        serials = [d["serial"] for d in draws if d["card_id"] == card_id]
        assert serials == list(range(1, len(serials) + 1))


def test_card_subassets_are_reserved(ledger_db, defaults):
    owner = defaults["addresses"][0]
    create(ledger_db, defaults)
    with pytest.raises(exceptions.ComposeError, match="reserved for its cards"):
        send(
            ledger_db,
            "issuance",
            {"source": owner, "asset": "BOOSTER.1.Common_Card.1", "quantity": 1},
        )
    with pytest.raises(exceptions.ComposeError, match="reserved for its cards"):
        send(
            ledger_db,
            "fairminter",
            {"source": owner, "asset": "child", "asset_parent": "BOOSTER", "price": 1},
        )


def test_invalid_creation(ledger_db, defaults):
    send(
        ledger_db,
        "fairbooster",
        {
            "source": defaults["addresses"][0],
            "asset": "DIVISIBLE",
            "cards": CARDS,
            "skip_validation": True,
            **creation_params(),
        },
    )
    row = last_row(ledger_db, "fairboosters")
    assert row["status"] == "invalid: asset `DIVISIBLE` already exists"
    assert row["asset"] is None
    assert ledger.fairboosters.get_fairbooster(ledger_db, "DIVISIBLE") is None


def test_parse_garbage(ledger_db, blockchain_mock, defaults):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    for module in (fairbooster, updatefairbooster, buybooster):
        module.parse(ledger_db, tx, b"\xff\x00garbage")
    assert last_row(ledger_db, "fairboosters")["status"] == "invalid: could not unpack"
    assert last_row(ledger_db, "fairbooster_updates")["status"] == "invalid: could not unpack"
    assert last_row(ledger_db, "fairbooster_purchases")["status"] == "invalid: could not unpack"


def test_state_db_table(state_db):
    # created by State DB migration 0017, filled by the API watcher
    assert queries.get_all_fairboosters(state_db).result == []
    assert queries.get_fairbooster(state_db, "BOOSTER") is None


# CBOR-shaped fuzz: any decoded value may reach validate() and the invalid-record
# bindings, and none may raise (an exception in parse() halts every node).
any_value = st.one_of(
    st.integers(min_value=-(2**64), max_value=2**64),
    st.booleans(),
    st.text(max_size=8),
    st.binary(max_size=33),
    st.floats(allow_nan=True, allow_infinity=True),
    st.none(),
    st.decimals(allow_nan=True, allow_infinity=True, places=2),
    st.lists(st.integers(min_value=0, max_value=255), max_size=3),
    st.dictionaries(st.integers(min_value=-1, max_value=8), st.integers(), max_size=2),
)
map_keys = st.one_of(st.integers(min_value=-1, max_value=8), st.text(max_size=2), st.none())
any_card = st.one_of(st.lists(any_value, min_size=5, max_size=5), any_value)
asset_ids = st.one_of(st.just(BOOSTER_ID), st.just(DIVISIBLE_ID), any_value)


def assert_parse_does_not_raise(module, ledger_db, tx, message):
    try:
        module.parse(ledger_db, tx, message)
    except apsw.ConstraintError:
        pass  # Hypothesis reuses ledger_db across examples
    except Exception as exc:  # pylint: disable=broad-except
        pytest.fail(f"{module.__name__}.parse raised {type(exc).__name__}: {exc}")


@settings(
    max_examples=200, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(
    asset_ids,
    st.lists(any_value, min_size=7, max_size=7),
    st.one_of(st.lists(any_card, max_size=3), any_value),
)
def test_fuzz_fairbooster_parse(ledger_db, blockchain_mock, defaults, asset_id, params, cards):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    assert_parse_does_not_raise(fairbooster, ledger_db, tx, cbor2.dumps([asset_id, *params, cards]))


@settings(
    max_examples=200, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(
    asset_ids,
    st.one_of(st.dictionaries(map_keys, any_value, max_size=4), any_value),
    st.one_of(st.lists(any_card, max_size=3), any_value),
)
def test_fuzz_updatefairbooster_parse(
    ledger_db, blockchain_mock, defaults, asset_id, params, cards
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = cbor2.dumps([asset_id, params, cards])
    assert_parse_does_not_raise(updatefairbooster, ledger_db, tx, message)


@settings(
    max_examples=200, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(st.binary(max_size=16))
def test_fuzz_buybooster_parse(ledger_db, blockchain_mock, defaults, message):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    assert_parse_does_not_raise(buybooster, ledger_db, tx, message)
