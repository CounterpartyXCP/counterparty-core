import json
import typing
from typing import Literal

from counterpartycore.lib.api.util import divide
from sentry_sdk import start_span as start_sentry_span

OrderStatus = Literal["all", "open", "expired", "filled", "cancelled"]
OrderMatchesStatus = Literal["all", "pending", "completed", "expired"]
BetStatus = Literal["cancelled", "dropped", "expired", "filled", "open"]
DispenserStatus = Literal["all", "open", "closed", "closing", "open_empty_address"]
DispenserStatusNumber = {"open": 0, "closed": 10, "closing": 11, "open_empty_address": 1}
DispenserStatusNumberInverted = {value: key for key, value in DispenserStatusNumber.items()}
FairmintersStatus = Literal["all", "open", "closed", "pending"]
IssuancesAssetEvents = Literal[
    "all",
    "creation",
    "reissuance",
    "lock_quantity",
    "reset",
    "change_description",
    "transfer",
    "open_fairminter",
    "fairmint",
    "lock_description",
]

BetMatchesStatus = Literal[
    "dropped",
    "expired",
    "pending",
    "settled: for equal",
    "settled: for notequal",
    "settled: liquidated for bear",
]
DebitAction = Literal[
    None,
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
    None,
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
BalanceType = Literal["all", "utxo", "address"]
TransactionType = Literal[
    "all",
    "bet",
    "broadcast",
    "btcpay",
    "cancel",
    "destroy",
    "dispenser",
    "dispense",
    "dividend",
    "issuance",
    "order",
    "send",
    "enhanced_send",
    "mpma",
    "rps",
    "rpsresolve",
    "sweep",
    "fairminter",
    "fairmint",
    "attach",
    "detach",
    "utxomove" "unknown",
]

SUPPORTED_SORT_FIELDS = {
    "balances": ["address", "asset", "quantity"],
    "order_matches": [
        "block_index",
        "forward_asset",
        "forward_quantity",
        "backward_asset",
        "backward_quantity",
        "match_expire_index",
    ],
    "orders": [
        "block_index",
        "give_asset",
        "give_quantity",
        "get_asset",
        "get_quantity",
        "expiration",
        "give_price",
        "get_price",
    ],
    "dispensers": [
        "block_index",
        "asset",
        "give_quantity",
        "give_remaining",
        "dispense_count",
        "satoshirate",
        "price",
    ],
    "xcp_holders": [
        "quantity",
        "holding_type",
        "status",
    ],
    "asset_holders": [
        "quantity",
        "holding_type",
        "status",
    ],
}

ADDRESS_FIELDS = ["source", "address", "issuer", "destination"]


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
                bindings.append(value)
            elif key.endswith("__like"):
                where_field.append(f"{key[:-6]} LIKE ?")
                bindings.append(value)
            elif key.endswith("__notlike"):
                where_field.append(f"{key[:-9]} NOT LIKE ?")
                bindings.append(value)
            elif key.endswith("__in"):
                where_field.append(f"{key[:-4]} IN ({','.join(['?'] * len(value))})")
                bindings += value
            elif key.endswith("__notnull"):
                where_field.append(f"{key[:-9]} IS NOT NULL")
            else:
                if key in ADDRESS_FIELDS and len(value.split(",")) > 1:
                    where_field.append(f"{key} IN ({','.join(['?'] * len(value.split(',')))})")
                    bindings += value.split(",")
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
        where_clause_count = f"WHERE {where_clause} "
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
        where_clause = f"WHERE ({where_clause}) "
    else:
        where_clause = ""

    group_by_clause = ""
    if group_by:
        group_by_clause = f"GROUP BY {group_by}"

    if select == "*":
        select = f"*, {cursor_field} AS {cursor_field}"
    elif cursor_field not in select:
        select = f"{select}, {cursor_field} AS {cursor_field}"
    if table in ["transactions", "sends", "btcpays", "sweeps", "dispenses"]:
        select += ", NULLIF(destination, '') AS destination"

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

    with start_sentry_span(op="db.sql.execute", description=query) as sql_span:
        sql_span.set_tag("db.system", "sqlite3")
        cursor.execute(query, bindings)
        result = cursor.fetchall()

    with start_sentry_span(op="db.sql.execute", description=query_count) as sql_span:
        sql_span.set_tag("db.system", "sqlite3")
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
    query_result = select_rows(db, table, where, limit=1, select=select, group_by=group_by)
    if query_result.result:
        return QueryResult(query_result.result[0], None, 1)
    return None


GET_BLOCKS_WHERE = {
    "ledger_hash__notnull": None,
}


def get_blocks(ledger_db, cursor: str = None, limit: int = 10, offset: int = None):
    """
    Returns the list of the last ten blocks
    :param str cursor: The index of the most recent block to return (e.g. $LAST_BLOCK_INDEX)
    :param int limit: The number of blocks to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "blocks",
        cursor_field="block_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        where=GET_BLOCKS_WHERE,
    )


def get_block_by_height(ledger_db, block_index: int):
    """
    Return the information of a block
    :param int block_index: The index of the block to return (e.g. $LAST_BLOCK_INDEX)
    """
    return select_row(ledger_db, "blocks", where=GET_BLOCKS_WHERE | {"block_index": block_index})


def get_block_by_hash(ledger_db, block_hash: str):
    """
    Return the information of a block
    :param str block_hash: The index of the block to return (e.g. $LAST_BLOCK_HASH)
    """
    return select_row(ledger_db, "blocks", where=GET_BLOCKS_WHERE | {"block_hash": block_hash})


def get_last_block(ledger_db):
    """
    Return the information of the last block
    """
    return select_row(
        ledger_db,
        "blocks",
        where=GET_BLOCKS_WHERE,
    )


def prepare_transactions_where(type, other_conditions=None):
    where = []
    type_list = type.split(",")
    for transaction_type in type_list:
        if transaction_type == "all":
            where = [other_conditions] if other_conditions else []
            break
        if transaction_type in typing.get_args(TransactionType):
            where_status = {"transaction_type": transaction_type}
            if other_conditions:
                where_status.update(other_conditions)
            where.append(where_status)
    return where


def get_transactions(
    ledger_db,
    type: TransactionType = "all",
    cursor: str = None,
    limit: int = 10,
    offset: int = None,
):
    """
    Returns the list of the last ten transactions
    :param str type: The type of the transaction to return
    :param str cursor: The index of the most recent transactions to return (e.g. $LAST_TX_INDEX)
    :param int limit: The number of transactions to return (e.g. 2)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "transactions",
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        where=prepare_transactions_where(type),
    )


