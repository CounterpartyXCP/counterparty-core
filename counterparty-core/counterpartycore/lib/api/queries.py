# pylint: disable=too-many-lines

import json
import re
import typing
import weakref
from typing import Literal

import apsw
from sentry_sdk import start_span as start_sentry_span

from counterpartycore.lib.ledger.markets import (
    compute_pool_input_for_target_price,
    compute_pool_output,
    get_pool_fee_bps,
    pool_has_liquidity,
    sort_pair,
)
from counterpartycore.lib.utils import hashcodec
from counterpartycore.lib.utils.helpers import divide


def _convert_hash_value(field, value):
    """If the WHERE clause targets a hash column and the caller passes a hex
    string, convert it to BLOB so it can match the at-rest representation."""
    if value is None:
        return value
    if isinstance(value, bytes):
        return value
    if field in hashcodec.HASH_COLUMN_NAMES and isinstance(value, str):
        try:
            return hashcodec.hash_to_db(value)
        except ValueError:
            return value
    return value


# Legacy hash filter keys in callers that have been replaced by
# ``*_tx_index`` foreign keys. ``select_rows`` rewrites the WHERE clause so the
# existing API surface (which still accepts hex tx_hash query params) can
# resolve via a transactions subquery.
_HASH_FK_WHERE_REWRITE = {
    "dispenser_tx_hash": "dispenser_tx_index",
    "fairminter_tx_hash": "fairminter_tx_index",
    "order_tx_hash": "order_tx_index",
    "offer_hash": "offer_tx_index",
}

# For tables where a legacy hash column was dropped and replaced by a
# ``*_tx_index`` FK, ``select_rows`` rewrites ``SELECT *`` to re-expose the
# legacy hash via a JOIN against ``transactions`` so the API response shape is
# preserved. The mapping uses ``ledger_db.transactions`` so it also works when
# the query targets a State DB connection (which ATTACHes the Ledger DB as
# ``ledger_db`` at read-only open time).
_HASH_FK_PROJECTIONS = {
    "dispenses": ("dispenser_tx_index", "dispenser_tx_hash"),
    "dispenser_refills": ("dispenser_tx_index", "dispenser_tx_hash"),
    "fairmints": ("fairminter_tx_index", "fairminter_tx_hash"),
    "pool_matches": ("order_tx_index", "order_tx_hash"),
    "cancels": ("offer_tx_index", "offer_hash"),
}


# Per-connection cache so we run the schema probe at most once per pooled
# connection instead of on every ``select_rows`` call. Using a
# ``WeakKeyDictionary`` lets the entry disappear automatically when the
# connection is garbage-collected.
_TX_TABLE_NAME_CACHE: "weakref.WeakKeyDictionary" = weakref.WeakKeyDictionary()


def _probe_transactions_table(cursor, qualified_name):
    """Return ``qualified_name`` if the cursor can SELECT from it, else None.

    The absence of the table is the expected negative path here (e.g. early
    bootstrap before the Ledger DB exists, or when ``ledger_db`` is not
    ATTACHed). Returning ``None`` lets the caller try the next candidate.

    ``qualified_name`` is always a hard-coded constant from this module
    (``transactions`` or ``ledger_db.transactions``); the f-string is safe.
    """
    try:
        cursor.execute(f"SELECT 1 FROM {qualified_name} LIMIT 0")  # nosec B608  # noqa: S608
    except apsw.SQLError:
        return None
    return qualified_name


def _resolve_transactions_table_name(db):
    """Return ``transactions`` if the connection sees that table directly,
    ``ledger_db.transactions`` if ``ledger_db`` is attached and contains it,
    or ``None`` otherwise (in which case hash-FK projections are skipped).

    The result is cached per connection: API hot paths read from ``messages``
    and the ``_HASH_FK_PROJECTIONS`` tables on every call; without the cache
    each call would issue 1-2 extra SQL probes against the connection.
    """
    cached = _TX_TABLE_NAME_CACHE.get(db)
    if cached is not None:
        return cached if cached != "" else None

    cursor = db.cursor()
    resolved = _probe_transactions_table(cursor, "transactions")
    if resolved is None:
        resolved = _probe_transactions_table(cursor, "ledger_db.transactions")

    # Cache an empty sentinel for the negative result so we don't keep
    # re-probing connections that won't see ``transactions`` (e.g. early
    # bootstrap before the Ledger DB exists). The None case is short-lived
    # in practice and the cache entry will be replaced on the next attach.
    _TX_TABLE_NAME_CACHE[db] = resolved if resolved is not None else ""
    return resolved


# Cache of table -> list of public columns (everything except the internal
# ``*_tx_index`` FK that replaced the legacy hash). Populated lazily on first
# projection.
_HASH_FK_PUBLIC_COLUMNS: dict[str, tuple[str, ...]] = {}


# Columns shared between a main table and the joined ``transactions`` table
# that need explicit ``__m.`` qualification when ``select_rows`` adds the
# JOIN for ``messages`` / ``_HASH_FK_PROJECTIONS`` tables. Lifted out of the
# function body so the tuple isn't reallocated on every API call.
_AMBIGUOUS_COLS = frozenset(
    {
        "block_index",
        "tx_index",
        "rowid",
        "tx_hash",
        "source",
        "destination",
        "block_time",
        "btc_amount",
        "fee",
        "data",
        "supported",
        "utxos_info",
        "transaction_type",
    }
)
_MESSAGES_QUALIFY_M_FIELDS = frozenset({"block_index", "tx_index", "rowid", "message_index"})

# Views whose ``COUNT(*)`` can be safely answered by counting rows from a
# single underlying table (the LEFT JOINs in the view's definition do not
# multiply rows because they all join on a unique key on the right side).
# Mapping: view_name -> (main_table, columns_only_on_main_table). When the
# caller's WHERE filter is restricted to those columns we can replace the
# view's FROM with ``main_table`` and skip its internal JOINs entirely.
# ``all_transactions_with_status`` is omitted on purpose: it counts over
# ``mempool_transactions UNION ALL transactions`` and there is no single
# underlying table to substitute.
_COUNT_FROM_OVERRIDE = {
    "transactions_with_status": (
        "transactions",
        frozenset(
            {
                "tx_index",
                "tx_hash",
                "block_index",
                "block_time",
                "source",
                "destination",
                "btc_amount",
                "fee",
                "data",
                "supported",
                "utxos_info",
                "transaction_type",
            }
        ),
    ),
}


def _hash_fk_public_columns(db, table):
    """Return the list of column names to expose to the API for a table
    where the legacy hash was replaced by a ``*_tx_index`` FK, i.e. every
    column of the underlying table *except* that internal FK.

    The legacy hash column is re-hydrated separately by the caller via a
    ``LEFT JOIN`` against ``transactions``.
    """
    cached = _HASH_FK_PUBLIC_COLUMNS.get(table)
    if cached is not None:
        return cached
    index_col, _hash_col = _HASH_FK_PROJECTIONS[table]
    cursor = db.cursor()
    rows = cursor.execute(f"PRAGMA table_info({table})").fetchall()  # nosec B608  # noqa: S608
    cols = []
    for row in rows:
        if isinstance(row, dict):
            name = row["name"]
        else:
            name = row[1]
        if name == index_col:
            continue
        cols.append(name)
    cols_tuple = tuple(cols)
    _HASH_FK_PUBLIC_COLUMNS[table] = cols_tuple
    return cols_tuple


def _project_messages_tx_hash(select_clause):
    """Rewrite identifiers in a ``SELECT`` clause targeting the joined
    ``messages``/``transactions`` view (``messages.tx_hash`` was dropped in
    favour of an FK on ``transactions``):

    - ``tx_hash`` -> ``__txh.tx_hash AS tx_hash`` (the column alias keeps
      ``tx_hash``, which is in ``hashcodec.HASH_COLUMN_NAMES`` so the
      connection rowtracer converts BLOB -> hex without a per-row UDF).
    - bare ``block_index`` -> ``__m.block_index AS block_index``
      (both ``messages`` and ``transactions`` have ``block_index``; without
      a qualifier the join is ambiguous).
    - bare ``rowid`` -> ``__m.rowid AS rowid``
      (both tables have an implicit ``rowid``; the join needs an explicit
      qualifier).

    Uses word-boundary safe rewrites so ``last_status_tx_hash`` etc. are not
    touched.
    """
    rewritten = re.sub(
        r"(?<![A-Za-z0-9_\.])tx_hash(?![A-Za-z0-9_])",
        "__txh.tx_hash AS tx_hash",
        select_clause,
    )
    rewritten = re.sub(
        r"(?<![A-Za-z0-9_\.])block_index(?![A-Za-z0-9_])",
        "__m.block_index AS block_index",
        rewritten,
    )
    # Collapse ``rowid AS rowid`` to ``__m.rowid AS rowid``. We need a
    # dedicated pass first so the bare-``rowid`` rewrite below does not
    # mangle the alias position.
    rewritten = re.sub(
        r"(?<![A-Za-z0-9_\.])rowid\s+AS\s+rowid(?![A-Za-z0-9_])",
        "__m.rowid AS rowid",
        rewritten,
        flags=re.IGNORECASE,
    )
    # Qualify a bare ``rowid`` column reference (used by callers that select
    # rowid without an explicit alias). Skip when already qualified
    # (``__m.rowid``) or when it appears as an alias (``AS rowid``).
    rewritten = re.sub(
        r"(?<![A-Za-z0-9_\.])(?<!AS\s)rowid(?![A-Za-z0-9_])",
        "__m.rowid AS rowid",
        rewritten,
    )
    return rewritten


