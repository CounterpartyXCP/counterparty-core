import logging
import math

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger.caches import OrdersCache
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.ledger.events import credit, insert_record, insert_update
from counterpartycore.lib.utils import hashcodec

logger = logging.getLogger(config.LOGGER_NAME)

#####################
#   POOL UTILITIES  #
#####################

XCP_POOL_FEE_BPS = 50
OTHER_POOL_FEE_BPS = 100


def sort_pair(asset_a, asset_b):
    if asset_a > asset_b:
        return asset_b, asset_a
    return asset_a, asset_b


def get_pool_fee_bps(pool):
    if config.XCP in (pool["asset_a"], pool["asset_b"]):
        return XCP_POOL_FEE_BPS
    return OTHER_POOL_FEE_BPS


def pool_has_liquidity(pool):
    return pool is not None and pool["reserve_a"] > 0 and pool["reserve_b"] > 0


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


def compute_pool_input_for_target_price(
    reserve_in, reserve_out, target_price_num, target_price_den, fee_bps
):
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


#####################
#       ORDERS      #
#####################

### SELECTS ###


def get_pending_order_matches(db, tx0_hash, tx1_hash):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid FROM order_matches
            WHERE (
                tx0_hash in (:tx0_hash, :tx1_hash) OR
                tx1_hash in (:tx0_hash, :tx1_hash)
            )
            GROUP BY id
        ) WHERE status = :status
        ORDER BY rowid
    """
    bindings = {
        "status": "pending",
        "tx0_hash": hashcodec.hash_to_db(tx0_hash),
        "tx1_hash": hashcodec.hash_to_db(tx1_hash),
    }
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_pending_btc_order_matches(db, address):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM order_matches
            WHERE (tx0_address = ? AND forward_asset = ?) OR (tx1_address = ? AND backward_asset = ?)
        ) WHERE status = ?
        ORDER BY rowid
    """
    bindings = (address, config.BTC, address, config.BTC, "pending")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_match(db, match_id):
    cursor = db.cursor()
    query = """
        SELECT *, rowid
        FROM order_matches
        WHERE id = ?
        ORDER BY rowid DESC LIMIT 1"""
    bindings = (match_id,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_matches_to_expire(db, block_index):
    cursor = db.cursor()
    query = """SELECT * FROM (
        SELECT *, MAX(rowid) AS rowid
        FROM order_matches
        WHERE match_expire_index = ? - 1
        GROUP BY id
    ) WHERE status = ?
    ORDER BY rowid
    """
    bindings = (block_index, "pending")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order(db, order_hash: str):
    """
    Returns the information of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. 23f68fdf934e81144cca31ce8ef69062d553c521321a039166e7ba99aede0776)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM orders
        WHERE tx_hash = ?
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (hashcodec.hash_to_db(order_hash),)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_first_block_index(cursor, tx_hash):
    query = """
        SELECT block_index FROM orders
        WHERE tx_hash = ?
        ORDER BY rowid ASC LIMIT 1
    """
    bindings = (hashcodec.hash_to_db(tx_hash),)
    cursor.execute(query, bindings)
    return cursor.fetchone()["block_index"]


def get_orders_to_expire(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE expire_index = ? - 1
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (block_index, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_open_btc_orders(db, address):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE (source = ? AND give_asset = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (address, config.BTC, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_open_orders_by_source(db, address):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE source = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (address, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_orders_no_cache(db, tx_hash, give_asset, get_asset):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE (tx_hash != ? AND give_asset = ? AND get_asset = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (hashcodec.hash_to_db(tx_hash), get_asset, give_asset, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_orders(db, tx_hash, give_asset, get_asset):
    if CurrentState().ledger_state() == "Catching Up":
        return OrdersCache(db).get_matching_orders(tx_hash, give_asset, get_asset)
    return get_matching_orders_no_cache(db, tx_hash, give_asset, get_asset)


def insert_order(db, order):
    insert_record(db, "orders", order, "OPEN_ORDER")
    if not CurrentState().parsing_mempool():
        OrdersCache(db).insert_order(order)


### UPDATES ###


def update_order(db, tx_hash, update_data):
    insert_update(db, "orders", "tx_hash", tx_hash, update_data, "ORDER_UPDATE")
    if not CurrentState().parsing_mempool():
        OrdersCache(db).update_order(tx_hash, update_data)


def mark_order_as_filled(db, tx0_hash, tx1_hash, source=None):
    select_bindings = {
        "tx0_hash": hashcodec.hash_to_db(tx0_hash),
        "tx1_hash": hashcodec.hash_to_db(tx1_hash),
    }

    where_source = ""
    if source is not None:
        where_source = " AND source = :source"
        select_bindings["source"] = source

    # no sql injection here
    select_query = f"""
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM orders
            WHERE
                tx_hash in (:tx0_hash, :tx1_hash)
                {where_source}
            GROUP BY tx_hash
        ) WHERE give_remaining = 0 OR get_remaining = 0
    """  # nosec B608  # noqa: S608 # nosec B608

    cursor = db.cursor()
    cursor.execute(select_query, select_bindings)
    for order in cursor:
        update_data = {"status": "filled"}
        insert_update(
            db,
            "orders",
            "rowid",
            order["rowid"],
            update_data,
            "ORDER_FILLED",
            {"tx_hash": order["tx_hash"]},
        )
        if not CurrentState().parsing_mempool():
            OrdersCache(db).update_order(order["tx_hash"], update_data)


def update_order_match_status(db, order_match_id, status):
    update_data = {"status": status}
    # add `order_match_id` for backward compatibility
    insert_update(
        db,
        "order_matches",
        "id",
        order_match_id,
        update_data,
        "ORDER_MATCH_UPDATE",
        {"order_match_id": order_match_id},
    )


#####################
#     DISPENSERS    #
#####################

### SELECTS ###


def get_dispenser_info(db, tx_hash=None, tx_index=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if tx_hash is not None:
        where.append("tx_hash = ?")
        bindings.append(hashcodec.hash_to_db(tx_hash))
    if tx_index is not None:
        where.append("tx_index = ?")
        bindings.append(tx_index)
    # no sql injection here
    if len(where) == 0:
        query = """
            SELECT *
            FROM dispensers
            ORDER BY rowid DESC LIMIT 1
        """
    else:
        query = f"""
            SELECT *
            FROM dispensers
            WHERE ({" AND ".join(where)})
            ORDER BY rowid DESC LIMIT 1
        """  # nosec B608  # noqa: S608 # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_dispensers_info(db, tx_hash_list):
    cursor = db.cursor()
    query = f"""
        SELECT *, MAX(rowid) AS rowid FROM dispensers
        WHERE tx_hash IN ({",".join(["?" for e in range(0, len(tx_hash_list))])})
        GROUP BY tx_hash
    """  # nosec B608  # noqa: S608 # nosec B608
    cursor.execute(query, [hashcodec.hash_to_db(h) for h in tx_hash_list])
    dispensers = cursor.fetchall()
    result = {}
    for dispenser in dispensers:
        del dispenser["rowid"]
        # rowtracer converts BLOB -> hex; key the result on the hex form so
        # callers passing hex keys can index it back.
        tx_hash = dispenser["tx_hash"]
        del dispenser["tx_hash"]
        del dispenser["asset"]
        result[tx_hash] = dispenser
    return result


def get_refilling_count(db, dispenser_tx_hash):
    # ``dispenser_refills.dispenser_tx_hash`` was replaced by an integer
    # ``dispenser_tx_index`` FK; translate the hex hash via the
    # ``transactions`` table.
    cursor = db.cursor()
    query = """
        SELECT count(*) cnt
        FROM dispenser_refills
        WHERE dispenser_tx_index = (
            SELECT tx_index FROM transactions WHERE tx_hash = ?
        )
    """
    bindings = (hashcodec.hash_to_db(dispenser_tx_hash),)
    cursor.execute(query, bindings)
    return cursor.fetchall()[0]["cnt"]


def get_pending_dispensers(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM dispensers
            WHERE close_block_index = :close_block_index
            GROUP BY source, asset
        )
        WHERE status = :status_closing
        ORDER BY tx_index
    """
    bindings = {
        "close_block_index": block_index,
        "status_closing": 11,  # STATUS_CLOSING
    }
    cursor.execute(query, bindings)
    result = cursor.fetchall()

    return result


