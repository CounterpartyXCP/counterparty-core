"""Fairminter cards: a fairminter distributing weighted card subassets,
drawn in the block that follows each mint (`fairminter_cards`)."""

import hashlib

import pytest
from counterpartycore.lib import exceptions, ledger
from counterpartycore.lib.api import compose, queries
from counterpartycore.lib.messages import addcards, fairmint, fairminter
from counterpartycore.test.mocks import bitcoind as bitcoind_mock_module
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled, run_scenario

# weight, max_supply (0: unlimited)
# the third card is unnamed: it is `<asset>.3`
CARDS = [[70, 0, "COMMON"], [25, 5, "RARE"], [5, 1]]
CARD_NAMES = ["COMMON", "RARE", "3"]


def send(ledger_db, name, params, encoding="multisig"):
    """Compose, sign and mine `name` in its own block, like the fixtures do."""
    run_scenario(ledger_db, bitcoind_mock_module, [[name, dict(params), {"encoding": encoding}]])


def mine_empty_block(ledger_db):
    bitcoind_mock_module.mine_block(ledger_db, [])


def rows(ledger_db, sql, *bindings):
    return ledger_db.execute(sql, bindings).fetchall()


def last_fairmint(ledger_db):
    return rows(ledger_db, "SELECT * FROM fairmints ORDER BY rowid DESC LIMIT 1")[0]


def validate(ledger_db, defaults, **overrides):
    params = {
        "source": defaults["addresses"][0],
        "asset": "CARDTEST",
        "asset_parent": "",
        "price": 1,
        "quantity_by_price": 1,
        "max_mint_per_tx": 3,
        "max_mint_per_address": 0,
        "hard_cap": 0,
        "premint_quantity": 0,
        "start_block": 0,
        "end_block": 0,
        "soft_cap": 0,
        "soft_cap_deadline_block": 0,
        "minted_asset_commission": 0.0,
        "burn_payment": False,
        "lock_description": False,
        "lock_quantity": False,
        "divisible": False,
        "description": "",
        "mime_type": "",
        "pool_quantity": 0,
        "lp_asset": "",
        "cards": CARDS,
        "lock_cards": False,
    }
    params.update(overrides)
    return fairminter.validate(ledger_db, **params)


def test_validate_cards(ledger_db, defaults):
    assert validate(ledger_db, defaults) == []
    assert validate(ledger_db, defaults, lock_cards=True) == []

    with ProtocolChangesDisabled(["fairminter_cards"]):
        assert validate(ledger_db, defaults) == ["cards are not yet enabled"]

    assert validate(ledger_db, defaults, cards=[], lock_cards=True) == ["lock_cards requires cards"]
    assert validate(ledger_db, defaults, cards=[[1, 0, 3]]) == [
        "card 1 must be [weight, max_supply] or [weight, max_supply, name]"
    ]
    assert validate(ledger_db, defaults, cards=[[1, 0, "A"], [1, 0, "A"]]) == [
        "card 2: duplicate card name `A`"
    ]
    # a name may not collide with the number of an unnamed card
    assert validate(ledger_db, defaults, cards=[[1, 0, "2"], [1, 0]]) == [
        "card 2: duplicate card name `2`"
    ]
    assert validate(ledger_db, defaults, cards=[[1, 0, "BAD NAME"], [1, 0, "OK"]]) == [
        "invalid card asset name `CARDTEST.BAD NAME`: ('subasset name contains invalid character:', ' ')"
    ]
    assert validate(ledger_db, defaults, cards=[[1, 0], [0, 0]]) == [
        f"card 2: weight must be between 1 and {2**63 - 1}"
    ]
    assert validate(ledger_db, defaults, cards=[[1, -1]]) == [
        f"card 1: max_supply must be between 0 and {2**63 - 1}"
    ]
    assert validate(ledger_db, defaults, cards=[[2**62, 0], [2**62, 0]]) == [
        "total card weight exceeds maximum value"
    ]
    assert validate(ledger_db, defaults, cards=[[1, 0]] * 1001) == ["too many cards (maximum 1000)"]
    assert validate(ledger_db, defaults, divisible=True) == ["cards require divisible = False"]
    assert validate(ledger_db, defaults, premint_quantity=1) == [
        "cards are incompatible with premint_quantity"
    ]
    assert validate(ledger_db, defaults, soft_cap=1, soft_cap_deadline_block=400000) == [
        "cards are incompatible with soft_cap"
    ]
    assert validate(ledger_db, defaults, minted_asset_commission=0.1) == [
        "cards are incompatible with minted_asset_commission"
    ]
    assert validate(ledger_db, defaults, minted_asset_commission=float("nan")) == [
        "`minted_asset_commission` must be a number"
    ]
    assert validate(ledger_db, defaults, max_mint_per_tx=0) == ["cards require max_mint_per_tx > 0"]
    assert validate(ledger_db, defaults, max_mint_per_tx=1001) == [
        "cards require max_mint_per_tx <= 1000"
    ]
    # every card capped: a hard cap is required, no larger than the deck
    assert validate(ledger_db, defaults, cards=[[1, 1], [1, 2]]) == [
        "hard_cap is required when every card has a max_supply"
    ]
    assert validate(ledger_db, defaults, cards=[[1, 1], [1, 2]], hard_cap=4) == [
        "hard_cap exceeds the remaining supply of the cards"
    ]
    assert validate(ledger_db, defaults, cards=[[1, 1], [1, 2]], hard_cap=3) == []
    assert validate(ledger_db, defaults, price=0, hard_cap=2, max_mint_per_tx=3) == [
        "max_mint_per_tx must be <= hard_cap"
    ]
    # numeric parents only once subassets on numerics are allowed
    with ProtocolChangesDisabled(["allow_subassets_on_numerics"]):
        assert validate(ledger_db, defaults, asset="A95428956661682178") == [
            "invalid card asset name `A95428956661682178.COMMON`: parent asset name too long"
        ]


