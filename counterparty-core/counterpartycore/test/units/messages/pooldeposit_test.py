import pytest
from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import pooldeposit, poolwithdraw


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
    quantity = config.MAX_INT // 2 + 1
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        quantity,
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


def test_validate_off_ratio_deposit_uses_proportional_amounts(ledger_db, defaults, blockchain_mock):
    quantity = defaults["quantity"]
    source = defaults["addresses"][0]

    tx1 = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(
        ledger_db, source, "XCP", "DIVISIBLE", quantity // 4, quantity // 4
    )
    pooldeposit.parse(ledger_db, tx1, data[1:])

    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")
    pool = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)
    dep_a = pool["reserve_a"] // 10
    dep_b = pool["reserve_b"] // 5
    actual_a, actual_b = pooldeposit.calculate_actual_deposit_amounts(pool, dep_a, dep_b)

    balance_b = ledger.balances.get_balance(ledger_db, source, sorted_b)
    ledger.events.debit(
        ledger_db,
        source,
        sorted_b,
        balance_b - actual_b,
        0,
        action="test",
        event="test",
    )

    problems = pooldeposit.validate(ledger_db, source, sorted_a, sorted_b, dep_a, dep_b)
    assert problems == []
    assert dep_b > actual_b


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
    quantity_a = defaults["quantity"]
    quantity_b = defaults["quantity"] * 2

    source, _, data = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        quantity_a,
        quantity_b,
    )

    # Strip the type ID byte
    message = data[1:]
    asset_a, asset_b, q_a, q_b, min_lp = pooldeposit.unpack(ledger_db, message)

    assert asset_a == "XCP"
    assert asset_b == "DIVISIBLE"
    assert q_a == quantity_a
    assert q_b == quantity_b


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
    quantity = defaults["quantity"]
    _, _, data = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        quantity,
        quantity,
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
                    "asset_a": "DIVISIBLE",
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
    quantity = defaults["quantity"]

    # First deposit creates pool (use half of balance)
    tx1 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data = pooldeposit.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", quantity // 4, quantity // 4
    )
    pooldeposit.parse(ledger_db, tx1, data[1:])

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_asset = pool["lp_asset"]
    lp_after_first = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    assert lp_after_first > 0

    # Second deposit — same amounts
    tx2 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data2 = pooldeposit.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", quantity // 4, quantity // 4
    )
    pooldeposit.parse(ledger_db, tx2, data2[1:])

    lp_after_second = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    # Should have roughly doubled LP tokens
    new_lp = lp_after_second - lp_after_first
    assert new_lp > 0
    assert new_lp == lp_after_first  # same amount deposited = same LP minted

    # Pool reserves should have doubled
    pool_after = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    assert pool_after["reserve_a"] == quantity // 4 * 2
    assert pool_after["reserve_b"] == quantity // 4 * 2


def test_parse_mismatched_ratio(ledger_db, defaults, blockchain_mock, test_helpers):
    """Off-ratio deposit takes only proportional amounts, leaves excess with user."""
    quantity = defaults["quantity"]

    # Create 1:1 pool
    tx1 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data = pooldeposit.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", quantity, quantity
    )
    pooldeposit.parse(ledger_db, tx1, data[1:])

    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")
    p = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)
    lp_asset = p["lp_asset"]
    lp_before = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    bal_b_before = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], sorted_b)

    # Second deposit with 2:1 ratio (double one side)
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
    assert new_lp > 0

    # Only proportional amounts enter pool — ratio is preserved
    p_after = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)
    assert p_after["reserve_a"] == p["reserve_a"] + dep_a
    # reserve_b grows by the proportional amount, not the full dep_b
    actual_b = dep_a * p["reserve_b"] // p["reserve_a"]
    assert p_after["reserve_b"] == p["reserve_b"] + actual_b
    assert actual_b < dep_b  # excess was NOT taken

    # User's balance of the excess side should reflect only proportional debit
    bal_b_after = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], sorted_b)
    assert bal_b_after == bal_b_before - actual_b


def test_slippage_protection_rejects_low_mint(ledger_db, defaults, blockchain_mock, test_helpers):
    """Deposit with min_lp_quantity rejects if minted LP is below threshold."""
    quantity = defaults["quantity"]

    # Create 1:1 pool
    tx1 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data = pooldeposit.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", quantity // 4, quantity // 4
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
        min_lp_quantity=quantity * 999,  # impossible to mint this many
    )
    tx2 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])

    # parse should reject — slippage protection triggered
    with pytest.raises(exceptions.MessageError, match="slippage protection"):
        pooldeposit.parse(ledger_db, tx2, data2[1:])


