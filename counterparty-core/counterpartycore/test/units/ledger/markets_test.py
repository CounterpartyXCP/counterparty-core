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

    # compute_pool_input_for_target_price
    result = markets.compute_pool_input_for_target_price(1000, 1000, 1000, 500, 50)
    assert result >= 0

    # get_pool_fee_bps
    assert markets.get_pool_fee_bps({"asset_a": "XCP", "asset_b": "DIVISIBLE"}) == 50
    assert markets.get_pool_fee_bps({"asset_a": "DIVISIBLE", "asset_b": "NODIVISIBLE"}) == 100
