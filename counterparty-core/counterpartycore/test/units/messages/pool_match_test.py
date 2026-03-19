from counterpartycore.lib import config, ledger
from counterpartycore.lib.messages import order, pool as pool_mod, pooldeposit


def create_pool(ledger_db, blockchain_mock, source, asset_a, asset_b, qty_a, qty_b):
    """Helper: deposit to create a pool and return the pool dict."""
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, asset_a, asset_b, qty_a, qty_b)
    pooldeposit.parse(ledger_db, tx, data[1:])
    sorted_a, sorted_b = pool_mod.sort_pair(asset_a, asset_b)
    return pool_mod.get_pool(ledger_db, sorted_a, sorted_b)


def place_order(
    ledger_db,
    blockchain_mock,
    source,
    give_asset,
    give_qty,
    get_asset,
    get_qty,
    expiration=2000,
    fee=10000,
):
    """Helper: compose and parse an order, return (tx, message)."""
    tx = blockchain_mock.dummy_tx(ledger_db, source, fee=fee)
    _, _, data = order.compose(
        ledger_db,
        source,
        give_asset,
        give_qty,
        get_asset,
        get_qty,
        expiration,
        0,
    )
    message = data[1:]  # strip type ID byte
    order.parse(ledger_db, tx, message)
    return tx


def test_order_fills_against_pool(ledger_db, defaults, blockchain_mock, test_helpers):
    """An order placed against a pair with a pool should fill from the pool."""
    source_lp = defaults["addresses"][0]  # liquidity provider
    source_trader = defaults["addresses"][1]  # trader

    qty = defaults["quantity"]  # 1 XCP = 100000000 sat

    # Create pool: XCP/DIVISIBLE with equal reserves
    pool = create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", qty, qty)
    assert pool is not None
    assert pool["reserve_a"] > 0

    sorted_a, sorted_b = pool_mod.sort_pair("XCP", "DIVISIBLE")

    # Record trader balances before
    trader_div_before = ledger.balances.get_balance(ledger_db, source_trader, "DIVISIBLE")

    # Place order: trader wants to sell XCP for DIVISIBLE
    # Small order to partially fill from pool
    give_qty = qty // 10  # 10% of reserves
    get_qty = give_qty // 2  # willing to accept 50% of give (generous price)

    tx = place_order(
        ledger_db, blockchain_mock, source_trader, "XCP", give_qty, "DIVISIBLE", get_qty
    )

    # Pool should have been matched — check pool_matches table
    cursor = ledger_db.cursor()
    matches = cursor.execute(
        "SELECT * FROM pool_matches WHERE order_tx_hash = ?", (tx["tx_hash"],)
    ).fetchall()

    assert len(matches) > 0, "Order should have matched against pool"
    match = matches[0]
    assert match["backward_asset"] == "XCP"  # trader gave XCP
    assert match["forward_asset"] == "DIVISIBLE"  # trader got DIVISIBLE
    assert match["backward_quantity"] > 0
    assert match["forward_quantity"] > 0
    assert match["fee_quantity"] > 0

    # Trader should have received DIVISIBLE
    trader_div_after = ledger.balances.get_balance(ledger_db, source_trader, "DIVISIBLE")
    assert trader_div_after > trader_div_before

    # Pool reserves should have changed
    pool_after = pool_mod.get_pool(ledger_db, sorted_a, sorted_b)
    assert pool_after["reserve_a"] != pool["reserve_a"]
    assert pool_after["reserve_b"] != pool["reserve_b"]


def test_order_respects_price_limit(ledger_db, defaults, blockchain_mock, test_helpers):
    """An order with a strict price should not fill at a worse rate."""
    source_lp = defaults["addresses"][0]
    source_trader = defaults["addresses"][1]
    qty = defaults["quantity"]

    # Create pool with 10:1 ratio (DIVISIBLE is 10x more expensive than XCP)
    create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", qty * 10, qty)

    # Trader wants 1:1 rate — pool can't provide this
    # Pool price is ~10 XCP per DIVISIBLE, trader wants 1:1
    give_qty = qty // 10
    get_qty = give_qty  # demanding 1:1 when pool is 10:1

    tx = place_order(
        ledger_db, blockchain_mock, source_trader, "XCP", give_qty, "DIVISIBLE", get_qty
    )

    # Should NOT match against pool (price too demanding)
    cursor = ledger_db.cursor()
    matches = cursor.execute(
        "SELECT * FROM pool_matches WHERE order_tx_hash = ?", (tx["tx_hash"],)
    ).fetchall()

    # Order should remain open, not filled by pool at bad price
    orders = cursor.execute(
        "SELECT * FROM orders WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1", (tx["tx_hash"],)
    ).fetchall()
    assert orders[0]["status"] == "open"
    assert orders[0]["give_remaining"] == give_qty