def get_dispensers_count(db, source, status, origin):
    cursor = db.cursor()
    query = """
        SELECT count(*) cnt FROM (
            SELECT *, MAX(rowid)
            FROM dispensers
            WHERE source = ? AND origin = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index
    """
    bindings = (source, origin, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()[0]["cnt"]


def get_dispensers(
    db,
    status_in=None,
    source_in=None,
    address=None,
    asset=None,
    origin=None,
    status=None,
    order_by=None,
    group_by=None,
):
    cursor = db.cursor()
    bindings = []
    # where for immutable fields
    first_where = []
    if address is not None:
        first_where.append("source = ?")
        bindings.append(address)
    if source_in is not None:
        first_where.append(f"source IN ({','.join(['?' for e in range(0, len(source_in))])})")
        bindings += source_in
    if asset is not None:
        first_where.append("asset = ?")
        bindings.append(asset)
    if origin is not None:
        first_where.append("origin = ?")
        bindings.append(origin)
    # where for mutable fields
    second_where = []
    if status is not None:
        second_where.append("status = ?")
        bindings.append(status)
    if status_in is not None:
        second_where.append(f"status IN ({','.join(['?' for e in range(0, len(status_in))])})")
        bindings += status_in
    # build query
    first_where_str = " AND ".join(first_where)
    if first_where_str != "":
        first_where_str = f"WHERE ({first_where_str})"
    second_where_str = " AND ".join(second_where)
    if second_where_str != "":
        second_where_str = f"WHERE ({second_where_str})"
    order_clause = f"ORDER BY {order_by}" if order_by is not None else "ORDER BY tx_index"
    group_clause = f"GROUP BY {group_by}" if group_by is not None else "GROUP BY asset, source"
    # no sql injection here
    query = f"""
        SELECT *, rowid FROM (
            SELECT *, MAX(rowid) as rowid
            FROM dispensers
            {first_where_str}
            {group_clause}
        ) {second_where_str}
        {order_clause}
    """  # nosec B608  # noqa: S608 # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_all_dispensables(db):
    cursor = db.cursor()
    query = """SELECT DISTINCT source AS source FROM dispensers"""
    dispensables = {}
    for row in cursor.execute(query).fetchall():
        dispensables[row["source"]] = True
    return dispensables


### UPDATES ###


def update_dispenser(db, rowid, update_data, dispenser_info):
    insert_update(db, "dispensers", "rowid", rowid, update_data, "DISPENSER_UPDATE", dispenser_info)


#####################
#       POOLS       #
#####################

### SELECTS ###


def get_pool(db, asset_a, asset_b):
    cursor = db.cursor()
    query = """
        SELECT * FROM pools
        WHERE asset_a = ? AND asset_b = ?
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (asset_a, asset_b)
    cursor.execute(query, bindings)
    pools = cursor.fetchall()
    cursor.close()
    if pools:
        return pools[0]
    return None


def get_pool_by_lp_asset(db, lp_asset):
    cursor = db.cursor()
    query = """
        SELECT * FROM pools
        WHERE lp_asset = ?
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (lp_asset,)
    cursor.execute(query, bindings)
    pools = cursor.fetchall()
    cursor.close()
    if pools:
        return pools[0]
    return None


def get_all_pools(db):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM pools
            GROUP BY asset_a, asset_b
        ) WHERE reserve_a > 0 AND reserve_b > 0
        ORDER BY asset_a, asset_b
    """
    cursor.execute(query)
    return cursor.fetchall()


def get_pool_deposits(db, asset_a, asset_b):
    cursor = db.cursor()
    query = """
        SELECT * FROM pool_deposits
        WHERE asset_a = ? AND asset_b = ? AND status = 'valid'
        ORDER BY block_index, tx_index
    """
    cursor.execute(query, (asset_a, asset_b))
    return cursor.fetchall()


def get_pool_withdrawals(db, asset_a, asset_b):
    cursor = db.cursor()
    query = """
        SELECT * FROM pool_withdrawals
        WHERE asset_a = ? AND asset_b = ? AND status = 'valid'
        ORDER BY block_index, tx_index
    """
    cursor.execute(query, (asset_a, asset_b))
    return cursor.fetchall()


def get_open_orders_for_pair(db, give_asset, get_asset):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE give_asset = ? AND get_asset = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    cursor.execute(query, (give_asset, get_asset, "open"))
    return cursor.fetchall()


def get_pool_matches_by_order(db, order_tx_hash):
    # ``pool_matches.order_tx_hash`` was replaced by an integer
    # ``order_tx_index`` FK; translate the hex hash via the
    # ``transactions`` table.
    cursor = db.cursor()
    query = """
        SELECT * FROM pool_matches
        WHERE order_tx_index = (
            SELECT tx_index FROM transactions WHERE tx_hash = ?
        )
        ORDER BY block_index, tx_index
    """
    cursor.execute(query, (hashcodec.hash_to_db(order_tx_hash),))
    return cursor.fetchall()


### UPDATES ###


def insert_pool(db, pool_data):
    insert_record(db, "pools", pool_data, "OPEN_POOL")


def update_pool(db, asset_a, asset_b, new_reserve_a, new_reserve_b):
    cursor = db.cursor()
    cursor.execute(
        "SELECT rowid FROM pools WHERE asset_a = ? AND asset_b = ? ORDER BY rowid DESC LIMIT 1",
        (asset_a, asset_b),
    )
    row = cursor.fetchone()
    cursor.close()
    if row is None:
        raise exceptions.ConsensusError(
            f"update_pool called with no matching pool row for {asset_a}/{asset_b}"
        )
    update_data = {"reserve_a": new_reserve_a, "reserve_b": new_reserve_b}
    insert_update(
        db,
        "pools",
        "rowid",
        row["rowid"],
        update_data,
        "POOL_UPDATE",
        {"asset_a": asset_a, "asset_b": asset_b},
    )


### POOL SWAP EXECUTION ###


def try_pool_fill(tx1, pool, max_give, target_price_num=None, target_price_den=None):
    """Try to fill an order against the pool. Returns (fill_quantity, output) or (0, 0)."""
    if not pool or not pool_has_liquidity(pool):
        return 0, 0

    if tx1["give_asset"] == pool["asset_a"]:
        reserve_in, reserve_out = pool["reserve_a"], pool["reserve_b"]
    else:
        reserve_in, reserve_out = pool["reserve_b"], pool["reserve_a"]

    fee_bps = get_pool_fee_bps(pool)

    if target_price_num is not None:
        fill_quantity = compute_pool_input_for_target_price(
            reserve_in, reserve_out, target_price_num, target_price_den, fee_bps
        )
        fill_quantity = min(fill_quantity, max_give)
    else:
        fill_quantity = max_give

    if fill_quantity <= 0:
        return 0, 0

    output = compute_pool_output(reserve_in, reserve_out, fill_quantity, fee_bps)
    # Ceil so the limit price is enforced strictly (floor would allow
    # sub-satoshi fills below the order's rate).
    min_output = -(-fill_quantity * tx1["get_quantity"] // tx1["give_quantity"])
    if output < min_output or output <= 0:
        return 0, 0

    return fill_quantity, output


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

    assert new_reserve_a * new_reserve_b >= pool["reserve_a"] * pool["reserve_b"]

    credit(
        db,
        tx1["source"],
        tx1["get_asset"],
        get_quantity,
        tx["tx_index"],
        action="pool match",
        event=tx1["tx_hash"],
    )

    update_pool(db, *sort_pair(asset_a, asset_b), new_reserve_a, new_reserve_b)

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
    insert_record(db, "pool_matches", bindings, "POOL_MATCH")

    logger.info(
        "Pool match: %(backward_quantity)s %(backward_asset)s -> %(forward_quantity)s %(forward_asset)s "
        "(fee: %(fee_quantity)s, %(fee_bps)s bps) [%(order_tx_hash)s]",
        bindings,
    )