OrderStatus = Literal["all", "open", "expired", "filled", "cancelled"]
OrderMatchesStatus = Literal["all", "pending", "completed", "expired"]
BetStatus = Literal["cancelled", "dropped", "expired", "filled", "open"]
DispenserStatus = Literal["all", "open", "closed", "closing", "open_empty_address"]
DispenserStatusNumber = {"open": 0, "closed": 10, "closing": 11, "open_empty_address": 1}  # pylint: disable=invalid-name
DispenserStatusNumberInverted = {value: key for key, value in DispenserStatusNumber.items()}  # pylint: disable=invalid-name
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
    "utxomove",
    "unknown",
]
SendType = Literal["all", "send", "attach", "move", "detach"]

SUPPORTED_SORT_FIELDS = {
    "balances": ["address", "asset", "asset_longname", "quantity"],
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
    "pools": [
        "block_index",
        "reserve_a",
        "reserve_b",
    ],
    "pool_matches": [
        "block_index",
        "forward_quantity",
        "backward_quantity",
    ],
}

ADDRESS_FIELDS = ["source", "address", "issuer", "destination"]


class QueryResult:
    def __init__(self, result, next_cursor, table, result_count=None):
        self.result = result
        self.next_cursor = next_cursor
        self.result_count = result_count
        self.table = table


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

    if table == "all_transactions_with_status":
        cursor_field = "tx_index"

    cursor = db.cursor()

    if where is None:
        where = [{}]
    if isinstance(where, dict):
        where = [where]

    bindings = []

    # ``messages.tx_hash`` has been dropped from storage. Reads from
    # ``messages`` are rewritten to come from a JOIN against ``transactions``
    # so legacy callers that still filter or project on ``tx_hash`` keep
    # working.
    rewrite_messages_tx_hash = table == "messages"

    table_has_hash_fk = table in _HASH_FK_PROJECTIONS

    def _qualify(field):
        """Disambiguate columns when the SELECT joins ``messages`` or one of
        the ``_HASH_FK_PROJECTIONS`` tables against ``transactions``."""
        if rewrite_messages_tx_hash:
            if field in _MESSAGES_QUALIFY_M_FIELDS:
                return f"__m.{field}"
            if field == "tx_hash":
                return "__txh.tx_hash"
        elif table_has_hash_fk:
            if field in _AMBIGUOUS_COLS:
                return f"__m.{field}"
        return field

    # ``where_needs_join`` tracks whether the rewritten WHERE clause
    # references a column that only exists on the joined ``__txh`` /
    # ``__txjoin`` (i.e. ``messages.tx_hash`` is filtered). When False, the
    # COUNT(*) query is rebuilt against the main table alone to skip a
    # full-table LEFT JOIN that contributes nothing to the row count.
    where_needs_join = False
    # Set of base field names referenced anywhere in the WHERE clause; used
    # to decide whether the ``_COUNT_FROM_OVERRIDE`` shortcut is safe.
    where_fields_used: set[str] = set()

    # Resolve the transactions table once so _HASH_FK_WHERE_REWRITE subqueries
    # use the same table name as the FROM clause JOIN (or emit a false condition
    # when no transactions table is reachable from this connection).
    _where_tx_table = _resolve_transactions_table_name(db)

    or_where = []
    for where_dict in where:
        where_field = []
        for key, value in where_dict.items():
            if key.endswith("__gt"):
                field = key[:-4]
                where_field.append(f"{_qualify(field)} > ?")
                bindings.append(_convert_hash_value(field, value))
            elif key.endswith("__like"):
                field = key[:-6]
                where_field.append(f"{_qualify(field)} LIKE ?")
                bindings.append(value)
            elif key.endswith("__notlike"):
                field = key[:-9]
                where_field.append(f"{_qualify(field)} NOT LIKE ?")
                bindings.append(value)
            elif key.endswith("__in"):
                field = key[:-4]
                if field in _HASH_FK_WHERE_REWRITE:
                    new_field = _HASH_FK_WHERE_REWRITE[field]
                    if _where_tx_table is None:
                        where_field.append("(0 = 1)")
                    else:
                        placeholders = ",".join(
                            [f"(SELECT tx_index FROM {_where_tx_table} WHERE tx_hash = ?)"] * len(value)  # nosec B608  # noqa: S608
                        )
                        where_field.append(f"{new_field} IN ({placeholders})")
                        bindings += [hashcodec.hash_to_db(v) for v in value]
                    # ``field`` becomes the resolved FK column so the
                    # ``_COUNT_FROM_OVERRIDE`` gate sees the actual schema
                    # column rather than the legacy hex hash alias.
                    field = new_field
                else:
                    where_field.append(f"{_qualify(field)} IN ({','.join(['?'] * len(value))})")
                    bindings += [_convert_hash_value(field, v) for v in value]
            elif key.endswith("__notnull"):
                field = key[:-9]
                where_field.append(f"{_qualify(field)} IS NOT NULL")
            elif key.endswith("__null"):
                field = key[:-6]
                where_field.append(f"{_qualify(field)} IS NULL")
            elif key.endswith("__nocase"):
                field = key[:-8]
                where_field.append(f"{_qualify(field)} = ? COLLATE NOCASE")
                bindings.append(_convert_hash_value(field, value))
            else:
                if key in _HASH_FK_WHERE_REWRITE:
                    new_field = _HASH_FK_WHERE_REWRITE[key]
                    if _where_tx_table is None:
                        where_field.append("(0 = 1)")
                    else:
                        where_field.append(
                            f"{new_field} = (SELECT tx_index FROM {_where_tx_table} WHERE tx_hash = ?)"  # nosec B608  # noqa: S608
                        )
                        bindings.append(hashcodec.hash_to_db(value))
                    # ``key`` is the legacy hex hash column (e.g.
                    # ``dispenser_tx_hash``); record the *resolved* FK column
                    # name so the override gate sees the actual schema column.
                    field = new_field
                elif key in ADDRESS_FIELDS and len(value.split(",")) > 1:
                    where_field.append(f"{key} IN ({','.join(['?'] * len(value.split(',')))})")
                    bindings += value.split(",")
                    field = key
                else:
                    where_field.append(f"{_qualify(key)} = ?")
                    bindings.append(_convert_hash_value(key, value))
                    field = key
            # Track the base field name and whether the WHERE references a
            # column that only exists on a joined table.
            where_fields_used.add(field)
            if rewrite_messages_tx_hash and field == "tx_hash":
                where_needs_join = True

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

    cursor_field_qualified = _qualify(cursor_field)
    if offset is None and last_cursor is not None:
        if where_clause != "":
            where_clause = f"({where_clause}) AND "
        if order == "ASC":
            where_clause += f" {cursor_field_qualified} >= ?"
        else:
            where_clause += f" {cursor_field_qualified} <= ?"
        bindings.append(last_cursor)

    if where_clause:
        where_clause = f"WHERE ({where_clause}) "
    else:
        where_clause = ""

    group_by_clause = ""
    if group_by:
        group_by_clause = f"GROUP BY {group_by}"

    if select == "*":
        select = f"*, {cursor_field_qualified} AS {cursor_field}"
    elif cursor_field not in select:
        select = f"{select}, {cursor_field_qualified} AS {cursor_field}"
    if (
        table
        in [
            "all_transactions_with_status",
            "transactions_with_status",
            "sends",
            "btcpays",
            "sweeps",
            "dispenses",
        ]
        and "COUNT(*)" not in select
    ):
        # When ``dispenses`` rows are read through the hash-FK JOIN, the
        # outer ``transactions`` row also contains a ``destination`` column;
        # qualify the reference so SQLite knows we mean the dispense row.
        dest_ref = "__m.destination" if table_has_hash_fk else "destination"
        select += f", NULLIF({dest_ref}, '') AS destination"

    # Rewrite ``SELECT ... tx_hash ... FROM messages`` to project
    # ``transactions.tx_hash`` through the join we set up above.
    if rewrite_messages_tx_hash:
        txtable = _resolve_transactions_table_name(db)
        if txtable is None:
            from_clause = "messages AS __m"
            # Word-boundary safe substitution so embedded substrings such as
            # ``last_status_tx_hash`` (not a column on ``messages`` today, but
            # this branch is shared with future schema additions) are not
            # corrupted by a naive ``str.replace``.
            select_rewritten = re.sub(
                r"(?<![A-Za-z0-9_\.])tx_hash(?![A-Za-z0-9_])",
                "NULL AS tx_hash",
                select,
            )
        else:
            from_clause = (
                f"messages AS __m LEFT JOIN {txtable} AS __txh ON __txh.tx_index = __m.tx_index"
            )
            # Project tx_hash from the joined transactions; leave other columns
            # untouched. We do a token-level rewrite so embedded substrings such
            # as ``last_status_tx_hash`` are not touched.
            select_rewritten = _project_messages_tx_hash(select)
    elif table_has_hash_fk:
        # Add the legacy hash column back via a JOIN against ``transactions``
        # so the API row shape remains unchanged after the column drop.
        # Explicitly enumerate public columns so the internal ``*_tx_index``
        # FK that replaced the legacy hash does NOT leak into the response.
        index_col, hash_col = _HASH_FK_PROJECTIONS[table]
        public_cols = _hash_fk_public_columns(db, table)
        explicit_cols = ", ".join(f"__m.{c}" for c in public_cols)
        txtable = _resolve_transactions_table_name(db)
        if txtable is None:
            # No transactions table available (e.g. State DB without the
            # Ledger DB attached). Skip the JOIN and surface a NULL legacy
            # hash; callers that need the real hash can fetch it separately.
            from_clause = f"{table} AS __m"
            if "*" in select:
                select_rewritten = select.replace("*", f"{explicit_cols}, NULL AS {hash_col}", 1)
            else:
                select_rewritten = f"{select}, NULL AS {hash_col}"
        else:
            from_clause = (
                f"{table} AS __m LEFT JOIN {txtable} AS __txjoin "
                f"ON __txjoin.tx_index = __m.{index_col}"
            )
            # ``hash_col`` (dispenser_tx_hash / fairminter_tx_hash / order_tx_hash
            # / offer_hash) is in ``hashcodec.HASH_COLUMN_NAMES`` so the rowtracer
            # converts the BLOB to 64-char hex; no per-row Python UDF needed.
            if "*" in select:
                # Expand the bare ``*`` to the explicit public column list
                # and re-add the legacy hash via the JOIN.
                select_rewritten = select.replace(
                    "*",
                    f"{explicit_cols}, __txjoin.tx_hash AS {hash_col}",
                    1,
                )
            else:
                select_rewritten = f"{select}, __txjoin.tx_hash AS {hash_col}"
    else:
        from_clause = table
        select_rewritten = select

    query = f"SELECT {select_rewritten} FROM {from_clause} {where_clause} {group_by_clause}"  # nosec B608  # noqa: S608 # nosec B608

    # COUNT(*) query fast-path: when there is no ``group_by`` and no
    # ``wrap_where``, the LEFT JOINs we added for ``messages`` and the
    # ``_HASH_FK_PROJECTIONS`` tables do not affect the row count (they all
    # join on a unique key on the right). Building the COUNT against the
    # main table alone, with a tightly scoped ``WHERE``, lets SQLite use
    # the appropriate index and skip materializing JOIN rows. For a
    # 100K-row ledger this turns a 20ms wrap-COUNT into a sub-ms direct
    # COUNT. Falls back to the legacy wrap pattern when ``group_by`` is
    # present (where the wrap is required for correct semantics) or when
    # ``wrap_where`` filters on JOIN'd columns.
    count_fast_from = None
    if not group_by_clause and wrap_where is None:
        if rewrite_messages_tx_hash:
            # ``messages`` reads need the JOIN only if the caller filters on
            # ``tx_hash`` (the joined ``__txh`` column). All other filters
            # are on plain ``messages`` columns, so we count from
            # ``messages`` directly.
            if where_needs_join:
                count_fast_from = from_clause
            else:
                count_fast_from = "messages AS __m"
        elif table_has_hash_fk:
            # The hash-FK rewrite resolves ``*_tx_hash`` filters via a
            # correlated subquery on ``transactions`` (see
            # ``_HASH_FK_WHERE_REWRITE``), so the LEFT JOIN is only there
            # to expose the legacy hash column to the SELECT. Skip it
            # entirely for COUNT.
            count_fast_from = f"{table} AS __m"
        elif table in _COUNT_FROM_OVERRIDE:
            # Views like ``transactions_with_status`` wrap a LEFT JOIN
            # against ``blocks`` / ``transactions_status``; counting from
            # the underlying ``transactions`` table is equivalent (the
            # LEFT JOINs are on a unique key on the right) -- but only if
            # the caller's filter is restricted to columns that exist on
            # the underlying table.
            main_table, safe_columns = _COUNT_FROM_OVERRIDE[table]
            if where_fields_used <= safe_columns:
                count_fast_from = main_table

    if count_fast_from is not None:
        query_count = f"SELECT COUNT(*) AS count FROM {count_fast_from} {where_clause_count}"  # nosec B608  # noqa: S608 # nosec B608
    else:
        # Legacy wrap-COUNT path: required when ``group_by`` is set or the
        # caller passes ``wrap_where`` whose filter may reference JOIN'd
        # columns.
        query_count = (
            f"SELECT {select_rewritten} FROM {from_clause} {where_clause_count} {group_by_clause}"  # nosec B608  # noqa: S608 # nosec B608
        )

    if wrap_where is not None:
        wrap_where_field = []
        for key, value in wrap_where.items():
            if key.endswith("__gt"):
                field = key[:-4]
                wrap_where_field.append(f"{field} > ?")
            else:
                field = key
                wrap_where_field.append(f"{field} = ?")
            converted = _convert_hash_value(field, value)
            bindings.append(converted)
            bindings_count.append(converted)
        wrap_where_clause = " AND ".join(wrap_where_field)
        wrap_where_clause = f"WHERE {wrap_where_clause}"
        query = f"SELECT * FROM ({query}) {wrap_where_clause}"  # nosec B608  # noqa: S608 # nosec B608
        query_count = f"SELECT COUNT(*) AS count FROM ({query_count}) {wrap_where_clause}"  # nosec B608  # noqa: S608 # nosec B608
    elif count_fast_from is None:
        # ``group_by`` path: COUNT(*) over the grouped sub-select.
        query_count = f"SELECT COUNT(*) AS count FROM ({query_count})"  # nosec B608  # noqa: S608 # nosec B608

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
    elif table == "all_transactions_with_status":
        order_by.append("confirmed ASC")
        order_by.append(f"{cursor_field} {order}")
    if len(order_by) == 0:
        order_by.append(f"{cursor_field} {order}")
    order_by_clause = f"ORDER BY {','.join(order_by)}"

    query = f"{query} {order_by_clause} LIMIT ?"  # nosec B608  # noqa: S608 # nosec B608
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
        # Don't return a cursor when using sort or offset
        # (cursor is ignored in those cases, so returning one would cause infinite loops)
        if sort is not None or offset is not None:
            next_cursor = None
        else:
            next_cursor = result[-1][cursor_field]
        result = result[:-1]
    else:
        next_cursor = None

    if table in ["messages", "mempool"]:
        for row in result:
            if "params" not in row:
                break
            row["params"] = json.loads(row["params"])

    if table == "all_transactions_with_status":
        for row in result:
            row["confirmed"] = bool(row["confirmed"])

    return QueryResult(result, next_cursor, table, result_count)


