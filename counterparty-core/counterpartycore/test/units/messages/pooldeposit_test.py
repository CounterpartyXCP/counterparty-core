import struct

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
        lp_asset="A99999999999999999",
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
    actual_a, actual_b = pooldeposit.compute_actual_deposit_amounts(pool, dep_a, dep_b)

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
    # 1 byte type ID + QQQQQQ (48 bytes)
    assert len(data) == 1 + pooldeposit.LENGTH
    assert data[0] == pooldeposit.ID


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
    asset_a, asset_b, q_a, q_b, min_lp, lp_asset_id = pooldeposit.unpack(ledger_db, message)

    assert asset_a == "XCP"
    assert asset_b == "DIVISIBLE"
    assert q_a == quantity_a
    assert q_b == quantity_b
    # XCP:DIVISIBLE pool doesn't exist in the fixture, so compose must have
    # selected an lp_asset_id for the first-deposit path.
    assert lp_asset_id > 0


def test_unpack_bad_data(ledger_db):
    asset_a, asset_b, q_a, q_b, min_lp, lp_asset_id = pooldeposit.unpack(ledger_db, b"\x00\x01\x02")
    assert asset_a == ""
    assert asset_b == ""
    assert q_a == 0
    assert q_b == 0
    assert lp_asset_id == 0


def test_unpack_wrong_length(ledger_db):
    asset_a, asset_b, q_a, q_b, min_lp, lp_asset_id = pooldeposit.unpack(ledger_db, b"\x00" * 16)
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


def test_slippage_protection_rejects_low_mint(ledger_db, defaults, blockchain_mock):
    """Deposit with min_lp_quantity above achievable mint is rejected at compose."""
    quantity = defaults["quantity"]

    tx1 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data = pooldeposit.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", quantity // 4, quantity // 4
    )
    pooldeposit.parse(ledger_db, tx1, data[1:])

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")
    dep = pool["reserve_a"] // 10

    with pytest.raises(exceptions.ComposeError, match="slippage protection"):
        pooldeposit.compose(
            ledger_db,
            defaults["addresses"][0],
            sorted_a,
            sorted_b,
            dep,
            dep,
            min_lp_quantity=quantity * 999,
        )


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
    with pytest.raises(exceptions.ComposeError, match="slippage protection"):
        pooldeposit.compose(
            ledger_db,
            defaults["addresses"][0],
            "XCP",
            "DIVISIBLE",
            quantity,
            quantity,
            min_lp_quantity=quantity * 10,
        )


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

    with pytest.raises(exceptions.ComposeError, match="slippage protection"):
        pooldeposit.compose(
            ledger_db,
            source,
            "XCP",
            "DIVISIBLE",
            quantity,
            quantity,
            min_lp_quantity=quantity * 10,
        )


def test_restart_after_external_lp_destroy(ledger_db, defaults, blockchain_mock):
    """Pool is recoverable when every LP holder destroys their LP externally."""
    from counterpartycore.lib.messages import destroy

    quantity = defaults["quantity"] // 4
    source = defaults["addresses"][0]

    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", quantity, quantity)
    pooldeposit.parse(ledger_db, tx, data[1:])

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_asset = pool["lp_asset"]
    lp_balance = ledger.balances.get_balance(ledger_db, source, lp_asset)

    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, ddata = destroy.compose(ledger_db, source, lp_asset, lp_balance, b"brick")
    destroy.parse(ledger_db, tx, ddata[1:])

    assert ledger.supplies.asset_supply(ledger_db, lp_asset) == 0
    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    stranded_a, stranded_b = pool["reserve_a"], pool["reserve_b"]
    assert stranded_a > 0 and stranded_b > 0

    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, rdata = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", quantity, quantity)
    pooldeposit.parse(ledger_db, tx, rdata[1:])

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    assert pool["reserve_a"] == stranded_a + quantity
    assert pool["reserve_b"] == stranded_b + quantity
    assert ledger.supplies.asset_supply(ledger_db, lp_asset) > 0
    assert ledger.balances.get_balance(ledger_db, source, lp_asset) > 0


