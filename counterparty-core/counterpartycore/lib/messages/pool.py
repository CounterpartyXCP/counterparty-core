# AMM liquidity pool utilities: constant product (x*y=k) math,
# pool match execution, and deposit-triggered order matching.

import logging
import math

from counterpartycore.lib import config, ledger

logger = logging.getLogger(config.LOGGER_NAME)

XCP_POOL_FEE_BPS = 50   # 0.50% for XCP pairs
OTHER_POOL_FEE_BPS = 100  # 1.00% for non-XCP pairs


def get_pool_fee_bps(pool):
    """Return the swap fee in basis points for this pool.

    XCP pairs get a lower fee (0.50%) to encourage XCP liquidity.
    Non-XCP pairs charge 1.00% to compensate LPs for higher risk.
    """
    if pool["asset_a"] == config.XCP or pool["asset_b"] == config.XCP:
        return XCP_POOL_FEE_BPS
    return OTHER_POOL_FEE_BPS


def isqrt(n):
    """Integer square root (floor).  Python 3.8+ has math.isqrt."""
    return math.isqrt(n)


def compute_pool_output(reserve_in, reserve_out, input_qty, fee_bps):
    """Constant-product swap with fee.  Returns integer output quantity.

    Uses Uniswap v2's precision trick: multiply by fee factor BEFORE dividing,
    so the division happens only once at the end.  This matches UniswapV2Library:

      amountInWithFee = amountIn * (10000 - feeBps)
      numerator       = amountInWithFee * reserveOut
      denominator     = reserveIn * 10000 + amountInWithFee
      return numerator / denominator

    The fee portion stays in reserve_in, growing k.
    """
    if input_qty <= 0 or reserve_in <= 0 or reserve_out <= 0:
        return 0
    input_with_fee = input_qty * (10000 - fee_bps)
    numerator = input_with_fee * reserve_out
    denominator = reserve_in * 10000 + input_with_fee
    return numerator // denominator


def pool_marginal_price(reserve_in, reserve_out, fee_bps):
    """Marginal price of the pool: units of input per 1 unit of output.

    Includes fee.  Returns integer ratio scaled by 1e8 for precision.
    price = reserve_in * 10000 / (reserve_out * (10000 - fee_bps))
    """
    if reserve_out <= 0:
        return 0
    return (reserve_in * 10000 * config.UNIT) // (reserve_out * (10000 - fee_bps))


def compute_pool_input_for_target_price(reserve_in, reserve_out, target_price_num,
                                         target_price_den, fee_bps):
    """How much to swap into the pool before its marginal price reaches the
    target price (expressed as target_price_num / target_price_den in terms of
    give_asset per get_asset).

    After swapping dx into the pool:
        new_reserve_in  = reserve_in + dx
        effective_dx    = dx * (10000 - fee_bps) / 10000
        new_reserve_out = reserve_in * reserve_out / (reserve_in + effective_dx)
        new_price       = new_reserve_in / (new_reserve_out * (10000 - fee_bps) / 10000)

    Setting new_price = target_price and solving for dx gives a quadratic.
    We use integer arithmetic throughout for determinism.

    Returns the maximum integer dx such that the pool price stays <= target.
    Returns 0 if the pool is already at or above target price.
    """
    if reserve_in <= 0 or reserve_out <= 0:
        return 0
    if target_price_den <= 0 or target_price_num <= 0:
        return 0

    fee_factor = 10000 - fee_bps

    # Current marginal price check: is pool already at or past target?
    current_price_lhs = reserve_in * 10000 * target_price_den
    current_price_rhs = reserve_out * fee_factor * target_price_num
    if current_price_lhs >= current_price_rhs:
        return 0

    # Quadratic: a*dx^2 + b*dx + c = 0
    a = fee_factor
    b_coeff = reserve_in * (10000 + fee_factor)
    c_target = reserve_in * reserve_out * fee_factor * target_price_num // target_price_den
    constant = reserve_in * reserve_in * 10000 - c_target

    discriminant = b_coeff * b_coeff - 4 * a * constant
    if discriminant < 0:
        return 0

    sqrt_disc = isqrt(discriminant)
    # Positive root: dx = (-b + sqrt(discriminant)) / (2a)
    numerator = -b_coeff + sqrt_disc
    if numerator <= 0:
        return 0

    dx = numerator // (2 * a)
    return max(dx, 0)


def compute_pool_output_for_order(pool, give_asset, give_quantity, fee_bps):
    """Compute how much get_asset a trader receives for give_quantity of give_asset.

    Determines which reserve is 'in' and which is 'out' based on give_asset.
    """
    if give_asset == pool["asset_a"]:
        return compute_pool_output(pool["reserve_a"], pool["reserve_b"], give_quantity, fee_bps)
    else:
        return compute_pool_output(pool["reserve_b"], pool["reserve_a"], give_quantity, fee_bps)


def sort_pair(asset_a, asset_b):
    """Return (asset_a, asset_b) sorted alphabetically."""
    if asset_a > asset_b:
        return asset_b, asset_a
    return asset_a, asset_b


def get_pool(db, asset_a, asset_b):
    """Fetch the pool row for the sorted pair, or None."""
    return ledger.markets.get_pool(db, *sort_pair(asset_a, asset_b))


def get_pool_for_pair(db, give_asset, get_asset):
    """Get pool for a trading pair (assets in any order). Returns None if no pool."""
    return get_pool(db, give_asset, get_asset)


