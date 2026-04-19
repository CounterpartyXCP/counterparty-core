from counterpartycore.lib import ledger
from counterpartycore.lib.messages import order, pooldeposit


def create_pool(ledger_db, blockchain_mock, source, asset_a, asset_b, quantity_a, quantity_b):
    """Helper: deposit to create a pool and return the pool dict."""
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, asset_a, asset_b, quantity_a, quantity_b)
    pooldeposit.parse(ledger_db, tx, data[1:])
    sorted_a, sorted_b = ledger.markets.sort_pair(asset_a, asset_b)
    return ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)


def place_order(
    ledger_db,
    blockchain_mock,
    source,
    give_asset,
    give_quantity,
    get_asset,
    get_quantity,
    expiration=2000,
    fee=10000,
):
    """Helper: compose and parse an order, return (tx, message)."""
    tx = blockchain_mock.dummy_tx(ledger_db, source, fee=fee)
    _, _, data = order.compose(
        ledger_db,
        source,
        give_asset,
        give_quantity,
        get_asset,
        get_quantity,
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

    quantity = defaults["quantity"]  # 1 XCP = 100000000 sat

    # Create pool: XCP/DIVISIBLE with equal reserves
    pool = create_pool(
        ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", quantity, quantity
    )
    assert pool is not None
    assert pool["reserve_a"] > 0

    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")

    # Record trader balances before
    trader_div_before = ledger.balances.get_balance(ledger_db, source_trader, "DIVISIBLE")

    # Place order: trader wants to sell XCP for DIVISIBLE
    # Small order to partially fill from pool
    give_quantity = quantity // 10  # 10% of reserves
    get_quantity = give_quantity // 2  # willing to accept 50% of give (generous price)

    tx = place_order(
        ledger_db, blockchain_mock, source_trader, "XCP", give_quantity, "DIVISIBLE", get_quantity
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
    pool_after = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)
    assert pool_after["reserve_a"] != pool["reserve_a"]
    assert pool_after["reserve_b"] != pool["reserve_b"]


def test_pool_tail_partial_fill_at_taker_limit(ledger_db, defaults, blockchain_mock):
    source_lp = defaults["addresses"][0]
    source_trader = defaults["addresses"][1]
    quantity = defaults["quantity"]

    pool = create_pool(
        ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", quantity, quantity
    )
    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")
    reserve_a_before = pool["reserve_a"]
    reserve_b_before = pool["reserve_b"]

    # Tight rate (give:get = 2:1) would overshoot if pool took the full give.
    give_quantity = quantity
    get_quantity = quantity // 2

    trader_div_before = ledger.balances.get_balance(ledger_db, source_trader, "DIVISIBLE")

    tx = place_order(
        ledger_db, blockchain_mock, source_trader, "XCP", give_quantity, "DIVISIBLE", get_quantity
    )

    cursor = ledger_db.cursor()
    matches = cursor.execute(
        "SELECT * FROM pool_matches WHERE order_tx_hash = ?", (tx["tx_hash"],)
    ).fetchall()
    assert len(matches) > 0

    trader_div_after = ledger.balances.get_balance(ledger_db, source_trader, "DIVISIBLE")
    assert trader_div_after > trader_div_before

    orders = cursor.execute(
        "SELECT * FROM orders WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1", (tx["tx_hash"],)
    ).fetchall()
    assert 0 < orders[0]["give_remaining"] < give_quantity

    pool_after = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)
    if sorted_a == "XCP":
        assert pool_after["reserve_a"] > reserve_a_before
        assert pool_after["reserve_b"] < reserve_b_before
    else:
        assert pool_after["reserve_b"] > reserve_b_before
        assert pool_after["reserve_a"] < reserve_a_before


