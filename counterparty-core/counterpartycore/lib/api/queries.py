import json


class QueryResult:
    def __init__(self, result, next_cursor, result_count=None):
        self.result = result
        self.next_cursor = next_cursor
        self.result_count = result_count


def select_rows(
    db,
    table,
    where=None,
    cursor_field="rowid",
    last_cursor=None,
    offset=None,
    limit=100,
    select="*",
    group_by="",
    order="DESC",
    wrap_where=None,
):
    cursor = db.cursor()

    if where is None:
        where = [{}]
    if isinstance(where, dict):
        where = [where]

    bindings = []

    or_where = []
    for where_dict in where:
        where_field = []
        for key, value in where_dict.items():
            if key.endswith("__gt"):
                where_field.append(f"{key[:-4]} > ?")
            elif key.endswith("__like"):
                where_field.append(f"{key[:-6]} LIKE ?")
            else:
                where_field.append(f"{key} = ?")
            bindings.append(value)
        and_where_clause = ""
        if where_field:
            and_where_clause = " AND ".join(where_field)
            and_where_clause = f"({and_where_clause})"
            or_where.append(and_where_clause)

    where_clause = ""
    if or_where:
        where_clause = " OR ".join(or_where)

    if where_clause:
        where_clause_count = f"WHERE {where_clause}"
    else:
        where_clause_count = ""
    bindings_count = list(bindings)

    if offset is None and last_cursor is not None:
        if where_clause != "":
            where_clause = f"({where_clause}) AND "
        if order == "ASC":
            where_clause += f" {cursor_field} >= ?"
        else:
            where_clause += f" {cursor_field} <= ?"
        bindings.append(last_cursor)

    if where_clause:
        where_clause = f"WHERE {where_clause}"

    group_by_clause = ""
    if group_by:
        group_by_clause = f"GROUP BY {group_by}"

    if select == "*":
        select = f"*, {cursor_field} AS {cursor_field}"

    query = f"SELECT {select} FROM {table} {where_clause} {group_by_clause}"  # nosec B608  # noqa: S608
    query_count = f"SELECT {select} FROM {table} {where_clause_count} {group_by_clause}"  # nosec B608  # noqa: S608

    if wrap_where is not None:
        wrap_where_field = []
        for key, value in wrap_where.items():
            if key.endswith("__gt"):
                wrap_where_field.append(f"{key[:-4]} > ?")
            else:
                wrap_where_field.append(f"{key} = ?")
            bindings.append(value)
            bindings_count.append(value)
        wrap_where_clause = " AND ".join(wrap_where_field)
        wrap_where_clause = f"WHERE {wrap_where_clause}"
        query = f"SELECT * FROM ({query}) {wrap_where_clause}"  # nosec B608  # noqa: S608
        query_count = f"SELECT COUNT(*) AS count FROM ({query_count}) {wrap_where_clause}"  # nosec B608  # noqa: S608
    else:
        query_count = f"SELECT COUNT(*) AS count FROM ({query_count})"  # nosec B608  # noqa: S608

    query = f"{query} ORDER BY {cursor_field} {order} LIMIT ?"  # nosec B608  # noqa: S608
    bindings.append(limit + 1)
    if offset is not None:
        query = f"{query} OFFSET ?"
        bindings.append(offset)

    cursor.execute(query, bindings)
    result = cursor.fetchall()

    cursor.execute(query_count, bindings_count)
    result_count = cursor.fetchone()["count"]

    if result and len(result) > limit:
        next_cursor = result[-1][cursor_field]
        result = result[:-1]
    else:
        next_cursor = None

    if table == "messages":
        for row in result:
            if "params" not in row:
                break
            row["params"] = json.loads(row["params"])

    return QueryResult(result, next_cursor, result_count)


def select_row(db, table, where, select="*"):
    query_result = select_rows(db, table, where, limit=1, select=select)
    if query_result.result:
        return QueryResult(query_result.result[0], None, 1)
    return None