def get_transactions_by_block(
    ledger_db,
    block_index: int,
    type: TransactionType = "all",
    cursor: str = None,
    limit: int = 10,
    offset: int = None,
):
    """
    Returns the transactions of a block
    :param int block_index: The index of the block to return (e.g. $LAST_BLOCK_INDEX)
    :param str type: The type of the transaction to return
    :param str cursor: The last transaction index to return (e.g. $LAST_TX_INDEX)
    :param int limit: The maximum number of transactions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"block_index": block_index}
    return select_rows(
        ledger_db,
        "transactions",
        where=prepare_transactions_where(type, where),
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_transactions_by_address(
    ledger_db,
    address: str,
    type: TransactionType = "all",
    cursor: str = None,
    limit: int = 10,
    offset: int = None,
):
    """
    Returns the transactions of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str type: The type of the transaction to return
    :param str cursor: The last transaction index to return (e.g. $LAST_TX_INDEX)
    :param int limit: The maximum number of transactions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"source": address}
    return select_rows(
        ledger_db,
        "transactions",
        where=prepare_transactions_where(type, where),
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_transactions_by_addresses(
    ledger_db,
    addresses: str,
    type: TransactionType = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the transactions of a list of addresses
    :param str addresses: Comma separated list of addresses to return (e.g. $ADDRESS_1,$ADDRESS_2)
    :param str type: The type of the transaction to return
    :param str cursor: The last transaction index to return (e.g. $LAST_TX_INDEX)
    :param int limit: The maximum number of transactions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"source__in": addresses.split(",")}
    return select_rows(
        ledger_db,
        "transactions",
        where=prepare_transactions_where(type, where),
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_transaction_by_hash(ledger_db, tx_hash: str):
    """
    Returns a transaction by its hash.
    :param tx_hash: The hash of the transaction (e.g. $LAST_TX_HASH)
    """
    return select_row(
        ledger_db,
        "transactions",
        where={"tx_hash": tx_hash},
    )


def get_transaction_by_tx_index(ledger_db, tx_index: int):
    """
    Returns a transaction by its index.
    :param tx_index: The index of the transaction (e.g. $LAST_TX_INDEX)
    """
    return select_row(
        ledger_db,
        "transactions",
        where={"tx_index": tx_index},
    )


def get_all_events(
    ledger_db, event_name: str = None, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns all events
    :param str event_name: Comma separated list of events to return
    :param str cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = None
    if event_name:
        where = [{"event": event} for event in event_name.split(",")]
    return select_rows(
        ledger_db,
        "messages",
        where=where,
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index",
    )


def get_events_by_block(
    ledger_db,
    block_index: int,
    event_name: str = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a block
    :param int block_index: The index of the block to return (e.g. $LAST_EVENT_BLOCK)
    :param str event_name: Comma separated list of events to return
    :param str cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"block_index": block_index}
    if event_name:
        where = [{"event": event, "block_index": block_index} for event in event_name.split(",")]
    return select_rows(
        ledger_db,
        "messages",
        where=where,
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash",
    )


def get_events_by_transaction_hash(
    ledger_db,
    tx_hash: str,
    event_name: str = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_EVENT_TX_HASH)
    :param str event_name: Comma separated list of events to return
    :param str cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"tx_hash": tx_hash}
    if event_name:
        where = [{"event": event, "tx_hash": tx_hash} for event in event_name.split(",")]
    return select_rows(
        ledger_db,
        "messages",
        where=where,
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index",
    )


def get_events_by_transaction_hash_and_event(
    ledger_db, tx_hash: str, event: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_EVENT_TX_HASH)
    :param str event: The event to filter by (e.g. CREDIT)
    :param str cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "messages",
        where={"tx_hash": tx_hash, "event": event},
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index",
    )


def get_events_by_transaction_index(
    ledger_db,
    tx_index: int,
    event_name: str = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. $LAST_EVENT_TX_INDEX)
    :param str event_name: Comma separated list of events to return
    :param str cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    query_result = select_row(ledger_db, "transactions", where={"tx_index": tx_index})
    if query_result:
        return get_events_by_transaction_hash(
            ledger_db,
            query_result.result["tx_hash"],
            event_name=event_name,
            cursor=cursor,
            limit=limit,
            offset=offset,
        )
    return None


def get_events_by_transaction_index_and_event(
    ledger_db, tx_index: int, event: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. $LAST_EVENT_TX_INDEX)
    :param str event: The event to filter by (e.g. CREDIT)
    :param str cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    query_result = select_row(ledger_db, "transactions", where={"tx_index": tx_index})
    if query_result:
        return get_events_by_transaction_hash_and_event(
            ledger_db,
            query_result.result["tx_hash"],
            event,
            cursor=cursor,
            limit=limit,
            offset=offset,
        )
    return None


def get_events_by_block_and_event(
    ledger_db,
    block_index: int,
    event: str,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a block filtered by event
    :param int block_index: The index of the block to return (e.g. $LAST_EVENT_BLOCK)
    :param str event: The event to filter by (e.g. CREDIT)
    :param str cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    if event == "count":
        return get_event_counts_by_block(ledger_db, block_index=block_index)
    return select_rows(
        ledger_db,
        "messages",
        where={"block_index": block_index, "event": event},
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash",
    )


def get_event_by_index(ledger_db, event_index: int):
    """
    Returns the event of an index
    :param int event_index: The index of the event to return (e.g. $LAST_EVENT_INDEX)
    """
    return select_row(
        ledger_db,
        "messages",
        where={"message_index": event_index},
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, rowid AS rowid",
    )


def get_events_by_name(
    ledger_db, event: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the events filtered by event name
    :param str event: The event to return (e.g. CREDIT)
    :param str cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "messages",
        where={"event": event},
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index",
    )


def get_events_by_addresses(
    ledger_db,
    state_db,
    addresses: str,
    event_name: str = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a list of addresses
    :param str addresses: Comma separated list of addresses to return (e.g. $ADDRESS_1,$ADDRESS_2)
    :param str event_name: Comma separated list of events to return
    :param str cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    events = select_rows(
        state_db,
        "address_events",
        where=[{"address__in": addresses.split(",")}],
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )
    events_indexes = [event["event_index"] for event in events.result]
    where = {"message_index__in": events_indexes}
    if event_name:
        where["event__in"] = event_name.split(",")
    result = select_rows(
        ledger_db,
        "messages",
        where=where,
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index",
    )
    return QueryResult(result.result, events.next_cursor, events.result_count)


def get_all_mempool_events(
    ledger_db,
    event_name: str = None,
    addresses: str = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns all mempool events
    :param str event_name: Comma separated list of events to return
    :param str addresses: Comma separated list of addresses to return
    :param str cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = []
    if event_name:
        if addresses:
            for address in addresses.split(","):
                where = [
                    {"event": event, "addresses__like": f"%{address}%"}
                    for event in event_name.split(",")
                ]
        else:
            where = [{"event": event} for event in event_name.split(",")]
    elif addresses:
        for address in addresses.split(","):
            where.append({"addresses__like": f"%{address}%"})

    select = "tx_hash, event, bindings AS params, timestamp"
    return select_rows(
        ledger_db,
        "mempool",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select=select,
    )


def get_mempool_events_by_name(
    ledger_db, event: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the mempool events filtered by event name
    :param str event: The event to return (e.g. CREDIT)
    :param str cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    select = "tx_hash, event, bindings AS params, timestamp"
    return select_rows(
        ledger_db,
        "mempool",
        where={"event": event},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select=select,
    )


def get_mempool_events_by_tx_hash(
    ledger_db,
    tx_hash: str,
    event_name: str = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the mempool events filtered by transaction hash
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_MEMPOOL_TX_HASH)
    :param str event_name: Comma separated list of events to return
    :param str cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"tx_hash": tx_hash}
    if event_name:
        where = [{"event": event, "tx_hash": tx_hash} for event in event_name.split(",")]
    select = "tx_hash, event, bindings AS params, timestamp"
    return select_rows(
        ledger_db,
        "mempool",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select=select,
    )


def get_mempool_events_by_addresses(
    ledger_db, addresses: str, cursor: str = None, limit: int = 100
):
    """
    Returns the mempool events of a list of addresses
    :param str addresses: Comma separated list of addresses to return (e.g. $ADDRESS_3,$ADDRESS_4)
    :param str cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    where = []
    for address in addresses.split(","):
        where.append({"addresses__like": f"%{address}%"})
    select = "tx_hash, event, bindings AS params, timestamp"
    result = select_rows(
        ledger_db,
        "mempool",
        where=where,
        last_cursor=cursor,
        limit=limit,
        select=select,
    )
    return result


def get_event_counts_by_block(
    ledger_db, block_index: int, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the event counts of a block
    :param int block_index: The index of the block to return (e.g. $LAST_BLOCK_INDEX)
    :param str cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "messages",
        where={"block_index": block_index},
        select="event, COUNT(*) AS event_count",
        group_by="event",
        cursor_field="event",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_event_count(state_db, event: str):
    """
    Returns the number of events
    :param int event: The name of the event to return (e.g. CREDIT)
    """
    return select_row(
        state_db,
        "events_count",
        where={"event": event},
    )


def get_all_events_counts(state_db, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns the event counts of all blocks
    :param str cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        state_db,
        "events_count",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_credits_by_block(
    ledger_db,
    block_index: int,
    action: CreditAction = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the credits of a block
    :param int block_index: The index of the block to return (e.g. $LAST_CREDIT_BLOCK)
    :param str action: The action to filter by
    :param str cursor: The last credit index to return
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"block_index": block_index, "quantity__gt": 0}
    if action:
        where["calling_function"] = action
    return select_rows(
        ledger_db,
        "credits",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_credits_by_address(
    ledger_db,
    address: str,
    action: CreditAction = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the credits of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str action: The action to filter by
    :param str cursor: The last index of the credits to return
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = [{"address": address, "quantity__gt": 0}, {"utxo_address": address, "quantity__gt": 0}]
    if action:
        where[0]["calling_function"] = action
        where[1]["calling_function"] = action
    return select_rows(
        ledger_db, "credits", where=where, last_cursor=cursor, limit=limit, offset=offset
    )


def get_credits_by_asset(
    ledger_db,
    asset: str,
    action: CreditAction = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the credits of an asset
    :param str asset: The asset to return (e.g. $ASSET_1)
    :param str action: The action to filter by
    :param str cursor: The last index of the credits to return
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"asset": asset.upper(), "quantity__gt": 0}
    if action:
        where["calling_function"] = action
    return select_rows(
        ledger_db, "credits", where=where, last_cursor=cursor, limit=limit, offset=offset
    )


def get_debits_by_block(
    ledger_db,
    block_index: int,
    action: DebitAction = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the debits of a block
    :param int block_index: The index of the block to return (e.g. $LAST_DEBIT_BLOCK)
    :param str action: The action to filter by
    :param str cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"block_index": block_index, "quantity__gt": 0}
    if action:
        where["action"] = action
    return select_rows(
        ledger_db,
        "debits",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_debits_by_address(
    ledger_db,
    address: str,
    action: DebitAction = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the debits of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str action: The action to filter by
    :param str cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = [{"address": address, "quantity__gt": 0}, {"utxo_address": address, "quantity__gt": 0}]
    if action:
        where[0]["action"] = action
        where[1]["action"] = action
    return select_rows(
        ledger_db, "debits", where=where, last_cursor=cursor, limit=limit, offset=offset
    )


def get_debits_by_asset(
    ledger_db,
    asset: str,
    action: DebitAction = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the debits of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param str action: The action to filter by
    :param str cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"asset": asset.upper(), "quantity__gt": 0}
    if action:
        where["action"] = action
    return select_rows(
        ledger_db, "debits", where=where, last_cursor=cursor, limit=limit, offset=offset
    )


def get_sends(ledger_db, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns all the sends include Enhanced and MPMA sends
    :param str cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_block(
    ledger_db, block_index: int, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the sends, include Enhanced and MPMA sends, of a block
    :param int block_index: The index of the block to return (e.g. $LAST_SEND_BLOCK)
    :param str cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_transaction_hash(
    ledger_db, tx_hash: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the sends, include Enhanced and MPMA sends, of a block
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_SEND_TX_HASH)
    :param str cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where={"tx_hash": tx_hash},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_asset(
    ledger_db, asset: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the sends, include Enhanced and MPMA sends, of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param str cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where={"asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_expirations(
    state_db, block_index: int, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the expirations of a block
    :param int block_index: The index of the block to return (e.g. $LAST_ORDER_EXPIRATION_BLOCK)
    :param str cursor: The last index of the expirations to return
    :param int limit: The maximum number of expirations to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        state_db,
        "all_expirations",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_cancels(
    ledger_db, block_index: int, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the cancels of a block
    :param int block_index: The index of the block to return (e.g. $LAST_CANCEL_BLOCK)
    :param str cursor: The last index of the cancels to return
    :param int limit: The maximum number of cancels to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "cancels",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_destructions(
    ledger_db, block_index: int, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the destructions of a block
    :param int block_index: The index of the block to return (e.g. $LAST_DESTRUCTION_BLOCK)
    :param str cursor: The last index of the destructions to return
    :param int limit: The maximum number of destructions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "destructions",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def prepare_issuance_where(asset_events, other_conditions=None):
    where = []
    asset_events_list = asset_events.split(",")
    for asset_event in asset_events_list:
        if asset_event == "all":
            where = [other_conditions] if other_conditions else []
            break
        if asset_event in typing.get_args(IssuancesAssetEvents):
            if asset_event in ["open_fairminter", "fairmint"]:
                # these event are always alone
                where_status = {"asset_events": asset_event}
            else:
                where_status = {"asset_events__like": f"%{asset_event}%"}
            if other_conditions:
                where_status.update(other_conditions)
            where.append(where_status)
    return where


def get_issuances(
    ledger_db,
    asset_events: IssuancesAssetEvents = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns all the issuances
    :param str cursor: The last index of the issuances to return
    :param str asset_events: Filter result by one or several comma separated asset events
    :param int limit: The maximum number of issuances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = prepare_issuance_where(asset_events, {"status": "valid"})
    return select_rows(
        ledger_db,
        "issuances",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_issuances_by_block(
    ledger_db,
    block_index: int,
    asset_events: IssuancesAssetEvents = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the issuances of a block
    :param int block_index: The index of the block to return (e.g. $LAST_ISSUANCE_BLOCK)
    :param str asset_events: Filter result by one or several comma separated asset events
    :param str cursor: The last index of the issuances to return
    :param int limit: The maximum number of issuances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = prepare_issuance_where(asset_events, {"block_index": block_index, "status": "valid"})
    return select_rows(
        ledger_db,
        "issuances",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_issuance_by_transaction_hash(ledger_db, tx_hash: str):
    """
    Returns the issuances of a block
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_ISSUANCE_TX_HASH)
    """
    return select_row(ledger_db, "issuances", where={"tx_hash": tx_hash})


def get_issuances_by_asset(
    ledger_db,
    asset: str,
    asset_events: IssuancesAssetEvents = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the issuances of an asset
    :param str asset: The asset to return (e.g. $ASSET_1)
    :param str asset_events: Filter result by one or several comma separated asset events
    :param str cursor: The last index of the issuances to return
    :param int limit: The maximum number of issuances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = prepare_issuance_where(
        asset_events, {"asset": asset.upper(), "status": "valid"}
    ) + prepare_issuance_where(
        asset_events, {"UPPER(asset_longname)": asset.upper(), "status": "valid"}
    )
    return select_rows(
        ledger_db,
        "issuances",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_issuances_by_address(
    ledger_db,
    address: str,
    asset_events: IssuancesAssetEvents = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the issuances of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str asset_events: Filter result by one or several comma separated asset events
    :param str cursor: The last index of the issuances to return
    :param int limit: The maximum number of issuances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = prepare_issuance_where(asset_events, {"issuer": address, "status": "valid"})
    return select_rows(
        ledger_db,
        "issuances",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses(ledger_db, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns all the dispenses
    :param str cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dispenses",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_block(
    ledger_db, block_index: int, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a block
    :param int block_index: The index of the block to return (e.g. $LAST_DISPENSE_BLOCK)
    :param str cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dispenses",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_transaction_hash(
    ledger_db, tx_hash: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a block
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_DISPENSE_TX_HASH)
    :param str cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dispenses",
        where={"tx_hash": tx_hash},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_dispenser(
    ledger_db, dispenser_hash: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a dispenser
    :param str dispenser_hash: The hash of the dispenser to return (e.g. $DISPENSER_TX_HASH_1)
    :param str cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dispenses",
        where={"dispenser_tx_hash": dispenser_hash},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_source(
    ledger_db, address: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a source
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dispenses",
        where={"source": address},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_destination(
    ledger_db, address: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a destination
    :param str address: The address to return (e.g. $ADDRESS_2)
    :param str cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dispenses",
        where={"destination": address},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_asset(
    ledger_db, asset: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param str cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dispenses",
        where={"asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_source_and_asset(
    ledger_db, address: str, asset: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str asset: The asset to return (e.g. XCP)
    :param str cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dispenses",
        where={"source": address, "asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_destination_and_asset(
    ledger_db, address: str, asset: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. $ADDRESS_2)
    :param str asset: The asset to return (e.g. XCP)
    :param str cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dispenses",
        where={"destination": address, "asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sweeps(ledger_db, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns all sweeps
    :param str cursor: The last index of the sweeps to return
    :param int limit: The maximum number of sweeps to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sweeps",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sweeps_by_block(
    ledger_db, block_index: int, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the sweeps of a block
    :param int block_index: The index of the block to return (e.g. $LAST_SWEEP_BLOCK)
    :param str cursor: The last index of the sweeps to return
    :param int limit: The maximum number of sweeps to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sweeps",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sweep_by_transaction_hash(ledger_db, tx_hash: str):
    """
    Returns the sweeps of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_SWEEP_TX_HASH)
    """
    return select_rows(
        ledger_db,
        "sweeps",
        where={"tx_hash": tx_hash},
    )


def get_sweeps_by_address(
    ledger_db, address: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the sweeps of an address
    :param str address: The address to return (e.g. $ADDRESS_3)
    :param str cursor: The last index of the sweeps to return
    :param int limit: The maximum number of sweeps to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sweeps",
        where=[{"source": address}, {"destination": address}],
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_address_balances(
    state_db,
    address: str,
    type: BalanceType = all,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the balances of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str type: The type of balances to return
    :param str cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the balances to return (overrides the `cursor` parameter) (e.g. quantity:desc)
    """
    where = [
        {"address": address, "quantity__gt": 0},
        {"utxo_address": address, "quantity__gt": 0},
    ]
    if type == "utxo":
        where.pop(0)
    elif type == "address":
        where.pop(1)

    return select_rows(
        state_db,
        "balances",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="address, asset, quantity, utxo, utxo_address",
        sort=sort,
    )


def get_utxo_balances(
    state_db, utxo: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the balances of an utxo
    :param str utxo: The utxo to return (e.g. $UTXO_WITH_BALANCE)
    :param str cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        state_db,
        "balances",
        where={"utxo": utxo, "quantity__gt": 0},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        select="asset, quantity, utxo, utxo_address",
    )


def utxos_with_balances(state_db, utxos: str):
    """
    Check if the utxos have balances
    :param str utxos: Comma separated list of utxos (e.g. $UTXO_1,$UTXO_2)
    """
    utxo_list = utxos.split(",")
    utxo_with_balances_result = select_rows(
        state_db,
        "balances",
        select="utxo, CAST(MIN(SUM(quantity), 1) AS BOOLEAN) AS has_balance",
        where={"utxo__in": utxo_list},
        group_by="utxo",
    )
    utxo_with_balances = utxo_with_balances_result.result

    result = {}
    for utxo in utxo_with_balances:
        result[utxo["utxo"]] = bool(utxo["has_balance"])
    for utxo in utxo_list:
        if utxo not in result:
            result[utxo] = False

    return QueryResult(result, None, len(utxo_list))


def get_balances_by_addresses(
    state_db,
    addresses: str,
    type: BalanceType = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the balances of several addresses
    :param str addresses: Comma separated list of addresses (e.g. $ADDRESS_1,$ADDRESS_2)
    :param str type: The type of balances to return
    :param str cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the balances to return (overrides the `cursor` parameter) (e.g. quantity:desc)
    """
    where = [
        {"address__in": addresses.split(","), "quantity__gt": 0},
        {"utxo_address__in": addresses.split(","), "quantity__gt": 0},
    ]
    if type == "utxo":
        where.pop(0)
    elif type == "address":
        where.pop(1)

    assets_result = select_rows(
        state_db,
        "balances",
        select="DISTINCT asset AS asset",
        where=where,
        order="ASC",
        cursor_field="asset",
        last_cursor=cursor,
        offset=offset,
        limit=limit,
    )
    assets = [asset["asset"] for asset in assets_result.result]

    where = [
        {"address__in": addresses.split(","), "asset__in": assets, "quantity__gt": 0},
        {"utxo_address__in": addresses.split(","), "asset__in": assets, "quantity__gt": 0},
    ]
    if type == "utxo":
        where.pop(0)
    elif type == "address":
        where.pop(1)

    balances = select_rows(
        state_db,
        "balances",
        where=where,
        select="address, asset, quantity, utxo, utxo_address",
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
                    "utxo": balance["utxo"],
                    "utxo_address": balance["utxo_address"],
                    "quantity": balance["quantity"],
                }
            )
        result.append(current_balances)

    return QueryResult(result, assets_result.next_cursor, assets_result.result_count)


def get_balances_by_address_and_asset(
    state_db,
    address: str,
    asset: str,
    type: BalanceType = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the balances of an address and asset
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str asset: The asset to return (e.g. XCP)
    :param str type: The type of balances to return
    :param str cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = [
        {"address": address, "asset": asset.upper(), "quantity__gt": 0},
        {"utxo_address": address, "asset": asset.upper(), "quantity__gt": 0},
    ]
    if type == "utxo":
        where.pop(0)
    elif type == "address":
        where.pop(1)

    return select_rows(
        state_db,
        "balances",
        select="address, asset, quantity, utxo, utxo_address",
        where=where,
        last_cursor=cursor,
        offset=offset,
        limit=limit,
    )


def get_balances_by_asset_and_address(state_db, asset: str, address: str):
    """
    Returns the balances of an address and asset
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str asset: The asset to return (e.g. XCP)
    """
    return get_balances_by_address_and_asset(state_db, address, asset)


def get_bets(
    state_db, status: BetStatus = "open", cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the bets of a feed
    :param str status: The status of the bet (e.g. filled)
    :param str cursor: The last index of the bets to return
    :param int limit: The maximum number of bets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        state_db,
        "bets",
        where={"status": status},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_bet_by_feed(
    state_db,
    address: str,
    status: BetStatus = "open",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the bets of a feed
    :param str address: The address of the feed (e.g. $ADDRESS_1)
    :param str status: The status of the bet (e.g. filled)
    :param str cursor: The last index of the bets to return
    :param int limit: The maximum number of bets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        state_db,
        "bets",
        where={"feed_address": address, "status": status},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_valid_broadcasts(
    ledger_db,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns all valid broadcasts
    :param str cursor: The last index of the broadcasts to return
    :param int limit: The maximum number of broadcasts to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "broadcasts",
        where={"status": "valid"},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_broadcasts_by_source(
    ledger_db,
    address: str,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the broadcasts of a source
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str cursor: The last index of the broadcasts to return
    :param int limit: The maximum number of broadcasts to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "broadcasts",
        where={"source": address, "status": "valid"},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_broadcast_by_transaction_hash(ledger_db, tx_hash: str):
    """
    Returns the broadcast of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_BROADCAST_TX_HASH)
    """
    return select_row(
        ledger_db,
        "broadcasts",
        where={"tx_hash": tx_hash},
    )


def get_burns_by_address(
    ledger_db, address: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the burns of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str cursor: The last index of the burns to return
    :param int limit: The maximum number of burns to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "burns",
        where={"source": address},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_address(
    ledger_db, address: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the sends, include Enhanced and MPMA sends, of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where={"source": address},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_address_and_asset(
    ledger_db, address: str, asset: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the sends, include Enhanced and MPMA sends, of an address and asset
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str asset: The asset to return (e.g. $ASSET_5)
    :param str cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where={"source": address, "asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_receive_by_address(
    ledger_db, address: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the receives of an address
    :param str address: The address to return (e.g. $ADDRESS_5)
    :param str cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where={"destination": address},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_receive_by_address_and_asset(
    ledger_db, address: str, asset: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the receives of an address and asset
    :param str address: The address to return (e.g. $ADDRESS_5)
    :param str asset: The asset to return (e.g. $ASSET_5)
    :param str cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where={"destination": address, "asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def prepare_dispenser_where(status, other_conditions=None):
    where = []
    statuses = status.split(",")
    for s in statuses:
        if s.isdigit():
            s = DispenserStatusNumberInverted.get(int(s), "all")  # noqa: PLW2901

        if s == "all":
            where = other_conditions or {}
            break

        if s in DispenserStatusNumber:
            where_status = {"status": DispenserStatusNumber[s]}
            if other_conditions:
                where_status.update(other_conditions)

            where.append(where_status)

    return where


SELECT_DISPENSERS = "*, (satoshirate * 1.0) / (give_quantity * 1.0) AS price"


def get_dispensers(
    state_db,
    status: DispenserStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns all dispensers
    :param str status: The status of the dispensers to return
    :param str cursor: The last index of the dispensers to return
    :param int limit: The maximum number of dispensers to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the dispensers to return (overrides the `cursor` parameter) (e.g. block_index:asc)
    """

    return select_rows(
        state_db,
        "dispensers",
        where=prepare_dispenser_where(status),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
        select=SELECT_DISPENSERS,
    )


def get_dispensers_by_address(
    state_db,
    address: str,
    status: DispenserStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the dispensers of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str status: The status of the dispensers to return
    :param str cursor: The last index of the dispensers to return
    :param int limit: The maximum number of dispensers to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the dispensers to return (overrides the `cursor` parameter) (e.g. give_quantity:desc)
    """
    return select_rows(
        state_db,
        "dispensers",
        where=prepare_dispenser_where(status, {"source": address}),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
        select=SELECT_DISPENSERS,
    )


def get_dispensers_by_asset(
    state_db,
    asset: str,
    status: DispenserStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the dispensers of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param str status: The status of the dispensers to return
    :param str cursor: The last index of the dispensers to return
    :param int limit: The maximum number of dispensers to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the dispensers to return (overrides the `cursor` parameter) (e.g. give_quantity:desc)
    """
    return select_rows(
        state_db,
        "dispensers",
        where=prepare_dispenser_where(status, {"asset": asset.upper()}),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
        select=SELECT_DISPENSERS,
    )


def get_dispenser_by_address_and_asset(state_db, address: str, asset: str):
    """
    Returns the dispenser of an address and an asset
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str asset: The asset to return (e.g. XCP)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_row(
        state_db,
        "dispensers",
        where={"source": address, "asset": asset.upper()},
        select=SELECT_DISPENSERS,
    )


def get_valid_assets(
    state_db, named: bool = None, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the valid assets
    :param bool named: Whether to return only named assets (e.g. true)
    :param str cursor: The last index of the assets to return
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
        state_db,
        "assets_info",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_asset(state_db, asset: str):
    """
    Returns an asset by its name
    :param str asset: The name of the asset to return (e.g. $ASSET_1)
    """
    where = [{"asset": asset.upper()}, {"UPPER(asset_longname)": asset.upper()}]
    return select_row(
        state_db,
        "assets_info",
        where=where,
    )


def get_subassets_by_asset(
    state_db, asset: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns asset subassets
    :param str asset: The name of the asset to return (e.g. $ASSET_7)
    :param str cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = [{"asset_longname__like": f"{asset.upper()}.%"}]
    return select_rows(
        state_db,
        "assets_info",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_valid_assets_by_issuer(
    state_db,
    address: str,
    named: bool = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the valid assets issued by an address
    :param str address: The issuer to return (e.g. $ADDRESS_1)
    :param bool named: Whether to return only named assets (e.g. true)
    :param str cursor: The last index of the assets to return
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
        state_db,
        "assets_info",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_valid_assets_by_owner(
    state_db,
    address: str,
    named: bool = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the valid assets owned by an address
    :param str address: The owner to return (e.g. $ADDRESS_1)
    :param bool named: Whether to return only named assets (e.g. true)
    :param str cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"owner": address}
    if named is not None:
        if named:
            where["asset__notlike"] = "A%"
        else:
            where["asset__like"] = "A%"

    return select_rows(
        state_db,
        "assets_info",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_valid_assets_by_issuer_or_owner(
    state_db,
    address: str,
    named: bool = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the valid assets issued or owned by an address
    :param str address: The issuer or owner to return (e.g. $ADDRESS_1)
    :param bool named: Whether to return only named assets (e.g. true)
    :param str cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = [{"issuer": address}, {"owner": address}]
    if named is not None:
        if named:
            for p in where:
                p["asset__notlike"] = "A%"
        else:
            for p in where:
                p["asset__like"] = "A%"

    return select_rows(
        state_db,
        "assets_info",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dividends(ledger_db, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns all the dividends
    :param str cursor: The last index of the dividend to return
    :param int limit: The maximum number of dividend to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dividends",
        # where={"status": "valid"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dividend(ledger_db, dividend_hash: str):
    """
    Returns a dividend by its hash
    :param str dividend_hash: The hash of the dividend to return (e.g. $LAST_DIVIDEND_TX_HASH)
    """
    return select_row(
        ledger_db,
        "dividends",
        where={"tx_hash": dividend_hash},
    )


def get_dividends_by_asset(
    ledger_db, asset: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the dividends of an asset
    :param str asset: The asset to return (e.g. $ASSET_5)
    :param str cursor: The last index of the dividend to return
    :param int limit: The maximum number of dividend to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dividends",
        where={"asset": asset.upper(), "status": "valid"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dividends_distributed_by_address(
    ledger_db, address: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the dividends distributed by an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "dividends",
        where={"source": address, "status": "valid"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dividend_disribution(
    ledger_db, dividend_hash: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns a dividend distribution by its hash
    :param str dividend_hash: The hash of the dividend distribution to return (e.g. $LAST_DIVIDEND_TX_HASH)
    :param str cursor: The last index of the credit to return
    :param int limit: The maximum number of credit to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "credits",
        where={"event": dividend_hash},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_asset_balances(
    state_db,
    asset: str,
    type: BalanceType = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the asset balances
    :param str asset: The asset to return (e.g. $ASSET_1)
    :param str type: The type of balances to return
    :param str cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the balances to return (overrides the `cursor` parameter) (e.g. quantity:desc)
    """
    where = [{"asset": asset.upper(), "quantity__gt": 0}]
    if type == "utxo":
        where.append({"utxo__notnull": True})
    elif type == "address":
        where.append({"address__notnull": True})

    return select_rows(
        state_db,
        "balances",
        where=where,
        select="address, utxo, utxo_address, asset, quantity",
        order="ASC",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def prepare_where_status(status, arg_type, other_conditions=None):
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
    return prepare_where_status(status, OrderStatus, other_conditions=other_conditions)


def prepare_order_matches_where(status, other_conditions=None):
    return prepare_where_status(status, OrderMatchesStatus, other_conditions=other_conditions)


SELECT_ORDERS = "*, "
SELECT_ORDERS += "(get_quantity * 1.0) / (give_quantity * 1.0) AS give_price, "
SELECT_ORDERS += "(give_quantity * 1.0) / (get_quantity * 1.0) AS get_price"


def get_orders(
    state_db,
    status: OrderStatus = "all",
    get_asset: str = None,
    give_asset: str = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns all the orders
    :param str status: The status of the orders to return
    :param str get_asset: The get asset to return
    :param str give_asset: The give asset to return
    :param str cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the orders to return (overrides the `cursor` parameter) (e.g. expiration:desc)
    """
    where = {}
    if get_asset:
        where["get_asset"] = get_asset.upper()
    if give_asset:
        where["give_asset"] = give_asset.upper()
    return select_rows(
        state_db,
        "orders",
        cursor_field="tx_index",
        where=prepare_order_where(status, where),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
        select=SELECT_ORDERS,
    )


def get_orders_by_asset(
    state_db,
    asset: str,
    status: OrderStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the orders of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param str status: The status of the orders to return
    :param str cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the orders to return (overrides the `cursor` parameter) (e.g. expiration:desc)
    """
    where = prepare_order_where(status, {"give_asset": asset.upper()}) + prepare_order_where(
        status, {"get_asset": asset.upper()}
    )

    return select_rows(
        state_db,
        "orders",
        cursor_field="tx_index",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
        select=SELECT_ORDERS,
    )


def get_orders_by_address(
    state_db,
    address: str,
    status: OrderStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the orders of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str status: The status of the orders to return
    :param str cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the orders to return (overrides the `cursor` parameter) (e.g. expiration:desc)
    """
    return select_rows(
        state_db,
        "orders",
        cursor_field="tx_index",
        where=prepare_order_where(status, {"source": address}),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
        select=SELECT_ORDERS,
    )


def get_orders_by_two_assets(
    state_db,
    asset1: str,
    asset2: str,
    status: OrderStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the orders to exchange two assets
    :param str asset1: The first asset to return (e.g. BTC)
    :param str asset2: The second asset to return (e.g. XCP)
    :param str status: The status of the orders to return
    :param str cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the orders to return (overrides the `cursor` parameter) (e.g. expiration:desc)
    """
    where = prepare_order_where(
        status, {"give_asset": asset1.upper(), "get_asset": asset2.upper()}
    ) + prepare_order_where(status, {"give_asset": asset2.upper(), "get_asset": asset1.upper()})
    query_result = select_rows(
        state_db,
        "orders",
        cursor_field="tx_index",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
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


def get_asset_holders(
    state_db, asset: str, cursor: str = None, limit: int = 100, offset: int = None, sort: str = None
):
    """
    Returns the holders of an asset
    :param str asset: The asset to return (e.g. $ASSET_1)
    :param str cursor: The last index of the holder to return
    :param int limit: The maximum number of holders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the holders to return (overrides the `cursor` parameter) (e.g. quantity:desc)
    """
    table_name = "xcp_holders" if asset.upper() == "XCP" else "asset_holders"
    return select_rows(
        state_db,
        table_name,
        where={"asset": asset.upper()},
        order="ASC",
        cursor_field="cursor_id",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def get_order(state_db, order_hash: str):
    """
    Returns the information of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. $LAST_ORDER_TX_HASH)
    """
    return select_row(
        state_db,
        "orders",
        where={"tx_hash": order_hash},
        select=SELECT_ORDERS,
    )


def get_all_order_matches(
    state_db,
    status: OrderMatchesStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns all the order matches
    :param str status: The status of the order matches to return
    :param str cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the order matches to return (overrides the `cursor` parameter) (e.g. forward_quantity:desc)
    """
    return select_rows(
        state_db,
        "order_matches",
        where=prepare_order_matches_where(status),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def get_order_matches_by_order(
    state_db,
    order_hash: str,
    status: OrderMatchesStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the order matches of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. $ORDER_WITH_MATCH_HASH)
    :param str status: The status of the order matches to return
    :param str cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the order matches to return (overrides the `cursor` parameter) (e.g. forward_quantity:desc)
    """
    where = prepare_order_matches_where(
        status, {"tx0_hash": order_hash}
    ) + prepare_order_matches_where(status, {"tx1_hash": order_hash})
    return select_rows(
        state_db,
        "order_matches",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def get_order_matches_by_asset(
    state_db,
    asset: str,
    status: OrderMatchesStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the orders of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param str status: The status of the order matches to return
    :param str cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the order matches to return (overrides the `cursor` parameter) (e.g. forward_quantity:desc)
    """
    where = prepare_order_matches_where(
        status, {"forward_asset": asset.upper()}
    ) + prepare_order_matches_where(status, {"backward_asset": asset.upper()})

    return select_rows(
        state_db,
        "order_matches",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def get_order_matches_by_two_assets(
    state_db,
    asset1: str,
    asset2: str,
    status: OrderMatchesStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the orders to exchange two assets
    :param str asset1: The first asset to return (e.g. BTC)
    :param str asset2: The second asset to return (e.g. XCP)
    :param str status: The status of the order matches to return
    :param str cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the order matches to return (overrides the `cursor` parameter) (e.g. forward_quantity:desc)
    """
    where = prepare_order_matches_where(
        status, {"forward_asset": asset1.upper(), "backward_asset": asset2.upper()}
    ) + prepare_order_matches_where(
        status, {"forward_asset": asset2.upper(), "backward_asset": asset1.upper()}
    )
    query_result = select_rows(
        state_db,
        "order_matches",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
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
    ledger_db, order_hash: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the BTC pays of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. $ORDER_WITH_BTCPAY_HASH)
    :param str cursor: The last index of the resolutions to return
    :param int limit: The maximum number of resolutions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "btcpays",
        where={"order_match_id__like": f"%{order_hash}%"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_bet(state_db, bet_hash: str):
    """
    Returns the information of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 5d097b4729cb74d927b4458d365beb811a26fcee7f8712f049ecbe780eb496ed)
    """
    return select_row(
        state_db,
        "bets",
        where={"tx_hash": bet_hash},
    )


def get_bet_matches_by_bet(
    state_db,
    bet_hash: str,
    status: BetMatchesStatus = "pending",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the bet matches of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 5d097b4729cb74d927b4458d365beb811a26fcee7f8712f049ecbe780eb496ed)
    :param str status: The status of the bet matches (e.g. expired)
    :param str cursor: The last index of the bet matches to return
    :param int limit: The maximum number of bet matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        state_db,
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
    ledger_db, bet_hash: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the resolutions of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 36bbbb7dbd85054dac140a8ad8204eda2ee859545528bd2a9da69ad77c277ace)
    :param str cursor: The last index of the resolutions to return
    :param int limit: The maximum number of resolutions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "bet_match_resolutions",
        where={"bet_match_id__like": f"%{bet_hash}%"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_all_burns(ledger_db, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns the burns
    :param str status: The status of the burns to return (e.g. valid)
    :param str cursor: The last index of the burns to return
    :param int limit: The maximum number of burns to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "burns",
        where={"status": "valid"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenser_info_by_hash(state_db, dispenser_hash: str):
    """
    Returns the dispenser information by tx_hash
    :param str dispenser_hash: The hash of the dispenser to return (e.g. $DISPENSER_TX_HASH_1)
    """
    return select_row(
        state_db,
        "dispensers",
        where={"tx_hash": dispenser_hash},
        select=SELECT_DISPENSERS,
    )


def prepare_fairminters_where(status, other_conditions=None):
    return prepare_where_status(status, FairmintersStatus, other_conditions=other_conditions)


def get_all_fairminters(
    state_db,
    status: FairmintersStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns all fairminters
    :param str status: The status of the fairminters to return
    :param str cursor: The last index of the fairminter to return
    :param int limit: The maximum number of fairminter to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = prepare_fairminters_where(status)
    return select_rows(
        state_db, "fairminters", where=where, last_cursor=cursor, limit=limit, offset=offset
    )


def get_fairminter(state_db, tx_hash: str):
    """
    Returns the fairminter by its hash
    :param str fairminter_hash: The hash of the fairminter to return (e.g. $LAST_FAIRMINTER_TX_HASH)
    """
    return select_row(
        state_db,
        "fairminters",
        where={"tx_hash": tx_hash},
    )


def get_fairminters_by_block(
    state_db,
    block_index: int,
    status: FairmintersStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the fairminters by its block index
    :param int block_index: The block index of the fairminter to return (e.g. $LAST_FAIRMINTER_BLOCK)
    :param str status: The status of the fairminters to return
    :param str cursor: The last index of the fairminter to return
    :param int limit: The maximum number of fairminter to return (e.g. 5)
    :param int offset: The number of lines to skip before
    """
    where = prepare_fairminters_where(status, {"block_index": block_index})
    return select_rows(
        state_db, "fairminters", where=where, last_cursor=cursor, limit=limit, offset=offset
    )


def get_fairminters_by_asset(
    state_db,
    asset: str,
    status: FairmintersStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the fairminter by its asset
    :param str asset: The asset of the fairminter to return (e.g. $ASSET_1)
    :param str status: The status of the fairminters to return
    """
    where = {"asset": asset.upper()}
    if "." in asset:
        where = {"asset_longname": asset.upper()}
    where = prepare_fairminters_where(status, where)
    return select_rows(
        state_db, "fairminters", where=where, last_cursor=cursor, limit=limit, offset=offset
    )


def get_fairminters_by_address(
    state_db,
    address: str,
    status: FairmintersStatus = "all",
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the fairminter by its source
    :param str address: The source of the fairminter to return (e.g. $ADDRESS_1)
    :param str status: The status of the fairminters to return
    """
    where = prepare_fairminters_where(status, {"source": address})
    return select_rows(
        state_db, "fairminters", where=where, last_cursor=cursor, limit=limit, offset=offset
    )


def get_fairmints_by_fairminter(
    ledger_db, tx_hash: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the mints by fairminter
    :param str fairminter_hash: The hash of the fairminter to return (e.g. $LAST_FAIRMINTER_TX_HASH)
    """
    return select_rows(
        ledger_db,
        "fairmints",
        where={"fairminter_tx_hash": tx_hash},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_fairmints_by_address(
    ledger_db, address: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the mints by address
    :param str address: The address of the mints to return (e.g. $ADDRESS_2)
    """
    return select_rows(
        ledger_db,
        "fairmints",
        where={"source": address},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_fairmints_by_asset(
    ledger_db, asset: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the mints by asset
    :param str asset: The asset of the mints to return (e.g. $ASSET_1)
    """
    return select_rows(
        ledger_db,
        "fairmints",
        where={"asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_fairmints_by_address_and_asset(
    ledger_db, address: str, asset: str, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the mints by address and asset
    :param str address: The address of the mints to return (e.g. $ADDRESS_2)
    :param str asset: The asset of the mints to return (e.g. $ASSET_1)
    """
    return select_rows(
        ledger_db,
        "fairmints",
        where={"source": address, "asset": asset.upper()},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_all_fairmints(ledger_db, cursor: str = None, limit: int = 100, offset: int = None):
    """
    Returns all fairmints
    :param str cursor: The last index of the fairmint to return
    :param int limit: The maximum number of fairmint to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(ledger_db, "fairmints", last_cursor=cursor, limit=limit, offset=offset)


def get_fairmint(ledger_db, tx_hash: str):
    """
    Returns the fairmint by its hash
    :param str tx_hash: The hash of the fairmint to return (e.g. $LAST_FAIRMINT_TX_HASH)
    """
    return select_row(
        ledger_db,
        "fairmints",
        where={"tx_hash": tx_hash},
    )


def get_fairmints_by_block(
    ledger_db, block_index: int, cursor: str = None, limit: int = 100, offset: int = None
):
    """
    Returns the fairmints by its block index
    :param int block_index: The block index of the fairmint to return (e.g. $LAST_FAIRMINT_BLOCK)
    :param str cursor: The last index of the fairmint to return
    :param int limit: The maximum number of fairmint to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "fairmints",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )
