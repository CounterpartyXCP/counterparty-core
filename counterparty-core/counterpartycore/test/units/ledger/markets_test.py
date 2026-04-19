from counterpartycore.lib.ledger import currentstate, markets


def test_markets(ledger_db, defaults):
    assert len(markets.get_pending_btc_order_matches(ledger_db, defaults["addresses"][0])) == 0
    assert len(markets.get_open_btc_orders(ledger_db, defaults["addresses"][0])) == 1

    original_state = currentstate.CurrentState().ledger_state()
    currentstate.CurrentState().set_ledger_state(ledger_db, "Catching Up")
    assert len(markets.get_matching_orders(ledger_db, "tx_hash", "BTC", "XCP")) == 2
    currentstate.CurrentState().set_ledger_state(ledger_db, original_state)

    open_orders = ledger_db.execute(
        """SELECT rowid FROM (
            SELECT *, MAX(rowid) as rowid
            FROM orders
            GROUP BY tx_hash
        )"""
    ).fetchall()
    ledger_db.execute("DROP TRIGGER block_update_orders")

    ledger_db.execute(
        "UPDATE orders SET give_remaining = 0 WHERE rowid = ?", (open_orders[0]["rowid"],)
    )
    ledger_db.execute(
        "UPDATE orders SET get_remaining = 0 WHERE rowid = ?", (open_orders[1]["rowid"],)
    )

    open_orders = ledger_db.execute(
        """SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM orders
            GROUP BY tx_hash
        ) WHERE give_remaining = 0 OR get_remaining = 0"""
    ).fetchall()

    order_filled_count_before = ledger_db.execute(
        "SELECT COUNT(*) AS count FROM orders WHERE status = ?", ("filled",)
    ).fetchone()["count"]

    markets.mark_order_as_filled(ledger_db, open_orders[0]["tx_hash"], open_orders[1]["tx_hash"])

    order_filled_count_after = ledger_db.execute(
        "SELECT COUNT(*) AS count FROM orders WHERE status = ?", ("filled",)
    ).fetchone()["count"]

    assert order_filled_count_before + 2 == order_filled_count_after

    markets.mark_order_as_filled(
        ledger_db, open_orders[0]["tx_hash"], open_orders[1]["tx_hash"], source="source"
    )

    order_filled_count_after = ledger_db.execute(
        "SELECT COUNT(*) AS count FROM orders WHERE status = ?", ("filled",)
    ).fetchone()["count"]

    assert order_filled_count_before + 2 == order_filled_count_after

    dispensers = ledger_db.execute(
        "SELECT * FROM dispensers ORDER BY rowid DESC LIMIT 1"
    ).fetchall()

    assert markets.get_dispenser_info(ledger_db) == [dispensers[0]]
    assert markets.get_dispenser_info(ledger_db, tx_hash=dispensers[0]["tx_hash"]) == [
        dispensers[0]
    ]
    assert markets.get_dispenser_info(ledger_db, tx_index=dispensers[0]["tx_index"]) == [
        dispensers[0]
    ]
    assert markets.get_dispenser_info(
        ledger_db, tx_hash=dispensers[0]["tx_hash"], tx_index=dispensers[0]["tx_index"]
    ) == [dispensers[0]]

    result = markets.get_dispensers_info(ledger_db, [dispensers[0]["tx_hash"]])
    assert isinstance(result[dispensers[0]["tx_hash"]], dict)
    assert result[dispensers[0]["tx_hash"]]["tx_index"] == dispensers[0]["tx_index"]

    assert (
        markets.get_dispensers_count(
            ledger_db, dispensers[0]["source"], dispensers[0]["status"], dispensers[0]["origin"]
        )
        == 2
    )
    assert len(markets.get_dispensers(ledger_db, source_in=[dispensers[0]["source"]])) == 2
    assert len(markets.get_dispensers(ledger_db, origin=dispensers[0]["origin"])) == 2


def test_pool_queries(ledger_db):
    # Fixture has POOLASSETA/POOLASSETB pool
    pools = markets.get_all_pools(ledger_db)
    assert len(pools) >= 1
    assert markets.get_pool(ledger_db, "POOLASSETA", "POOLASSETB") is not None
    assert markets.get_pool(ledger_db, "XCP", "DIVISIBLE") is None
    pool = markets.get_pool(ledger_db, "POOLASSETA", "POOLASSETB")
    assert markets.get_pool_by_lp_asset(ledger_db, pool["lp_asset"]) is not None
    assert markets.get_pool_by_lp_asset(ledger_db, "NONEXISTENT") is None
    assert isinstance(markets.get_pool_deposits(ledger_db, "POOLASSETA", "POOLASSETB"), list)
    assert markets.get_pool_withdrawals(ledger_db, "POOLASSETA", "POOLASSETB") == []
    assert isinstance(markets.get_open_orders_for_pair(ledger_db, "XCP", "DIVISIBLE"), list)
    assert markets.get_pool_matches_by_order(ledger_db, "a" * 64) == []


def test_compute_pool_math(ledger_db):
    # Exercise pool math functions
    assert markets.isqrt(0) == 0
    assert markets.isqrt(100) == 10
    assert markets.isqrt(2) == 1

    # compute_pool_output with known values
    assert markets.compute_pool_output(1000, 1000, 100, 50) == 90

    # compute_pool_input_for_target_price — normal case
    result = markets.compute_pool_input_for_target_price(1000, 1000, 1000, 500, 50)
    assert result >= 0

    # edge cases: early returns
    assert markets.compute_pool_input_for_target_price(0, 1000, 1000, 500, 50) == 0  # reserve_in=0
    assert markets.compute_pool_input_for_target_price(1000, 1000, 0, 500, 50) == 0  # target_den=0
    assert markets.compute_pool_input_for_target_price(1000, 1000, 1000, 0, 50) == 0  # target_num=0
    # price already past target (current >= target)
    assert markets.compute_pool_input_for_target_price(1000, 1000, 1, 10000, 50) == 0

    # get_pool_fee_bps
    assert markets.compute_pool_input_for_target_price(10000, 1, 1, 9999, 50) == 0

    # get_pool_fee_bps
    assert markets.get_pool_fee_bps({"asset_a": "XCP", "asset_b": "DIVISIBLE"}) == 50
    assert markets.get_pool_fee_bps({"asset_a": "DIVISIBLE", "asset_b": "NODIVISIBLE"}) == 100

    # pool_has_liquidity
    assert markets.pool_has_liquidity({"reserve_a": 100, "reserve_b": 100}) is True
    assert markets.pool_has_liquidity({"reserve_a": 0, "reserve_b": 100}) is False
    assert markets.pool_has_liquidity({"reserve_a": 100, "reserve_b": 0}) is False
    assert markets.pool_has_liquidity(None) is False

    # compute_pool_output edge cases
    assert markets.compute_pool_output(0, 1000, 100, 50) == 0
    assert markets.compute_pool_output(1000, 0, 100, 50) == 0
    assert markets.compute_pool_output(1000, 1000, 0, 50) == 0


def test_execute_pool_match_enforces_k_invariant(ledger_db, defaults, blockchain_mock):
    import pytest
    from counterpartycore.lib.messages import pooldeposit

    source = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(
        ledger_db, source, "XCP", "DIVISIBLE", defaults["quantity"], defaults["quantity"]
    )
    pooldeposit.parse(ledger_db, tx, data[1:])
    pool = markets.get_pool(ledger_db, *markets.sort_pair("XCP", "DIVISIBLE"))

    bad_give = 1
    bad_get = pool["reserve_b"] - 1
    tx1 = {
        "source": defaults["addresses"][1],
        "tx_hash": "b" * 64,
        "give_asset": pool["asset_a"],
        "get_asset": pool["asset_b"],
        "give_quantity": bad_give,
        "get_quantity": bad_get,
    }
    tx2 = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][1])
    with pytest.raises(AssertionError):
        markets.execute_pool_match(ledger_db, tx2, tx1, pool, bad_give, bad_get)


def test_compute_pool_input_never_overshoots_target():
    """dx must never push the pool's marginal price past target."""
    cases = [
        (1_000_000, 1_000_000, 101, 100, 30),
        (1_000_000, 2_000_000, 1, 1, 30),
        (100_000_000, 1_000, 1000, 1, 100),
        (1234, 5678, 7, 3, 0),
        (10_000_000, 10_000, 105, 100, 50),
    ]
    for r_in, r_out, t_num, t_den, fee in cases:
        dx = markets.compute_pool_input_for_target_price(r_in, r_out, t_num, t_den, fee)
        if dx > 0:
            fee_factor = 10000 - fee
            y = r_out * dx * fee_factor // (r_in * 10000 + dx * fee_factor)
            assert (r_in + dx) * 10000 * t_den <= (r_out - y) * fee_factor * t_num


def test_try_pool_fill_early_returns(ledger_db):
    """Exercise try_pool_fill early-return paths."""
    tx1 = {
        "give_asset": "POOLASSETA",
        "get_asset": "POOLASSETB",
        "give_quantity": 10000,
        "get_quantity": 1,
        "source": "test_source",
        "tx_hash": "a" * 64,
    }

    # no pool
    assert markets.try_pool_fill(tx1, None, 500) == (0, 0)

    # pool with no liquidity
    empty_pool = {
        "asset_a": "POOLASSETA",
        "asset_b": "POOLASSETB",
        "reserve_a": 0,
        "reserve_b": 0,
    }
    assert markets.try_pool_fill(tx1, empty_pool, 500) == (0, 0)

    # pool where target price already past (fill_quantity = 0)
    pool = {
        "asset_a": "POOLASSETA",
        "asset_b": "POOLASSETB",
        "reserve_a": 10_000_000,
        "reserve_b": 10_000_000,
    }
    assert markets.try_pool_fill(tx1, pool, 500, target_price_num=1, target_price_den=100000) == (
        0,
        0,
    )

    # pool where output < min_output (bad price for the order)
    tx1_bad_price = {
        "give_asset": "POOLASSETA",
        "get_asset": "POOLASSETB",
        "give_quantity": 1,
        "get_quantity": 10_000_000,
        "source": "test_source",
        "tx_hash": "a" * 64,
    }
    assert markets.try_pool_fill(tx1_bad_price, pool, 1) == (0, 0)

    # successful fill (no target price)
    fill_qty, output = markets.try_pool_fill(tx1, pool, 500)
    assert fill_qty == 500
    assert output > 0

    # asset_b as give_asset (reversed direction)
    tx1_reversed = {
        "give_asset": "POOLASSETB",
        "get_asset": "POOLASSETA",
        "give_quantity": 10000,
        "get_quantity": 1,
        "source": "test_source",
        "tx_hash": "b" * 64,
    }
    fill_qty, output = markets.try_pool_fill(tx1_reversed, pool, 500)
    assert fill_qty == 500
    assert output > 0
