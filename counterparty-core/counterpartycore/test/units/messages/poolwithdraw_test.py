import pytest
from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import pooldeposit, poolwithdraw


def create_pool(ledger_db, blockchain_mock, source, quantity_a, quantity_b):
    """Helper: deposit to create a pool and return (tx, pool)."""
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", quantity_a, quantity_b)
    pooldeposit.parse(ledger_db, tx, data[1:])
    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    return tx, pool


def test_validate_valid(ledger_db, defaults, blockchain_mock):
    create_pool(
        ledger_db,
        blockchain_mock,
        defaults["addresses"][0],
        defaults["quantity"],
        defaults["quantity"],
    )
    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_balance = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], pool["lp_asset"])
    problems = poolwithdraw.validate(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", lp_balance
    )
    assert problems == []


def test_validate_btc_rejected(ledger_db, defaults):
    problems = poolwithdraw.validate(ledger_db, defaults["addresses"][0], "BTC", "XCP", 1000)
    assert "BTC pairs are not supported" in problems[0]


def test_validate_same_asset(ledger_db, defaults):
    problems = poolwithdraw.validate(ledger_db, defaults["addresses"][0], "XCP", "XCP", 1000)
    assert "assets must be different" in problems[0]


def test_validate_nonexistent_asset(ledger_db, defaults):
    problems = poolwithdraw.validate(
        ledger_db, defaults["addresses"][0], "XCP", "DOESNOTEXIST", 1000
    )
    assert any("does not exist" in p for p in problems)


def test_validate_zero_quantity(ledger_db, defaults):
    problems = poolwithdraw.validate(ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", 0)
    assert any("must be positive" in p for p in problems)


def test_validate_negative_quantity(ledger_db, defaults):
    problems = poolwithdraw.validate(ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", -100)
    assert any("must be positive" in p for p in problems)


def test_validate_overflow_quantity(ledger_db, defaults):
    problems = poolwithdraw.validate(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", config.MAX_INT + 1
    )
    assert any("exceeds maximum" in p for p in problems)


def test_validate_min_quantity_a_overflow(ledger_db, defaults):
    problems = poolwithdraw.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        100,
        min_quantity_a=config.MAX_INT + 1,
    )
    assert any("min_quantity_a exceeds maximum value" in p for p in problems)


def test_validate_min_quantity_b_overflow(ledger_db, defaults):
    problems = poolwithdraw.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        100,
        min_quantity_b=config.MAX_INT + 1,
    )
    assert any("min_quantity_b exceeds maximum value" in p for p in problems)


def test_validate_min_quantities_type_and_negative(ledger_db, defaults):
    problems = poolwithdraw.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        100,
        min_quantity_a="1",
    )
    assert any("min_quantity_a must be an integer" in p for p in problems)

    problems = poolwithdraw.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        100,
        min_quantity_b="1",
    )
    assert any("min_quantity_b must be an integer" in p for p in problems)

    problems = poolwithdraw.validate(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        100,
        min_quantity_a=-1,
        min_quantity_b=-1,
    )
    assert any("min_quantity_a cannot be negative" in p for p in problems)
    assert any("min_quantity_b cannot be negative" in p for p in problems)


def test_validate_no_pool(ledger_db, defaults):
    problems = poolwithdraw.validate(ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", 1000)
    assert any("pool does not exist" in p for p in problems)


def test_validate_insufficient_lp_balance(ledger_db, defaults, blockchain_mock):
    create_pool(
        ledger_db,
        blockchain_mock,
        defaults["addresses"][0],
        defaults["quantity"],
        defaults["quantity"],
    )
    # Try to withdraw more LP tokens than held
    problems = poolwithdraw.validate(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", 10**18
    )
    assert any("insufficient LP token balance" in p for p in problems)


def test_validate_rejects_asymmetric_drain(ledger_db, defaults, blockchain_mock):
    """Withdrawals that would redeem zero of either side are rejected."""
    source = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", 100_000_000, 4)
    pooldeposit.parse(ledger_db, tx, data[1:])

    problems = poolwithdraw.validate(ledger_db, source, "XCP", "DIVISIBLE", 1)
    assert any("withdrawal too small" in p for p in problems)


def test_compose_produces_correct_format(ledger_db, defaults, blockchain_mock):
    create_pool(
        ledger_db,
        blockchain_mock,
        defaults["addresses"][0],
        defaults["quantity"],
        defaults["quantity"],
    )
    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_balance = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], pool["lp_asset"])

    source, destinations, data = poolwithdraw.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", lp_balance
    )
    assert source == defaults["addresses"][0]
    assert destinations == []
    assert len(data) == 1 + poolwithdraw.LENGTH
    assert data[0] == poolwithdraw.ID


