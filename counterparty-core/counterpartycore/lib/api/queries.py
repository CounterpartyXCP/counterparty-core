import json
import typing
from typing import Literal

from counterpartycore.lib import config
from counterpartycore.lib.api.util import divide
from flask import request

OrderStatus = Literal["all", "open", "expired", "filled", "cancelled"]
OrderMatchesStatus = Literal["all", "pending", "completed", "expired"]
BetStatus = Literal["cancelled", "dropped", "expired", "filled", "open"]
DispenserStatus = Literal["all", "open", "closed", "closing", "open_empty_address"]
DispenserStatusNumber = {
    "open": 0,
    "closed": 10,
    "closing": 11,
    "open_empty_address": 1,
}

BetMatchesStatus = Literal[
    "dropped",
    "expired",
    "pending",
    "settled: for equal",
    "settled: for notequal",
    "settled: liquidated for bear",
]
DebitAction = Literal[
    "bet",
    "destroy",
    "dividend",
    "dividend fee",
    "issuance fee",
    "mpma send",
    "open RPS",
    "open dispenser",
    "open dispenser empty addr",
    "open order",
    "refill dispenser",
    "reopen RPS after matching expiration",
    "reset destroy",
    "send",
    "sweep",
    "sweep fee",
]
CreditAction = Literal[
    "Closed: Max dispenses reached",
    "bet settled: for equal",
    "bet settled: for notequal",
    "bet settled: liquidated for bear",
    "btcpay",
    "burn",
    "cancel order",
    "close dispenser",
    "dispense",
    "dispenser close",
    "dividend",
    "feed fee",
    "filled",
    "issuance",
    "mpma send",
    "open dispenser empty addr",
    "order cancelled",
    "order expired",
    "order match",
    "recredit backward quantity",
    "recredit forward quantity",
    "recredit wager",
    "recredit wager remaining",
    "reset issuance",
    "send",
    "sweep",
    "wins",
]

SUPPORTED_SORT_FIELDS = {
    "balances": ["address", "asset", "quantity"],
}


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
    sort=None,
):
    if offset is not None or sort is not None:
        last_cursor = None

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
            elif key.endswith("__notlike"):
                where_field.append(f"{key[:-9]} NOT LIKE ?")
            elif key.endswith("__in"):
                where_field.append(f"{key[:-4]} IN ({','.join(['?'] * len(value))})")
            else:
                where_field.append(f"{key} = ?")
            if key.endswith("__in"):
                bindings += value
            else:
                bindings.append(value)
        and_where_clause = ""
        if where_field:
            and_where_clause = " AND ".join(where_field)
            and_where_clause = f"({and_where_clause})"
            or_where.append(and_where_clause)

    where_clause = ""
    if or_where:
        where_clause = " OR ".join(or_where)

    last_block = config.MEMPOOL_BLOCK_INDEX
    include_unconfirmed = request is not None and request.args.get(
        "unconfirmed", "false"
    ).lower() in ["true", "1"]
    if include_unconfirmed:
        last_block += 1

    no_block_index_tables = ["mempool", "assets_info", "balances"]

    if where_clause:
        where_clause_count = f"WHERE {where_clause} "
        if table not in no_block_index_tables:
            where_clause_count += f"AND block_index < {last_block}"
    elif table not in no_block_index_tables:
        where_clause_count = f"WHERE block_index < {last_block}"
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
        where_clause = f"WHERE {where_clause} "
        if table not in no_block_index_tables:
            where_clause += f"AND block_index < {last_block}"
    elif table not in no_block_index_tables:
        where_clause = f"WHERE block_index < {last_block}"
    else:
        where_clause = ""

    group_by_clause = ""
    if group_by:
        group_by_clause = f"GROUP BY {group_by}"

    if select == "*":
        select = f"*, {cursor_field} AS {cursor_field}"
    elif cursor_field not in select:
        select = f"{select}, {cursor_field} AS {cursor_field}"
    if table not in no_block_index_tables:
        select = f"{select}, CASE WHEN block_index = {config.MEMPOOL_BLOCK_INDEX} THEN FALSE ELSE TRUE END AS confirmed"

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

    order_by = []
    if sort is not None:
        sort_fields = sort.split(",")
        for sort_field in sort_fields:
            if ":" in sort_field:
                sort_name, sort_order = sort_field.split(":")[0:2]
            else:
                sort_name = sort_field
                sort_order = "ASC"
            if sort_order.upper() not in ["ASC", "DESC"]:
                sort_order = "ASC"
            if sort_name in SUPPORTED_SORT_FIELDS.get(table, []):
                order_by.append(f"{sort_name} {sort_order.upper()}")
    if len(order_by) == 0:
        order_by.append(f"{cursor_field} {order}")
    order_by_clause = f"ORDER BY {','.join(order_by)}"

    query = f"{query} {order_by_clause} LIMIT ?"  # nosec B608  # noqa: S608
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

    if table in ["messages", "mempool"]:
        for row in result:
            if "params" not in row:
                break
            row["params"] = json.loads(row["params"])

    return QueryResult(result, next_cursor, result_count)