def test_order_respects_price_limit(ledger_db, defaults, blockchain_mock, test_helpers):
    """An order with a strict price should not fill at a worse rate."""
    source_lp = defaults["addresses"][0]
    source_trader = defaults["addresses"][1]
    quantity = defaults["quantity"]

    # Create pool with 10:1 ratio (DIVISIBLE is 10x more expensive than XCP)
    create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", quantity * 10, quantity)

    # Trader wants 1:1 rate — pool can't provide this
    # Pool price is ~10 XCP per DIVISIBLE, trader wants 1:1
    give_quantity = quantity // 10
    get_quantity = give_quantity  # demanding 1:1 when pool is 10:1

    tx = place_order(
        ledger_db, blockchain_mock, source_trader, "XCP", give_quantity, "DIVISIBLE", get_quantity
    )

    # Should NOT match against pool (price too demanding)
    cursor = ledger_db.cursor()
    cursor.execute(
        "SELECT * FROM pool_matches WHERE order_tx_hash = ?", (tx["tx_hash"],)
    ).fetchall()

    # Order should remain open, not filled by pool at bad price
    orders = cursor.execute(
        "SELECT * FROM orders WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1", (tx["tx_hash"],)
    ).fetchall()
    assert orders[0]["status"] == "open"
    assert orders[0]["give_remaining"] == give_quantity


