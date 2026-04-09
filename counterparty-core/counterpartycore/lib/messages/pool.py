# Pool match execution and deposit-triggered order matching.

import logging

from counterpartycore.lib import config, ledger

logger = logging.getLogger(config.LOGGER_NAME)


def try_pool_fill(db, tx1, pool, max_give, target_price_num=None, target_price_den=None):
    """Try to fill an order against the pool. Returns (fill_quantity, output) or (0, 0)."""
    if not pool or not ledger.markets.pool_has_liquidity(pool):
        return 0, 0

    if tx1["give_asset"] == pool["asset_a"]:
        reserve_in, reserve_out = pool["reserve_a"], pool["reserve_b"]
    else:
        reserve_in, reserve_out = pool["reserve_b"], pool["reserve_a"]

    fee_bps = ledger.markets.get_pool_fee_bps(pool)

    if target_price_num is not None:
        fill_quantity = ledger.markets.compute_pool_input_for_target_price(
            reserve_in, reserve_out, target_price_num, target_price_den, fee_bps
        )
        fill_quantity = min(fill_quantity, max_give)
    else:
        fill_quantity = max_give

    if fill_quantity <= 0:
        return 0, 0

    output = ledger.markets.compute_pool_output(reserve_in, reserve_out, fill_quantity, fee_bps)
    min_output = fill_quantity * tx1["get_quantity"] // tx1["give_quantity"]
    if output < min_output or output <= 0:
        return 0, 0

    return fill_quantity, output


def execute_pool_match(db, tx, tx1, pool, give_quantity, get_quantity):
    """Fill part of tx1's order against the pool."""
    fee_bps = ledger.markets.get_pool_fee_bps(pool)
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

    ledger.markets.update_pool(
        db, *ledger.markets.sort_pair(asset_a, asset_b), new_reserve_a, new_reserve_b
    )

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