def select_row(db, table, where, select="*", group_by=""):
    query_result = select_rows(db, table, where, limit=1, select=select, group_by=group_by)
    if query_result.result:
        return QueryResult(query_result.result[0], None, table, 1)
    return None


GET_BLOCKS_WHERE = {
    "ledger_hash__notnull": None,
}


def get_blocks(ledger_db, cursor: int = None, limit: int = 10, offset: int = None):
    """
    Returns the list of the last ten blocks
    :param int cursor: The index of the most recent block to return (e.g. $LAST_BLOCK_INDEX)
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


def prepare_transactions_where(type, other_conditions=None):  # pylint: disable=W0622
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
    type: TransactionType = "all",  # pylint: disable=W0622
    show_unconfirmed: bool = False,
    valid: bool = None,
    cursor: int = None,
    limit: int = 10,
    offset: int = None,
):
    """
    Returns the list of the last ten transactions
    :param str type: The type of the transaction to return
    :param bool show_unconfirmed: Show unconfirmed transactions
    :param bool valid: If True, only return valid transactions
    :param int cursor: The index of the most recent transactions to return (e.g. $LAST_TX_INDEX)
    :param int limit: The number of transactions to return (e.g. 2)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    table_name = "all_transactions_with_status" if show_unconfirmed else "transactions_with_status"
    where = None
    if valid is not None:
        where = {"valid": valid}
    return select_rows(
        ledger_db,
        table_name,
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        where=prepare_transactions_where(type, where),
    )