def test_validate_existing_card_asset(ledger_db, defaults):
    # `DIVISIBLE.1` would be a card of a fairminter on DIVISIBLE: issue it first
    send(
        ledger_db,
        "issuance",
        {
            "source": defaults["addresses"][0],
            "asset": "DIVISIBLE.ONE",
            "quantity": 2,
            "divisible": False,
            "description": "card one",
        },
    )
    # DIVISIBLE itself is divisible, so use a fresh parent for the card checks
    assert validate(
        ledger_db,
        defaults,
        asset="DIVISIBLE",
        divisible=True,
        cards=[[1, 2, "ONE"]],
        hard_cap=1,
    ) == [
        "cards require divisible = False",
        "card asset `DIVISIBLE.ONE` already reached its max_supply",
        "hard_cap exceeds the remaining supply of the cards",
    ]
    assert validate(
        ledger_db,
        defaults,
        source=defaults["addresses"][1],
        asset="DIVISIBLE",
        divisible=True,
        cards=[[1, 3, "ONE"]],
        hard_cap=1,
    ) == [
        "Asset `DIVISIBLE` is not issued by `mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns`.",
        "cards require divisible = False",
        "card asset `DIVISIBLE.ONE` is not issued by `mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns`",
    ]


def test_compose_unpack(ledger_db, defaults):
    source, destinations, data = fairminter.compose(
        ledger_db,
        defaults["addresses"][0],
        "CARDTEST",
        price=1,
        max_mint_per_tx=3,
        hard_cap=10,
        divisible=False,
        cards=CARDS,
        lock_cards=True,
    )
    assert source == defaults["addresses"][0]
    assert destinations == []
    unpacked = fairminter.unpack(data[1:], return_dict=True)
    assert unpacked["asset"] == "CARDTEST"
    assert unpacked["cards"] == CARDS
    assert unpacked["lock_cards"] is True
    assert unpacked["pool_quantity"] == 0
    assert unpacked["lp_asset"] is None
    assert unpacked["mime_type"] == "text/plain"
    assert unpacked["description"] == ""
    assert fairminter.unpack(data[1:])[-2:] == (CARDS, True)

    with pytest.raises(exceptions.ComposeError, match="cards require divisible = False"):
        fairminter.compose(
            ledger_db,
            defaults["addresses"][0],
            "CARDTEST",
            price=1,
            max_mint_per_tx=3,
            cards=CARDS,
        )


