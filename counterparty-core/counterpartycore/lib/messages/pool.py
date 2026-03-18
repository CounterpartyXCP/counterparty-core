# AMM liquidity pool utilities: constant product (x*y=k) math, pool match
# execution, deposit-triggered order matching, and shared pool helpers.

import logging
import math

from counterpartycore.lib import config, ledger

logger = logging.getLogger(config.LOGGER_NAME)

XCP_POOL_FEE_BPS = 50   # 0.50% for XCP pairs
OTHER_POOL_FEE_BPS = 100  # 1.00% for non-XCP pairs

def get_pool_fee_bps(pool):
    if pool["asset_a"] == config.XCP or pool["asset_b"] == config.XCP:
        return XCP_POOL_FEE_BPS
    return OTHER_POOL_FEE_BPS

def isqrt(n):
    return math.isqrt(n)

def compute_pool_output(reserve_in, reserve_out, input_qty, fee_bps):
    """Constant-product swap with fee. Returns integer output quantity."""
    if input_qty <= 0 or reserve_in <= 0 or reserve_out <= 0:
        return 0
    input_with_fee = input_qty * (10000 - fee_bps)
    numerator = input_with_fee * reserve_out
    denominator = reserve_in * 10000 + input_with_fee
    return numerator // denominator

def compute_pool_input_for_target_price(reserve_in, reserve_out, target_price_num,
                                         target_price_den, fee_bps):
    """Max input before pool marginal price reaches target. Returns 0 if already past."""
    if reserve_in <= 0 or reserve_out <= 0:
        return 0
    if target_price_den <= 0 or target_price_num <= 0:
        return 0

    fee_factor = 10000 - fee_bps

    current_price_lhs = reserve_in * 10000 * target_price_den
    current_price_rhs = reserve_out * fee_factor * target_price_num
    if current_price_lhs >= current_price_rhs:
        return 0

    a = fee_factor
    b_coeff = reserve_in * (10000 + fee_factor)
    c_target = reserve_in * reserve_out * fee_factor * target_price_num // target_price_den
    constant = reserve_in * reserve_in * 10000 - c_target

    discriminant = b_coeff * b_coeff - 4 * a * constant
    if discriminant < 0:
        return 0

    sqrt_disc = isqrt(discriminant)
    numerator = -b_coeff + sqrt_disc
    if numerator <= 0:
        return 0

    dx = numerator // (2 * a)
    return max(dx, 0)

def sort_pair(asset_a, asset_b):
    if asset_a > asset_b:
        return asset_b, asset_a
    return asset_a, asset_b

def get_pool(db, asset_a, asset_b):
    return ledger.markets.get_pool(db, *sort_pair(asset_a, asset_b))

def get_pool_for_pair(db, give_asset, get_asset):
    return get_pool(db, give_asset, get_asset)

def pool_has_liquidity(pool):
    return pool is not None and pool["reserve_a"] > 0 and pool["reserve_b"] > 0

def get_lp_supply(db, pool):
    return ledger.supplies.asset_supply(db, pool["lp_asset"])

def insert_pool(db, pool_data):
    ledger.markets.insert_pool(db, pool_data)

def update_pool(db, asset_a, asset_b, new_reserve_a, new_reserve_b):
    ledger.markets.update_pool(db, *sort_pair(asset_a, asset_b), new_reserve_a, new_reserve_b)

def try_pool_fill(db, tx1, pool, max_give, target_price_num=None, target_price_den=None):
    """Try to fill an order against the pool. Returns (fill_qty, output) or (0, 0)."""
    if not pool or not pool_has_liquidity(pool):
        return 0, 0

    if tx1["give_asset"] == pool["asset_a"]:
        reserve_in, reserve_out = pool["reserve_a"], pool["reserve_b"]
    else:
        reserve_in, reserve_out = pool["reserve_b"], pool["reserve_a"]

    fee_bps = get_pool_fee_bps(pool)

    if target_price_num is not None:
        fill_qty = compute_pool_input_for_target_price(
            reserve_in, reserve_out, target_price_num, target_price_den, fee_bps
        )
        fill_qty = min(fill_qty, max_give)
    else:
        fill_qty = max_give

    if fill_qty <= 0:
        return 0, 0

    output = compute_pool_output(reserve_in, reserve_out, fill_qty, fee_bps)
    min_output = fill_qty * tx1["get_quantity"] // tx1["give_quantity"]
    if output < min_output or output <= 0:
        return 0, 0

    return fill_qty, output

def execute_pool_match(db, tx, tx1, pool, give_quantity, get_quantity):
    """Fill part of tx1's order against the pool."""
    fee_bps = get_pool_fee_bps(pool)
    fee_quantity = give_quantity * fee_bps // 10000

    asset_a, asset_b = pool["asset_a"], pool["asset_b"]
    if tx1["give_asset"] == asset_a:
        new_reserve_a = pool["reserve_a"] + give_quantity
        new_reserve_b = pool["reserve_b"] - get_quantity
    else:
        new_reserve_b = pool["reserve_b"] + give_quantity
        new_reserve_a = pool["reserve_a"] - get_quantity

    ledger.events.credit(
        db,
        tx1["source"],
        tx1["get_asset"],
        get_quantity,
        tx["tx_index"],
        action="pool match",
        event=tx1["tx_hash"],
    )

    update_pool(db, asset_a, asset_b, new_reserve_a, new_reserve_b)

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
    pool = get_pool(db, asset_a, asset_b)
    if not pool or not pool_has_liquidity(pool):
        return

    for give_asset, get_asset in [(asset_a, asset_b), (asset_b, asset_a)]:
        pool = get_pool(db, asset_a, asset_b)
        if not pool or not pool_has_liquidity(pool):
            break
        fill_resting_orders(db, tx, pool, give_asset, get_asset)

def fill_resting_orders(db, tx, pool, give_asset, get_asset):
    open_orders = ledger.markets.get_open_orders_for_pair(db, give_asset, get_asset)

    open_orders = sorted(open_orders, key=lambda x: x["tx_index"])
    open_orders = sorted(
        open_orders,
        key=lambda x: ledger.issuances.price(x["get_quantity"], x["give_quantity"]),
    )

    for order in open_orders:
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