def get_blocks(db, cursor: int = None, limit: int = 10, offset: int = None):
    """
    Returns the list of the last ten blocks
    :param int cursor: The index of the most recent block to return (e.g. 840000)
    :param int limit: The number of blocks to return (e.g. 2)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "blocks", cursor_field="block_index", last_cursor=cursor, limit=limit, offset=offset
    )


def get_block_by_height(db, block_index: int):
    """
    Return the information of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return select_row(db, "blocks", where={"block_index": block_index})


def get_block_by_hash(db, block_hash: str):
    """
    Return the information of a block
    :param str block_hash: The index of the block to return (e.g. 0000000000000000000073b0a277154cbc420e04fd8c699ae188d8d4421418ad)
    """
    return select_row(db, "blocks", where={"block_hash": block_hash})


def get_last_block(db):
    """
    Return the information of the last block
    """
    return select_row(db, "blocks", where={})


def get_transactions_by_block(
    db, block_index: int, cursor: int = None, limit: int = 10, offset: int = None
):
    """
    Returns the transactions of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int cursor: The last transaction index to return (e.g. 10665092)
    :param int limit: The maximum number of transactions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "transactions",
        where={"block_index": block_index},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_all_events(db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns all events
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "messages",
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, timestamp",
    )


def get_events_by_block(
    db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the events of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "messages",
        where={"block_index": block_index},
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash",
    )


def get_events_by_transaction_hash(
    db, tx_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "messages",
        where={"tx_hash": tx_hash},
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, timestamp",
    )


def get_events_by_transaction_hash_and_event(
    db, tx_hash: str, event: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "messages",
        where={"tx_hash": tx_hash, "event": event},
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, timestamp",
    )


def get_events_by_transaction_index(
    db, tx_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. 1000)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    query_result = select_row(db, "transactions", where={"tx_index": tx_index})
    if query_result:
        return get_events_by_transaction_hash(
            db, query_result.result["tx_hash"], cursor=cursor, limit=limit, offset=offset
        )
    return None


def get_events_by_transaction_index_and_event(
    db, tx_index: int, event: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. 1000)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    query_result = select_row(db, "transactions", where={"tx_index": tx_index})
    if query_result:
        return get_events_by_transaction_hash_and_event(
            db, query_result.result["tx_hash"], event, cursor=cursor, limit=limit, offset=offset
        )
    return None


def get_events_by_block_and_event(
    db, block_index: int, event: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the events of a block filtered by event
    :param int block_index: The index of the block to return (e.g. 840464)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    if event == "count":
        return get_event_counts_by_block(db, block_index=block_index)
    return select_rows(
        db,
        "messages",
        where={"block_index": block_index, "event": event},
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash",
    )


def get_event_by_index(db, event_index: int):
    """
    Returns the event of an index
    :param int event_index: The index of the event to return (e.g. 10665092)
    """
    return select_row(
        db,
        "messages",
        where={"message_index": event_index},
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, timestamp, rowid AS rowid",
    )


def get_events_by_name(db, event: str, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns the events filtered by event name
    :param str event: The event to return (e.g. CREDIT)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "messages",
        where={"event": event},
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, timestamp",
    )


def get_all_mempool_events(db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns all mempool events
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(db, "mempool", last_cursor=cursor, limit=limit, offset=offset)


def get_mempool_events_by_name(
    db, event: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the mempool events filtered by event name
    :param str event: The event to return (e.g. OPEN_ORDER)
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "mempool", where={"event": event}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_mempool_events_by_tx_hash(
    db, tx_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the mempool events filtered by transaction hash
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "mempool", where={"tx_hash": tx_hash}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_event_counts_by_block(
    db, block_index: int, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the event counts of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "messages",
        where={"block_index": block_index},
        select="event, COUNT(*) AS event_count",
        group_by="event",
        cursor_field="event",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_event_count(db, event: str):
    """
    Returns the number of events
    :param int event: The name of the event to return (e.g. CREDIT)
    """
    return select_row(
        db,
        "messages",
        where={"event": event},
        select="event, COUNT(*) AS event_count",
    )


def get_all_events_counts(db, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns the event counts of all blocks
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "messages",
        select="event, COUNT(*) AS event_count",
        group_by="event",
        cursor_field="event",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_credits_by_block(
    db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the credits of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int cursor: The last credit index to return
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "credits",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_credits_by_address(
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the credits of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param int cursor: The last index of the credits to return
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "credits", where={"address": address}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_credits_by_asset(db, asset: str, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns the credits of an asset
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param int cursor: The last index of the credits to return
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "credits", where={"asset": asset}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_debits_by_block(
    db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the debits of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "debits",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_debits_by_address(
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the debits of an address
    :param str address: The address to return (e.g. bc1q7787j6msqczs58asdtetchl3zwe8ruj57p9r9y)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "debits", where={"address": address}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_debits_by_asset(db, asset: str, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns the debits of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "debits", where={"asset": asset}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_sends_by_block(
    db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the sends of a block
    :param int block_index: The index of the block to return (e.g. 840459)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "sends",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_asset(db, asset: str, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns the sends of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "sends", where={"asset": asset}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_expirations(db, block_index: int, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns the expirations of a block
    :param int block_index: The index of the block to return (e.g. 840356)
    :param int cursor: The last index of the expirations to return
    :param int limit: The maximum number of expirations to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "all_expirations",
        where={"block_index": block_index},
        cursor_field="cursor_id",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_cancels(db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns the cancels of a block
    :param int block_index: The index of the block to return (e.g. 839746)
    :param int cursor: The last index of the cancels to return
    :param int limit: The maximum number of cancels to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "cancels",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_destructions(
    db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the destructions of a block
    :param int block_index: The index of the block to return (e.g. 839988)
    :param int cursor: The last index of the destructions to return
    :param int limit: The maximum number of destructions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "destructions",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_issuances_by_block(
    db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the issuances of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int cursor: The last index of the issuances to return
    :param int limit: The maximum number of issuances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "issuances",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_issuances_by_asset(
    db, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the issuances of an asset
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param int cursor: The last index of the issuances to return
    :param int limit: The maximum number of issuances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "issuances", where={"asset": asset}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_issuances_by_address(
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the issuances of an address
    :param str address: The address to return (e.g. 178etygrwEeeyQso9we85rUqYZbkiqzL4A)
    :param int cursor: The last index of the issuances to return
    :param int limit: The maximum number of issuances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "issuances", where={"issuer": address}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_dispenses_by_block(
    db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a block
    :param int block_index: The index of the block to return (e.g. 840322)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispenses",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_dispenser(
    db, dispenser_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a dispenser
    :param str dispenser_hash: The hash of the dispenser to return (e.g. 753787004d6e93e71f6e0aa1e0932cc74457d12276d53856424b2e4088cc542a)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispenses",
        where={"dispenser_tx_hash": dispenser_hash},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_source(
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a source
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "dispenses", where={"source": address}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_dispenses_by_destination(
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a destination
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispenses",
        where={"destination": address},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_asset(
    db, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of an asset
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "dispenses", where={"asset": asset}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_dispenses_by_source_and_asset(
    db, address: str, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispenses",
        where={"source": address, "asset": asset},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_destination_and_asset(
    db, address: str, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispenses",
        where={"destination": address, "asset": asset},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sweeps_by_block(
    db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the sweeps of a block
    :param int block_index: The index of the block to return (e.g. 836519)
    :param int cursor: The last index of the sweeps to return
    :param int limit: The maximum number of sweeps to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "sweeps",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sweeps_by_address(
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the sweeps of an address
    :param str address: The address to return (e.g. 18szqTVJUWwYrtRHq98Wn4DhCGGiy3jZ87)
    :param int cursor: The last index of the sweeps to return
    :param int limit: The maximum number of sweeps to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "sweeps", where={"source": address}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_address_balances(
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the balances of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param int cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "balances",
        where={"address": address},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="address, asset, quantity, MAX(rowid) AS rowid",
        group_by="address, asset",
    )


def get_balance_by_address_and_asset(db, address: str, asset: str):
    """
    Returns the balance of an address and asset
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param str asset: The asset to return (e.g. XCP)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_row(
        db,
        "balances",
        where={"address": address, "asset": asset},
    )