def test_draw_cards(ledger_db):
    cards = [
        {"card_index": 1, "asset": "A95428956661682178", "weight": 1, "max_supply": 0},
        {"card_index": 2, "asset": "A95428956661682179", "weight": 1, "max_supply": 2},
        {"card_index": 3, "asset": "A95428956661682180", "weight": 2, "max_supply": 0},
    ]
    block_hash = "aa" * 32
    tx_hash = "bb" * 32
    drawn = fairminter.draw_cards(ledger_db, block_hash, tx_hash, cards, 100)
    assert sum(drawn.values()) == 100
    # the capped card leaves the draw once exhausted
    assert drawn[2] == 2
    # deterministic: same seed, same draws; another seed, other draws
    assert fairminter.draw_cards(ledger_db, block_hash, tx_hash, cards, 100) == drawn
    assert fairminter.draw_cards(ledger_db, "cc" * 32, tx_hash, cards, 100) != drawn
    # first draw: 64 high bits of sha256(block_hash || tx_hash || 0) modulo the total weight
    digest = hashlib.sha256(bytes.fromhex(block_hash + tx_hash) + (0).to_bytes(4, "big")).digest()
    position = int.from_bytes(digest[:8], "big") % 4
    expected_first = 1 if position < 1 else 2 if position < 2 else 3
    assert fairminter.draw_cards(ledger_db, block_hash, tx_hash, cards, 1) == {expected_first: 1}
    # a single unlimited card always wins
    assert fairminter.draw_cards(ledger_db, block_hash, tx_hash, cards[:1], 7) == {1: 7}
    with pytest.raises(exceptions.ParseTransactionError, match="no card left to draw"):
        fairminter.draw_cards(ledger_db, block_hash, tx_hash, cards[1:2], 3)


