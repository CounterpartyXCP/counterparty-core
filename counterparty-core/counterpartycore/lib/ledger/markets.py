from counterpartycore.lib import config
from counterpartycore.lib.ledger.caches import OrdersCache
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.ledger.events import insert_record, insert_update

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
    bindings = {"status": "pending", "tx0_hash": tx0_hash, "tx1_hash": tx1_hash}
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
    bindings = (order_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_first_block_index(cursor, tx_hash):
    query = """
        SELECT block_index FROM orders
        WHERE tx_hash = ?
        ORDER BY rowid ASC LIMIT 1
    """
    bindings = (tx_hash,)
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
    bindings = (tx_hash, get_asset, give_asset, "open")
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
    select_bindings = {"tx0_hash": tx0_hash, "tx1_hash": tx1_hash}

    where_source = ""
    if source is not None:
        where_source = f" AND source = :source"  # noqa: F541
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
        {"order_match_id": id},
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
        bindings.append(tx_hash)
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
    cursor.execute(query, tx_hash_list)
    dispensers = cursor.fetchall()
    result = {}
    for dispenser in dispensers:
        del dispenser["rowid"]
        tx_hash = dispenser["tx_hash"]
        del dispenser["tx_hash"]
        del dispenser["asset"]
        result[tx_hash] = dispenser
    return result


def get_refilling_count(db, dispenser_tx_hash):
    cursor = db.cursor()
    query = """
        SELECT count(*) cnt
        FROM dispenser_refills
        WHERE dispenser_tx_hash = ?
    """
    bindings = (dispenser_tx_hash,)
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