def get_bet_by_feed(
    db, address: str, status: str = "open", cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the bets of a feed
    :param str address: The address of the feed (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the bet (e.g. filled)
    :param int cursor: The last index of the bets to return
    :param int limit: The maximum number of bets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "bets",
        where={"feed_address": address},
        wrap_where={"status": status},
        select="*, MAX(rowid) AS rowid",
        group_by="tx_hash",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_broadcasts_by_source(
    db,
    address: str,
    status: str = "valid",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the broadcasts of a source
    :param str address: The address to return (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the broadcasts to return (e.g. valid)
    :param int cursor: The last index of the broadcasts to return
    :param int limit: The maximum number of broadcasts to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "broadcasts",
        where={"source": address, "status": status},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_burns_by_address(
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the burns of an address
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    :param int cursor: The last index of the burns to return
    :param int limit: The maximum number of burns to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "burns", where={"source": address}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_sends_by_address(
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the sends of an address
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "sends", where={"source": address}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_sends_by_address_and_asset(
    db, address: str, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the sends of an address and asset
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "sends",
        where={"source": address, "asset": asset},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_receive_by_address(
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the receives of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "sends", where={"destination": address}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_receive_by_address_and_asset(
    db, address: str, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the receives of an address and asset
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "sends",
        where={"destination": address, "asset": asset},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispensers_by_address(
    db, address: str, status: int = 0, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispensers of an address
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param int status: The status of the dispensers to return (e.g. 0)
    :param int cursor: The last index of the dispensers to return
    :param int limit: The maximum number of dispensers to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispensers",
        where={"source": address},
        wrap_where={"status": status},
        select="*, MAX(rowid) AS rowid",
        group_by="asset, source",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispensers_by_asset(
    db, asset: str, status: int = 0, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispensers of an asset
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    :param int status: The status of the dispensers to return (e.g. 0)
    :param int cursor: The last index of the dispensers to return
    :param int limit: The maximum number of dispensers to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispensers",
        where={"asset": asset},
        wrap_where={"status": status},
        select="*, MAX(rowid) AS rowid",
        group_by="asset, source",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenser_by_address_and_asset(db, address: str, asset: str):
    """
    Returns the dispenser of an address and an asset
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_row(
        db,
        "dispensers",
        where={"source": address, "asset": asset},
    )


def get_valid_assets(db, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns the valid assets
    :param int cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "issuances",
        where={"status": "valid"},
        cursor_field="asset",
        group_by="asset",
        order="ASC",
        select="asset, asset_longname, description, issuer, divisible, locked",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dividends(db, asset: str, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns the dividends of an asset
    :param str asset: The asset to return (e.g. GMONEYPEPE)
    :param int cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dividends",
        where={"asset": asset, "status": "valid"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_asset_balances(db, asset: str, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns the asset balances
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param int cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "balances",
        where={"asset": asset},
        wrap_where={"quantity__gt": 0},
        cursor_field="address",
        select="address, asset, quantity, MAX(rowid) AS rowid",
        group_by="address, asset",
        order="ASC",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_orders_by_asset(
    db, asset: str, status: str = "open", cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the orders of an asset
    :param str asset: The asset to return (e.g. NEEDPEPE)
    :param str status: The status of the orders to return (e.g. filled)
    :param int cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "orders",
        where=[{"give_asset": asset}, {"get_asset": asset}],
        wrap_where={"status": status},
        select="*, MAX(rowid) AS rowid",
        group_by="tx_hash",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_orders_by_two_assets(
    db,
    asset1: str,
    asset2: str,
    status: str = "open",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the orders to exchange two assets
    :param str asset1: The first asset to return (e.g. NEEDPEPE)
    :param str asset2: The second asset to return (e.g. XCP)
    :param str status: The status of the orders to return (e.g. filled)
    :param int cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    query_result = select_rows(
        db,
        "orders",
        where=[
            {"give_asset": asset1, "get_asset": asset2},
            {"give_asset": asset2, "get_asset": asset1},
        ],
        wrap_where={"status": status},
        select="*, MAX(rowid) AS rowid",
        group_by="tx_hash",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )
    for order in query_result.result:
        order["market_pair"] = f"{asset1}/{asset2}"
        if order["give_asset"] == asset1:
            order["market_dir"] = "SELL"
        else:
            order["market_dir"] = "BUY"
    return QueryResult(query_result.result, query_result.next_cursor, query_result.result_count)


def get_asset_holders(db, asset: str, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns the holders of an asset
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    :param int cursor: The last index of the holder to return
    :param int limit: The maximum number of holders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "all_holders",
        where={"asset": asset},
        order="ASC",
        cursor_field="cursor_id",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_order(db, order_hash: str):
    """
    Returns the information of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. 23f68fdf934e81144cca31ce8ef69062d553c521321a039166e7ba99aede0776)
    """
    return select_row(
        db,
        "orders",
        where={"tx_hash": order_hash},
    )


def get_order_matches_by_order(
    db,
    order_hash: str,
    status: str = "pending",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the order matches of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. 5461e6f99a37a7167428b4a720a52052cd9afed43905f818f5d7d4f56abd0947)
    :param str status: The status of the order matches to return (e.g. completed)
    :param int cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "order_matches",
        where=[{"tx0_hash": order_hash}, {"tx1_hash": order_hash}],  # tx0_hash = ? OR tx1_hash = ?
        select="*, MAX(rowid) AS rowid",
        group_by="id",
        wrap_where={"status": status},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_btcpays_by_order(
    db, order_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the BTC pays of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. 299b5b648f54eacb839f3487232d49aea373cdd681b706d4cc0b5e0b03688db4)
    :param int cursor: The last index of the resolutions to return
    :param int limit: The maximum number of resolutions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "btcpays",
        where={"order_match_id__like": f"%{order_hash}%"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_bet(db, bet_hash: str):
    """
    Returns the information of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 5d097b4729cb74d927b4458d365beb811a26fcee7f8712f049ecbe780eb496ed)
    """
    return select_row(
        db,
        "bets",
        where={"tx_hash": bet_hash},
    )


def get_bet_matches_by_bet(
    db,
    bet_hash: str,
    status: str = "pending",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the bet matches of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 5d097b4729cb74d927b4458d365beb811a26fcee7f8712f049ecbe780eb496ed)
    :param str status: The status of the bet matches (e.g. expired)
    :param int cursor: The last index of the bet matches to return
    :param int limit: The maximum number of bet matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "bet_matches",
        where=[{"tx0_hash": bet_hash}, {"tx1_hash": bet_hash}],  # tx0_hash = ? OR tx1_hash = ?
        select="*, MAX(rowid) AS rowid",
        group_by="id",
        wrap_where={"status": status},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_resolutions_by_bet(
    db, bet_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the resolutions of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 36bbbb7dbd85054dac140a8ad8204eda2ee859545528bd2a9da69ad77c277ace)
    :param int cursor: The last index of the resolutions to return
    :param int limit: The maximum number of resolutions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "bet_match_resolutions",
        where={"bet_match_id__like": f"%{bet_hash}%"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_all_burns(
    db, status: str = "valid", cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the burns
    :param str status: The status of the burns to return (e.g. valid)
    :param int cursor: The last index of the burns to return
    :param int limit: The maximum number of burns to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "burns", where={"status": status}, last_cursor=cursor, limit=limit, offset=offset
    )


def get_dispenser_info_by_hash(db, dispenser_hash: str):
    """
    Returns the dispenser information by tx_hash
    :param str dispenser_hash: The hash of the dispenser to return (e.g. 753787004d6e93e71f6e0aa1e0932cc74457d12276d53856424b2e4088cc542a)
    """
    return select_row(
        db,
        "dispensers",
        where={"tx_hash": dispenser_hash},
    )