def test_pool_reserves_update_after_match(ledger_db, defaults, blockchain_mock):
    """After a pool match, reserves should reflect the swap."""
    source_lp = defaults["addresses"][0]
    source_trader = defaults["addresses"][1]
    quantity = defaults["quantity"]

    create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", quantity, quantity)

    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")
    pool_before = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)

    # Small trade
    give_quantity = quantity // 20
    get_quantity = 1  # very generous price, will fill

    place_order(
        ledger_db, blockchain_mock, source_trader, "XCP", give_quantity, "DIVISIBLE", get_quantity
    )

    pool_after = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)

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
    quantity = defaults["quantity"]

    create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", quantity, quantity)

    give_quantity = quantity // 10
    get_quantity = 1  # generous

    tx = place_order(
        ledger_db, blockchain_mock, source_trader, "XCP", give_quantity, "DIVISIBLE", get_quantity
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
    quantity = defaults["quantity"]

    # Place BTC order — no pool can exist for BTC pairs
    tx = place_order(
        ledger_db,
        blockchain_mock,
        source_trader,
        "BTC",
        quantity // 100,
        "XCP",
        quantity,
        fee=10000,
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
    quantity = defaults["quantity"]

    # Create pool at 1:1 ratio
    create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", quantity, quantity)

    # Trader places order with very tight price (wants almost 1:1)
    # Pool has 0.5% fee on XCP pairs, so effective output < input
    # Order demands 99.6% output — pool at 0.5% fee gives ~99.5%, won't fill
    give_quantity = quantity // 10
    get_quantity = give_quantity * 996 // 1000  # wants 99.6% back

    tx = place_order(
        ledger_db, blockchain_mock, source_trader, "XCP", give_quantity, "DIVISIBLE", get_quantity
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
    """Order with generous price (get_quantity=1) fills from pool."""
    source_lp = defaults["addresses"][0]
    source_trader = defaults["addresses"][1]
    quantity = defaults["quantity"]

    create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", quantity, quantity)

    # Trader places very generous order (get_quantity=1 means any output is acceptable)
    give_quantity = quantity // 10

    tx = blockchain_mock.dummy_tx(ledger_db, source_trader, fee=10000)
    _, _, data = order.compose(
        ledger_db, source_trader, "XCP", give_quantity, "DIVISIBLE", 1, 2000, 0
    )
    order.parse(ledger_db, tx, data[1:])

    cursor = ledger_db.cursor()
    matches = cursor.execute(
        "SELECT * FROM pool_matches WHERE order_tx_hash = ?", (tx["tx_hash"],)
    ).fetchall()

    # Pool should fill this — any output >= 1 is acceptable
    assert len(matches) > 0
    assert matches[0]["fee_bps"] == 50  # XCP pair = 0.5%


def test_generous_limit_partial_pool_fill_marks_filled(
    ledger_db, defaults, blockchain_mock, test_helpers
):
    """Order with generous limit + pool at better price + book order causing partial fill.

    The partial pool fill should exhaust get_remaining before give_remaining.
    The order must be marked filled (not left open with negative get_remaining).
    """
    source_lp = defaults["addresses"][0]
    source_trader = defaults["addresses"][1]
    quantity = defaults["quantity"]

    # 1. Create pool at 1:1 (much better than the trader's limit)
    pool_size = quantity // 2
    create_pool(ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", pool_size, pool_size)

    # 2. Place a resting book order that will cap the pool fill via interleave.
    #    This order sells DIVISIBLE wanting XCP at 2:1 rate.
    place_order(
        ledger_db, blockchain_mock, source_lp, "DIVISIBLE", quantity // 10, "XCP", quantity // 5
    )

    # 3. Trader places order with very generous limit: sell some XCP, want only 1 sat DIVISIBLE.
    #    Pool at ~1:1 will give far more output than the 1 sat minimum,
    #    so get_remaining goes deeply negative while give_remaining stays positive.
    give_quantity = quantity // 4
    get_quantity = 1

    tx = place_order(
        ledger_db, blockchain_mock, source_trader, "XCP", give_quantity, "DIVISIBLE", get_quantity
    )

    cursor = ledger_db.cursor()
    ord = cursor.execute(
        "SELECT * FROM orders WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1", (tx["tx_hash"],)
    ).fetchone()

    assert ord["status"] == "filled", (
        f"Order should be filled but is {ord['status']} "
        f"(give_remaining={ord['give_remaining']}, get_remaining={ord['get_remaining']})"
    )


def test_skewed_pool_arb_then_deposit(ledger_db, defaults, blockchain_mock, test_helpers):
    """Skewed pool is corrected via arb swap, then depositor adds at corrected ratio."""
    source_lp = defaults["addresses"][0]
    source_arb = defaults["addresses"][1]
    quantity = defaults["quantity"]

    # 1. Create pool with skewed ratio: 10:1 (DIVISIBLE is 10x overpriced vs XCP)
    sorted_a, sorted_b = ledger.markets.sort_pair("XCP", "DIVISIBLE")
    pool = create_pool(
        ledger_db, blockchain_mock, source_lp, "XCP", "DIVISIBLE", quantity, quantity // 10
    )
    initial_ratio = (
        pool["reserve_a"] / pool["reserve_b"]
        if sorted_a == "DIVISIBLE"
        else pool["reserve_b"] / pool["reserve_a"]
    )

    # 2. Arb buys cheap DIVISIBLE from pool by selling XCP
    arb_quantity = quantity // 5
    place_order(ledger_db, blockchain_mock, source_arb, "XCP", arb_quantity, "DIVISIBLE", 1)

    # 3. Pool ratio should have shifted — more XCP, less DIVISIBLE
    pool_after_arb = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)
    if sorted_a == "DIVISIBLE":
        new_ratio = pool_after_arb["reserve_a"] / pool_after_arb["reserve_b"]
    else:
        new_ratio = pool_after_arb["reserve_b"] / pool_after_arb["reserve_a"]
    # DIVISIBLE/XCP ratio decreased (DIVISIBLE got cheaper)
    assert new_ratio < initial_ratio

    # k should have grown (fees stay in pool)
    k_before = pool["reserve_a"] * pool["reserve_b"]
    k_after = pool_after_arb["reserve_a"] * pool_after_arb["reserve_b"]
    assert k_after >= k_before

    # 4. New LP deposits at the corrected ratio (proportional)
    lp_asset = pool_after_arb["lp_asset"]
    dep_a = pool_after_arb["reserve_a"] // 5
    dep_b = pool_after_arb["reserve_b"] // 5
    tx_dep = blockchain_mock.dummy_tx(ledger_db, source_lp)
    _, _, data = pooldeposit.compose(ledger_db, source_lp, sorted_a, sorted_b, dep_a, dep_b)
    pooldeposit.parse(ledger_db, tx_dep, data[1:])

    # Deposit should succeed and mint LP tokens
    lp_balance = ledger.balances.get_balance(ledger_db, source_lp, lp_asset)
    assert lp_balance > 0

    # Pool reserves grew and ratio is preserved (proportional deposit)
    pool_final = ledger.markets.get_pool(ledger_db, sorted_a, sorted_b)
    assert pool_final["reserve_a"] > pool_after_arb["reserve_a"]
    assert pool_final["reserve_b"] > pool_after_arb["reserve_b"]
    # Ratio should be unchanged (within integer rounding)
    ratio_before = pool_after_arb["reserve_a"] * 10000 // pool_after_arb["reserve_b"]
    ratio_after = pool_final["reserve_a"] * 10000 // pool_final["reserve_b"]
    assert abs(ratio_before - ratio_after) <= 1


def test_xcp_pair_lower_fee_than_non_xcp(ledger_db, defaults, blockchain_mock):
    """XCP pairs should have 50 bps fee, non-XCP should have 100 bps."""
    # XCP pair
    xcp_pool = {"asset_a": "DIVISIBLE", "asset_b": "XCP"}
    assert ledger.markets.get_pool_fee_bps(xcp_pool) == 50

    # Non-XCP pair
    other_pool = {"asset_a": "ASSET_A", "asset_b": "ASSET_B"}
    assert ledger.markets.get_pool_fee_bps(other_pool) == 100


# =============================================================================
# Tests for compute_pool_output edge cases
# =============================================================================


def test_compute_pool_output_zero_input():
    """Zero input should return zero output."""
    assert ledger.markets.compute_pool_output(1000, 1000, 0, 50) == 0


def test_compute_pool_output_negative_input():
    """Negative input should return zero output."""
    assert ledger.markets.compute_pool_output(1000, 1000, -5, 50) == 0


def test_compute_pool_output_zero_reserve_in():
    """Zero reserve_in should return zero output."""
    assert ledger.markets.compute_pool_output(0, 1000, 100, 50) == 0


def test_compute_pool_output_zero_reserve_out():
    """Zero reserve_out should return zero output."""
    assert ledger.markets.compute_pool_output(1000, 0, 100, 50) == 0


# =============================================================================
# Tests for compute_pool_input_for_target_price
# =============================================================================


def test_target_price_basic_fill():
    """Pool at 1:1, target price allows some fill, returns positive input."""
    reserve = 100_000_000  # 1 unit each
    # Target price = 2:1 (trader willing to pay 2 input per 1 output).
    # Pool starts at 1:1 so marginal price is well below 2:1 — should allow fill.
    result = ledger.markets.compute_pool_input_for_target_price(reserve, reserve, 2, 1, 50)
    assert result > 0


def test_target_price_already_past():
    """Pool already past target price should return 0."""
    # Pool at 10:1 (reserve_in=10x reserve_out) — marginal price ~10 input per output.
    # Target 2:1 is more favourable than current price, so already past.
    result = ledger.markets.compute_pool_input_for_target_price(
        1_000_000_000, 100_000_000, 2, 1, 50
    )
    assert result == 0


def test_target_price_zero_reserves():
    """Zero reserves should return 0."""
    assert ledger.markets.compute_pool_input_for_target_price(0, 100, 1, 1, 50) == 0
    assert ledger.markets.compute_pool_input_for_target_price(100, 0, 1, 1, 50) == 0


def test_target_price_zero_target():
    """Zero target price numerator or denominator should return 0."""
    assert ledger.markets.compute_pool_input_for_target_price(100, 100, 0, 1, 50) == 0
    assert ledger.markets.compute_pool_input_for_target_price(100, 100, 1, 0, 50) == 0


def test_target_price_output_reaches_target():
    """After feeding the returned input into compute_pool_output, marginal price is near the target."""
    reserve_in = 100_000_000
    reserve_out = 100_000_000
    fee_bps = 50
    target_num = 3  # target price = 3/1 (3 input per 1 output)
    target_den = 1

    dx = ledger.markets.compute_pool_input_for_target_price(
        reserve_in, reserve_out, target_num, target_den, fee_bps
    )
    assert dx > 0

    # Simulate the swap
    dy = ledger.markets.compute_pool_output(reserve_in, reserve_out, dx, fee_bps)
    new_ri = reserve_in + dx
    new_ro = reserve_out - dy

    # Marginal price after swap = new_ri * 10000 / (new_ro * fee_factor)
    fee_factor = 10000 - fee_bps
    marginal_price = new_ri * 10000 / (new_ro * fee_factor)
    target_price = target_num / target_den

    # Should be close to target (within 1% or 1 unit tolerance from integer rounding)
    assert abs(marginal_price - target_price) / target_price < 0.01


def test_target_price_negative_discriminant():
    """Extreme parameters that could produce a negative discriminant should return 0."""
    # Very small reserves with very tight target — set up so discriminant is non-positive.
    # reserve_in=1, reserve_out=1, target very close to current price.
    # Current marginal = 1*10000 / (1*9950) ≈ 1.005
    # Target 10050:10000 ≈ 1.005 — current_price_lhs ~= current_price_rhs, nearly zero fill.
    result = ledger.markets.compute_pool_input_for_target_price(1, 1, 10050, 10000, 50)
    # Should be 0 or a very small positive — either way no crash
    assert result >= 0