def test_compose_and_unpack_roundtrip(ledger_db, defaults, blockchain_mock):
    create_pool(
        ledger_db,
        blockchain_mock,
        defaults["addresses"][0],
        defaults["quantity"],
        defaults["quantity"],
    )
    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_balance = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], pool["lp_asset"])

    _, _, data = poolwithdraw.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", lp_balance
    )
    message = data[1:]
    asset_a, asset_b, quantity, min_a, min_b = poolwithdraw.unpack(ledger_db, message)

    assert asset_a == "XCP"
    assert asset_b == "DIVISIBLE"
    assert quantity == lp_balance
    assert min_a == 0
    assert min_b == 0


def test_unpack_bad_data(ledger_db):
    asset_a, asset_b, lp_qty, min_a, min_b = poolwithdraw.unpack(ledger_db, b"\x00\x01\x02")
    assert asset_a == ""
    assert asset_b == ""
    assert lp_qty == 0
    assert min_a == 0
    assert min_b == 0


def test_unpack_return_dict(ledger_db):
    result = poolwithdraw.unpack(ledger_db, b"\x00\x01", return_dict=True)
    assert isinstance(result, dict)
    assert "asset_a" in result
    assert "quantity" in result


def test_compose_rejects_invalid(ledger_db, defaults):
    with pytest.raises(exceptions.ComposeError):
        poolwithdraw.compose(ledger_db, defaults["addresses"][0], "BTC", "XCP", 1000)


def test_compose_skip_validation(ledger_db, defaults):
    source, _, data = poolwithdraw.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        0,
        skip_validation=True,
    )
    assert len(data) > 0


def test_parse_invalid_message(ledger_db, defaults, blockchain_mock, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    poolwithdraw.parse(ledger_db, tx, b"\xff\xff\xff")
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "pool_withdrawals",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "status": "invalid: could not unpack",
                },
            },
        ],
    )


def test_parse_valid_withdrawal(ledger_db, defaults, blockchain_mock, test_helpers):
    # First create a pool
    create_pool(
        ledger_db,
        blockchain_mock,
        defaults["addresses"][0],
        defaults["quantity"],
        defaults["quantity"],
    )
    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_asset = pool["lp_asset"]
    lp_balance = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    assert lp_balance > 0

    # Record balances before withdrawal
    xcp_before = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], "XCP")
    div_before = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], "DIVISIBLE")

    # Compose and parse withdrawal
    _, _, data = poolwithdraw.compose(
        ledger_db, defaults["addresses"][0], "XCP", "DIVISIBLE", lp_balance
    )
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    poolwithdraw.parse(ledger_db, tx, data[1:])

    # Verify withdrawal record
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "pool_withdrawals",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "status": "valid",
                },
            },
            {
                "table": "transactions_status",
                "values": {
                    "tx_index": tx["tx_index"],
                    "valid": True,
                },
            },
        ],
    )

    # LP tokens should be fully burned
    lp_after = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    assert lp_after == 0

    # Should have received assets back
    xcp_after = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], "XCP")
    div_after = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], "DIVISIBLE")
    assert xcp_after > xcp_before
    assert div_after > div_before


def test_parse_partial_withdrawal(ledger_db, defaults, blockchain_mock, test_helpers):
    # Create pool
    create_pool(
        ledger_db,
        blockchain_mock,
        defaults["addresses"][0],
        defaults["quantity"],
        defaults["quantity"],
    )
    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_asset = pool["lp_asset"]
    lp_balance = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)

    # Withdraw half
    half = lp_balance // 2
    _, _, data = poolwithdraw.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        half,
    )
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    poolwithdraw.parse(ledger_db, tx, data[1:])

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "pool_withdrawals",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "source": defaults["addresses"][0],
                    "status": "valid",
                },
            },
        ],
    )

    # Should still have half the LP tokens
    lp_after = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    assert lp_after == lp_balance - half

    # Pool should still have reserves
    pool_after = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    assert pool_after["reserve_a"] > 0
    assert pool_after["reserve_b"] > 0


