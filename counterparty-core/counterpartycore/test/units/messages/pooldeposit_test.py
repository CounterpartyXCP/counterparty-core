import pytest
from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import pooldeposit


def test_validate_valid(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        defaults["quantity"],
        defaults["quantity"],
    )
    assert problems == []


def test_validate_btc_rejected(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "BTC",
        "XCP",
        defaults["quantity"],
        defaults["quantity"],
    )
    assert "BTC pairs are not supported" in problems[0]


def test_validate_same_asset(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "XCP",
        defaults["quantity"],
        defaults["quantity"],
    )
    assert "assets must be different" in problems[0]


def test_validate_nonexistent_asset(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DOESNOTEXIST",
        defaults["quantity"],
        defaults["quantity"],
    )
    assert any("does not exist" in p for p in problems)


def test_validate_zero_quantity(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        0,
        defaults["quantity"],
    )
    assert any("must be positive" in p for p in problems)


def test_validate_negative_quantity(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        -100,
        defaults["quantity"],
    )
    assert any("must be positive" in p for p in problems)


def test_validate_overflow_quantity(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        config.MAX_INT + 1,
        defaults["quantity"],
    )
    assert any("exceeds maximum" in p for p in problems)


def test_validate_product_overflow(ledger_db, defaults):
    qty = config.MAX_INT // 2 + 1
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        qty,
        3,
    )
    assert any("quantity_a * quantity_b exceeds" in p for p in problems)


def test_validate_insufficient_balance(ledger_db, defaults):
    # Large enough to exceed balance, small enough that product fits MAX_INT
    huge = config.MAX_INT // 2
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        huge,
        1,
    )
    assert any("insufficient balance" in p for p in problems)


def test_compose_produces_correct_format(ledger_db, defaults):
    source, destinations, data = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        defaults["quantity"],
        defaults["quantity"],
    )
    assert source == defaults["addresses"][0]
    assert destinations == []
    # Data: 1 byte type ID + 32 bytes struct
    assert len(data) == 1 + 40  # SHORT_TXTYPE (1) + QQQQQ (40)
    # First byte is type ID 120
    assert data[0] == 120


def test_compose_and_unpack_roundtrip(ledger_db, defaults):
    qty_a = defaults["quantity"]
    qty_b = defaults["quantity"] * 2

    source, _, data = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        qty_a,
        qty_b,
    )

    # Strip the type ID byte
    message = data[1:]
    asset_a, asset_b, q_a, q_b, min_lp = pooldeposit.unpack(ledger_db, message)

    assert asset_a == "XCP"
    assert asset_b == "DIVISIBLE"
    assert q_a == qty_a
    assert q_b == qty_b


def test_unpack_bad_data(ledger_db):
    asset_a, asset_b, q_a, q_b, min_lp = pooldeposit.unpack(ledger_db, b"\x00\x01\x02")
    assert asset_a == ""
    assert asset_b == ""
    assert q_a == 0
    assert q_b == 0


def test_unpack_wrong_length(ledger_db):
    asset_a, asset_b, q_a, q_b, min_lp = pooldeposit.unpack(ledger_db, b"\x00" * 16)
    assert asset_a == ""


def test_unpack_return_dict(ledger_db):
    result = pooldeposit.unpack(ledger_db, b"\x00\x01", return_dict=True)
    assert isinstance(result, dict)
    assert "asset_a" in result
    assert "quantity_a" in result


def test_compose_rejects_invalid(ledger_db, defaults):
    with pytest.raises(exceptions.ComposeError):
        pooldeposit.compose(
            ledger_db,
            defaults["addresses"][0],
            "BTC",
            "XCP",
            defaults["quantity"],
            defaults["quantity"],
        )


def test_compose_skip_validation(ledger_db, defaults):
    # This would normally fail (BTC pair) but skip_validation allows it
    # It will fail at get_asset_id for BTC though, so use valid assets with bad amounts
    source, _, data = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        0,  # invalid quantity
        0,
        skip_validation=True,
    )
    assert len(data) > 0  # composed despite invalid


def test_parse_invalid_message(ledger_db, defaults, blockchain_mock, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    pooldeposit.parse(ledger_db, tx, b"\xff\xff\xff")
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "pool_deposits",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "status": "invalid: could not unpack",
                },
            },
        ],
    )


def test_parse_valid_first_deposit(ledger_db, defaults, blockchain_mock, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    qty = defaults["quantity"]
    _, _, data = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        qty,
        qty,
    )
    message = data[1:]  # strip type ID

    pooldeposit.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "pool_deposits",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "status": "valid",
                },
            },
        ],
    )

    # Verify pool was created
    cursor = ledger_db.cursor()
    cursor.execute("SELECT * FROM pools ORDER BY rowid DESC LIMIT 1")
    pool = cursor.fetchone()
    assert pool is not None

    # Verify LP token issuance
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "issuances",
                "values": {
                    "asset": pool["lp_asset"],
                    "issuer": config.UNSPENDABLE,
                    "divisible": True,
                    "status": "valid",
                },
            },
        ],
    )

    # Verify transaction status
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "transactions_status",
                "values": {
                    "tx_index": tx["tx_index"],
                    "valid": True,
                },
            },
        ],
    )