def test_validate_blocks_pool_during_active_fairmint(ledger_db, defaults, blockchain_mock):
    """Manual pool creation is blocked while a fairmint-pool is active for the asset."""
    from counterpartycore.lib.messages import fairminter

    source = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(ledger_db, source, use_first_tx=True)
    # FAIRMINTED, price=1, hard_cap=100, soft_cap=60, pool_quantity=40, lp_asset=A95428956661682177
    message = b"\x95\x1b\x00\x00\x18\xc0\xfd\xcd\xeb_\x00\x01\x01\x00\x00\x18d\x00\x1a\x00\x0c5\x00\x1a\x00\r\xbb\xa0\x18<\x1a\x00\x0c\xf8P\x00\xf4\xf4\xf5\xf5`@\x18(\x1b\x01S\x08!g\x1b\x10\x01"
    fairminter.parse(ledger_db, tx, message)

    problems = pooldeposit.validate(ledger_db, source, "FAIRMINTED", "XCP", 100, 100)
    assert any("fairminter with pool_quantity is active" in p for p in problems)


def test_validate_blocks_pool_during_active_fairmint_reverse_pair(
    ledger_db, defaults, blockchain_mock
):
    """Earmark check runs on both asset_a and asset_b — (XCP, FAIRMINTED) is equally blocked."""
    from counterpartycore.lib.messages import fairminter

    source = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(ledger_db, source, use_first_tx=True)
    message = b"\x95\x1b\x00\x00\x18\xc0\xfd\xcd\xeb_\x00\x01\x01\x00\x00\x18d\x00\x1a\x00\x0c5\x00\x1a\x00\r\xbb\xa0\x18<\x1a\x00\x0c\xf8P\x00\xf4\xf4\xf5\xf5`@\x18(\x1b\x01S\x08!g\x1b\x10\x01"
    fairminter.parse(ledger_db, tx, message)

    problems = pooldeposit.validate(ledger_db, source, "XCP", "FAIRMINTED", 100, 100)
    assert any("fairminter with pool_quantity is active" in p for p in problems)


def test_validate_blocks_pool_with_earmarked_lp_asset(ledger_db, defaults, blockchain_mock):
    """lp_asset earmarked by an active fairminter is rejected in pooldeposit.validate."""
    from counterpartycore.lib.messages import fairminter

    source = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(ledger_db, source, use_first_tx=True)
    message = b"\x95\x1b\x00\x00\x18\xc0\xfd\xcd\xeb_\x00\x01\x01\x00\x00\x18d\x00\x1a\x00\x0c5\x00\x1a\x00\r\xbb\xa0\x18<\x1a\x00\x0c\xf8P\x00\xf4\xf4\xf5\xf5`@\x18(\x1b\x01S\x08!g\x1b\x10\x01"
    fairminter.parse(ledger_db, tx, message)

    problems = pooldeposit.validate(
        ledger_db, source, "XCP", "DIVISIBLE", 100, 100, lp_asset="A95428956661682177"
    )
    assert any("earmarked by an active fairminter" in p for p in problems)


def test_validate_allows_pool_after_fairminter_closes(ledger_db, defaults, blockchain_mock):
    """Once the fairminter is closed, the earmark is released and a pool may be created."""
    from counterpartycore.lib.messages import fairminter

    source = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(ledger_db, source, use_first_tx=True)
    message = b"\x95\x1b\x00\x00\x18\xc0\xfd\xcd\xeb_\x00\x01\x01\x00\x00\x18d\x00\x1a\x00\x0c5\x00\x1a\x00\r\xbb\xa0\x18<\x1a\x00\x0c\xf8P\x00\xf4\xf4\xf5\xf5`@\x18(\x1b\x01S\x08!g\x1b\x10\x01"
    fairminter.parse(ledger_db, tx, message)

    fm_row = ledger.issuances.get_fairminter_by_asset(ledger_db, "FAIRMINTED")
    ledger.issuances.update_fairminter(ledger_db, fm_row["tx_hash"], {"status": "closed"})

    problems = pooldeposit.validate(ledger_db, source, "FAIRMINTED", "XCP", 100, 100)
    assert not any("fairminter with pool_quantity is active" in p for p in problems)


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
    """Tiny deposits into a skewed pool that would mint 0 LP are rejected."""
    quantity = defaults["quantity"]
    source = defaults["addresses"][0]

    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")
    tx1 = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, sorted_a, sorted_b, quantity, 1)
    pooldeposit.parse(ledger_db, tx1, data[1:])

    problems = pooldeposit.validate(ledger_db, source, sorted_a, sorted_b, 1, 1)
    assert any("deposit too small" in p for p in problems)