def select_row(db, table, where, select="*", group_by=""):
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


def get_transactions(db, cursor: int = None, limit: int = 10, offset: int = None):
    """
    Returns the list of the last ten transactions
    :param int cursor: The index of the most recent transactions to return (e.g. 2736157)
    :param int limit: The number of transactions to return (e.g. 2)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "transactions", cursor_field="tx_index", last_cursor=cursor, limit=limit, offset=offset
    )


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


def get_transactions_by_address(
    db, address: str, cursor: int = None, limit: int = 10, offset: int = None
):
    """
    Returns the transactions of an address
    :param str address: The address to return (e.g. 1PHnxfHgojebxzW6muz8zfbE4bkDtbEudx)
    :param int cursor: The last transaction index to return (e.g. 2736469)
    :param int limit: The maximum number of transactions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "transactions",
        where={"source": address},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_transactions_by_addresses(
    db, addresses: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the transactions of a list of addresses
    :param str addresses: Comma separated list of addresses to return (e.g. 1PHnxfHgojebxzW6muz8zfbE4bkDtbEudx,1PHnxfHgojebxzW6muz8zfbE4bkDtbEudx)
    :param int cursor: The last transaction index to return (e.g. 2736469)
    :param int limit: The maximum number of transactions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "transactions",
        where=[{"source__in": addresses.split(",")}],
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_transaction_by_hash(db, tx_hash: str):
    """
    Returns a transaction by its hash.
    :param tx_hash: The hash of the transaction (e.g. 876a6cfbd4aa22ba4fa85c2e1953a1c66649468a43a961ad16ea4d5329e3e4c5)
    """
    return select_row(
        db,
        "transactions",
        where={"tx_hash": tx_hash},
    )


def get_transaction_by_tx_index(db, tx_index: int):
    """
    Returns a transaction by its index.
    :param tx_index: The index of the transaction (e.g. 10000)
    """
    return select_row(
        db,
        "transactions",
        where={"tx_index": tx_index},
    )


def get_all_events(
    db, event_name: str = None, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns all events
    :param str event_name: Comma separated list of events to return (e.g. CREDIT,DEBIT)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = None
    if event_name:
        where = [{"event": event} for event in event_name.split(",")]
    return select_rows(
        db,
        "messages",
        where=where,
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index",
    )


def get_events_by_block(
    db,
    block_index: int,
    event_name: str = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"block_index": block_index}
    if event_name:
        where = [{"event": event, "block_index": block_index} for event in event_name.split(",")]
    return select_rows(
        db,
        "messages",
        where=where,
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash",
    )


def get_events_by_transaction_hash(
    db,
    tx_hash: str,
    event_name: str = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"tx_hash": tx_hash}
    if event_name:
        where = [{"event": event, "tx_hash": tx_hash} for event in event_name.split(",")]
    return select_rows(
        db,
        "messages",
        where=where,
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index",
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
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index",
    )


def get_events_by_transaction_index(
    db,
    tx_index: int,
    event_name: str = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. 1000)
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    query_result = select_row(db, "transactions", where={"tx_index": tx_index})
    if query_result:
        return get_events_by_transaction_hash(
            db,
            query_result.result["tx_hash"],
            event_name=event_name,
            cursor=cursor,
            limit=limit,
            offset=offset,
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
    :param int cursor: The last event index to return
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
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, rowid AS rowid",
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
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index",
    )


def get_events_by_addresses(
    db, addresses: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the events of a list of addresses
    :param str addresses: Comma separated list of addresses to return (e.g. 1EC2K34dNc41pk63rc7bMQjbndqfoqQg4V,bc1q5mqesdy0gaj0suzxg4jx7ycmpw66kygdyn80mg)
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    events = select_rows(
        db,
        "address_events",
        where=[{"address__in": addresses.split(",")}],
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )
    events_indexes = [event["event_index"] for event in events.result]
    result = select_rows(
        db,
        "messages",
        where=[{"message_index__in": events_indexes}],
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index",
    )
    return QueryResult(result.result, events.next_cursor, events.result_count)


def get_all_mempool_events(
    db, event_name: str = None, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns all mempool events
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = None
    if event_name:
        where = [{"event": event} for event in event_name.split(",")]
    select = "tx_hash, event, bindings AS params"
    return select_rows(
        db, "mempool", where=where, last_cursor=cursor, limit=limit, offset=offset, select=select
    )


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
    select = "tx_hash, event, bindings AS params"
    return select_rows(
        db,
        "mempool",
        where={"event": event},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select=select,
    )


def get_mempool_events_by_tx_hash(
    db,
    tx_hash: str,
    event_name: str = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the mempool events filtered by transaction hash
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"tx_hash": tx_hash}
    if event_name:
        where = [{"event": event, "tx_hash": tx_hash} for event in event_name.split(",")]
    select = "tx_hash, event, bindings AS params"
    return select_rows(
        db, "mempool", where=where, last_cursor=cursor, limit=limit, offset=offset, select=select
    )


def get_mempool_events_by_addresses(db, addresses: str, cursor: int = None, limit: int = 100):
    """
    Returns the mempool events of a list of addresses
    :param str addresses: Comma separated list of addresses to return (e.g. 1EC2K34dNc41pk63rc7bMQjbndqfoqQg4V,bc1q5mqesdy0gaj0suzxg4jx7ycmpw66kygdyn80mg)
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    where = []
    for address in addresses.split(","):
        where.append({"addresses__like": f"%{address}%"})
    select = "tx_hash, event, bindings AS params"
    result = select_rows(
        db,
        "mempool",
        where=where,
        last_cursor=cursor,
        limit=limit,
        select=select,
    )
    return result


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
    db,
    block_index: int,
    action: CreditAction = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the credits of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param str action: The action to filter by
    :param int cursor: The last credit index to return
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"block_index": block_index, "quantity__gt": 0}
    if action:
        where["calling_function"] = action
    return select_rows(
        db,
        "credits",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_credits_by_address(
    db,
    address: str,
    action: CreditAction = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the credits of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param str action: The action to filter by
    :param int cursor: The last index of the credits to return
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"address": address, "quantity__gt": 0}
    if action:
        where["calling_function"] = action
    return select_rows(db, "credits", where=where, last_cursor=cursor, limit=limit, offset=offset)


def get_credits_by_asset(
    db,
    asset: str,
    action: CreditAction = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the credits of an asset
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param str action: The action to filter by
    :param int cursor: The last index of the credits to return
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"asset": asset.upper(), "quantity__gt": 0}
    if action:
        where["calling_function"] = action
    return select_rows(db, "credits", where=where, last_cursor=cursor, limit=limit, offset=offset)


def get_debits_by_block(
    db,
    block_index: int,
    action: DebitAction = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the debits of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param str action: The action to filter by
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"block_index": block_index, "quantity__gt": 0}
    if action:
        where["action"] = action
    return select_rows(
        db,
        "debits",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_debits_by_address(
    db,
    address: str,
    action: DebitAction = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the debits of an address
    :param str address: The address to return (e.g. bc1q7787j6msqczs58asdtetchl3zwe8ruj57p9r9y)
    :param str action: The action to filter by
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"address": address, "quantity__gt": 0}
    if action:
        where["action"] = action
    return select_rows(db, "debits", where=where, last_cursor=cursor, limit=limit, offset=offset)


def get_debits_by_asset(
    db,
    asset: str,
    action: DebitAction = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the debits of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param str action: The action to filter by
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"asset": asset.upper(), "quantity__gt": 0}
    if action:
        where["action"] = action
    return select_rows(db, "debits", where=where, last_cursor=cursor, limit=limit, offset=offset)


def get_sends(db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns all the sends include Enhanced and MPMA sends
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "sends",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_block(
    db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the sends, include Enhanced and MPMA sends, of a block
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


def get_sends_by_transaction_hash(
    db, tx_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the sends, include Enhanced and MPMA sends, of a block
    :param str tx_hash: The hash of the transaction to return (e.g. c7497d0c427083df81a884ff39e282e176943a436a82f4c0a0878afdc601229f)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "sends",
        where={"tx_hash": tx_hash},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_asset(db, asset: str, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns the sends, include Enhanced and MPMA sends, of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "sends", where={"asset": asset.upper()}, last_cursor=cursor, limit=limit, offset=offset
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


def get_issuances(db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns all the issuances
    :param int cursor: The last index of the issuances to return
    :param int limit: The maximum number of issuances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "issuances",
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


def get_issuance_by_transaction_hash(db, tx_hash: str):
    """
    Returns the issuances of a block
    :param str tx_hash: The hash of the transaction to return (e.g. 54cb76d13f9e496294abdf40e87fa266e4cc040219b76c67fa819eaaaee4195a)
    """
    return select_row(db, "issuances", where={"tx_hash": tx_hash})


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
        db,
        "issuances",
        where=[{"asset": asset.upper()}, {"UPPER(asset_longname)": asset.upper()}],
        last_cursor=cursor,
        limit=limit,
        offset=offset,
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


def get_dispenses(db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns all the dispenses
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispenses",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
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


def get_dispenses_by_transaction_hash(
    db, tx_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a block
    :param str tx_hash: The hash of the transaction to return (e.g. 5a7e6a0f8bbff69f5e6fefa75eb919b913649a14e68cca41af38737f49e5be92)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispenses",
        where={"tx_hash": tx_hash},
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
    :param str address: The address to return (e.g. bc1qq735dv8peps2ayr3qwwwdwylq4ddwcgrpyg9r2)
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
    :param str address: The address to return (e.g. bc1qzcdkhnexpjc8wvkyrpyrsn0f5xzcpu877mjmgj)
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
    :param str asset: The asset to return (e.g. FLOCK)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispenses",
        where={"asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_source_and_asset(
    db, address: str, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. bc1qq735dv8peps2ayr3qwwwdwylq4ddwcgrpyg9r2)
    :param str asset: The asset to return (e.g. FLOCK)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispenses",
        where={"source": address, "asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_destination_and_asset(
    db, address: str, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. bc1qzcdkhnexpjc8wvkyrpyrsn0f5xzcpu877mjmgj)
    :param str asset: The asset to return (e.g. FLOCK)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispenses",
        where={"destination": address, "asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sweeps(db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns all sweeps
    :param int cursor: The last index of the sweeps to return
    :param int limit: The maximum number of sweeps to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "sweeps",
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


def get_sweep_by_transaction_hash(db, tx_hash: str):
    """
    Returns the sweeps of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 8cacf853c989393ce21e05e286958a3c650b94ac6f92807114552e1492e9c937)
    """
    return select_rows(
        db,
        "sweeps",
        where={"tx_hash": tx_hash},
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
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None, sort: str = None
):
    """
    Returns the balances of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param int cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the balances to return (overrides the `cursor` parameter) (e.g. quantity:desc)
    """
    return select_rows(
        db,
        "balances",
        where={"address": address, "quantity__gt": 0},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="address, asset, quantity",
        sort=sort,
    )


def get_balances_by_addresses(
    db, addresses: str, cursor: int = None, limit: int = 100, offset: int = None, sort: str = None
):
    """
    Returns the balances of several addresses
    :param str addresses: Comma separated list of addresses (e.g. 1m8vd7FPHtS8fu6NQduCibfjCt3T8UPoz,1fUcHBfCgVqNwFmECZ2SSjKBvnFfWbKbr)
    :param int cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the balances to return (overrides the `cursor` parameter) (e.g. quantity:desc)
    """
    assets_result = select_rows(
        db,
        "balances",
        select="DISTINCT asset AS asset",
        where={"address__in": addresses.split(","), "quantity__gt": 0},
        order="ASC",
        cursor_field="asset",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )
    assets = [asset["asset"] for asset in assets_result.result]

    balances = select_rows(
        db,
        "balances",
        where={"address__in": addresses.split(","), "asset__in": assets, "quantity__gt": 0},
        select="address, asset, quantity",
        order="ASC",
        cursor_field="asset",
        sort=sort,
    ).result

    result = []
    if len(balances) > 0:
        current_balances = {
            "asset": balances[0]["asset"],
            "total": 0,
            "addresses": [],
        }
        for balance in balances:
            if balance["asset"] != current_balances["asset"]:
                result.append(current_balances)
                current_balances = {
                    "asset": balance["asset"],
                    "total": 0,
                    "addresses": [],
                }
            current_balances["total"] += balance["quantity"]
            current_balances["addresses"].append(
                {
                    "address": balance["address"],
                    "quantity": balance["quantity"],
                }
            )

    return QueryResult(result, assets_result.next_cursor, assets_result.result_count)


def get_balance_by_address_and_asset(db, address: str, asset: str):
    """
    Returns the balance of an address and asset
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param str asset: The asset to return (e.g. XCP)
    """
    return select_row(
        db,
        "balances",
        select="address, asset, quantity",
        where={"address": address, "asset": asset.upper()},
    )


def get_bets(
    db, status: BetStatus = "open", cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the bets of a feed
    :param str status: The status of the bet (e.g. filled)
    :param int cursor: The last index of the bets to return
    :param int limit: The maximum number of bets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "bets",
        where={"status": status},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_bet_by_feed(
    db,
    address: str,
    status: BetStatus = "open",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
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
        where={"feed_address": address, "status": status},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_valid_broadcasts(
    db,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns all valid broadcasts
    :param int cursor: The last index of the broadcasts to return
    :param int limit: The maximum number of broadcasts to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "broadcasts",
        where={"status": "valid"},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_broadcasts_by_source(
    db,
    address: str,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the broadcasts of a source
    :param str address: The address to return (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param int cursor: The last index of the broadcasts to return
    :param int limit: The maximum number of broadcasts to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "broadcasts",
        where={"source": address, "status": "valid"},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_broadcast_by_transaction_hash(db, tx_hash: str):
    """
    Returns the broadcast of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 916944b5ae39289615ea55c91ada4605300d6213edf131db3913cf42f0f1b717)
    """
    return select_row(
        db,
        "broadcasts",
        where={"tx_hash": tx_hash},
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
    Returns the sends, include Enhanced and MPMA sends, of an address
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
    Returns the sends, include Enhanced and MPMA sends, of an address and asset
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "sends",
        where={"source": address, "asset": asset.upper()},
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
        where={"destination": address, "asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def preprare_dispenser_where(status, other_conditions=None):
    where = []
    statuses = status.split(",")
    for status in statuses:
        if status == "all":
            where = other_conditions or {}
            break
        if status in DispenserStatusNumber:
            where_status = {"status": DispenserStatusNumber[status]}
            if other_conditions:
                where_status.update(other_conditions)
            where.append(where_status)
    return where


def get_dispensers(
    db, status: DispenserStatus = "all", cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispensers of an address
    :param str status: The status of the dispensers to return (e.g. open)
    :param int cursor: The last index of the dispensers to return (e.g. 319619)
    :param int limit: The maximum number of dispensers to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """

    return select_rows(
        db,
        "dispensers",
        where=preprare_dispenser_where(status),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispensers_by_address(
    db,
    address: str,
    status: DispenserStatus = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the dispensers of an address
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param str status: The status of the dispensers to return (e.g. open)
    :param int cursor: The last index of the dispensers to return
    :param int limit: The maximum number of dispensers to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispensers",
        where=preprare_dispenser_where(status, {"source": address}),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispensers_by_asset(
    db,
    asset: str,
    status: DispenserStatus = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the dispensers of an asset
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    :param str status: The status of the dispensers to return (e.g. open)
    :param int cursor: The last index of the dispensers to return
    :param int limit: The maximum number of dispensers to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dispensers",
        where=preprare_dispenser_where(status, {"asset": asset.upper()}),
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
        where={"source": address, "asset": asset.upper()},
    )


def get_valid_assets(
    db, named: bool = None, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the valid assets
    :param bool named: Whether to return only named assets (e.g. true)
    :param int cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {}
    if named is not None:
        if named:
            where["asset__notlike"] = "A%"
        else:
            where["asset__like"] = "A%"

    return select_rows(
        db,
        "assets_info",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_asset(db, asset: str):
    """
    Returns an asset by its name
    :param str asset: The name of the asset to return (e.g. PEPECASH)
    """
    where = [{"asset": asset.upper()}, {"UPPER(asset_longname)": asset.upper()}]
    return select_row(
        db,
        "assets_info",
        where=where,
    )


def get_subassets_by_asset(
    db, asset: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns asset subassets
    :param str asset: The name of the asset to return (e.g. XCPTORCH)
    :param int cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = [{"asset_longname__like": f"{asset.upper()}.%"}]
    return select_rows(
        db,
        "assets_info",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_valid_assets_by_issuer(
    db, address: str, named: bool = None, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the valid assets of an issuer
    :param str address: The issuer to return (e.g. 1GQhaWqejcGJ4GhQar7SjcCfadxvf5DNBD)
    :param bool named: Whether to return only named assets (e.g. true)
    :param int cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"issuer": address}
    if named is not None:
        if named:
            where["asset__notlike"] = "A%"
        else:
            where["asset__like"] = "A%"

    return select_rows(
        db,
        "assets_info",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dividends(db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns all the dividends
    :param int cursor: The last index of the dividend to return
    :param int limit: The maximum number of dividend to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    cursorsb = db.cursor()
    cursorsb.execute("SELECT * FROM dividends")

    return select_rows(
        db,
        "dividends",
        # where={"status": "valid"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dividend(db, dividend_hash: str):
    """
    Returns a dividend by its hash
    :param str dividend_hash: The hash of the dividend to return (e.g. d74242f4789f98c0ff6df44fe21a2cf614f02e694c1e34f1193d3a8f35cc01a0)
    """
    return select_row(
        db,
        "dividends",
        where={"tx_hash": dividend_hash},
    )


def get_dividends_by_asset(
    db, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dividends of an asset
    :param str asset: The asset to return (e.g. GMONEYPEPE)
    :param int cursor: The last index of the dividend to return
    :param int limit: The maximum number of dividend to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dividends",
        where={"asset": asset.upper(), "status": "valid"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dividends_distributed_by_address(
    db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dividends distributed by an address
    :param str address: The address to return (e.g. 1PHnxfHgojebxzW6muz8zfbE4bkDtbEudx)
    :param int cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "dividends",
        where={"source": address, "status": "valid"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dividend_disribution(
    db, dividend_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns a dividend distribution by its hash
    :param str dividend_hash: The hash of the dividend distribution to return (e.g. 9b7b9
    :param int cursor: The last index of the credit to return
    :param int limit: The maximum number of credit to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "credits",
        where={"event": dividend_hash},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_asset_balances(
    db, asset: str, cursor: str = None, limit: int = 100, offset: int = None, sort: str = None
):
    """
    Returns the asset balances
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param int cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the balances to return (overrides the `cursor` parameter) (e.g. quantity:desc)
    """
    return select_rows(
        db,
        "balances",
        where={"asset": asset.upper(), "quantity__gt": 0},
        cursor_field="address",
        select="address, asset, quantity",
        order="ASC",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def prepare_order_where_status(status, arg_type, other_conditions=None):
    where = []
    statuses = status.split(",")
    for status in statuses:
        if status == "all":
            where = [other_conditions] if other_conditions else []
            break
        if status in typing.get_args(arg_type):
            where_status = {"status": status}
            if other_conditions:
                where_status.update(other_conditions)
            where.append(where_status)
    return where


def prepare_order_where(status, other_conditions=None):
    return prepare_order_where_status(status, OrderStatus, other_conditions=other_conditions)


def prepare_order_matches_where(status, other_conditions=None):
    return prepare_order_where_status(status, OrderMatchesStatus, other_conditions=other_conditions)


def get_orders(
    db, status: OrderStatus = "all", cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns all the orders
    :param str status: The status of the orders to return (e.g. filled)
    :param int cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "orders",
        cursor_field="tx_index",
        where=prepare_order_where(status),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_orders_by_asset(
    db,
    asset: str,
    status: OrderStatus = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the orders of an asset
    :param str asset: The asset to return (e.g. NEEDPEPE)
    :param str status: The status of the orders to return (e.g. filled)
    :param int cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = prepare_order_where(status, {"give_asset": asset.upper()}) + prepare_order_where(
        status, {"get_asset": asset.upper()}
    )

    return select_rows(
        db,
        "orders",
        cursor_field="tx_index",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_orders_by_address(
    db,
    address: str,
    status: OrderStatus = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the orders of an address
    :param str address: The address to return (e.g. 1H875qrfLT3USeA1zDhngDMtb7VsmAdL8c)
    :param str status: The status of the orders to return (e.g. filled)
    :param int cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db,
        "orders",
        cursor_field="tx_index",
        where=prepare_order_where(status, {"source": address}),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_orders_by_two_assets(
    db,
    asset1: str,
    asset2: str,
    status: OrderStatus = "all",
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
    where = prepare_order_where(
        status, {"give_asset": asset1.upper(), "get_asset": asset2.upper()}
    ) + prepare_order_where(status, {"give_asset": asset2.upper(), "get_asset": asset1.upper()})
    query_result = select_rows(
        db,
        "orders",
        cursor_field="tx_index",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )
    for order in query_result.result:
        order["market_pair"] = f"{asset1}/{asset2}"
        if order["give_asset"] == asset1:
            order["market_dir"] = "SELL"
            order["market_price"] = divide(order["give_quantity"], order["get_quantity"])
        else:
            order["market_dir"] = "BUY"
            order["market_price"] = divide(order["get_quantity"], order["give_quantity"])
    return QueryResult(query_result.result, query_result.next_cursor, query_result.result_count)


def get_asset_holders(db, asset: str, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns the holders of an asset
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    :param int cursor: The last index of the holder to return
    :param int limit: The maximum number of holders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    table_name = "xcp_holders" if asset.upper() == "XCP" else "asset_holders"
    return select_rows(
        db,
        table_name,
        where={"asset": asset.upper()},
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
    status: OrderMatchesStatus = "all",
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
    where = prepare_order_matches_where(
        status, {"tx0_hash": order_hash}
    ) + prepare_order_matches_where(status, {"tx1_hash": order_hash})
    return select_rows(
        db,
        "order_matches",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_order_matches_by_asset(
    db,
    asset: str,
    status: OrderMatchesStatus = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the orders of an asset
    :param str asset: The asset to return (e.g. NEEDPEPE)
    :param str status: The status of the order matches to return (e.g. completed)
    :param int cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = prepare_order_matches_where(
        status, {"forward_asset": asset.upper()}
    ) + prepare_order_matches_where(status, {"backward_asset": asset.upper()})

    return select_rows(
        db,
        "order_matches",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_order_matches_by_two_assets(
    db,
    asset1: str,
    asset2: str,
    status: OrderMatchesStatus = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the orders to exchange two assets
    :param str asset1: The first asset to return (e.g. NEEDPEPE)
    :param str asset2: The second asset to return (e.g. XCP)
    :param str status: The status of the order matches to return (e.g. completed)
    :param int cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = prepare_order_matches_where(
        status, {"forward_asset": asset1.upper(), "backward_asset": asset2.upper()}
    ) + prepare_order_matches_where(
        status, {"forward_asset": asset2.upper(), "backward_asset": asset1.upper()}
    )
    query_result = select_rows(
        db,
        "order_matches",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )
    for order in query_result.result:
        order["market_pair"] = f"{asset1}/{asset2}"
        if order["forward_asset"] == asset1:
            order["market_dir"] = "SELL"
            order["market_price"] = divide(order["forward_quantity"], order["backward_quantity"])
        else:
            order["market_dir"] = "BUY"
            order["market_price"] = divide(order["backward_quantity"], order["forward_quantity"])
    return QueryResult(query_result.result, query_result.next_cursor, query_result.result_count)


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
    status: BetMatchesStatus = "pending",
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
        where=[
            {"tx0_hash": bet_hash, "status": status},
            {"tx1_hash": bet_hash, "status": status},
        ],  # tx0_hash = ? OR tx1_hash = ?
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


def get_all_burns(db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns the burns
    :param str status: The status of the burns to return (e.g. valid)
    :param int cursor: The last index of the burns to return
    :param int limit: The maximum number of burns to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        db, "burns", where={"status": "valid"}, last_cursor=cursor, limit=limit, offset=offset
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