def test_open_mint_draw_and_add_cards(ledger_db, defaults, test_helpers):
    issuer = defaults["addresses"][0]
    minter = defaults["addresses"][1]
    send(
        ledger_db,
        "fairminter",
        {
            "source": issuer,
            "asset": "CARDTEST",
            "price": 1,
            "max_mint_per_tx": 3,
            "divisible": False,
            "description": "the collection",
            "cards": CARDS,
        },
    )
    fairminter_row = rows(ledger_db, "SELECT * FROM fairminters ORDER BY rowid DESC LIMIT 1")[0]
    assert fairminter_row["asset"] == "CARDTEST"
    assert fairminter_row["status"] == "open"
    assert fairminter_row["lock_cards"] is False
    cards = ledger.issuances.get_fairminter_cards(ledger_db, fairminter_row)
    assert [(c["card_index"], c["weight"], c["max_supply"]) for c in cards] == [
        (1, 70, 0),
        (2, 25, 5),
        (3, 5, 1),
    ]
    assert [c["asset_longname"] for c in cards] == [f"CARDTEST.{n}" for n in CARD_NAMES]
    assert all(c["fairminter_tx_index"] == fairminter_row["tx_index"] for c in cards)
    for card in cards:
        asset = ledger.issuances.get_asset(ledger_db, card["asset_longname"])
        assert asset["asset"] == card["asset"]
        assert asset["fair_minting"] is True
        assert asset["divisible"] is False
        assert asset["issuer"] == issuer
        assert asset["supply"] == 0
        assert asset["msg_index"] == card["card_index"]
        assert asset["tx_hash"] == fairminter_row["tx_hash"]
    # the parent asset gets no supply
    assert ledger.issuances.get_asset(ledger_db, "CARDTEST")["supply"] == 0

    # the issuer cannot issue a card while the fairminter is open
    with pytest.raises(exceptions.ComposeError, match="cannot issue during fair minting"):
        send(
            ledger_db,
            "issuance",
            {"source": issuer, "asset": "CARDTEST.RARE", "quantity": 1, "divisible": False},
        )

    # mint 3 cards: paid now, drawn in the next block
    xcp_before = ledger.balances.get_balance(ledger_db, minter, "XCP")
    send(ledger_db, "fairmint", {"source": minter, "asset": "CARDTEST", "quantity": 3})
    fairmint_row = last_fairmint(ledger_db)
    assert fairmint_row["status"] == "valid"
    assert fairmint_row["earn_quantity"] == 3
    assert fairmint_row["paid_quantity"] == 3
    assert fairmint_row["asset"] == "CARDTEST"
    assert ledger.balances.get_balance(ledger_db, minter, "XCP") == xcp_before - 3
    for card in cards:
        assert ledger.balances.get_balance(ledger_db, minter, card["asset"]) == 0

    mine_empty_block(ledger_db)
    drawn = {
        card["asset_longname"]: ledger.balances.get_balance(ledger_db, minter, card["asset"])
        for card in cards
    }
    assert sum(drawn.values()) == 3
    assert drawn["CARDTEST.3"] <= 1
    credits = rows(
        ledger_db,
        "SELECT * FROM credits WHERE event = ? ORDER BY rowid",
        fairmint_row["tx_hash"],
    )
    # the XCP payment to the issuer, then the drawn cards
    assert credits[0]["calling_function"] == "fairmint payment"
    assert credits[0]["asset"] == "XCP"
    credits = credits[1:]
    assert [c["calling_function"] for c in credits] == ["fairmint"] * len(credits)
    assert sum(c["quantity"] for c in credits) == 3
    assert all(c["tx_index"] == fairmint_row["tx_index"] for c in credits)
    issuances = rows(
        ledger_db,
        "SELECT * FROM issuances WHERE tx_hash = ? ORDER BY msg_index",
        bytes.fromhex(fairmint_row["tx_hash"]),
    )
    assert [i["asset_events"] for i in issuances] == ["fairmint"] * len(issuances)
    assert sum(i["quantity"] for i in issuances) == 3
    card_index_by_longname = {c["asset_longname"]: c["card_index"] for c in cards}
    for issuance in issuances:
        assert drawn[issuance["asset_longname"]] == issuance["quantity"]
        assert issuance["msg_index"] == card_index_by_longname[issuance["asset_longname"]]
        assert issuance["source"] == minter
        assert issuance["fair_minting"] is True
    # the supply of each card is what was drawn
    for card in cards:
        assert (
            ledger.supplies.asset_supply(ledger_db, card["asset"]) == drawn[card["asset_longname"]]
        )
    # a fairmint of the previous block is resolved once
    mine_empty_block(ledger_db)
    assert sum(ledger.balances.get_balance(ledger_db, minter, c["asset"]) for c in cards) == 3

    # the issuer adds two cards (EPIC and the unnamed number 5) and locks the cards
    with pytest.raises(exceptions.ComposeError, match="duplicate card name `RARE`"):
        addcards.compose(ledger_db, issuer, "CARDTEST", [[1, 0, "RARE"]])
    with pytest.raises(exceptions.ComposeError, match="duplicate card name `3`"):
        addcards.compose(ledger_db, issuer, "CARDTEST", [[1, 0, "3"]])
    send(
        ledger_db,
        "addcards",
        {"source": issuer, "asset": "CARDTEST", "cards": [[10, 0, "EPIC"], [1, 2]]},
    )
    cards = ledger.issuances.get_fairminter_cards(ledger_db, fairminter_row)
    assert [c["asset_longname"] for c in cards] == [
        f"CARDTEST.{n}" for n in CARD_NAMES + ["EPIC", "5"]
    ]
    assert cards[4]["max_supply"] == 2
    card_5 = ledger.issuances.get_asset(ledger_db, "CARDTEST.5")
    assert card_5["fair_minting"] is True
    assert card_5["msg_index"] == 5
    assert card_5["tx_hash"] != fairminter_row["tx_hash"]
    assert (
        rows(ledger_db, "SELECT * FROM fairminters ORDER BY rowid DESC LIMIT 1")[0]["lock_cards"]
        is False
    )

    with pytest.raises(exceptions.ComposeError, match="is not owned by"):
        addcards.compose(ledger_db, minter, "CARDTEST", [[1, 0]])
    with pytest.raises(exceptions.ComposeError, match="has no cards"):
        addcards.compose(ledger_db, issuer, "FREEFAIRMIN", [[1, 0]])
    with pytest.raises(exceptions.ComposeError, match="nothing to do"):
        addcards.compose(ledger_db, issuer, "CARDTEST")
    with pytest.raises(exceptions.ComposeError, match="too many cards"):
        addcards.compose(ledger_db, issuer, "CARDTEST", [[1, 0]] * 996)

    send(ledger_db, "addcards", {"source": issuer, "asset": "CARDTEST", "lock_cards": True})
    fairminter_row = rows(ledger_db, "SELECT * FROM fairminters ORDER BY rowid DESC LIMIT 1")[0]
    assert fairminter_row["lock_cards"] is True
    assert fairminter_row["status"] == "open"
    with pytest.raises(exceptions.ComposeError, match="are locked"):
        addcards.compose(ledger_db, issuer, "CARDTEST", [[1, 0]])
    # an invalid addcards is recorded as such
    data = addcards.compose(ledger_db, issuer, "CARDTEST", [[1, 0]], skip_validation=True)[2]
    assert addcards.unpack(data[1:], return_dict=True) == {
        "asset": "CARDTEST",
        "cards": [[1, 0]],
        "lock_cards": False,
    }
    tx = dict(bitcoind_mock_module.BlockchainMock().dummy_tx(ledger_db, issuer))
    addcards.parse(ledger_db, tx, data[1:])
    assert len(ledger.issuances.get_fairminter_cards(ledger_db, fairminter_row)) == 5

    # the whole thing survives a rollback / reparse of the draws
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "fairminter_cards",
                "values": {
                    "fairminter_tx_hash": fairminter_row["tx_hash"],
                    "card_index": 5,
                    "asset_longname": "CARDTEST.5",
                    "weight": 1,
                    "max_supply": 2,
                },
            }
        ],
    )