def test_parse_subsequent_deposit(ledger_db, defaults, blockchain_mock, test_helpers):
    """Second deposit into existing pool mints proportional LP tokens."""
    qty = defaults["quantity"]

    # First deposit creates pool (use half of balance)
    tx1 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data = pooldeposit.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", qty // 4, qty // 4
    )
    pooldeposit.parse(ledger_db, tx1, data[1:])

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_asset = pool["lp_asset"]
    lp_after_first = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    assert lp_after_first > 0

    # Second deposit — same amounts
    tx2 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data2 = pooldeposit.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", qty // 4, qty // 4
    )
    pooldeposit.parse(ledger_db, tx2, data2[1:])

    lp_after_second = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    # Should have roughly doubled LP tokens
    new_lp = lp_after_second - lp_after_first
    assert new_lp > 0
    assert new_lp == lp_after_first  # same amount deposited = same LP minted

    # Pool reserves should have doubled
    pool_after = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    assert pool_after["reserve_a"] == qty // 4 * 2
    assert pool_after["reserve_b"] == qty // 4 * 2


def test_parse_mismatched_ratio(ledger_db, defaults, blockchain_mock, test_helpers):
    """Deposit with wrong ratio succeeds but mints LP capped by limiting side."""
    qty = defaults["quantity"]

    # Create 1:1 pool
    tx1 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data = pooldeposit.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", qty, qty
    )
    pooldeposit.parse(ledger_db, tx1, data[1:])

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_asset = pool["lp_asset"]
    lp_before = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)

    # Second deposit with 2:1 ratio (double one side)
    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")
    p = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)
    dep_a = p["reserve_a"] // 10
    dep_b = p["reserve_b"] // 5  # double the ratio
    _, _, data2 = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        sorted_a,
        sorted_b,
        dep_a,
        dep_b,
    )
    tx2 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    pooldeposit.parse(ledger_db, tx2, data2[1:])

    lp_after = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    new_lp = lp_after - lp_before

    # LP minted should be based on limiting side (dep_a), not the larger dep_b
    assert new_lp > 0

    # Both assets enter pool (reserves grow by full amounts, not just matched ratio)
    p_after = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)
    assert p_after["reserve_a"] == p["reserve_a"] + dep_a
    assert p_after["reserve_b"] == p["reserve_b"] + dep_b

    # LP minted should equal the SMALLER proportional contribution
    # subsequent_deposit uses supply BEFORE the deposit for calculation
    supply_at_deposit = lp_before  # total supply when second deposit happened
    expected_from_a = dep_a * supply_at_deposit // p["reserve_a"]
    expected_from_b = dep_b * supply_at_deposit // p["reserve_b"]
    assert new_lp == min(expected_from_a, expected_from_b)
    # Smaller side caps the minting — larger side's excess enters reserves
    assert expected_from_a < expected_from_b  # dep_a is the limiting side


def test_slippage_protection_rejects_low_mint(ledger_db, defaults, blockchain_mock, test_helpers):
    """Deposit with min_lp_quantity rejects if minted LP is below threshold."""
    qty = defaults["quantity"]

    # Create 1:1 pool
    tx1 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data = pooldeposit.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", qty // 4, qty // 4
    )
    pooldeposit.parse(ledger_db, tx1, data[1:])

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")

    # Compose a second deposit with unreachably high min_lp_quantity
    dep = pool["reserve_a"] // 10
    _, _, data2 = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        sorted_a,
        sorted_b,
        dep,
        dep,
        min_lp_quantity=qty * 999,  # impossible to mint this many
    )
    tx2 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])

    # parse should reject — slippage protection triggered
    with pytest.raises(exceptions.MessageError, match="slippage protection"):
        pooldeposit.parse(ledger_db, tx2, data2[1:])


def test_slippage_protection_allows_when_met(ledger_db, defaults, blockchain_mock, test_helpers):
    """Deposit succeeds when minted LP meets min_lp_quantity threshold."""
    qty = defaults["quantity"]

    # Create 1:1 pool
    tx1 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data = pooldeposit.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", qty // 4, qty // 4
    )
    pooldeposit.parse(ledger_db, tx1, data[1:])

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_asset = pool["lp_asset"]
    lp_before = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")

    # Deposit same ratio with min_lp_quantity = 1 (easily met)
    dep = pool["reserve_a"] // 10
    _, _, data2 = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        sorted_a,
        sorted_b,
        dep,
        dep,
        min_lp_quantity=1,
    )
    tx2 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    pooldeposit.parse(ledger_db, tx2, data2[1:])

    lp_after = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    assert lp_after > lp_before