def get_transactions_by_block(
    ledger_db,
    block_index: int,
    type: TransactionType = "all",  # pylint: disable=W0622
    show_unconfirmed: bool = False,
    valid: bool = None,
    cursor: int = None,
    limit: int = 10,
    offset: int = None,
):
    """
    Returns the transactions of a block
    :param int block_index: The index of the block to return (e.g. $LAST_BLOCK_INDEX)
    :param str type: The type of the transaction to return
    :param bool show_unconfirmed: Show unconfirmed transactions
    :param bool valid: If True, only return valid transactions
    :param int cursor: The last transaction index to return (e.g. $LAST_TX_INDEX)
    :param int limit: The maximum number of transactions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    table_name = "all_transactions_with_status" if show_unconfirmed else "transactions_with_status"
    where = {"block_index": block_index}
    if valid is not None:
        where["valid"] = valid
    return select_rows(
        ledger_db,
        table_name,
        where=prepare_transactions_where(type, where),
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_transactions_by_address(
    ledger_db,
    address: str,
    type: TransactionType = "all",  # pylint: disable=W0622
    show_unconfirmed: bool = False,
    valid: bool = None,
    cursor: int = None,
    limit: int = 10,
    offset: int = None,
):
    """
    Returns the transactions of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str type: The type of the transaction to return
    :param bool show_unconfirmed: Show unconfirmed transactions
    :param bool valid: If True, only return valid transactions
    :param int cursor: The last transaction index to return (e.g. $LAST_TX_INDEX)
    :param int limit: The maximum number of transactions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"source": address}
    if valid is not None:
        where["valid"] = valid
    table_name = "all_transactions_with_status" if show_unconfirmed else "transactions_with_status"
    return select_rows(
        ledger_db,
        table_name,
        where=prepare_transactions_where(type, where),
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_transactions_by_addresses(
    ledger_db,
    addresses: str,
    type: TransactionType = "all",  # pylint: disable=W0622
    show_unconfirmed: bool = False,
    valid: bool = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the transactions of a list of addresses
    :param str addresses: Comma separated list of addresses to return (e.g. $ADDRESS_1,$ADDRESS_2)
    :param str type: The type of the transaction to return
    :param bool show_unconfirmed: Show unconfirmed transactions
    :param bool valid: If True, only return valid transactions
    :param int cursor: The last transaction index to return (e.g. $LAST_TX_INDEX)
    :param int limit: The maximum number of transactions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"source__in": addresses.split(",")}
    if valid is not None:
        where["valid"] = valid
    table_name = "all_transactions_with_status" if show_unconfirmed else "transactions_with_status"
    return select_rows(
        ledger_db,
        table_name,
        where=prepare_transactions_where(type, where),
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_transaction_types_count(state_db):
    """
    Returns the count of each transaction type
    """
    return select_rows(
        state_db,
        "transaction_types_count",
        select="transaction_type, count",
        cursor_field="count",
        order="DESC",
    )


def get_transaction_types_count_by_block(
    ledger_db, block_index: int, count_unconfirmed: bool = False
):
    """
    Returns the count of each transaction type
    :param int block_index: The index of the block to return (e.g. $LAST_TX_INDEX)
    :param bool count_unconfirmed: Count unconfirmed transactions
    """
    table_name = "all_transactions_with_status" if count_unconfirmed else "transactions_with_status"
    return select_rows(
        ledger_db,
        table_name,
        select="transaction_type, COUNT(*) AS count",
        where={"block_index": block_index},
        group_by="transaction_type",
        cursor_field="count",
        order="DESC",
    )


def get_transaction_types_count_by_address(
    ledger_db, address: str, count_unconfirmed: bool = False
):
    """
    Returns the count of each transaction type
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param bool count_unconfirmed: Count unconfirmed transactions
    """
    table_name = "all_transactions_with_status" if count_unconfirmed else "transactions_with_status"
    return select_rows(
        ledger_db,
        table_name,
        select="transaction_type, COUNT(*) AS count",
        where={"source": address},
        group_by="transaction_type",
        cursor_field="count",
        order="DESC",
    )


def get_transaction_by_hash(ledger_db, tx_hash: str):
    """
    Returns a transaction by its hash.
    :param tx_hash: The hash of the transaction (e.g. $LAST_TX_HASH)
    """
    return select_row(
        ledger_db,
        "all_transactions_with_status",
        where={"tx_hash": tx_hash},
    )


def get_transaction_by_tx_index(ledger_db, tx_index: int):
    """
    Returns a transaction by its index.
    :param tx_index: The index of the transaction (e.g. $LAST_TX_INDEX)
    """
    return select_row(
        ledger_db,
        "all_transactions_with_status",
        where={"tx_index": tx_index},
    )


def get_all_events(
    ledger_db, event_name: str = None, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns all events
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a block
    :param int block_index: The index of the block to return (e.g. $LAST_EVENT_BLOCK)
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_EVENT_TX_HASH)
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
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
    ledger_db, tx_hash: str, event: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_EVENT_TX_HASH)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. $LAST_EVENT_TX_INDEX)
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    query_result = select_row(ledger_db, "transactions_with_status", where={"tx_index": tx_index})
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
    ledger_db, tx_index: int, event: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. $LAST_EVENT_TX_INDEX)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    query_result = select_row(ledger_db, "transactions_with_status", where={"tx_index": tx_index})
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a block filtered by event
    :param int block_index: The index of the block to return (e.g. $LAST_EVENT_BLOCK)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int cursor: The last event index to return
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
    ledger_db, event: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the events filtered by event name
    :param str event: The event to return (e.g. CREDIT)
    :param int cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the events of a list of addresses
    :param str addresses: Comma separated list of addresses to return (e.g. $ADDRESS_1,$ADDRESS_2)
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return (e.g. $LAST_EVENT_INDEX)
    :param int limit: The maximum number of events to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = [{"address__in": addresses.split(",")}]
    if event_name:
        where[0]["event__in"] = event_name.split(",")
    events = select_rows(
        state_db,
        "address_events",
        where=where,
        cursor_field="event_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )
    events_indexes = [event["event_index"] for event in events.result]
    result = select_rows(
        ledger_db,
        "messages",
        where={"message_index__in": events_indexes},
        cursor_field="event_index",
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index",
    )
    return QueryResult(result.result, events.next_cursor, "messages", events.result_count)


def get_all_mempool_events(
    ledger_db,
    event_name: str = None,
    addresses: str = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns all mempool events
    :param str event_name: Comma separated list of events to return
    :param str addresses: Comma separated list of addresses to return
    :param int cursor: The last event index to return
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
    ledger_db, event: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the mempool events filtered by event name
    :param str event: The event to return (e.g. CREDIT)
    :param int cursor: The last event index to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the mempool events filtered by transaction hash
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_MEMPOOL_TX_HASH)
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return
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
    ledger_db, addresses: str, event_name: str = None, cursor: int = None, limit: int = 100
):
    """
    Returns the mempool events of a list of addresses
    :param str addresses: Comma separated list of addresses to return (e.g. $ADDRESS_3,$ADDRESS_4)
    :param str event_name: Comma separated list of events to return
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    where = []
    for address in addresses.split(","):
        where_address = {"addresses__like": f"%{address}%"}
        if event_name:
            where_address["event__in"] = event_name.split(",")
        where.append(where_address)
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
    :param str cursor: The last event name to return
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


def get_all_events_counts(state_db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns the event counts of all blocks
    :param int cursor: The last event index to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the credits of a block
    :param int block_index: The index of the block to return (e.g. $LAST_CREDIT_BLOCK)
    :param str action: The action to filter by
    :param int cursor: The last credit index to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the credits of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str action: The action to filter by
    :param int cursor: The last index of the credits to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the credits of an asset
    :param str asset: The asset to return (e.g. $ASSET_1)
    :param str action: The action to filter by
    :param int cursor: The last index of the credits to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the debits of a block
    :param int block_index: The index of the block to return (e.g. $LAST_DEBIT_BLOCK)
    :param str action: The action to filter by
    :param int cursor: The last index of the debits to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the debits of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str action: The action to filter by
    :param int cursor: The last index of the debits to return
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
    return select_rows(
        ledger_db, "debits", where=where, last_cursor=cursor, limit=limit, offset=offset
    )


def prepare_sends_where(send_type: SendType, other_conditions=None):
    where = []
    send_type_list = send_type.split(",")
    for type_send in send_type_list:
        if type_send == "all":
            if isinstance(other_conditions, dict):
                where = [other_conditions]
            elif isinstance(other_conditions, list):
                where = other_conditions
            break
        if type_send in typing.get_args(SendType):
            where_send = {"send_type": type_send}
            if other_conditions:
                if isinstance(other_conditions, dict):
                    where_send.update(other_conditions)
                    where.append(where_send)
                elif isinstance(other_conditions, list):
                    for other_condition in other_conditions:
                        where.append(other_condition | where_send)
            else:
                where.append(where_send)
    return where


def get_sends(
    ledger_db, send_type: SendType = "all", cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns all the sends include Enhanced and MPMA sends
    :param str send_type: The type of the send to return
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where=prepare_sends_where(send_type),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_block(
    ledger_db,
    block_index: int,
    send_type: SendType = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the sends, include Enhanced and MPMA sends, of a block
    :param int block_index: The index of the block to return (e.g. $LAST_SEND_BLOCK)
    :param str send_type: The type of the send to return
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where=prepare_sends_where(send_type, {"block_index": block_index}),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_transaction_hash(
    ledger_db,
    tx_hash: str,
    send_type: SendType = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the sends, include Enhanced and MPMA sends, of a block
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_SEND_TX_HASH)
    :param str send_type: The type of the send to return
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where=prepare_sends_where(send_type, {"tx_hash": tx_hash}),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_asset(
    ledger_db,
    asset: str,
    send_type: SendType = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the sends, include Enhanced and MPMA sends, of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param str send_type: The type of the send to return
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where=prepare_sends_where(send_type, {"asset": asset.upper()}),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_expirations(
    state_db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the expirations of a block
    :param int block_index: The index of the block to return (e.g. $LAST_ORDER_EXPIRATION_BLOCK)
    :param int cursor: The last index of the expirations to return
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
    ledger_db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the cancels of a block
    :param int block_index: The index of the block to return (e.g. $LAST_CANCEL_BLOCK)
    :param int cursor: The last index of the cancels to return
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


def get_all_valid_destructions(ledger_db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns the destructions of a block
    :param int cursor: The last index of the destructions to return
    :param int limit: The maximum number of destructions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "destructions",
        where={"status": "valid"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_valid_destructions_by_block(
    ledger_db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the destructions of a block
    :param int block_index: The index of the block to return (e.g. $LAST_DESTRUCTION_BLOCK)
    :param int cursor: The last index of the destructions to return
    :param int limit: The maximum number of destructions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "destructions",
        where={"block_index": block_index, "status": "valid"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_valid_destructions_by_address(
    ledger_db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the destructions of a block
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param int cursor: The last index of the destructions to return
    :param int limit: The maximum number of destructions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "destructions",
        where={"source": address, "status": "valid"},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_valid_destructions_by_asset(
    ledger_db, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the destructions of a block
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the destructions to return
    :param int limit: The maximum number of destructions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "destructions",
        where={"asset": asset.upper(), "status": "valid"},
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns all the issuances
    :param int cursor: The last index of the issuances to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the issuances of a block
    :param int block_index: The index of the block to return (e.g. $LAST_ISSUANCE_BLOCK)
    :param str asset_events: Filter result by one or several comma separated asset events
    :param int cursor: The last index of the issuances to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the issuances of an asset
    :param str asset: The asset to return (e.g. $ASSET_1)
    :param str asset_events: Filter result by one or several comma separated asset events
    :param int cursor: The last index of the issuances to return
    :param int limit: The maximum number of issuances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = prepare_issuance_where(
        asset_events, {"asset": asset.upper(), "status": "valid"}
    ) + prepare_issuance_where(
        asset_events, {"asset_longname__nocase": asset.upper(), "status": "valid"}
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the issuances of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str asset_events: Filter result by one or several comma separated asset events
    :param int cursor: The last index of the issuances to return
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


def get_dispenses(ledger_db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns all the dispenses
    :param int cursor: The last index of the dispenses to return
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


def get_dispense(ledger_db, tx_hash: str):
    """
    Returns all the dispenses
    :param str tx_hash: The hash of the transaction to return
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_row(
        ledger_db,
        "dispenses",
        where={"tx_hash": tx_hash},
    )