def test_deck_hard_cap_and_close(ledger_db, defaults):
    issuer = defaults["addresses"][0]
    minter = defaults["addresses"][1]
    send(
        ledger_db,
        "fairminter",
        {
            "source": issuer,
            "asset": "CARDDECK",
            "price": 1,
            "max_mint_per_tx": 3,
            "hard_cap": 3,
            "divisible": False,
            "lock_quantity": True,
            "lock_cards": True,
            "cards": [[1, 1], [1, 1], [1, 1]],
        },
    )
    fairminter_row = rows(ledger_db, "SELECT * FROM fairminters ORDER BY rowid DESC LIMIT 1")[0]
    assert fairminter_row["lock_cards"] is True
    cards = ledger.issuances.get_fairminter_cards(ledger_db, fairminter_row)

    assert fairmint.validate(ledger_db, minter, "CARDDECK", 4) == [
        "Quantity exceeds maximum allowed per transaction"
    ]
    send(ledger_db, "fairmint", {"source": minter, "asset": "CARDDECK", "quantity": 2})
    # the hard cap counts the cards reserved by the fairmints, not yet drawn
    assert fairmint.validate(ledger_db, minter, "CARDDECK", 2) == [
        "asset supply quantity exceeds hard cap"
    ]
    assert fairmint.validate(ledger_db, minter, "CARDDECK", 1) == []
    send(ledger_db, "fairmint", {"source": minter, "asset": "CARDDECK", "quantity": 1})
    fairminter_row = rows(ledger_db, "SELECT * FROM fairminters ORDER BY rowid DESC LIMIT 1")[0]
    assert fairminter_row["status"] == "closed"
    assert fairmint.validate(ledger_db, minter, "CARDDECK", 1) == [
        "fairminter is not open for asset: `CARDDECK`",
        "asset supply quantity exceeds hard cap",
    ]
    # closing issuances: parent and cards are no longer fair minting, and locked
    for asset in ["CARDDECK"] + [c["asset"] for c in cards]:
        last = ledger.issuances.get_asset(ledger_db, asset)
        assert last["fair_minting"] is False
        assert last["locked"] is True
        assert last["asset_events"] == "close_fairminter"
    closing = rows(
        ledger_db,
        "SELECT msg_index FROM issuances WHERE asset_events = 'close_fairminter' ORDER BY msg_index",
    )
    assert [r["msg_index"] for r in closing] == [1001, 1002, 1003, 1004]
    # the first mint (2 cards, previous block) was drawn before the close
    assert sum(ledger.balances.get_balance(ledger_db, minter, c["asset"]) for c in cards) == 2

    # the last mint is drawn in the next block: the whole deck is distributed
    mine_empty_block(ledger_db)
    for card in cards:
        assert ledger.balances.get_balance(ledger_db, minter, card["asset"]) == 1
        assert ledger.supplies.asset_supply(ledger_db, card["asset"]) == 1
        last = ledger.issuances.get_asset(ledger_db, card["asset"])
        assert last["fair_minting"] is False
        assert last["locked"] is True
    # the issuer can now change a card's description but not its supply
    send(
        ledger_db,
        "issuance",
        {
            "source": issuer,
            "asset": "CARDDECK.2",
            "quantity": 0,
            "divisible": False,
            "description": "the second card",
        },
    )
    assert ledger.issuances.get_asset(ledger_db, "CARDDECK.2")["description"] == "the second card"
    with pytest.raises(exceptions.ComposeError, match="locked asset"):
        send(
            ledger_db,
            "issuance",
            {"source": issuer, "asset": "CARDDECK.2", "quantity": 1, "divisible": False},
        )
    with pytest.raises(exceptions.ComposeError, match="fairminter is closed"):
        addcards.compose(ledger_db, issuer, "CARDDECK", [[1, 0]])