def test_create_pool_from_fairminter_halts_if_pool_exists(ledger_db, defaults, blockchain_mock):
    """Reaching create_pool_from_fairminter with an existing pool is an invariant
    violation (fairminter.validate and pooldeposit.validate both block it); halt cleanly."""
    source = defaults["addresses"][0]
    quantity = defaults["quantity"] // 4

    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", quantity, quantity)
    pooldeposit.parse(ledger_db, tx, data[1:])

    fairminter = {
        "tx_hash": "b" * 64,
        "tx_index": 999,
        "source": source,
        "lp_asset": "A95428956661682177",
    }
    with pytest.raises(
        exceptions.ParseTransactionError, match="pool already exists at soft-cap close"
    ):
        pooldeposit.create_pool_from_fairminter(
            ledger_db,
            fairminter,
            block_index=9999,
            asset="DIVISIBLE",
            quantity_tokens=quantity,
            quantity_xcp=quantity,
        )


def test_create_pool_from_fairminter(ledger_db, defaults, test_helpers):
    """Test trustless pool creation from fairminter resolution."""
    source = defaults["addresses"][0]
    quantity = defaults["quantity"]

    fairminter = {
        "tx_hash": "a" * 64,
        "tx_index": 999,
        "source": source,
        "lp_asset": "A95428956661682177",
    }

    lp = pooldeposit.create_pool_from_fairminter(
        ledger_db,
        fairminter,
        block_index=9999,
        asset="NODIVISIBLE",
        quantity_tokens=quantity,
        quantity_xcp=quantity,
    )
    assert lp > 0

    # Verify pool was created
    sorted_a, sorted_b = ledger.markets.sort_pair("NODIVISIBLE", config.XCP)
    pool = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)
    assert pool is not None
    assert pool["reserve_a"] == quantity
    assert pool["reserve_b"] == quantity

    # Verify LP tokens credited to UNSPENDABLE
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "credits",
                "values": {
                    "address": defaults["unspendable"],
                    "asset": pool["lp_asset"],
                    "quantity": lp,
                    "calling_function": "fairminter pool deposit",
                },
            },
            {
                "table": "pool_deposits",
                "values": {
                    "tx_hash": "a" * 64,
                    "asset_a": sorted_a,
                    "asset_b": sorted_b,
                    "status": "valid",
                },
            },
        ],
    )


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


# lp_asset / lp_asset_id plumbing for first-deposit txs.


def test_validate_first_deposit_requires_lp_asset(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        defaults["quantity"],
        defaults["quantity"],
        lp_asset=None,
    )
    assert any("requires an lp_asset" in p for p in problems)


def test_validate_min_lp_quantity_overflow(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        defaults["quantity"],
        defaults["quantity"],
        min_lp_quantity=config.MAX_INT + 1,
    )
    assert any("min_lp_quantity exceeds maximum value" in p for p in problems)


def test_validate_lp_asset_rejects_xcp(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        defaults["quantity"],
        defaults["quantity"],
        lp_asset="XCP",
    )
    assert any("must be a numeric asset" in p for p in problems)


def test_validate_lp_asset_rejects_btc(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        defaults["quantity"],
        defaults["quantity"],
        lp_asset="BTC",
    )
    assert any("must be a numeric asset" in p for p in problems)


def test_validate_lp_asset_rejects_taken_name(ledger_db, defaults):
    # A160361285792733729 is a pre-existing numeric asset in the fixture
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        defaults["quantity"],
        defaults["quantity"],
        lp_asset="A160361285792733729",
    )
    assert any("already in use" in p for p in problems)


def test_validate_lp_asset_rejects_base26_name(ledger_db, defaults):
    problems = pooldeposit.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        defaults["quantity"],
        defaults["quantity"],
        lp_asset="DIVISIBLE",
    )
    assert any("must be a numeric asset" in p for p in problems)