def test_pool_reserves_update_after_match(ledger_db, defaults, blockchain_mock):
    """After a pool match, reserves should reflect the swap."""
    source_lp = defaults["addresses"][0]
    source_trader = defaults["addresses"][1]
    qty = defaults["quantity"]

    create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", qty, qty)

    sorted_a, sorted_b = pool_mod.sort_pair("XCP", "DIVISIBLE")
    pool_before = pool_mod.get_pool(ledger_db, sorted_a, sorted_b)

    # Small trade
    give_qty = qty // 20
    get_qty = 1  # very generous price, will fill

    place_order(ledger_db, blockchain_mock, source_trader, "XCP", give_qty, "DIVISIBLE", get_qty)

    pool_after = pool_mod.get_pool(ledger_db, sorted_a, sorted_b)

    # XCP went into pool, DIVISIBLE came out
    if sorted_a == "DIVISIBLE":
        # reserve_a is DIVISIBLE (should decrease), reserve_b is XCP (should increase)
        assert pool_after["reserve_a"] < pool_before["reserve_a"]
        assert pool_after["reserve_b"] > pool_before["reserve_b"]
    else:
        # reserve_a is XCP (should increase), reserve_b is DIVISIBLE (should decrease)
        assert pool_after["reserve_a"] > pool_before["reserve_a"]
        assert pool_after["reserve_b"] < pool_before["reserve_b"]

    # k should have grown (fee stays in pool)
    k_before = pool_before["reserve_a"] * pool_before["reserve_b"]
    k_after = pool_after["reserve_a"] * pool_after["reserve_b"]
    assert k_after >= k_before


def test_pool_match_fee_recorded(ledger_db, defaults, blockchain_mock, test_helpers):
    """Pool match should record the correct fee in basis points."""
    source_lp = defaults["addresses"][0]
    source_trader = defaults["addresses"][1]
    qty = defaults["quantity"]

    create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", qty, qty)

    give_qty = qty // 10
    get_qty = 1  # generous

    tx = place_order(
        ledger_db, blockchain_mock, source_trader, "XCP", give_qty, "DIVISIBLE", get_qty
    )

    cursor = ledger_db.cursor()
    matches = cursor.execute(
        "SELECT * FROM pool_matches WHERE order_tx_hash = ?", (tx["tx_hash"],)
    ).fetchall()

    assert len(matches) > 0
    match = matches[0]
    assert match["fee_bps"] == 50  # 0.50% for XCP pairs
    expected_fee = match["backward_quantity"] * 50 // 10000
    assert match["fee_quantity"] == expected_fee


def test_no_pool_match_for_btc_pair(ledger_db, defaults, blockchain_mock):
    """BTC pairs should never match against pools (pools don't support BTC)."""
    source_trader = defaults["addresses"][1]
    qty = defaults["quantity"]

    # Place BTC order — no pool can exist for BTC pairs
    tx = place_order(
        ledger_db, blockchain_mock, source_trader, "BTC", qty // 100, "XCP", qty, fee=10000
    )

    cursor = ledger_db.cursor()
    matches = cursor.execute(
        "SELECT * FROM pool_matches WHERE order_tx_hash = ?", (tx["tx_hash"],)
    ).fetchall()

    assert len(matches) == 0


def test_pool_fee_affects_matching(ledger_db, defaults, blockchain_mock, test_helpers):
    """Pool fee makes pool more expensive — order only fills if fee-inclusive price is acceptable."""
    source_lp = defaults["addresses"][0]
    source_trader = defaults["addresses"][1]
    qty = defaults["quantity"]

    # Create pool at 1:1 ratio
    create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", qty, qty)

    # Trader places order with very tight price (wants almost 1:1)
    # Pool has 0.5% fee on XCP pairs, so effective output < input
    # Order demands 99.6% output — pool at 0.5% fee gives ~99.5%, won't fill
    give_qty = qty // 10
    get_qty = give_qty * 996 // 1000  # wants 99.6% back

    tx = place_order(
        ledger_db, blockchain_mock, source_trader, "XCP", give_qty, "DIVISIBLE", get_qty
    )

    cursor = ledger_db.cursor()
    ord = cursor.execute(
        "SELECT * FROM orders WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1", (tx["tx_hash"],)
    ).fetchone()

    matches = cursor.execute(
        "SELECT * FROM pool_matches WHERE order_tx_hash = ?", (tx["tx_hash"],)
    ).fetchall()

    # Pool can't fill at 99.6% because 0.5% fee means max output is ~99.5%
    # Order should remain open or only partially filled
    if len(matches) == 0:
        assert ord["status"] == "open"
    else:
        # If partially filled, remaining should be > 0
        assert ord["give_remaining"] > 0


def test_pool_fills_generous_order(ledger_db, defaults, blockchain_mock, test_helpers):
    """Order with generous price (get_qty=1) fills from pool."""
    source_lp = defaults["addresses"][0]
    source_trader = defaults["addresses"][1]
    qty = defaults["quantity"]

    create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", qty, qty)

    # Trader places very generous order (get_qty=1 means any output is acceptable)
    give_qty = qty // 10

    tx = blockchain_mock.dummy_tx(ledger_db, source_trader, fee=10000)
    _, _, data = order.compose(ledger_db, source_trader, "XCP", give_qty, "DIVISIBLE", 1, 2000, 0)
    order.parse(ledger_db, tx, data[1:])

    cursor = ledger_db.cursor()
    matches = cursor.execute(
        "SELECT * FROM pool_matches WHERE order_tx_hash = ?", (tx["tx_hash"],)
    ).fetchall()

    # Pool should fill this — any output >= 1 is acceptable
    assert len(matches) > 0
    assert matches[0]["fee_bps"] == 50  # XCP pair = 0.5%


def test_xcp_pair_lower_fee_than_non_xcp(ledger_db, defaults, blockchain_mock):
    """XCP pairs should have 50 bps fee, non-XCP should have 100 bps."""
    from counterpartycore.lib.messages import pool as pool_mod

    # XCP pair
    xcp_pool = {"asset_a": "DIVISIBLE", "asset_b": "XCP"}
    assert pool_mod.get_pool_fee_bps(xcp_pool) == 50

    # Non-XCP pair
    other_pool = {"asset_a": "ASSET_A", "asset_b": "ASSET_B"}
    assert pool_mod.get_pool_fee_bps(other_pool) == 100