def test_slippage_protection_allows_when_met(ledger_db, defaults, blockchain_mock, test_helpers):
    """Deposit succeeds when minted LP meets min_lp_quantity threshold."""
    quantity = defaults["quantity"]

    # Create 1:1 pool
    tx1 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data = pooldeposit.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", quantity // 4, quantity // 4
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


def test_first_deposit_respects_min_lp_quantity(ledger_db, defaults, blockchain_mock):
    quantity = defaults["quantity"] // 4
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        quantity,
        quantity,
        min_lp_quantity=quantity * 10,
    )

    with pytest.raises(exceptions.MessageError, match="slippage protection"):
        pooldeposit.parse(ledger_db, tx, data[1:])


def test_empty_pool_refund_respects_min_lp_quantity(ledger_db, defaults, blockchain_mock):
    quantity = defaults["quantity"] // 4
    source = defaults["addresses"][0]

    tx1 = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, deposit_data = pooldeposit.compose(
        ledger_db, source, "XCP", "DIVISIBLE", quantity, quantity
    )
    pooldeposit.parse(ledger_db, tx1, deposit_data[1:])

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    tx2 = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, withdraw_data = poolwithdraw.compose(
        ledger_db, source, pool["asset_a"], pool["asset_b"], quantity
    )
    poolwithdraw.parse(ledger_db, tx2, withdraw_data[1:])

    tx3 = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, refund_data = pooldeposit.compose(
        ledger_db,
        source,
        "XCP",
        "DIVISIBLE",
        quantity,
        quantity,
        min_lp_quantity=quantity * 10,
    )

    with pytest.raises(exceptions.MessageError, match="slippage protection"):
        pooldeposit.parse(ledger_db, tx3, refund_data[1:])


def test_validate_lp_token_cannot_be_pooled(ledger_db, defaults, blockchain_mock):
    """LP token from an existing pool cannot itself be deposited into a new pool."""
    quantity = defaults["quantity"] // 4
    source = defaults["addresses"][0]

    # Create a pool and get its LP token
    tx1 = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", quantity, quantity)
    pooldeposit.parse(ledger_db, tx1, data[1:])

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_asset = pool["lp_asset"]

    # Try to create a pool using the LP token
    problems = pooldeposit.validate(ledger_db, source, lp_asset, "XCP", 100, 100)
    assert any("LP token" in p for p in problems)


def test_validate_subsequent_deposit_too_small(ledger_db, defaults, blockchain_mock):
    """Subsequent deposit with tiny amounts that would mint 0 LP tokens should fail in parse."""
    quantity = defaults["quantity"]
    source = defaults["addresses"][0]

    # Create pool with asymmetric reserves so supply << reserve_a.
    # isqrt(quantity * 1) ≈ 10000 LP tokens, but reserve_a = quantity = 100M.
    # Then 1 sat deposit: minted = 1 * 10000 // 100M = 0.
    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")
    tx1 = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, sorted_a, sorted_b, quantity, 1)
    pooldeposit.parse(ledger_db, tx1, data[1:])

    _, _, data2 = pooldeposit.compose(
        ledger_db, source, sorted_a, sorted_b, 1, 1, skip_validation=True
    )
    tx2 = blockchain_mock.dummy_tx(ledger_db, source)
    with pytest.raises(exceptions.MessageError, match="deposit too small"):
        pooldeposit.parse(ledger_db, tx2, data2[1:])


def test_validate_xcp_fee_insufficient(ledger_db, defaults, blockchain_mock):
    """When gas fee > 0 and XCP balance is too low for fee + quantity, validation should fail."""
    from counterpartycore.lib.messages import gas

    source = defaults["addresses"][0]
    quantity = defaults["quantity"]

    # Check actual fee — if fee is 0 (gas disabled for pools), this test is vacuous.
    fee = gas.get_transaction_fee(ledger_db, pooldeposit.ID, 999999)
    if fee > 0:
        # Drain XCP to just below what's needed
        xcp_balance = ledger.balances.get_balance(ledger_db, source, config.XCP)
        # Need quantity for deposit + fee. If balance < quantity + fee, should get error.
        needed = quantity + fee
        if xcp_balance >= needed:
            # Drain balance so that balance < needed
            drain = xcp_balance - needed + 1
            ledger.events.debit(
                ledger_db, source, config.XCP, drain, 0, action="test", event="test"
            )

        problems = pooldeposit.validate(ledger_db, source, "XCP", "DIVISIBLE", quantity, 1)
        assert any("insufficient XCP for fee" in p for p in problems)