def test_compose_auto_generates_lp_asset_id(ledger_db, defaults):
    _, _, data = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        defaults["quantity"],
        defaults["quantity"],
    )
    _, _, _, _, _, lp_asset_id = pooldeposit.unpack(ledger_db, data[1:])
    assert lp_asset_id > 0


def test_compose_accepts_explicit_lp_asset(ledger_db, defaults):
    _, _, data = pooldeposit.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        defaults["quantity"],
        defaults["quantity"],
        lp_asset="A99999999999999999",
    )
    _, _, _, _, _, lp_asset_id = pooldeposit.unpack(ledger_db, data[1:])
    assert lp_asset_id == 99999999999999999


def test_compose_rejects_taken_lp_asset(ledger_db, defaults):
    with pytest.raises(exceptions.ComposeError):
        pooldeposit.compose(
            ledger_db,
            defaults["addresses"][0],
            "XCP",
            "DIVISIBLE",
            defaults["quantity"],
            defaults["quantity"],
            lp_asset="DIVISIBLE",
        )


def test_compose_subsequent_deposit_packs_zero_lp_asset_id(ledger_db, defaults, blockchain_mock):
    source = defaults["addresses"][0]
    quantity = defaults["quantity"]
    # first deposit creates the pool
    tx1 = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(
        ledger_db, source, "XCP", "DIVISIBLE", quantity // 4, quantity // 4
    )
    pooldeposit.parse(ledger_db, tx1, data[1:])
    # now the pool exists; compose should pack 0 for lp_asset_id
    _, _, data2 = pooldeposit.compose(
        ledger_db, source, "XCP", "DIVISIBLE", quantity // 4, quantity // 4
    )
    _, _, _, _, _, lp_asset_id = pooldeposit.unpack(ledger_db, data2[1:])
    assert lp_asset_id == 0


def _pack_message(asset_a_id, asset_b_id, q_a, q_b, min_lp, lp_asset_id):
    return struct.pack(pooldeposit.FORMAT, asset_a_id, asset_b_id, q_a, q_b, min_lp, lp_asset_id)


def test_parse_first_deposit_rejects_zero_lp_asset_id(
    ledger_db, defaults, blockchain_mock, test_helpers
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    q = defaults["quantity"]
    xcp_id = ledger.issuances.get_asset_id(ledger_db, "XCP")
    div_id = ledger.issuances.get_asset_id(ledger_db, "DIVISIBLE")
    message = _pack_message(xcp_id, div_id, q, q, 0, 0)

    pooldeposit.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "pool_deposits",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "status": "invalid: first pool deposit requires an lp_asset",
                },
            },
        ],
    )


def test_parse_first_deposit_rejects_taken_lp_asset_id(
    ledger_db, defaults, blockchain_mock, test_helpers
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    q = defaults["quantity"]
    xcp_id = ledger.issuances.get_asset_id(ledger_db, "XCP")
    div_id = ledger.issuances.get_asset_id(ledger_db, "DIVISIBLE")
    # A160361285792733729 is a numeric asset already issued in the fixture
    taken_id = ledger.issuances.get_asset_id(ledger_db, "A160361285792733729")
    message = _pack_message(xcp_id, div_id, q, q, 0, taken_id)

    pooldeposit.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "pool_deposits",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "status": "invalid: lp_asset A160361285792733729 is already in use",
                },
            },
        ],
    )


def test_parse_first_deposit_rejects_too_low_lp_asset_id(
    ledger_db, defaults, blockchain_mock, test_helpers
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    q = defaults["quantity"]
    xcp_id = ledger.issuances.get_asset_id(ledger_db, "XCP")
    div_id = ledger.issuances.get_asset_id(ledger_db, "DIVISIBLE")
    # An lp_asset_id in the sub-26^3 range raises AssetIDError in
    # generate_asset_name, so lp_asset resolves to None and validate
    # flags the missing lp_asset.
    message = _pack_message(xcp_id, div_id, q, q, 0, 100)

    pooldeposit.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "pool_deposits",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "status": "invalid: first pool deposit requires an lp_asset",
                },
            },
        ],
    )