def get_dispenses_by_block(
    ledger_db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a block
    :param int block_index: The index of the block to return (e.g. $LAST_DISPENSE_BLOCK)
    :param int cursor: The last index of the dispenses to return
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
    ledger_db, tx_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a block
    :param str tx_hash: The hash of the transaction to return (e.g. $LAST_DISPENSE_TX_HASH)
    :param int cursor: The last index of the dispenses to return
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
    ledger_db, dispenser_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a dispenser
    :param str dispenser_hash: The hash of the dispenser to return (e.g. $DISPENSER_TX_HASH_1)
    :param int cursor: The last index of the dispenses to return
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
    ledger_db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a source
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param int cursor: The last index of the dispenses to return
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
    ledger_db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of a destination
    :param str address: The address to return (e.g. $ADDRESS_2)
    :param int cursor: The last index of the dispenses to return
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
    ledger_db,
    asset: str,
    block_index: int = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the dispenses of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param int block_index: The index of the block to return
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = {"asset": asset.upper()}
    if block_index:
        where["block_index"] = block_index
    return select_rows(
        ledger_db,
        "dispenses",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_dispenses_by_source_and_asset(
    ledger_db, address: str, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the dispenses to return
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
    ledger_db, address: str, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. $ADDRESS_2)
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the dispenses to return
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


def get_sweeps(ledger_db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns all sweeps
    :param int cursor: The last index of the sweeps to return
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
    ledger_db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the sweeps of a block
    :param int block_index: The index of the block to return (e.g. $LAST_SWEEP_BLOCK)
    :param int cursor: The last index of the sweeps to return
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
    ledger_db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the sweeps of an address
    :param str address: The address to return (e.g. $ADDRESS_3)
    :param int cursor: The last index of the sweeps to return
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
    type: BalanceType = "all",  # pylint: disable=W0622
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the balances of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str type: The type of balances to return
    :param int cursor: The last index of the balances to return
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
        select="address, asset, asset_longname, quantity, utxo, utxo_address",
        sort=sort,
    )


def get_utxo_balances(
    state_db, utxo: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the balances of an utxo
    :param str utxo: The utxo to return (e.g. $UTXO_WITH_BALANCE)
    :param int cursor: The last index of the balances to return
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
        select="asset, asset_longname, quantity, utxo, utxo_address",
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

    return QueryResult(result, None, "balances", len(utxo_list))


def get_balances_by_addresses(  # pylint: disable=unused-argument
    state_db,
    addresses: str,
    type: BalanceType = "all",  # pylint: disable=W0622
    asset: str = None,
    cursor: str = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the balances of several addresses
    :param str addresses: Comma separated list of addresses (e.g. $ADDRESS_1,$ADDRESS_2)
    :param str type: The type of balances to return
    :param str asset: The asset to return (e.g. XCP)
    :param str cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the balances to return (overrides the `cursor` parameter) (e.g. quantity:desc)
    """
    address_list = addresses.split(",")
    cursor_db = state_db.cursor()

    # Build WHERE conditions based on type and asset filters
    where_conditions = []
    bindings = []

    # Address conditions based on type
    if type in ["all", "address"]:
        where_conditions.append(
            f"(address IN ({','.join(['?'] * len(address_list))}) AND quantity > 0)"
        )
        bindings.extend(address_list)

    if type in ["all", "utxo"]:
        where_conditions.append(
            f"(utxo_address IN ({','.join(['?'] * len(address_list))}) AND quantity > 0)"
        )
        bindings.extend(address_list)

    # Asset condition
    asset_condition = ""
    if asset is not None:
        asset_condition = " AND (asset = ? OR asset_longname = ?)"
        bindings.extend([asset, asset])

    # Combine WHERE conditions
    where_clause = " OR ".join(where_conditions)
    if asset_condition:
        where_clause = f"({where_clause}){asset_condition}"

    # Handle cursor for pagination (only when asset is None)
    cursor_condition = ""
    if asset is None and offset is None and cursor is not None:
        cursor_condition = " AND asset >= ?"
        bindings.append(cursor)

    # Build the main query with JSON aggregation
    final_where_clause = f"({where_clause})"
    if cursor_condition:
        final_where_clause = f"({where_clause}){cursor_condition}"

    sql = f"""
        SELECT 
            asset,
            asset_longname,
            SUM(quantity) as total,
            json_group_array(
                json_object(
                    'address', address,
                    'utxo', utxo,
                    'utxo_address', utxo_address,
                    'quantity', quantity
                )
            ) as addresses
        FROM balances
        WHERE {final_where_clause}
        GROUP BY asset, asset_longname
        ORDER BY asset ASC
    """  # nosec B608  # noqa: S608

    # Calculate next_cursor and result_count when asset is None
    next_cursor = None
    result_count = 0

    if asset is None:
        # Use limit + 1 to check if there are more results for pagination
        query_limit = limit + 1
        sql += f" LIMIT {query_limit}"
        if offset:
            sql += f" OFFSET {offset}"

        cursor_db.execute(sql, bindings)
        results = cursor_db.fetchall()

        # Check if we have more results than the limit
        if len(results) > limit:
            next_cursor = results[-1]["asset"]  # Last asset name becomes next cursor
            results = results[:-1]  # Remove the extra result

        # Count total results for result_count (without cursor condition)
        count_sql = f"""
            SELECT COUNT(DISTINCT asset) as count
            FROM balances
            WHERE ({where_clause})
        """  # nosec B608  # noqa: S608
        count_bindings = (
            bindings[:-1] if cursor is not None else bindings
        )  # Remove cursor binding for count
        cursor_db.execute(count_sql, count_bindings)
        result_count = cursor_db.fetchone()["count"]
    else:
        # When specific asset is provided, no pagination
        if limit:
            sql += f" LIMIT {limit}"
        if offset:
            sql += f" OFFSET {offset}"

        cursor_db.execute(sql, bindings)
        results = cursor_db.fetchall()
        result_count = 1 if results else 0

    # Process results to match the expected format
    result = []
    for row in results:
        addresses_data = json.loads(row["addresses"])
        result.append(
            {
                "asset": row["asset"],
                "asset_longname": row["asset_longname"],
                "total": row["total"],
                "addresses": addresses_data,
            }
        )

    return QueryResult(result, next_cursor, "balances", result_count)


def get_balances_by_address_and_asset(
    state_db,
    address: str,
    asset: str,
    type: BalanceType = "all",  # pylint: disable=W0622
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the balances of an address and asset
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str asset: The asset to return (e.g. XCP)
    :param str type: The type of balances to return
    :param int cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    where = [
        {"address": address, "asset": asset.upper(), "quantity__gt": 0},
        {"address": address, "asset_longname": asset.upper(), "quantity__gt": 0},
        {"utxo_address": address, "asset": asset.upper(), "quantity__gt": 0},
        {"utxo_address": address, "asset_longname": asset.upper(), "quantity__gt": 0},
    ]
    if type == "utxo":
        where.pop(0)
        where.pop(0)  # pop twice to remove first two elements
    elif type == "address":
        where.pop()  # pop last element (index 3)
        where.pop()  # pop new last element (was index 2)

    return select_rows(
        state_db,
        "balances",
        select="address, asset, asset_longname, quantity, utxo, utxo_address",
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
    state_db, status: BetStatus = "open", cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the bets of a feed
    :param str status: The status of the bet (e.g. filled)
    :param int cursor: The last index of the bets to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the bets of a feed
    :param str address: The address of the feed (e.g. $ADDRESS_1)
    :param str status: The status of the bet (e.g. filled)
    :param int cursor: The last index of the bets to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the broadcasts of a source
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param int cursor: The last index of the broadcasts to return
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
    ledger_db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the burns of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param int cursor: The last index of the burns to return
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
    ledger_db,
    address: str,
    send_type: SendType = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the sends, include Enhanced and MPMA sends, of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str send_type: The type of sends to return
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where=prepare_sends_where(
            send_type,
            [
                {"source": address},
                {"source_address": address},
                {"destination": address},
                {"destination_address": address},
            ],
        ),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_sends_by_address_and_asset(
    ledger_db,
    address: str,
    asset: str,
    send_type: SendType = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the sends, include Enhanced and MPMA sends, of an address and asset
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str asset: The asset to return (e.g. $ASSET_5)
    :param str send_type: The type of sends to return
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where=prepare_sends_where(
            send_type,
            [
                {"source": address, "asset": asset.upper()},
                {"source_address": address, "asset": asset.upper()},
                {"destination": address, "asset": asset.upper()},
                {"destination_address": address, "asset": asset.upper()},
            ],
        ),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_receive_by_address(
    ledger_db,
    address: str,
    send_type: SendType = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the receives of an address
    :param str address: The address to return (e.g. $ADDRESS_5)
    :param str send_type: The type of sends to return
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where=prepare_sends_where(send_type, {"destination": address}),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_receive_by_address_and_asset(
    ledger_db,
    address: str,
    asset: str,
    send_type: SendType = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the receives of an address and asset
    :param str address: The address to return (e.g. $ADDRESS_5)
    :param str asset: The asset to return (e.g. $ASSET_5)
    :param str send_type: The type of sends to return
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "sends",
        where=prepare_sends_where(send_type, {"destination": address, "asset": asset.upper()}),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def prepare_dispenser_where(status, other_conditions=None, exclude_with_oracle=False):
    where = []
    statuses = status.split(",")
    for s in statuses:
        if s.isdigit():
            s = DispenserStatusNumberInverted.get(int(s), "all")  # noqa: PLW2901

        if s == "all":
            where = other_conditions or {}
            if exclude_with_oracle:
                where["oracle_address__null"] = True
            break

        if s in DispenserStatusNumber:
            where_status = {"status": DispenserStatusNumber[s]}
            if other_conditions:
                where_status.update(other_conditions)
            if exclude_with_oracle:
                where_status["oracle_address__null"] = True

            where.append(where_status)

    return where


SELECT_DISPENSERS = "*, (satoshirate * 1.0) / (give_quantity * 1.0) AS price"


def get_dispensers(
    state_db,
    status: DispenserStatus = "all",
    exclude_with_oracle: bool = False,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns all dispensers
    :param str status: The status of the dispensers to return
    :param bool exclude_with_oracle: Whether to exclude dispensers with an oracle
    :param int cursor: The last index of the dispensers to return
    :param int limit: The maximum number of dispensers to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the dispensers to return (overrides the `cursor` parameter) (e.g. block_index:asc)
    """

    return select_rows(
        state_db,
        "dispensers",
        where=prepare_dispenser_where(status, exclude_with_oracle=exclude_with_oracle),
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
    exclude_with_oracle: bool = False,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the dispensers of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str status: The status of the dispensers to return
    :param bool exclude_with_oracle: Whether to exclude dispensers with an oracle
    :param int cursor: The last index of the dispensers to return
    :param int limit: The maximum number of dispensers to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the dispensers to return (overrides the `cursor` parameter) (e.g. give_quantity:desc)
    """
    return select_rows(
        state_db,
        "dispensers",
        where=prepare_dispenser_where(
            status, {"source": address}, exclude_with_oracle=exclude_with_oracle
        ),
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
    exclude_with_oracle: bool = False,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the dispensers of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param str status: The status of the dispensers to return
    :param bool exclude_with_oracle: Whether to exclude dispensers with an oracle
    :param int cursor: The last index of the dispensers to return
    :param int limit: The maximum number of dispensers to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the dispensers to return (overrides the `cursor` parameter) (e.g. give_quantity:desc)
    """
    return select_rows(
        state_db,
        "dispensers",
        where=prepare_dispenser_where(
            status, {"asset": asset.upper()}, exclude_with_oracle=exclude_with_oracle
        ),
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
    state_db, named: bool = None, cursor: int = None, limit: int = 100, offset: int = None
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
    where = [{"asset": asset.upper()}, {"asset_longname__nocase": asset.upper()}]
    return select_row(
        state_db,
        "assets_info",
        where=where,
    )


def get_subassets_by_asset(
    state_db, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns asset subassets
    :param str asset: The name of the asset to return (e.g. $ASSET_7)
    :param int cursor: The last index of the assets to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the valid assets issued by an address
    :param str address: The issuer to return (e.g. $ADDRESS_1)
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the valid assets owned by an address
    :param str address: The owner to return (e.g. $ADDRESS_1)
    :param bool named: Whether to return only named assets (e.g. true)
    :param int cursor: The last index of the assets to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the valid assets issued or owned by an address
    :param str address: The issuer or owner to return (e.g. $ADDRESS_1)
    :param bool named: Whether to return only named assets (e.g. true)
    :param int cursor: The last index of the assets to return
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


def get_dividends(ledger_db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns all the dividends
    :param int cursor: The last index of the dividend to return
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
    ledger_db, asset: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dividends of an asset
    :param str asset: The asset to return (e.g. $ASSET_5)
    :param int cursor: The last index of the dividend to return
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
    ledger_db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the dividends distributed by an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param int cursor: The last index of the assets to return
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
    ledger_db, dividend_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns a dividend distribution by its hash
    :param str dividend_hash: The hash of the dividend distribution to return (e.g. $LAST_DIVIDEND_TX_HASH)
    :param int cursor: The last index of the credit to return
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
    type: BalanceType = "all",  # pylint: disable=W0622
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the asset balances
    :param str asset: The asset to return (e.g. $ASSET_1)
    :param str type: The type of balances to return
    :param int cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the balances to return (overrides the `cursor` parameter) (e.g. quantity:desc)
    """
    where = [
        {"asset": asset.upper(), "quantity__gt": 0},
        {"asset_longname": asset.upper(), "quantity__gt": 0},
    ]
    if type == "utxo":
        where[0]["utxo__notnull"] = True
        where[1]["utxo__notnull"] = True
    elif type == "address":
        where[0]["address__notnull"] = True
        where[1]["address__notnull"] = True

    return select_rows(
        state_db,
        "balances",
        where=where,
        select="address, utxo, utxo_address, asset, asset_longname, quantity",
        order="ASC",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def prepare_where_status(status, arg_type, other_conditions=None):
    where = []
    statuses = status.split(",")
    for status_item in statuses:
        if status_item == "all":
            where = [other_conditions] if other_conditions else []
            break
        if status_item in typing.get_args(arg_type):
            where_status = {"status": status_item}
            if other_conditions:
                where_status.update(other_conditions)
            where.append(where_status)
    return where


def prepare_order_where(status, other_conditions=None):
    return prepare_where_status(status, OrderStatus, other_conditions=other_conditions)


def prepare_order_matches_where(status, other_conditions=None):
    return prepare_where_status(status, OrderMatchesStatus, other_conditions=other_conditions)


SELECT_ORDERS = (
    "*, "
    "COALESCE((get_quantity * 1.0) / (give_quantity * 1.0), 0) AS give_price, "
    "COALESCE((give_quantity * 1.0) / (get_quantity * 1.0), 0) AS get_price"
)
SELECT_ORDER_MATCHES = SELECT_ORDERS.replace("get_", "forward_").replace("give_", "backward_")


def get_orders(
    state_db,
    status: OrderStatus = "all",
    get_asset: str = None,  # pylint: disable=W0621
    give_asset: str = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns all the orders
    :param str status: The status of the orders to return
    :param str get_asset: The get asset to return
    :param str give_asset: The give asset to return
    :param int cursor: The last index of the orders to return
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
        "orders_info",
        cursor_field="tx_index",
        where=prepare_order_where(status, where),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def get_orders_by_asset(
    state_db,
    asset: str,
    status: OrderStatus = "all",
    get_asset: str = None,  # pylint: disable=W0621
    give_asset: str = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the orders of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param str status: The status of the orders to return
    :param str get_asset: The get asset to return
    :param str give_asset: The give asset to return
    :param int cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the orders to return (overrides the `cursor` parameter) (e.g. expiration:desc)
    """
    if get_asset:
        where = prepare_order_where(
            status, {"get_asset": get_asset.upper(), "give_asset": asset.upper()}
        )
    elif give_asset:
        where = prepare_order_where(
            status, {"give_asset": give_asset.upper(), "get_asset": asset.upper()}
        )
    else:
        where = prepare_order_where(status, {"give_asset": asset.upper()}) + prepare_order_where(
            status, {"get_asset": asset.upper()}
        )

    return select_rows(
        state_db,
        "orders_info",
        cursor_field="tx_index",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def get_orders_by_address(
    state_db,
    address: str,
    status: OrderStatus = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the orders of an address
    :param str address: The address to return (e.g. $ADDRESS_1)
    :param str status: The status of the orders to return
    :param int cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the orders to return (overrides the `cursor` parameter) (e.g. expiration:desc)
    """
    return select_rows(
        state_db,
        "orders_info",
        cursor_field="tx_index",
        where=prepare_order_where(status, {"source": address}),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def get_orders_by_two_assets(
    state_db,
    asset1: str,
    asset2: str,
    status: OrderStatus = "all",
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the orders to exchange two assets
    :param str asset1: The first asset to return (e.g. BTC)
    :param str asset2: The second asset to return (e.g. XCP)
    :param str status: The status of the orders to return
    :param int cursor: The last index of the orders to return
    :param int limit: The maximum number of orders to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the orders to return (overrides the `cursor` parameter) (e.g. expiration:desc)
    """
    where = prepare_order_where(
        status, {"give_asset": asset1.upper(), "get_asset": asset2.upper()}
    ) + prepare_order_where(status, {"give_asset": asset2.upper(), "get_asset": asset1.upper()})
    query_result = select_rows(
        state_db,
        "orders_info",
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
    return QueryResult(
        query_result.result, query_result.next_cursor, "orders", query_result.result_count
    )


def get_asset_holders(
    state_db, asset: str, cursor: str = None, limit: int = 100, offset: int = None, sort: str = None
):
    """
    Returns the holders of an asset
    :param str asset: The asset to return (e.g. $ASSET_1)
    :param str cursor: The last cursor of the holder to return
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
        "orders_info",
        where={"tx_hash": order_hash},
    )


def get_all_order_matches(
    state_db,
    status: OrderMatchesStatus = "all",
    block_index: int = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns all the order matches
    :param str status: The status of the order matches to return
    :param int block_index: The block index of the order matches to return
    :param int cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the order matches to return (overrides the `cursor` parameter) (e.g. forward_quantity:desc)
    """
    other_cond = {"block_index": block_index} if block_index else {}
    return select_rows(
        state_db,
        "order_matches",
        where=prepare_order_matches_where(status, other_cond),
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
        select=SELECT_ORDER_MATCHES,
    )


def get_order_matches_by_order(
    state_db,
    order_hash: str,
    status: OrderMatchesStatus = "all",
    block_index: int = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the order matches of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. $ORDER_WITH_MATCH_HASH)
    :param str status: The status of the order matches to return
    :param int block_index: The block index of the order matches to return
    :param int cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the order matches to return (overrides the `cursor` parameter) (e.g. forward_quantity:desc)
    """
    other_cond = {"block_index": block_index} if block_index else {}
    where = prepare_order_matches_where(
        status, {"tx0_hash": order_hash} | other_cond
    ) + prepare_order_matches_where(status, {"tx1_hash": order_hash} | other_cond)
    return select_rows(
        state_db,
        "order_matches",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
        select=SELECT_ORDER_MATCHES,
    )


def get_order_matches_by_asset(
    state_db,
    asset: str,
    status: OrderMatchesStatus = "all",
    forward_asset: str = None,
    backward_asset: str = None,
    block_index: int = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the orders of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param str status: The status of the order matches to return
    :param str forward_asset: The forward asset to return
    :param str backward_asset: The backward asset to return
    :param int block_index: The block index of the order matches to return
    :param int cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the order matches to return (overrides the `cursor` parameter) (e.g. forward_quantity:desc)
    """
    other_cond = {"block_index": block_index} if block_index else {}
    if forward_asset:
        where = prepare_order_matches_where(
            status,
            {"forward_asset": forward_asset.upper(), "backward_asset": asset.upper()} | other_cond,
        )
    elif backward_asset:
        where = prepare_order_matches_where(
            status,
            {"forward_asset": asset.upper(), "backward_asset": backward_asset.upper()} | other_cond,
        )
    else:
        where = prepare_order_matches_where(
            status, {"forward_asset": asset.upper()} | other_cond
        ) + prepare_order_matches_where(status, {"backward_asset": asset.upper()} | other_cond)

    return select_rows(
        state_db,
        "order_matches",
        where=where,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
        select=SELECT_ORDER_MATCHES,
    )


def get_order_matches_by_two_assets(
    state_db,
    asset1: str,
    asset2: str,
    status: OrderMatchesStatus = "all",
    block_index: int = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns the orders to exchange two assets
    :param str asset1: The first asset to return (e.g. BTC)
    :param str asset2: The second asset to return (e.g. XCP)
    :param str status: The status of the order matches to return
    :param int block_index: The block index of the order matches to return
    :param int cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the order matches to return (overrides the `cursor` parameter) (e.g. forward_quantity:desc)
    """
    other_cond = {"block_index": block_index} if block_index else {}
    where = prepare_order_matches_where(
        status, {"forward_asset": asset1.upper(), "backward_asset": asset2.upper()} | other_cond
    ) + prepare_order_matches_where(
        status, {"forward_asset": asset2.upper(), "backward_asset": asset1.upper()} | other_cond
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
    return QueryResult(
        query_result.result, query_result.next_cursor, "order_matches", query_result.result_count
    )


def get_btcpays_by_order(
    ledger_db, order_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the BTC pays of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. $ORDER_WITH_BTCPAY_HASH)
    :param int cursor: The last index of the resolutions to return
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
    ledger_db, bet_hash: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the resolutions of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 36bbbb7dbd85054dac140a8ad8204eda2ee859545528bd2a9da69ad77c277ace)
    :param int cursor: The last index of the resolutions to return
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


def get_all_burns(ledger_db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns the burns
    :param str status: The status of the burns to return (e.g. valid)
    :param int cursor: The last index of the burns to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns all fairminters
    :param str status: The status of the fairminters to return
    :param int cursor: The last index of the fairminter to return
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
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the fairminters by its block index
    :param int block_index: The block index of the fairminter to return (e.g. $LAST_FAIRMINTER_BLOCK)
    :param str status: The status of the fairminters to return
    :param int cursor: The last index of the fairminter to return
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
    cursor: int = None,
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
    cursor: int = None,
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
    ledger_db, tx_hash: str, cursor: int = None, limit: int = 100, offset: int = None
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
    ledger_db, address: str, cursor: int = None, limit: int = 100, offset: int = None
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
    ledger_db, asset: str, cursor: int = None, limit: int = 100, offset: int = None
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
    ledger_db, address: str, asset: str, cursor: int = None, limit: int = 100, offset: int = None
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


def get_all_fairmints(ledger_db, cursor: int = None, limit: int = 100, offset: int = None):
    """
    Returns all fairmints
    :param int cursor: The last index of the fairmint to return
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
    ledger_db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns the fairmints by its block index
    :param int block_index: The block index of the fairmint to return (e.g. $LAST_FAIRMINT_BLOCK)
    :param int cursor: The last index of the fairmint to return
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


#####################
#       POOLS       #
#####################


def get_pools(
    state_db,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns all AMM liquidity pools
    :param int cursor: The last index of the pools to return
    :param int limit: The maximum number of pools to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the pools to return (e.g. reserve_a:desc)
    """
    return select_rows(
        state_db,
        "pools",
        where=None,
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def get_pool_by_pair(
    state_db,
    asset1: str,
    asset2: str,
):
    """
    Returns the AMM pool for a given asset pair
    :param str asset1: The first asset in the pair (e.g. XCP)
    :param str asset2: The second asset in the pair (e.g. POOLTEST)
    """
    asset1 = asset1.upper()
    asset2 = asset2.upper()
    a, b = (asset1, asset2) if asset1 < asset2 else (asset2, asset1)
    return select_row(
        state_db,
        "pools",
        where={"asset_a": a, "asset_b": b},
    )


def get_pool_deposits_by_pair(
    state_db,
    asset1: str,
    asset2: str,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns deposits for a given pool pair
    :param str asset1: The first asset in the pair (e.g. XCP)
    :param str asset2: The second asset in the pair (e.g. $ASSET_1)
    :param int cursor: The last index of the deposits to return
    :param int limit: The maximum number of deposits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    asset1 = asset1.upper()
    asset2 = asset2.upper()
    a, b = (asset1, asset2) if asset1 < asset2 else (asset2, asset1)
    return select_rows(
        state_db,
        "pool_deposits",
        where={"asset_a": a, "asset_b": b, "status": "valid"},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_pool_withdrawals_by_pair(
    state_db,
    asset1: str,
    asset2: str,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns withdrawals for a given pool pair
    :param str asset1: The first asset in the pair (e.g. XCP)
    :param str asset2: The second asset in the pair (e.g. $ASSET_1)
    :param int cursor: The last index of the withdrawals to return
    :param int limit: The maximum number of withdrawals to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    asset1 = asset1.upper()
    asset2 = asset2.upper()
    a, b = (asset1, asset2) if asset1 < asset2 else (asset2, asset1)
    return select_rows(
        state_db,
        "pool_withdrawals",
        where={"asset_a": a, "asset_b": b, "status": "valid"},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_pool_matches_by_pair(
    state_db,
    asset1: str,
    asset2: str,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns pool matches (swaps) for a given pool pair
    :param str asset1: The first asset in the pair (e.g. XCP)
    :param str asset2: The second asset in the pair (e.g. $ASSET_1)
    :param int cursor: The last index of the pool matches to return
    :param int limit: The maximum number of pool matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    asset1 = asset1.upper()
    asset2 = asset2.upper()
    a, b = (asset1, asset2) if asset1 < asset2 else (asset2, asset1)
    return select_rows(
        state_db,
        "pool_matches",
        where={"asset_a": a, "asset_b": b},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_all_pool_matches(
    state_db,
    block_index: int = None,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
    sort: str = None,
):
    """
    Returns all pool matches (swaps against AMM pools)
    :param int block_index: The block index to filter by (e.g. 840000)
    :param int cursor: The last index of the pool matches to return
    :param int limit: The maximum number of pool matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    :param str sort: The sort order of the pool matches to return (e.g. forward_quantity:desc)
    """
    where = {"block_index": block_index} if block_index else {}
    return select_rows(
        state_db,
        "pool_matches",
        where=where or None,
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
        sort=sort,
    )


def get_pool_deposits_by_block(
    ledger_db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns pool deposits in a given block
    :param int block_index: The block index (e.g. 840000)
    :param int cursor: The last index of the deposits to return
    :param int limit: The maximum number of deposits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "pool_deposits",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_pool_withdrawals_by_block(
    ledger_db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns pool withdrawals in a given block
    :param int block_index: The block index (e.g. 840000)
    :param int cursor: The last index of the withdrawals to return
    :param int limit: The maximum number of withdrawals to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "pool_withdrawals",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_pool_matches_by_block(
    ledger_db, block_index: int, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns pool matches (swaps) in a given block
    :param int block_index: The block index (e.g. 840000)
    :param int cursor: The last index of the pool matches to return
    :param int limit: The maximum number of pool matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        ledger_db,
        "pool_matches",
        where={"block_index": block_index},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_pool_deposits_by_address(
    state_db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns pool deposits by a given address
    :param str address: The address to query (e.g. $ADDRESS_1)
    :param int cursor: The last index of the deposits to return
    :param int limit: The maximum number of deposits to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        state_db,
        "pool_deposits",
        where={"source": address, "status": "valid"},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_pool_withdrawals_by_address(
    state_db, address: str, cursor: int = None, limit: int = 100, offset: int = None
):
    """
    Returns pool withdrawals by a given address
    :param str address: The address to query (e.g. $ADDRESS_1)
    :param int cursor: The last index of the withdrawals to return
    :param int limit: The maximum number of withdrawals to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        state_db,
        "pool_withdrawals",
        where={"source": address, "status": "valid"},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_pool_positions_by_address(
    state_db,
    address: str,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns all AMM pool LP positions for a given address
    :param str address: The address to query LP positions for (e.g. $ADDRESS_1)
    :param int cursor: The last index of the positions to return
    :param int limit: The maximum number of positions to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    db_cursor = state_db.cursor()
    query_bindings = [address]
    cursor_clause = ""
    if offset is None and cursor is not None:
        cursor_clause = "AND b.rowid <= ?"
        query_bindings.append(cursor)
    query = f"""
        SELECT
            p.asset_a,
            p.asset_b,
            p.lp_asset,
            p.reserve_a,
            p.reserve_b,
            b.quantity,
            b.rowid AS rowid
        FROM balances b
        JOIN pools p ON b.asset = p.lp_asset
        WHERE b.address = ?
          AND b.quantity > 0
          {cursor_clause}
        ORDER BY b.rowid DESC
        LIMIT ?
    """  # noqa S608 # nosec B608
    query_bindings.append(limit + 1)
    if offset is not None:
        query += " OFFSET ?"
        query_bindings.append(offset)
    count_query = """
        SELECT COUNT(*) AS count
        FROM balances b
        JOIN pools p ON b.asset = p.lp_asset
        WHERE b.address = ?
          AND b.quantity > 0
    """  # noqa S608 # nosec B608
    db_cursor.execute(query, query_bindings)
    rows = db_cursor.fetchall()
    db_cursor.execute(count_query, (address,))
    result_count = db_cursor.fetchone()["count"]
    db_cursor.close()

    if len(rows) > limit:
        next_cursor = None if offset is not None else rows[-1]["rowid"]
        rows = rows[:limit]
    else:
        next_cursor = None

    return QueryResult(rows, next_cursor, "pools", result_count)


def get_pool_price_history(
    ledger_db,
    asset1: str,
    asset2: str,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns the price history for a pool pair (reserve snapshots at each state change).
    Each entry includes block_index, reserves, and computed price.
    Can be used to build price charts and compute TWAP.
    :param str asset1: The first asset in the pair (e.g. XCP)
    :param str asset2: The second asset in the pair (e.g. $ASSET_1)
    :param int cursor: The last index of the entries to return
    :param int limit: The maximum number of entries to return (e.g. 100)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    asset1 = asset1.upper()
    asset2 = asset2.upper()
    a, b = (asset1, asset2) if asset1 < asset2 else (asset2, asset1)
    return select_rows(
        ledger_db,
        "pools",
        where={"asset_a": a, "asset_b": b},
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_pool_matches_by_order(
    state_db,
    order_hash: str,
    cursor: int = None,
    limit: int = 100,
    offset: int = None,
):
    """
    Returns pool matches (swaps against the AMM) for a given order
    :param str order_hash: The hash of the order transaction (e.g. $ORDER_WITH_MATCH_HASH)
    :param int cursor: The last index of the pool matches to return
    :param int limit: The maximum number of pool matches to return (e.g. 5)
    :param int offset: The number of lines to skip before returning results (overrides the `cursor` parameter)
    """
    return select_rows(
        state_db,
        "pool_matches",
        where={"order_tx_hash": order_hash},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
        offset=offset,
    )


def get_pool_quote(state_db, asset1: str, asset2: str, quantity: int):
    """
    Returns the estimated swap output considering both AMM pool and resting order book.
    Reflects current state only; actual execution may differ if trades confirm before yours.
    :param asset1: The asset you want to sell (e.g. XCP)
    :param asset2: The asset you want to receive (e.g. $ASSET_1)
    :param quantity: The quantity of asset1 to sell (in satoshis) (e.g. 1000000)
    """
    asset1 = asset1.upper()
    asset2 = asset2.upper()
    give_asset = asset1
    give_quantity = quantity
    sorted_a, sorted_b = sort_pair(asset1, asset2)
    pool_row = select_row(state_db, "pools", where={"asset_a": sorted_a, "asset_b": sorted_b})
    pool = pool_row.result if pool_row else None
    has_pool = pool is not None and pool_has_liquidity(pool)

    orders_result = select_rows(
        state_db,
        "orders_info",
        where={"give_asset": asset2, "get_asset": asset1, "status": "open"},
        cursor_field="tx_index",
        sort="give_price:asc",
        limit=1000,
    )
    book_orders = orders_result.result if orders_result else []

    if not has_pool and not book_orders:
        return {
            "pool_exists": False,
            "estimated_output": 0,
            "book_orders": 0,
            "message": "No pool or orders exist for this pair.",
        }

    give_remaining = give_quantity
    pool_input_total = 0
    pool_output_total = 0
    book_output = 0
    book_orders_matched = 0

    if has_pool:
        fee_bps = get_pool_fee_bps(pool)
        if give_asset == pool["asset_a"]:
            sim_ri, sim_ro = pool["reserve_a"], pool["reserve_b"]
        else:
            sim_ri, sim_ro = pool["reserve_b"], pool["reserve_a"]
    else:
        fee_bps = 0
        sim_ri, sim_ro = 0, 0

    for order in book_orders:
        if give_remaining <= 0:
            break

        order_give_remaining = order["give_remaining"]
        if order_give_remaining <= 0:
            continue

        if has_pool and sim_ri > 0 and sim_ro > 0:
            pool_fill = compute_pool_input_for_target_price(
                sim_ri, sim_ro, order["get_quantity"], order["give_quantity"], fee_bps
            )
            pool_fill = min(pool_fill, give_remaining)

            if pool_fill > 0:
                pout = compute_pool_output(sim_ri, sim_ro, pool_fill, fee_bps)
                if pout > 0:
                    pool_output_total += pout
                    pool_input_total += pool_fill
                    give_remaining -= pool_fill
                    sim_ri += pool_fill
                    sim_ro -= pout

        if give_remaining <= 0:
            break

        can_take = min(give_remaining, order["get_remaining"])
        if can_take <= 0:
            continue
        get_from_order = can_take * order["give_quantity"] // order["get_quantity"]
        if get_from_order > order_give_remaining:
            get_from_order = order_give_remaining
            can_take = get_from_order * order["get_quantity"] // order["give_quantity"]

        if get_from_order > 0 and can_take > 0:
            book_output += get_from_order
            give_remaining -= can_take
            book_orders_matched += 1

    if give_remaining > 0 and has_pool and sim_ri > 0 and sim_ro > 0:
        pout = compute_pool_output(sim_ri, sim_ro, give_remaining, fee_bps)
        if pout > 0:
            pool_output_total += pout
            pool_input_total += give_remaining
            give_remaining = 0

    total_output = pool_output_total + book_output
    if has_pool and give_asset == pool["asset_a"]:
        orig_ri, orig_ro = pool["reserve_a"], pool["reserve_b"]
    elif has_pool:
        orig_ri, orig_ro = pool["reserve_b"], pool["reserve_a"]
    else:
        orig_ri, orig_ro = 0, 0
    marginal_price = orig_ro / orig_ri if orig_ri > 0 else 0
    effective_price = total_output / give_quantity if give_quantity > 0 else 0
    price_impact = (1 - effective_price / marginal_price) * 100 if marginal_price > 0 else 0

    result = {
        "estimated_output": total_output,
        "pool_output": pool_output_total,
        "book_output": book_output,
        "book_orders_matched": book_orders_matched,
        "give_remaining": give_remaining,
        "effective_price": effective_price,
        "price_impact": round(price_impact, 4),
    }
    if has_pool:
        result["pool_exists"] = True
        result["fee_bps"] = fee_bps
        result["fee_amount"] = pool_input_total * fee_bps // 10000 if fee_bps > 0 else 0
    else:
        result["pool_exists"] = False

    return result


def get_pool_quote_deposit(state_db, asset1: str, asset2: str, quantity: int):
    """
    Returns the required quantities of both assets and expected LP tokens for a deposit.
    :param asset1: The first asset in the pair (e.g. XCP)
    :param asset2: The second asset in the pair (e.g. $ASSET_1)
    :param quantity: The quantity of asset1 to deposit (in satoshis) (e.g. 1000000)
    """
    asset1 = asset1.upper()
    asset2 = asset2.upper()
    sorted_a, sorted_b = sort_pair(asset1, asset2)
    pool_row = select_row(state_db, "pools", where={"asset_a": sorted_a, "asset_b": sorted_b})
    pool = pool_row.result if pool_row else None

    if pool is None or pool["reserve_a"] == 0:
        return {
            "first_deposit": True,
            "asset_a": sorted_a,
            "asset_b": sorted_b,
            "quantity_a_required": None,
            "quantity_b_required": None,
            "quantity_minted_estimate": None,
            "message": "First deposit: provide both quantities to set the initial price.",
        }

    lp_info = select_row(state_db, "assets_info", where={"asset": pool["lp_asset"]})
    total_supply = lp_info.result["supply"] if lp_info else 0

    # ceil the partner so the user's pair lands on the A-constraint branch
    # in compute_actual_deposit_amounts and mints the quoted LP exactly
    if asset1 == sorted_a:
        quantity_a_required = quantity
        quantity_b_required = -(-quantity * pool["reserve_b"] // pool["reserve_a"])
        lp_estimate = quantity * total_supply // pool["reserve_a"] if total_supply else 0
    else:
        quantity_b_required = quantity
        quantity_a_required = -(-quantity * pool["reserve_a"] // pool["reserve_b"])
        lp_estimate = quantity * total_supply // pool["reserve_b"] if total_supply else 0

    return {
        "first_deposit": False,
        "asset_a": sorted_a,
        "asset_b": sorted_b,
        "quantity_a_required": quantity_a_required,
        "quantity_b_required": quantity_b_required,
        "quantity_minted_estimate": lp_estimate,
    }


def get_pool_quote_withdraw(state_db, asset1: str, asset2: str, quantity: int):
    """
    Returns the estimated assets received for burning a given amount of LP tokens.
    :param asset1: The first asset in the pair (e.g. XCP)
    :param asset2: The second asset in the pair (e.g. $ASSET_1)
    :param quantity: The quantity of LP tokens to destroy (in satoshis) (e.g. 1000000)
    """
    asset1 = asset1.upper()
    asset2 = asset2.upper()
    sorted_a, sorted_b = sort_pair(asset1, asset2)
    pool_row = select_row(state_db, "pools", where={"asset_a": sorted_a, "asset_b": sorted_b})
    pool = pool_row.result if pool_row else None
    if pool is None or pool["reserve_a"] == 0:
        return {"pool_exists": False, "message": "Pool does not exist or is empty."}

    lp_info = select_row(state_db, "assets_info", where={"asset": pool["lp_asset"]})
    total_supply = lp_info.result["supply"] if lp_info else 0

    if total_supply <= 0:
        return {"pool_exists": True, "supply": 0, "message": "No LP tokens in circulation."}

    quantity_a = quantity * pool["reserve_a"] // total_supply
    quantity_b = quantity * pool["reserve_b"] // total_supply

    return {
        "pool_exists": True,
        "asset_a": sorted_a,
        "asset_b": sorted_b,
        "quantity": quantity,
        "supply": total_supply,
        "quantity_a_estimate": quantity_a,
        "quantity_b_estimate": quantity_b,
        "reserve_a": pool["reserve_a"],
        "reserve_b": pool["reserve_b"],
    }