def test_lp_destroy_benefits_remaining_holders(ledger_db, defaults, blockchain_mock, test_helpers):
    """Destroying LP tokens locks reserves — remaining holders get more on withdrawal."""
    from counterpartycore.lib.messages import destroy

    # Create pool with addr0
    create_pool(
        ledger_db,
        blockchain_mock,
        defaults["addresses"][0],
        defaults["quantity"],
        defaults["quantity"],
    )
    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_asset = pool["lp_asset"]
    total_lp = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)

    # Destroy half the LP tokens
    half = total_lp // 2
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, data = destroy.compose(
        ledger_db, defaults["addresses"][0], lp_asset, half, b"lock liquidity"
    )
    destroy.parse(ledger_db, tx, data[1:])

    # Remaining LP balance
    remaining_lp = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], lp_asset)
    assert remaining_lp == total_lp - half

    # Withdraw remaining — should get proportional share
    xcp_before = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], "XCP")
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    _, _, wdata = poolwithdraw.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        remaining_lp,
        skip_validation=True,
    )
    poolwithdraw.parse(ledger_db, tx, wdata[1:])
    xcp_after = ledger.balances.get_balance(ledger_db, defaults["addresses"][0], "XCP")

    # Remaining LP holder gets ALL reserves (destroying LP reduces supply,
    # making remaining tokens claim 100% of pool)
    pool_after = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    assert pool_after["reserve_a"] == 0, "All reserves withdrawn by remaining holder"
    assert pool_after["reserve_b"] == 0, "All reserves withdrawn by remaining holder"

    # LP holder got back MORE per token than they would have without the destroy
    xcp_got = xcp_after - xcp_before
    assert xcp_got > 0, "Holder received reserves"


def test_parse_no_pool(ledger_db, defaults, blockchain_mock, test_helpers):
    """Withdraw from non-existent pool should be invalid."""
    _, _, data = poolwithdraw.compose(
        ledger_db,
        defaults["addresses"][0],
        "XCP",
        "DIVISIBLE",
        1000,
        skip_validation=True,
    )
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    poolwithdraw.parse(ledger_db, tx, data[1:])

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "pool_withdrawals",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "status": "invalid: pool does not exist",
                },
            },
        ],
    )


def test_small_but_redeemable_withdrawal(ledger_db, defaults, blockchain_mock, test_helpers):
    """Withdrawal that yields at least 1 sat of one asset should succeed."""
    quantity = defaults["quantity"]
    source = defaults["addresses"][0]

    create_pool(ledger_db, blockchain_mock, source, quantity, quantity)

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")

    # 2 LP tokens should yield at least 1 sat of each in a 1:1 pool
    _, _, data = poolwithdraw.compose(
        ledger_db, source, "XCP", "DIVISIBLE", 2, skip_validation=True
    )
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    poolwithdraw.parse(ledger_db, tx, data[1:])

    pool_after = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    assert pool_after["reserve_a"] < pool["reserve_a"]
    assert pool_after["reserve_b"] < pool["reserve_b"]


def test_validate_slippage_protection_min_a(ledger_db, defaults, blockchain_mock):
    source = defaults["addresses"][0]
    q = defaults["quantity"]
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", q, q)
    pooldeposit.parse(ledger_db, tx, data[1:])
    pool = ledger.markets.get_pool(ledger_db, *ledger.markets.sort_pair("XCP", "DIVISIBLE"))
    lp = ledger.balances.get_balance(ledger_db, source, pool["lp_asset"])

    problems = poolwithdraw.validate(
        ledger_db,
        source,
        "XCP",
        "DIVISIBLE",
        lp // 4,
        min_quantity_a=q * 10,
    )
    assert any("slippage protection" in p for p in problems)


def test_validate_slippage_protection_min_b(ledger_db, defaults, blockchain_mock):
    source = defaults["addresses"][0]
    q = defaults["quantity"]
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", q, q)
    pooldeposit.parse(ledger_db, tx, data[1:])
    pool = ledger.markets.get_pool(ledger_db, *ledger.markets.sort_pair("XCP", "DIVISIBLE"))
    lp = ledger.balances.get_balance(ledger_db, source, pool["lp_asset"])

    problems = poolwithdraw.validate(
        ledger_db,
        source,
        "XCP",
        "DIVISIBLE",
        lp // 4,
        min_quantity_a=0,
        min_quantity_b=q * 10,
    )
    assert any("slippage protection" in p for p in problems)