def test_parse_first_deposit_rejects_base26_lp_asset_id(
    ledger_db, defaults, blockchain_mock, test_helpers
):
    # 17576 = 26**3 decodes to the base-26 name "BAAA". Accepting this would
    # squat a human-readable name under issuer=UNSPENDABLE.
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    q = defaults["quantity"]
    xcp_id = ledger.issuances.get_asset_id(ledger_db, "XCP")
    div_id = ledger.issuances.get_asset_id(ledger_db, "DIVISIBLE")
    message = _pack_message(xcp_id, div_id, q, q, 0, 17576)

    pooldeposit.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "pool_deposits",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "status": "invalid: lp_asset must be a numeric asset",
                },
            },
        ],
    )


def test_compose_ignores_lp_asset_when_pool_exists(ledger_db, defaults, blockchain_mock):
    source = defaults["addresses"][0]
    q = defaults["quantity"]
    # Create the pool first
    tx1 = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", q // 4, q // 4)
    pooldeposit.parse(ledger_db, tx1, data[1:])

    # Compose a subsequent deposit, passing an explicit lp_asset that
    # should be ignored (pool already has its own LP asset)
    _, _, data2 = pooldeposit.compose(
        ledger_db,
        source,
        "XCP",
        "DIVISIBLE",
        q // 4,
        q // 4,
        lp_asset="A88888888888888888",
    )
    _, _, _, _, _, lp_asset_id = pooldeposit.unpack(ledger_db, data2[1:])
    assert lp_asset_id == 0


def test_subsequent_deposit_mints_min_of_bases(ledger_db, defaults, blockchain_mock):
    source = defaults["addresses"][0]
    tx1 = blockchain_mock.dummy_tx(ledger_db, source)
    q = defaults["quantity"]
    _, _, data = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", q, q // 2)
    pooldeposit.parse(ledger_db, tx1, data[1:])

    pool = ledger.markets.get_pool(ledger_db, *ledger.markets.sort_pair("XCP", "DIVISIBLE"))
    lp_asset = pool["lp_asset"]
    supply = ledger.supplies.asset_issued_total_no_cache(
        ledger_db, lp_asset
    ) - ledger.supplies.asset_destroyed_total_no_cache(ledger_db, lp_asset)
    reserve_a, reserve_b = pool["reserve_a"], pool["reserve_b"]

    deposit_a = reserve_a * 3 // 7
    deposit_b = reserve_b * 5 // 7
    actual_a, actual_b = pooldeposit.compute_actual_deposit_amounts(pool, deposit_a, deposit_b)

    a_basis = actual_a * supply // reserve_a
    b_basis = actual_b * supply // reserve_b
    expected = min(a_basis, b_basis)

    lp_before = ledger.balances.get_balance(ledger_db, source, lp_asset)
    tx2 = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data2 = pooldeposit.compose(
        ledger_db,
        source,
        pool["asset_a"],
        pool["asset_b"],
        deposit_a,
        deposit_b,
    )
    pooldeposit.parse(ledger_db, tx2, data2[1:])

    minted = ledger.balances.get_balance(ledger_db, source, lp_asset) - lp_before
    assert minted == expected
    assert minted <= a_basis
    assert minted <= b_basis


def test_parse_subsequent_deposit_ignores_lp_asset_id(ledger_db, defaults, blockchain_mock):
    source = defaults["addresses"][0]
    q = defaults["quantity"]
    tx1 = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", q // 4, q // 4)
    pooldeposit.parse(ledger_db, tx1, data[1:])

    pool = ledger.markets.get_pool(ledger_db, *ledger.markets.sort_pair("XCP", "DIVISIBLE"))
    reserve_a_before = pool["reserve_a"]

    garbage_lp_id = 42
    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")
    a_id = ledger.issuances.get_asset_id(ledger_db, sorted_a)
    b_id = ledger.issuances.get_asset_id(ledger_db, sorted_b)
    message = _pack_message(a_id, b_id, q // 4, q // 4, 0, garbage_lp_id)

    tx2 = blockchain_mock.dummy_tx(ledger_db, source)
    pooldeposit.parse(ledger_db, tx2, message)

    # Despite the garbage lp_asset_id, the second deposit is valid because
    # the pool already exists (lp_asset_id is ignored on subsequent deposits).
    pool_after = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)
    assert pool_after["reserve_a"] > reserve_a_before