def pool_has_liquidity(pool):
    """Check if pool has non-zero reserves."""
    return pool is not None and pool["reserve_a"] > 0 and pool["reserve_b"] > 0


def insert_pool(db, pool_data):
    """Insert a new pool record."""
    ledger.markets.insert_pool(db, pool_data)


def update_pool(db, asset_a, asset_b, new_reserve_a, new_reserve_b):
    """Update pool reserves."""
    ledger.markets.update_pool(db, *sort_pair(asset_a, asset_b), new_reserve_a, new_reserve_b)


def execute_pool_match(db, tx, tx1, pool, give_quantity, get_quantity):
    """Fill part of tx1's order against the pool.

    Accounting:
      - The trader's give_asset was already debited when the order was placed
        (escrowed in order.parse).  It flows into pool reserves via the
        reserve_in increase -- no second debit needed.
      - The trader receives get_asset via credit (comes from pool reserves
        via reserve_out decrease).
      - The fee portion stays in reserves, growing k, benefiting all LPs.
    """
    fee_bps = get_pool_fee_bps(pool)
    fee_quantity = give_quantity * fee_bps // 10000

    # Determine which direction the swap goes
    asset_a, asset_b = pool["asset_a"], pool["asset_b"]
    if tx1["give_asset"] == asset_a:
        new_reserve_a = pool["reserve_a"] + give_quantity
        new_reserve_b = pool["reserve_b"] - get_quantity
    else:
        new_reserve_b = pool["reserve_b"] + give_quantity
        new_reserve_a = pool["reserve_a"] - get_quantity

    # Credit the trader with get_asset
    ledger.events.credit(
        db,
        tx1["source"],
        tx1["get_asset"],
        get_quantity,
        tx["tx_index"],
        action="pool match",
        event=tx1["tx_hash"],
    )

    # Update pool reserves
    update_pool(db, asset_a, asset_b, new_reserve_a, new_reserve_b)

    # Record pool match event
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx1["source"],
        "asset_a": asset_a,
        "asset_b": asset_b,
        "forward_asset": tx1["get_asset"],
        "forward_quantity": get_quantity,
        "backward_asset": tx1["give_asset"],
        "backward_quantity": give_quantity,
        "fee_quantity": fee_quantity,
        "fee_bps": fee_bps,
        "order_tx_hash": tx1["tx_hash"],
        "status": "valid",
    }
    ledger.events.insert_record(db, "pool_matches", bindings, "POOL_MATCH")

    logger.info(
        "Pool match: %(backward_quantity)s %(backward_asset)s -> %(forward_quantity)s %(forward_asset)s "
        "(fee: %(fee_quantity)s, %(fee_bps)s bps) [%(order_tx_hash)s]",
        bindings,
    )


def match_resting_orders_against_pool(db, tx, asset_a, asset_b):
    """After a pool deposit, fill resting orders that are profitable against the pool."""
    pool = get_pool(db, asset_a, asset_b)
    if not pool or not pool_has_liquidity(pool):
        return

    for give_asset, get_asset in [(asset_a, asset_b), (asset_b, asset_a)]:
        pool = get_pool(db, asset_a, asset_b)
        if not pool or not pool_has_liquidity(pool):
            break
        fill_resting_orders(db, tx, pool, give_asset, get_asset)


def fill_resting_orders(db, tx, pool, give_asset, get_asset):
    """Fill resting orders in one direction against the pool."""
    open_orders = ledger.markets.get_open_orders_for_pair(db, give_asset, get_asset)

    # Sort by price: most aggressive (lowest get/give ratio) first
    open_orders = sorted(open_orders, key=lambda x: x["tx_index"])
    open_orders = sorted(
        open_orders,
        key=lambda x: ledger.issuances.price(x["get_quantity"], x["give_quantity"]),
    )

    for order in open_orders:
        # Refresh pool state after each fill (reserves change)
        pool = get_pool(db, pool["asset_a"], pool["asset_b"])
        if not pool or not pool_has_liquidity(pool):
            break

        give_remaining = order["give_remaining"]
        if give_remaining <= 0:
            continue

        fee_bps = get_pool_fee_bps(pool)

        if give_asset == pool["asset_a"]:
            reserve_in, reserve_out = pool["reserve_a"], pool["reserve_b"]
        else:
            reserve_in, reserve_out = pool["reserve_b"], pool["reserve_a"]

        max_fill = compute_pool_input_for_target_price(
            reserve_in, reserve_out,
            order["give_quantity"], order["get_quantity"],
            fee_bps,
        )

        if max_fill <= 0:
            continue

        fill_qty = min(max_fill, give_remaining)
        output = compute_pool_output(reserve_in, reserve_out, fill_qty, fee_bps)

        min_output = fill_qty * order["get_quantity"] // order["give_quantity"]
        if output < min_output or output <= 0:
            continue

        execute_pool_match(db, tx, order, pool, fill_qty, output)

        new_give_remaining = give_remaining - fill_qty
        new_get_remaining = order["get_remaining"] - output

        if new_give_remaining <= 0:
            status = "filled"
            new_give_remaining = 0
        else:
            status = "open"

        set_data = {
            "give_remaining": new_give_remaining,
            "get_remaining": new_get_remaining,
            "fee_required_remaining": order["fee_required_remaining"],
            "fee_provided_remaining": order["fee_provided_remaining"],
            "status": status,
        }
        ledger.markets.update_order(db, order["tx_hash"], set_data)