def test_free_mint_end_block(ledger_db, defaults, current_block_index):
    issuer = defaults["addresses"][0]
    minter = defaults["addresses"][2]
    send(
        ledger_db,
        "fairminter",
        {
            "source": issuer,
            "asset": "CARDFREE",
            "max_mint_per_tx": 2,
            "end_block": current_block_index + 2,
            "divisible": False,
            "cards": [[1, 0], [1, 0]],
        },
    )
    send(ledger_db, "fairmint", {"source": minter, "asset": "CARDFREE"})
    fairmint_row = last_fairmint(ledger_db)
    assert fairmint_row["earn_quantity"] == 2
    assert fairmint_row["paid_quantity"] == 0
    # end_block reached: closed by `after_block`, the pending draws still settle
    fairminter_row = rows(ledger_db, "SELECT * FROM fairminters ORDER BY rowid DESC LIMIT 1")[0]
    assert fairminter_row["status"] == "closed"
    cards = ledger.issuances.get_fairminter_cards(ledger_db, fairminter_row)
    mine_empty_block(ledger_db)
    assert sum(ledger.balances.get_balance(ledger_db, minter, c["asset"]) for c in cards) == 2


def test_api_fairminter_cards(ledger_db, defaults):
    issuer = defaults["addresses"][0]
    assert queries.get_fairminter_cards(ledger_db, "a" * 64).result == []
    send(
        ledger_db,
        "fairminter",
        {
            "source": issuer,
            "asset": "CARDAPI",
            "price": 1,
            "max_mint_per_tx": 2,
            "divisible": False,
            "cards": [[3, 0], [1, 4]],
            "lock_cards": True,
        },
    )
    fairminter_row = rows(ledger_db, "SELECT * FROM fairminters ORDER BY rowid DESC LIMIT 1")[0]
    result = queries.get_fairminter_cards(ledger_db, fairminter_row["tx_hash"])
    assert result.result_count == 2
    assert [card["card_index"] for card in result.result] == [2, 1]
    assert result.result[1] == {
        "rowid": 1,
        "fairminter_tx_hash": fairminter_row["tx_hash"],
        "block_index": fairminter_row["block_index"],
        "card_index": 1,
        "asset": ledger.issuances.get_asset(ledger_db, "CARDAPI.1")["asset"],
        "asset_longname": "CARDAPI.1",
        "weight": 3,
        "max_supply": 0,
    }
    assert compose.parse_cards("50,30:10,1:1:LEGENDARY, 2:0:EPIC") == [
        [50, 0],
        [30, 10],
        [1, 1, "LEGENDARY"],
        [2, 0, "EPIC"],
    ]
    assert compose.parse_cards("") is None
    with pytest.raises(exceptions.ComposeError, match="Invalid card `x`"):
        compose.parse_cards("1,x")
    with pytest.raises(exceptions.ComposeError, match="Invalid card `1:2:3:4`"):
        compose.parse_cards("1:2:3:4")
