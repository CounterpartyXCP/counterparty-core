"""
Unit tests for counterpartycore.lib.api.queries module.
Tests focus on covering uncovered lines in the module.
"""

import inspect

import pytest
from counterpartycore.lib import config
from counterpartycore.lib.api import queries, routes, verbose
from counterpartycore.lib.utils import hashcodec

# =============================================================================
# Tests for select_rows function - where clause handling
# =============================================================================


def test_select_rows_with_notlike_filter(state_db):
    """Test select_rows with __notlike filter (line 208-209)."""
    result = queries.select_rows(
        state_db,
        "assets_info",
        where={"asset__notlike": "A%"},
        limit=10,
    )
    assert result is not None
    # All returned assets should NOT start with 'A'
    for row in result.result:
        assert not row["asset"].startswith("A")


def test_select_rows_with_null_filter(state_db):
    """Test select_rows with __null filter (line 216)."""
    result = queries.select_rows(
        state_db,
        "dispensers",
        where={"oracle_address__null": True},
        limit=10,
    )
    assert result is not None
    # All returned dispensers should have NULL oracle_address
    for row in result.result:
        assert row["oracle_address"] is None


def test_select_rows_with_comma_separated_addresses(ledger_db, defaults):
    """Test select_rows with comma-separated addresses in ADDRESS_FIELDS (lines 222-223)."""
    # Get two addresses from defaults
    addr1 = defaults["addresses"][0]
    addr2 = defaults["addresses"][1]
    combined = f"{addr1},{addr2}"

    result = queries.select_rows(
        ledger_db,
        "credits",
        where={"address": combined},
        limit=10,
    )
    assert result is not None
    # All returned credits should be from one of the two addresses
    for row in result.result:
        assert row["address"] in [addr1, addr2]


def test_get_transactions_by_address_uses_indexed_base_filter(ledger_db, defaults):
    """Address-filtered transaction queries must resolve the address to its
    integer ``address_id`` and filter the indexed base ``transactions.source``
    instead of scanning the decoding ``transactions_with_status`` view (whose
    per-row ``(SELECT address FROM address_list ...)`` cannot use an index and
    turned ``/addresses/<addr>/transactions`` into a ~16s full scan for a busy
    address). Regression for the v11.2.0 Load API failure."""
    address = defaults["addresses"][0]

    executed = []
    ledger_db.setexectrace(lambda cursor, sql, bindings: (executed.append(sql) or True))
    try:
        result = queries.get_transactions_by_address(ledger_db, address, limit=50)
    finally:
        ledger_db.setexectrace(None)

    # Correctness: assert row CONTENT and row/``result_count`` consistency,
    # never just ``result is not None`` (which stays true for an empty result).
    assert result.result_count is not None
    assert len(result.result) == min(result.result_count, 50)
    for row in result.result:
        assert row["source"] == address

    # Performance: the row query rewrites the address filter into an indexed
    # ``tx_index IN (SELECT tx_index FROM transactions WHERE source ...)`` lookup
    # rather than comparing the view's decoded ``source`` string per row.
    row_query = next(s for s in executed if "transactions_with_status" in s and "COUNT(*)" not in s)
    normalized = " ".join(row_query.split())
    assert "tx_index IN (SELECT tx_index FROM transactions WHERE source IN" in normalized
    assert "address_list WHERE address IN" in normalized


def test_get_transactions_by_address_matches_naive_view_filter(ledger_db, defaults):
    """The indexed rewrite must return exactly the rows a naive filter on the
    decoding view returns -- same correctness, without the full scan."""
    address = defaults["addresses"][0]

    fast = queries.get_transactions_by_address(ledger_db, address, limit=10000, offset=0)
    fast_tx_indexes = sorted(row["tx_index"] for row in fast.result)

    naive_rows = (
        ledger_db.cursor()
        .execute(
            "SELECT tx_index FROM transactions_with_status WHERE source = ?",
            (address,),
        )
        .fetchall()
    )
    naive_tx_indexes = sorted(row["tx_index"] for row in naive_rows)

    assert fast_tx_indexes == naive_tx_indexes
    assert fast.result_count == len(naive_tx_indexes)


def test_select_rows_with_cursor_asc_order(ledger_db):
    """Test select_rows with cursor and ASC order (lines 247-250)."""
    # First get some results
    first_result = queries.select_rows(
        ledger_db,
        "credits",
        order="ASC",
        limit=5,
    )
    assert first_result is not None
    assert len(first_result.result) > 0

    # Use the next_cursor to get more results
    if first_result.next_cursor is not None:
        second_result = queries.select_rows(
            ledger_db,
            "credits",
            order="ASC",
            last_cursor=first_result.next_cursor,
            limit=5,
        )
        assert second_result is not None
        # With ASC order, the cursor should be >= than the last cursor
        if second_result.result:
            assert second_result.result[0]["rowid"] >= first_result.next_cursor


def test_select_rows_with_wrap_where(ledger_db):
    """Test select_rows with wrap_where parameter (lines 284-295)."""
    result = queries.select_rows(
        ledger_db,
        "credits",
        where={"quantity__gt": 0},
        wrap_where={"asset": "XCP"},
        limit=10,
    )
    assert result is not None
    # All returned credits should have asset == XCP
    for row in result.result:
        assert row["asset"] == "XCP"


def test_select_rows_with_wrap_where_gt(ledger_db):
    """Test select_rows with wrap_where using __gt filter (line 286-287)."""
    result = queries.select_rows(
        ledger_db,
        "credits",
        where={},
        wrap_where={"quantity__gt": 0},
        limit=10,
    )
    assert result is not None
    for row in result.result:
        assert row["quantity"] > 0


def test_select_rows_with_sort_no_order(state_db):
    """Test select_rows with sort field without explicit order (lines 306-307)."""
    result = queries.select_rows(
        state_db,
        "balances",
        where={"quantity__gt": 0},
        sort="quantity",  # No order specified, defaults to ASC
        limit=10,
    )
    assert result is not None


def test_select_rows_with_sort_invalid_order(state_db):
    """Test select_rows with sort field with invalid order (lines 308-309)."""
    result = queries.select_rows(
        state_db,
        "balances",
        where={"quantity__gt": 0},
        sort="quantity:INVALID",  # Invalid order defaults to ASC
        limit=10,
    )
    assert result is not None


def test_select_rows_balances_sort_asset_uses_asset_longname(state_db):
    cursor = state_db.cursor()
    address = "mnTESTBalanceSortAddress"
    cursor.executemany(
        """
        INSERT INTO balances (address, asset, asset_longname, quantity)
        VALUES (?, ?, ?, ?)
        """,
        [
            (address, "MYASSET", None, 1),
            (address, "A999999999999999999", "MYASSET.CHILD", 1),
            (address, "A888888888888888888", "ANOTHER.CHILD", 1),
        ],
    )

    result = queries.select_rows(
        state_db,
        "balances",
        where={"address": address},
        sort="asset",
        limit=10,
    )

    assert [row["asset"] for row in result.result] == [
        "A888888888888888888",
        "MYASSET",
        "A999999999999999999",
    ]


def test_select_rows_non_balance_asset_sort_uses_asset_field(state_db):
    result = queries.select_rows(
        state_db,
        "dispensers",
        sort="asset",
        limit=10,
    )

    assert result is not None


def test_select_rows_with_unsupported_sort_field(state_db):
    """Test select_rows with unsupported sort field (line 310-311)."""
    result = queries.select_rows(
        state_db,
        "balances",
        where={"quantity__gt": 0},
        sort="unsupported_field:asc",  # Unsupported field should be ignored
        limit=10,
    )
    assert result is not None


def _insert_quantitative_sort_fixtures(ledger_db):
    """Insert two rows per quantitative table (quantities 10 then 20) used by the sort tests."""
    # Asset columns store the compact asset_index, so register the synthetic
    # assets and reference them by index in the INSERTs below.
    for idx, asset_name in enumerate(("SORTSEND", "SORTISSUE", "SORTDISP", "SORTDIV"), start=1):
        ledger_db.execute(
            "INSERT OR IGNORE INTO assets (asset_id, asset_name) VALUES (?, ?)",
            (str(900000 + idx), asset_name),
        )
    # Address columns store the compact address_id; register the synthetic
    # addresses so address filters (e.g. broadcasts.source) resolve.
    for addr in ("source", "dest", "issuer", "sort-source"):
        ledger_db.execute("INSERT OR IGNORE INTO address_list (address) VALUES (?)", (addr,))
    ledger_db.executemany(
        """
        INSERT INTO transactions (
            tx_index, tx_hash, block_index, block_time, source,
            destination, btc_amount, fee, data, supported, utxos_info,
            transaction_type
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        [
            (900001, "a" * 64, 101, 1, "source", "dest", 0, 0, b"", 1, "", "send"),
            (900002, "b" * 64, 101, 2, "source", "dest", 0, 0, b"", 1, "", "send"),
            (900003, "c" * 64, 101, 3, "source", "dest", 0, 0, b"", 1, "", "issuance"),
            (900004, "d" * 64, 101, 4, "source", "dest", 0, 0, b"", 1, "", "issuance"),
            (900005, "e" * 64, 101, 5, "source", "dest", 0, 0, b"", 1, "", "broadcast"),
            (900006, "f" * 64, 101, 6, "source", "dest", 0, 0, b"", 1, "", "broadcast"),
            (900007, "1" * 64, 101, 7, "source", "dest", 0, 0, b"", 1, "", "dispense"),
            (900008, "3" * 64, 101, 8, "source", "dest", 0, 0, b"", 1, "", "dispense"),
            (900009, "5" * 64, 101, 9, "source", "dest", 0, 0, b"", 1, "", "dividend"),
            (900010, "6" * 64, 101, 10, "source", "dest", 0, 0, b"", 1, "", "dividend"),
        ],
    )
    ledger_db.executemany(
        """
        INSERT INTO sends (
            tx_index, tx_hash, block_index, source, destination, asset,
            quantity, status, msg_index, fee_paid, send_type
        ) VALUES (?, ?, ?, ?, ?, (SELECT asset_index FROM assets WHERE asset_name = ?), ?, ?, ?, ?, ?)
        """,
        [
            (900001, "a" * 64, 101, "source", "dest", "SORTSEND", 10, "valid", 0, 1, "send"),
            (900002, "b" * 64, 101, "source", "dest", "SORTSEND", 20, "valid", 0, 2, "send"),
        ],
    )
    ledger_db.executemany(
        """
        INSERT INTO issuances (
            tx_index, tx_hash, msg_index, block_index, asset, quantity,
            source, issuer, fee_paid, status
        ) VALUES (?, ?, ?, ?, (SELECT asset_index FROM assets WHERE asset_name = ?), ?, ?, ?, ?, ?)
        """,
        [
            (900003, "c" * 64, 0, 101, "SORTISSUE", 10, "source", "issuer", 1, "valid"),
            (900004, "d" * 64, 0, 101, "SORTISSUE", 20, "source", "issuer", 2, "valid"),
        ],
    )
    ledger_db.executemany(
        """
        INSERT INTO broadcasts (
            tx_index, tx_hash, block_index, source, timestamp, value,
            fee_fraction_int, text, locked, status
        ) VALUES (?, ?, ?, (SELECT address_id FROM address_list WHERE address = ?), ?, ?, ?, ?, ?, ?)
        """,
        [
            (900005, "e" * 64, 101, "sort-source", 1, 1.0, 1, "low", 0, "valid"),
            (900006, "f" * 64, 101, "sort-source", 2, 2.0, 2, "high", 0, "valid"),
        ],
    )
    ledger_db.executemany(
        """
        INSERT INTO dispenses (
            tx_index, dispense_index, tx_hash, block_index, source,
            destination, asset, dispense_quantity, dispenser_tx_index, btc_amount
        ) VALUES (?, ?, ?, ?, ?, ?, (SELECT asset_index FROM assets WHERE asset_name = ?), ?, ?, ?)
        """,
        [
            (900007, 0, "1" * 64, 101, "source", "dest", "SORTDISP", 10, 900001, 1),
            (900008, 0, "3" * 64, 101, "source", "dest", "SORTDISP", 20, 900002, 2),
        ],
    )
    ledger_db.executemany(
        """
        INSERT INTO dividends (
            tx_index, tx_hash, block_index, source, asset, dividend_asset,
            quantity_per_unit, fee_paid, status
        ) VALUES (?, ?, ?, ?, (SELECT asset_index FROM assets WHERE asset_name = ?),
            (SELECT asset_index FROM assets WHERE asset_name = ?), ?, ?, ?)
        """,
        [
            (900009, "5" * 64, 101, "source", "SORTDIV", "XCP", 10, 1, "valid"),
            (900010, "6" * 64, 101, "source", "SORTDIV", "XCP", 20, 2, "valid"),
        ],
    )


def test_select_rows_sort_additional_quantitative_tables(ledger_db):
    """Test sort fields added for quantitative API tables."""
    _insert_quantitative_sort_fixtures(ledger_db)

    cases = [
        ("sends", {"asset": "SORTSEND"}, "quantity", [10, 20]),
        ("issuances", {"asset": "SORTISSUE"}, "quantity", [10, 20]),
        ("broadcasts", {"source": "sort-source"}, "value", [1.0, 2.0]),
        ("dispenses", {"asset": "SORTDISP"}, "dispense_quantity", [10, 20]),
        ("dividends", {"asset": "SORTDIV"}, "quantity_per_unit", [10, 20]),
    ]
    for table, where, sort_field, expected in cases:
        result = queries.select_rows(
            ledger_db,
            table,
            where=where,
            sort=f"{sort_field}:asc",
            limit=2,
        )
        assert [row[sort_field] for row in result.result] == expected


def test_select_rows_sort_on_joined_table_qualifies_ambiguous_column(ledger_db):
    """Sorting a ``_HASH_FK_PROJECTIONS`` table (dispenses, pool_matches) by a
    column that also exists on ``transactions`` must not raise.

    Regression guard: these tables are queried as
    ``<table> AS __m LEFT JOIN transactions AS __txjoin``, so a bare
    ``ORDER BY btc_amount`` / ``ORDER BY block_index`` is an ambiguous column
    reference and SQLite raised ``ambiguous column name`` (HTTP 500). The sort
    field must be qualified with ``__m.`` exactly like the WHERE/cursor clauses.
    The dispenses fixture sets btc_amount to {1, 2} while the joined transactions
    rows have btc_amount 0, so the asserted order also proves it sorts on the
    dispenses column, not the transactions one.
    """
    _insert_quantitative_sort_fixtures(ledger_db)

    for order, expected in (("asc", [1, 2]), ("desc", [2, 1])):
        result = queries.select_rows(
            ledger_db,
            "dispenses",
            where={"asset": "SORTDISP"},
            sort=f"btc_amount:{order}",
            limit=10,
        )
        assert [row["btc_amount"] for row in result.result] == expected

    # block_index is also ambiguous (present on both dispenses and transactions);
    # sorting by it must succeed rather than raise.
    result = queries.select_rows(
        ledger_db,
        "dispenses",
        where={"asset": "SORTDISP"},
        sort="block_index:asc",
        limit=10,
    )
    assert len(result.result) == 2


def test_select_rows_sort_by_asset_orders_by_name_on_ledger_db(ledger_db):
    """Sorting a Ledger DB table by ``asset`` must order by the asset *name*,
    not by the compact ``asset_index`` the column is stored as.

    Regression guard: a bare ``ORDER BY asset`` would sort by issuance order /
    id. We register two assets whose insertion (index) order is the REVERSE of
    their alphabetical order, so an index sort and a name sort disagree.
    """
    for asset_id, asset_name in ((990001, "ZZZREGSORT"), (990002, "AAAREGSORT")):
        ledger_db.execute(
            "INSERT OR IGNORE INTO assets (asset_id, asset_name) VALUES (?, ?)",
            (str(asset_id), asset_name),
        )
    for addr in ("reg-sort-src", "reg-dest"):
        ledger_db.execute("INSERT OR IGNORE INTO address_list (address) VALUES (?)", (addr,))
    ledger_db.executemany(
        """
        INSERT INTO transactions (
            tx_index, tx_hash, block_index, block_time, source, destination,
            btc_amount, fee, data, supported, utxos_info, transaction_type
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        [
            (990001, "7" * 64, 101, 1, "reg-sort-src", "reg-dest", 0, 0, b"", 1, "", "send"),
            (990002, "8" * 64, 101, 2, "reg-sort-src", "reg-dest", 0, 0, b"", 1, "", "send"),
        ],
    )
    # ``source``/``destination`` are address_id FKs and ``asset`` an asset_index
    # FK, so resolve them on insert exactly like the write path does.
    ledger_db.executemany(
        """
        INSERT INTO sends (
            tx_index, tx_hash, block_index, source, destination, asset,
            quantity, status, msg_index, fee_paid, send_type
        ) VALUES (?, ?, ?,
            (SELECT address_id FROM address_list WHERE address = ?),
            (SELECT address_id FROM address_list WHERE address = ?),
            (SELECT asset_index FROM assets WHERE asset_name = ?), ?, ?, ?, ?, ?)
        """,
        [
            (
                990001,
                "7" * 64,
                101,
                "reg-sort-src",
                "reg-dest",
                "ZZZREGSORT",
                1,
                "valid",
                0,
                1,
                "send",
            ),
            (
                990002,
                "8" * 64,
                101,
                "reg-sort-src",
                "reg-dest",
                "AAAREGSORT",
                1,
                "valid",
                0,
                2,
                "send",
            ),
        ],
    )

    asc = queries.select_rows(
        ledger_db, "sends", where={"source": "reg-sort-src"}, sort="asset:asc", limit=10
    )
    assert [row["asset"] for row in asc.result] == ["AAAREGSORT", "ZZZREGSORT"]

    desc = queries.select_rows(
        ledger_db, "sends", where={"source": "reg-sort-src"}, sort="asset:desc", limit=10
    )
    assert [row["asset"] for row in desc.result] == ["ZZZREGSORT", "AAAREGSORT"]


def test_quantitative_getters_pass_sort_through(ledger_db):
    """The list getters for quantitative tables must forward `sort` to select_rows.

    The default order is descending (newest first), so an ascending sort proves the
    getter actually applied the requested order rather than ignoring it.
    """
    _insert_quantitative_sort_fixtures(ledger_db)

    cases = [
        (queries.get_sends_by_asset, ("SORTSEND",), "quantity", [10, 20]),
        (queries.get_issuances_by_asset, ("SORTISSUE",), "quantity", [10, 20]),
        (queries.get_broadcasts_by_source, ("sort-source",), "value", [1.0, 2.0]),
        (queries.get_dispenses_by_asset, ("SORTDISP",), "dispense_quantity", [10, 20]),
        (queries.get_dividends_by_asset, ("SORTDIV",), "quantity_per_unit", [10, 20]),
    ]
    for getter, getter_args, sort_field, expected in cases:
        result = getter(ledger_db, *getter_args, sort=f"{sort_field}:asc")
        assert [row[sort_field] for row in result.result] == expected, getter.__name__


def test_quantitative_endpoints_expose_sort():
    """Every quantitative list endpoint must expose `sort` as a query parameter.

    The API only injects parameters declared in the function signature, so a getter
    that does not declare `sort` silently ignores the query parameter. This guards
    against re-introducing that gap.
    """
    getters = [
        queries.get_sends,
        queries.get_sends_by_block,
        queries.get_sends_by_transaction_hash,
        queries.get_sends_by_asset,
        queries.get_sends_by_address,
        queries.get_sends_by_address_and_asset,
        queries.get_receive_by_address,
        queries.get_receive_by_address_and_asset,
        queries.get_issuances,
        queries.get_issuances_by_block,
        queries.get_issuances_by_asset,
        queries.get_issuances_by_address,
        queries.get_dispenses,
        queries.get_dispenses_by_block,
        queries.get_dispenses_by_transaction_hash,
        queries.get_dispenses_by_dispenser,
        queries.get_dispenses_by_source,
        queries.get_dispenses_by_destination,
        queries.get_dispenses_by_asset,
        queries.get_dispenses_by_source_and_asset,
        queries.get_dispenses_by_destination_and_asset,
        queries.get_valid_broadcasts,
        queries.get_broadcasts_by_source,
        queries.get_dividends,
        queries.get_dividends_by_asset,
        queries.get_dividends_distributed_by_address,
    ]
    for getter in getters:
        arg_names = [arg["name"] for arg in routes.prepare_route_args(getter)]
        assert "sort" in arg_names, f"{getter.__name__} does not expose a `sort` query parameter"


def test_sort_forwarding_tables_are_registered():
    """Every table passed to select_rows(..., sort=...) must be a SUPPORTED_SORT_FIELDS
    key, otherwise the sort is silently dropped at runtime.

    Regression: the orders endpoints query the `orders_info` view, but the fields
    were registered under `orders`, so sorting orders never applied.
    """
    missing = []
    for name, function in inspect.getmembers(queries, inspect.isfunction):
        for table in queries._select_rows_sort_tables(function):
            if table not in queries.SUPPORTED_SORT_FIELDS:
                missing.append((name, table))
    assert not missing, f"sort tables missing from SUPPORTED_SORT_FIELDS: {missing}"


def test_get_orders_sort_is_applied(state_db):
    """The orders endpoints sort on the `orders_info` view; an ascending sort must
    reverse the default descending order (regression for the orders_info key)."""
    desc = queries.get_orders(state_db, sort="give_quantity:desc").result
    asc = queries.get_orders(state_db, sort="give_quantity:asc").result
    if len(asc) < 2:
        pytest.skip("not enough orders in fixture to assert ordering")
    assert [row["give_quantity"] for row in asc] == sorted(row["give_quantity"] for row in asc)
    assert [row["give_quantity"] for row in desc] == list(
        reversed([row["give_quantity"] for row in asc])
    )


def test_select_rows_with_offset(ledger_db):
    """Test select_rows with offset parameter (lines 321-323)."""
    result = queries.select_rows(
        ledger_db,
        "credits",
        offset=5,
        limit=10,
    )
    assert result is not None


def test_select_row_returns_none(ledger_db):
    """Test select_row returns None when no match (line 363)."""
    result = queries.select_row(
        ledger_db,
        "transactions",
        where={"tx_hash": "nonexistent_hash_that_does_not_exist"},
    )
    assert result is None


def test_select_rows_can_skip_result_count(ledger_db):
    """Test select_rows can skip the extra count query for single-row lookups."""
    counted_result = queries.select_rows(
        ledger_db,
        "transactions",
        limit=1,
    )
    assert counted_result is not None
    assert counted_result.result_count is not None

    result = queries.select_rows(
        ledger_db,
        "transactions",
        limit=1,
        with_count=False,
    )
    assert result is not None
    assert result.result_count is None


def test_get_address_options(ledger_db, defaults):
    unset_address = defaults["addresses"][4]
    result = queries.get_address(ledger_db, unset_address)
    assert result.result == {
        "address": unset_address,
        "options": 0,
        "block_index": None,
    }

    address_with_options = defaults["addresses"][6]
    # ``addresses.address`` is now the compact ``address_id`` FK; register the
    # address in ``address_list`` and store its id (the API resolves the filter
    # to the id too).
    ledger_db.execute(
        "INSERT OR IGNORE INTO address_list (address) VALUES (?)", (address_with_options,)
    )
    ledger_db.execute(
        "INSERT INTO addresses (address, options, block_index) "
        "VALUES ((SELECT address_id FROM address_list WHERE address = ?), ?, ?)",
        (address_with_options, config.ADDRESS_OPTION_REQUIRE_MEMO, 123),
    )

    result = queries.get_address(ledger_db, address_with_options)
    assert result.result["address"] == address_with_options
    assert result.result["options"] == config.ADDRESS_OPTION_REQUIRE_MEMO
    assert result.result["block_index"] == 123


# =============================================================================
# Tests for transaction queries
# =============================================================================


def test_prepare_transactions_where_with_specific_types():
    """Test prepare_transactions_where with specific transaction types (lines 423-427)."""
    # Test with a specific valid type
    result = queries.prepare_transactions_where("send", {"block_index": 100})
    assert len(result) == 1
    assert result[0]["transaction_type"] == "send"
    assert result[0]["block_index"] == 100


def test_prepare_transactions_where_with_multiple_types():
    """Test prepare_transactions_where with multiple transaction types."""
    result = queries.prepare_transactions_where("send,order", {"block_index": 100})
    assert len(result) == 2


def test_prepare_transactions_where_with_invalid_type():
    """Test prepare_transactions_where with invalid transaction type."""
    result = queries.prepare_transactions_where("invalid_type")
    assert len(result) == 0


def test_get_transactions_by_block_with_valid_filter(ledger_db, current_block_index):
    """Test get_transactions_by_block with valid filter (line 487)."""
    result = queries.get_transactions_by_block(
        ledger_db,
        block_index=current_block_index,
        valid=True,
    )
    assert result is not None


def test_get_transactions_by_address_with_valid_filter(ledger_db, defaults):
    """Test get_transactions_by_address with valid filter (line 521)."""
    address = defaults["addresses"][0]
    result = queries.get_transactions_by_address(
        ledger_db,
        address=address,
        valid=True,
    )
    assert result is not None
    # Every returned transaction must actually be sourced from the queried
    # address: the address-string -> ``address_id`` WHERE rewrite must not fire
    # against the ``transactions_with_status`` view (which already exposes
    # ``source`` as a decoded string), otherwise the rows come back empty.
    assert all(row["source"] == address for row in result.result)


def test_get_transactions_by_addresses_with_valid_filter(ledger_db, defaults):
    """Test get_transactions_by_addresses with valid filter (line 556)."""
    addr1, addr2 = defaults["addresses"][0], defaults["addresses"][1]
    result = queries.get_transactions_by_addresses(
        ledger_db,
        addresses=f"{addr1},{addr2}",
        valid=True,
    )
    assert result is not None
    assert all(row["source"] in (addr1, addr2) for row in result.result)


def test_get_transactions_by_address_returns_matching_rows_and_consistent_count(ledger_db):
    """Regression (compact-hash normalization): on a migrated Ledger DB the
    ``transactions_with_status`` view exposes ``source``/``destination`` as the
    decoded address *string*, so ``select_rows`` must NOT apply its
    address-string -> ``address_id`` WHERE rewrite to it. When it did, the row
    query compared a string column against an integer id and returned ZERO rows,
    while ``result_count`` -- counted off the base ``transactions`` table via
    ``_COUNT_FROM_OVERRIDE`` where ``source`` is the integer id -- stayed
    non-zero: empty results paired with an inconsistent count. Endpoints
    affected: ``/v2/addresses/<address>/transactions`` (+ the multi-address
    variant) and ``/v2/addresses/<address>/transactions/counts``.
    """
    # Derive the busiest source address from the fixture itself so the test is
    # independent of the default-address layout and is never trivially empty.
    busiest = ledger_db.execute(
        "SELECT source, COUNT(*) AS c FROM transactions_with_status "
        "WHERE source IS NOT NULL GROUP BY source ORDER BY c DESC, source LIMIT 1"
    ).fetchone()
    address, expected_count = busiest["source"], busiest["c"]
    assert expected_count > 0  # sanity: the fixture has source-attributed txs

    result = queries.get_transactions_by_address(
        ledger_db, address=address, limit=expected_count + 10
    )
    # Rows are returned (the bug returned []), every row matches the address, and
    # the total count agrees with the rows (the bug left count != len(rows)).
    assert len(result.result) == expected_count
    assert all(row["source"] == address for row in result.result)
    assert result.result_count == expected_count

    # The per-type counts endpoint sums back to the same total (it returned no
    # groups at all under the bug).
    type_counts = queries.get_transaction_types_count_by_address(ledger_db, address=address)
    assert sum(row["count"] for row in type_counts.result) == expected_count


def test_transaction_queries_return_zero_btc_amount_for_null(ledger_db, current_block_index):
    """Test transaction endpoints do not expose null btc_amount values."""
    block = ledger_db.execute(
        "SELECT block_time FROM blocks WHERE block_index = ?",
        (current_block_index,),
    ).fetchone()
    tx_index = (
        ledger_db.execute("SELECT MAX(tx_index) AS tx_index FROM transactions").fetchone()[
            "tx_index"
        ]
        + 1
    )
    tx_hash = "ab" * 32
    ledger_db.execute(
        """INSERT INTO transactions(
            tx_index, tx_hash, block_index, block_time, source, destination,
            btc_amount, fee, data, supported, utxos_info, transaction_type
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            tx_index,
            hashcodec.hash_to_db(tx_hash),
            current_block_index,
            block["block_time"],
            "",
            "",
            None,
            None,
            None,
            True,
            "",
            "utxomove",
        ),
    )
    ledger_db.execute(
        "INSERT INTO transactions_status(tx_index, valid) VALUES(?, ?)",
        (tx_index, True),
    )

    query_result = queries.get_transaction_by_hash(ledger_db, tx_hash)
    assert query_result.result["btc_amount"] == 0

    query_result = queries.get_transactions(ledger_db, type="utxomove", limit=1)
    assert query_result.result[0]["tx_hash"] == tx_hash
    assert query_result.result[0]["btc_amount"] == 0


# =============================================================================
# Tests for event queries
# =============================================================================


def _messages_count(ledger_db, event_names=None):
    cursor = ledger_db.cursor()
    if event_names is None:
        return cursor.execute("SELECT COUNT(*) AS count FROM messages").fetchone()["count"]
    placeholders = ",".join(["?"] * len(event_names))
    return cursor.execute(
        f"SELECT COUNT(*) AS count FROM messages WHERE event IN ({placeholders})",  # noqa: S608
        event_names,
    ).fetchone()["count"]


def test_get_all_events_with_event_name(ledger_db, state_db):
    """Test get_all_events with event_name filter (line 658)."""
    result = queries.get_all_events(
        ledger_db,
        state_db,
        event_name="CREDIT,DEBIT",
    )
    assert result is not None
    for row in result.result:
        assert row["event"] in ["CREDIT", "DEBIT"]
    # result_count is read from the pre-aggregated `events_count` table and must
    # match a direct COUNT(*) over `messages` for the same filter.
    assert result.result_count == _messages_count(ledger_db, ["CREDIT", "DEBIT"])


def test_get_all_events_count_matches_messages(ledger_db, state_db):
    """The unfiltered total comes from `events_count` and must equal COUNT(*) of messages."""
    result = queries.get_all_events(ledger_db, state_db)
    assert result.result_count == _messages_count(ledger_db)


def test_get_events_by_name_count_matches_messages(ledger_db, state_db):
    """get_events_by_name reads its count from `events_count`; it must stay exact."""
    result = queries.get_events_by_name(ledger_db, state_db, event="CREDIT")
    for row in result.result:
        assert row["event"] == "CREDIT"
    assert result.result_count == _messages_count(ledger_db, ["CREDIT"])


def test_get_events_by_block_with_event_name(ledger_db, current_block_index):
    """Test get_events_by_block with event_name filter (line 689)."""
    result = queries.get_events_by_block(
        ledger_db,
        block_index=current_block_index,
        event_name="CREDIT",
    )
    assert result is not None


def test_get_events_by_transaction_hash_with_event_name(ledger_db):
    """Test get_events_by_transaction_hash with event_name filter (line 720)."""
    # First get a transaction hash
    tx_result = queries.select_rows(ledger_db, "transactions", limit=1)
    if tx_result.result:
        tx_hash = tx_result.result[0]["tx_hash"]
        result = queries.get_events_by_transaction_hash(
            ledger_db,
            tx_hash=tx_hash,
            event_name="CREDIT,DEBIT",
        )
        assert result is not None


def test_get_events_by_transaction_index_returns_none(ledger_db):
    """Test get_events_by_transaction_index returns None for invalid index (line 782)."""
    result = queries.get_events_by_transaction_index(
        ledger_db,
        tx_index=999999999,  # Non-existent transaction index
    )
    assert result is None


def test_get_events_by_transaction_index_and_event_returns_none(ledger_db):
    """Test get_events_by_transaction_index_and_event returns None for invalid index (line 806)."""
    result = queries.get_events_by_transaction_index_and_event(
        ledger_db,
        tx_index=999999999,  # Non-existent transaction index
        event="CREDIT",
    )
    assert result is None


def test_get_events_by_block_and_event_count(ledger_db, current_block_index):
    """Test get_events_by_block_and_event with event='count' (line 826)."""
    result = queries.get_events_by_block_and_event(
        ledger_db,
        block_index=current_block_index,
        event="count",
    )
    assert result is not None


# =============================================================================
# Tests for mempool events
# =============================================================================


def test_get_all_mempool_events_with_event_and_addresses(ledger_db, defaults):
    """Test get_all_mempool_events with both event_name and addresses (lines 932-939)."""
    result = queries.get_all_mempool_events(
        ledger_db,
        event_name="CREDIT",
        addresses=defaults["addresses"][0],
    )
    assert result is not None


def test_get_all_mempool_events_with_addresses_only(ledger_db, defaults):
    """Test get_all_mempool_events with addresses only (lines 941-942)."""
    result = queries.get_all_mempool_events(
        ledger_db,
        addresses=defaults["addresses"][0],
    )
    assert result is not None


def test_get_mempool_events_by_tx_hash_with_event_name(ledger_db):
    """Test get_mempool_events_by_tx_hash with event_name (line 996)."""
    result = queries.get_mempool_events_by_tx_hash(
        ledger_db,
        tx_hash="somehash",
        event_name="CREDIT,DEBIT",
    )
    assert result is not None


def test_get_mempool_events_by_addresses_with_event_name(ledger_db, defaults):
    """Test get_mempool_events_by_addresses with event_name (line 1023)."""
    result = queries.get_mempool_events_by_addresses(
        ledger_db,
        addresses=defaults["addresses"][0],
        event_name="CREDIT,DEBIT",
    )
    assert result is not None


# =============================================================================
# Tests for credits and debits
# =============================================================================


def test_get_credits_by_block_with_action(ledger_db, current_block_index):
    """Test get_credits_by_block with action filter (line 1106)."""
    result = queries.get_credits_by_block(
        ledger_db,
        block_index=current_block_index,
        action="issuance",
    )
    assert result is not None


def test_get_credits_by_address_with_action(ledger_db, defaults):
    """Test get_credits_by_address with action filter (lines 1135-1136)."""
    result = queries.get_credits_by_address(
        ledger_db,
        address=defaults["addresses"][0],
        action="issuance",
    )
    assert result is not None


def test_get_credits_by_asset_with_action(ledger_db):
    """Test get_credits_by_asset with action filter (line 1160)."""
    result = queries.get_credits_by_asset(
        ledger_db,
        asset="XCP",
        action="burn",
    )
    assert result is not None


def test_get_debits_by_block_with_action(ledger_db, current_block_index):
    """Test get_debits_by_block with action filter (line 1184)."""
    result = queries.get_debits_by_block(
        ledger_db,
        block_index=current_block_index,
        action="send",
    )
    assert result is not None


def test_get_debits_by_address_with_action(ledger_db, defaults):
    """Test get_debits_by_address with action filter (lines 1213-1214)."""
    result = queries.get_debits_by_address(
        ledger_db,
        address=defaults["addresses"][0],
        action="send",
    )
    assert result is not None


def test_get_debits_by_asset_with_action(ledger_db):
    """Test get_debits_by_asset with action filter (line 1238)."""
    result = queries.get_debits_by_asset(
        ledger_db,
        asset="XCP",
        action="send",
    )
    assert result is not None


def test_credits_expose_unique_index(ledger_db):
    """credits rows expose a stable `credit_index` (rowid) so identical rows
    within a single tx can be told apart (issue #3320)."""
    result = queries.select_rows(ledger_db, "credits", limit=50)
    assert len(result.result) > 0
    for row in result.result:
        assert "credit_index" in row
        assert row["credit_index"] == row["rowid"]

    # `credit_index` survives API cleaning while `rowid` is stripped.
    cleaned = verbose.clean_api_result(result.result)
    indexes = [row["credit_index"] for row in cleaned]
    for row in cleaned:
        assert "rowid" not in row
        assert "credit_index" in row
    # Unique per row, even for otherwise byte-identical credits.
    assert len(indexes) == len(set(indexes))


def test_debits_expose_unique_index(ledger_db):
    """debits rows expose a stable `debit_index` (rowid)."""
    result = queries.select_rows(ledger_db, "debits", limit=50)
    assert len(result.result) > 0
    for row in result.result:
        assert "debit_index" in row
        assert row["debit_index"] == row["rowid"]

    cleaned = verbose.clean_api_result(result.result)
    for row in cleaned:
        assert "rowid" not in row
        assert "debit_index" in row


# =============================================================================
# Tests for sends
# =============================================================================


def test_prepare_sends_where_with_specific_type():
    """Test prepare_sends_where with specific send type (lines 1254-1264)."""
    # Test with 'send' type
    result = queries.prepare_sends_where("send", {"block_index": 100})
    assert len(result) == 1
    assert result[0]["send_type"] == "send"
    assert result[0]["block_index"] == 100


def test_prepare_sends_where_with_list_conditions():
    """Test prepare_sends_where with list other_conditions (lines 1260-1262)."""
    result = queries.prepare_sends_where("send", [{"source": "addr1"}, {"destination": "addr2"}])
    assert len(result) == 2


def test_prepare_sends_where_all_with_list_conditions():
    """Test prepare_sends_where 'all' with list other_conditions (lines 1251-1252)."""
    result = queries.prepare_sends_where("all", [{"source": "addr1"}, {"destination": "addr2"}])
    assert len(result) == 2


def test_prepare_sends_where_with_invalid_type():
    """Test prepare_sends_where with invalid send type."""
    result = queries.prepare_sends_where("invalid_type")
    assert len(result) == 0


# =============================================================================
# Tests for issuances
# =============================================================================


def test_prepare_issuance_where_with_fairmint_events():
    """Test prepare_issuance_where with fairmint events (lines 1490-1498)."""
    # Test with open_fairminter (exact match)
    result = queries.prepare_issuance_where("open_fairminter", {"status": "valid"})
    assert len(result) == 1
    assert result[0]["asset_events"] == "open_fairminter"

    # Test with creation (like match)
    result = queries.prepare_issuance_where("creation", {"status": "valid"})
    assert len(result) == 1
    assert "asset_events__like" in result[0]


def test_prepare_issuance_where_with_invalid_event():
    """Test prepare_issuance_where with invalid asset event."""
    result = queries.prepare_issuance_where("invalid_event")
    assert len(result) == 0


# =============================================================================
# Tests for dispenses
# =============================================================================


def test_get_dispenses_by_source(ledger_db, defaults):
    """Test get_dispenses_by_source (line 1721)."""
    result = queries.get_dispenses_by_source(
        ledger_db,
        address=defaults["addresses"][0],
    )
    assert result is not None


def test_get_dispenses_by_destination(ledger_db, defaults):
    """Test get_dispenses_by_destination (line 1741)."""
    result = queries.get_dispenses_by_destination(
        ledger_db,
        address=defaults["addresses"][1],
    )
    assert result is not None


def test_get_dispenses_by_asset_with_block_index(ledger_db, current_block_index):
    """Test get_dispenses_by_asset with block_index filter (line 1769)."""
    result = queries.get_dispenses_by_asset(
        ledger_db,
        asset="XCP",
        block_index=current_block_index,
    )
    assert result is not None


def test_get_dispenses_by_source_and_asset(ledger_db, defaults):
    """Test get_dispenses_by_source_and_asset (line 1791)."""
    result = queries.get_dispenses_by_source_and_asset(
        ledger_db,
        address=defaults["addresses"][0],
        asset="XCP",
    )
    assert result is not None


def test_get_dispenses_by_destination_and_asset(ledger_db, defaults):
    """Test get_dispenses_by_destination_and_asset (line 1812)."""
    result = queries.get_dispenses_by_destination_and_asset(
        ledger_db,
        address=defaults["addresses"][1],
        asset="XCP",
    )
    assert result is not None


# =============================================================================
# Tests for balances
# =============================================================================


def test_get_address_balances_utxo_type(state_db, defaults):
    """Test get_address_balances with type='utxo' (line 1913)."""
    result = queries.get_address_balances(
        state_db,
        address=defaults["addresses"][0],
        type="utxo",
    )
    assert result is not None


def test_get_address_balances_address_type(state_db, defaults):
    """Test get_address_balances with type='address' (line 1915)."""
    result = queries.get_address_balances(
        state_db,
        address=defaults["addresses"][0],
        type="address",
    )
    assert result is not None


def test_utxos_with_balances_unknown_utxo(state_db):
    """Test utxos_with_balances returns False for unknown utxo (line 1970)."""
    result = queries.utxos_with_balances(
        state_db,
        utxos="unknown_utxo_1:0,unknown_utxo_2:1",
    )
    assert result is not None
    # Unknown UTXOs should return False
    for _utxo, has_balance in result.result.items():
        assert has_balance is False


def test_get_balances_by_addresses_with_offset(state_db, defaults):
    """Test get_balances_by_addresses with offset (line 2065)."""
    addresses = f"{defaults['addresses'][0]},{defaults['addresses'][1]}"
    result = queries.get_balances_by_addresses(
        state_db,
        addresses=addresses,
        offset=1,
    )
    assert result is not None


def test_get_balances_by_addresses_with_asset_and_offset(state_db, defaults):
    """Test get_balances_by_addresses with asset and offset (line 2091)."""
    addresses = f"{defaults['addresses'][0]},{defaults['addresses'][1]}"
    result = queries.get_balances_by_addresses(
        state_db,
        addresses=addresses,
        asset="XCP",
        offset=0,
    )
    assert result is not None


def test_get_balances_by_address_and_asset_utxo_type(state_db, defaults):
    """Test get_balances_by_address_and_asset with type='utxo' (lines 2138-2139)."""
    result = queries.get_balances_by_address_and_asset(
        state_db,
        address=defaults["addresses"][0],
        asset="XCP",
        type="utxo",
    )
    assert result is not None


def test_get_balances_by_address_and_asset_address_type(state_db, defaults):
    """Test get_balances_by_address_and_asset with type='address' (lines 2141-2142)."""
    result = queries.get_balances_by_address_and_asset(
        state_db,
        address=defaults["addresses"][0],
        asset="XCP",
        type="address",
    )
    assert result is not None


def test_get_balances_by_address_and_asset_subasset_longname(state_db, defaults):
    result = queries.get_balances_by_address_and_asset(
        state_db,
        address=defaults["addresses"][0],
        asset="PARENT.already.issued",
    )

    assert len(result.result) > 0
    assert result.result[0]["asset"] == "A95428959342453541"
    assert result.result[0]["asset_longname"] == "PARENT.already.issued"


# =============================================================================
# Tests for dispensers
# =============================================================================


def test_prepare_dispenser_where_with_numeric_status():
    """Test prepare_dispenser_where with numeric status (line 2419)."""
    # Status 0 = open
    result = queries.prepare_dispenser_where("0")
    assert len(result) == 1
    assert result[0]["status"] == 0


def test_prepare_dispenser_where_all_with_exclude_oracle():
    """Test prepare_dispenser_where 'all' with exclude_with_oracle (lines 2423-2424)."""
    result = queries.prepare_dispenser_where("all", exclude_with_oracle=True)
    assert "oracle_address__null" in result


def test_prepare_dispenser_where_with_exclude_oracle():
    """Test prepare_dispenser_where with exclude_with_oracle for specific status (lines 2427-2434)."""
    result = queries.prepare_dispenser_where(
        "open", {"source": "someaddr"}, exclude_with_oracle=True
    )
    assert len(result) == 1
    assert result[0]["status"] == 0
    assert result[0]["oracle_address__null"] is True


def test_prepare_dispenser_where_with_invalid_status():
    """Test prepare_dispenser_where with invalid status."""
    result = queries.prepare_dispenser_where("invalid_status")
    assert len(result) == 0


def test_get_dispensers_by_asset_prices_divisible_lots(state_db):
    """Test dispenser price is satoshis per whole asset unit for divisible assets."""
    state_db.execute(
        "INSERT INTO assets_info (asset, divisible) VALUES (?, ?)",
        ("UNITTESTDIV", True),
    )
    state_db.execute(
        """
        INSERT INTO dispensers (
            tx_index, tx_hash, block_index, source, asset, give_quantity,
            escrow_quantity, satoshirate, status, give_remaining, origin,
            dispense_count
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            9001,
            "a" * 64,
            9001,
            "addr1",
            "UNITTESTDIV",
            100000000,
            100000000,
            12345,
            0,
            100000000,
            "addr1",
            0,
        ),
    )
    state_db.execute(
        """
        INSERT INTO dispensers (
            tx_index, tx_hash, block_index, source, asset, give_quantity,
            escrow_quantity, satoshirate, status, give_remaining, origin,
            dispense_count
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            9002,
            "b" * 64,
            9002,
            "addr2",
            "UNITTESTDIV",
            200000000,
            200000000,
            12345,
            0,
            200000000,
            "addr2",
            0,
        ),
    )

    result = queries.get_dispensers_by_asset(
        state_db,
        "UNITTESTDIV",
        status="open",
        sort="price:asc",
    )

    assert [row["price"] for row in result.result] == [6172.5, 12345]


def test_get_dispensers_by_origin_filters_origin_address(state_db):
    """Test get_dispensers_by_origin returns dispensers created by an origin address."""
    state_db.execute(
        "INSERT INTO assets_info (asset, divisible) VALUES (?, ?)",
        ("ORIGINFILTER", False),
    )
    for tx_index, tx_hash, source, origin in [
        (9101, "c" * 64, "source1", "origin1"),
        (9102, "d" * 64, "source2", "origin1"),
        (9103, "e" * 64, "source3", "origin2"),
    ]:
        state_db.execute(
            """
            INSERT INTO dispensers (
                tx_index, tx_hash, block_index, source, asset, give_quantity,
                escrow_quantity, satoshirate, status, give_remaining, origin,
                dispense_count
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                tx_index,
                tx_hash,
                tx_index,
                source,
                "ORIGINFILTER",
                1,
                1,
                100,
                0,
                1,
                origin,
                0,
            ),
        )

    result = queries.get_dispensers_by_origin(
        state_db,
        "origin1",
        status="open",
        sort="block_index:asc",
    )

    assert [row["source"] for row in result.result] == ["source1", "source2"]
    assert [row["origin"] for row in result.result] == ["origin1", "origin1"]


# =============================================================================
# Tests for assets
# =============================================================================


def test_get_valid_assets_named_true(state_db):
    """Test get_valid_assets with named=True (lines 2568-2569)."""
    result = queries.get_valid_assets(
        state_db,
        named=True,
    )
    assert result is not None
    for row in result.result:
        assert not row["asset"].startswith("A")


def test_get_valid_assets_named_false(state_db):
    """Test get_valid_assets with named=False (lines 2570-2571)."""
    result = queries.get_valid_assets(
        state_db,
        named=False,
    )
    assert result is not None
    for row in result.result:
        assert row["asset"].startswith("A")


def test_get_valid_assets_by_issuer_named_true(state_db, defaults):
    """Test get_valid_assets_by_issuer with named=True (lines 2635-2636)."""
    result = queries.get_valid_assets_by_issuer(
        state_db,
        address=defaults["addresses"][0],
        named=True,
    )
    assert result is not None


def test_get_valid_assets_by_issuer_named_false(state_db, defaults):
    """Test get_valid_assets_by_issuer with named=False (lines 2637-2638)."""
    result = queries.get_valid_assets_by_issuer(
        state_db,
        address=defaults["addresses"][0],
        named=False,
    )
    assert result is not None


def test_get_valid_assets_by_owner_named_true(state_db, defaults):
    """Test get_valid_assets_by_owner with named=True (lines 2668-2669)."""
    result = queries.get_valid_assets_by_owner(
        state_db,
        address=defaults["addresses"][0],
        named=True,
    )
    assert result is not None


def test_get_valid_assets_by_owner_named_false(state_db, defaults):
    """Test get_valid_assets_by_owner with named=False (lines 2670-2671)."""
    result = queries.get_valid_assets_by_owner(
        state_db,
        address=defaults["addresses"][0],
        named=False,
    )
    assert result is not None


def test_get_valid_assets_by_issuer_or_owner_named_true(state_db, defaults):
    """Test get_valid_assets_by_issuer_or_owner with named=True (lines 2701-2703)."""
    result = queries.get_valid_assets_by_issuer_or_owner(
        state_db,
        address=defaults["addresses"][0],
        named=True,
    )
    assert result is not None


def test_get_valid_assets_by_issuer_or_owner_named_false(state_db, defaults):
    """Test get_valid_assets_by_issuer_or_owner with named=False (lines 2704-2706)."""
    result = queries.get_valid_assets_by_issuer_or_owner(
        state_db,
        address=defaults["addresses"][0],
        named=False,
    )
    assert result is not None


# =============================================================================
# Tests for asset balances
# =============================================================================


def test_get_asset_balances_utxo_type(state_db):
    """Test get_asset_balances with type='utxo' (lines 2830-2831)."""
    result = queries.get_asset_balances(
        state_db,
        asset="XCP",
        type="utxo",
    )
    assert result is not None


def test_get_asset_balances_address_type(state_db):
    """Test get_asset_balances with type='address' (lines 2833-2834)."""
    result = queries.get_asset_balances(
        state_db,
        asset="XCP",
        type="address",
    )
    assert result is not None


def test_get_asset_balances_subasset_longname(state_db):
    result = queries.get_asset_balances(state_db, asset="PARENT.already.issued")

    assert len(result.result) > 0
    assert result.result[0]["asset"] == "A95428959342453541"
    assert result.result[0]["asset_longname"] == "PARENT.already.issued"


# =============================================================================
# Tests for orders
# =============================================================================


def test_prepare_where_status_with_multiple_statuses():
    """Test prepare_where_status with multiple statuses (lines 2856-2860)."""
    result = queries.prepare_where_status(
        "open,filled", queries.OrderStatus, {"source": "someaddr"}
    )
    assert len(result) == 2


def test_prepare_where_status_with_invalid_status():
    """Test prepare_where_status with invalid status."""
    result = queries.prepare_where_status("invalid", queries.OrderStatus)
    assert len(result) == 0


def test_get_orders_with_get_asset(state_db):
    """Test get_orders with get_asset filter (line 2900)."""
    result = queries.get_orders(
        state_db,
        get_asset="XCP",
    )
    assert result is not None


def test_get_orders_with_give_asset(state_db):
    """Test get_orders with give_asset filter (line 2902)."""
    result = queries.get_orders(
        state_db,
        give_asset="XCP",
    )
    assert result is not None


def test_get_orders_by_asset_with_get_asset(state_db):
    """Test get_orders_by_asset with get_asset filter (lines 2938-2940)."""
    result = queries.get_orders_by_asset(
        state_db,
        asset="BTC",
        get_asset="XCP",
    )
    assert result is not None


def test_get_orders_by_asset_with_give_asset(state_db):
    """Test get_orders_by_asset with give_asset filter (lines 2941-2943)."""
    result = queries.get_orders_by_asset(
        state_db,
        asset="BTC",
        give_asset="XCP",
    )
    assert result is not None


def test_get_orders_by_two_assets_buy_direction(state_db):
    """Test get_orders_by_two_assets with BUY direction (lines 3031-3032)."""
    result = queries.get_orders_by_two_assets(
        state_db,
        asset1="XCP",
        asset2="BTC",
    )
    assert result is not None
    for order in result.result:
        assert order["market_pair"] == "XCP/BTC"
        assert order["market_dir"] in ["BUY", "SELL"]


# =============================================================================
# Tests for order matches
# =============================================================================


def test_get_order_matches_by_asset_with_forward_asset(state_db):
    """Test get_order_matches_by_asset with forward_asset filter (line 3168)."""
    result = queries.get_order_matches_by_asset(
        state_db,
        asset="BTC",
        forward_asset="XCP",
    )
    assert result is not None


def test_get_order_matches_by_asset_with_backward_asset(state_db):
    """Test get_order_matches_by_asset with backward_asset filter (lines 3172-3175)."""
    result = queries.get_order_matches_by_asset(
        state_db,
        asset="BTC",
        backward_asset="XCP",
    )
    assert result is not None


def test_get_order_matches_by_two_assets(state_db):
    """Test get_order_matches_by_two_assets (lines 3232-3238)."""
    result = queries.get_order_matches_by_two_assets(
        state_db,
        asset1="XCP",
        asset2="BTC",
    )
    assert result is not None
    for order_match in result.result:
        assert order_match["market_pair"] == "XCP/BTC"
        assert order_match["market_dir"] in ["BUY", "SELL"]


# =============================================================================
# Tests for fairminters
# =============================================================================


def test_get_fairminters_by_asset_with_longname(state_db):
    """Test get_fairminters_by_asset with subasset longname (line 3429)."""
    # Test with a subasset-style name (contains .)
    result = queries.get_fairminters_by_asset(
        state_db,
        asset="PARENT.CHILD",
    )
    assert result is not None


# =============================================================================
# Tests for AMM pool queries
# =============================================================================


def test_get_pools(state_db):
    """Test get_pools returns a result (may be empty pre-activation)."""
    result = queries.get_pools(state_db)
    assert result is not None


def test_get_pool_by_pair_nonexistent(state_db):
    """Test get_pool_by_pair for a pair with no pool."""
    result = queries.get_pool_by_pair(state_db, "XCP", "DIVISIBLE")
    # No pool exists in default test fixture — returns None
    assert result is None


def test_get_pool_deposits_by_pair(state_db):
    """Test get_pool_deposits_by_pair (may be empty)."""
    result = queries.get_pool_deposits_by_pair(state_db, "XCP", "DIVISIBLE")
    assert result is not None


def test_get_pool_withdrawals_by_pair(state_db):
    """Test get_pool_withdrawals_by_pair (may be empty)."""
    result = queries.get_pool_withdrawals_by_pair(state_db, "XCP", "DIVISIBLE")
    assert result is not None


def test_get_pool_matches_by_pair(state_db):
    """Test get_pool_matches_by_pair (may be empty)."""
    result = queries.get_pool_matches_by_pair(state_db, "XCP", "DIVISIBLE")
    assert result is not None


def test_get_all_pool_matches(state_db):
    """Test get_all_pool_matches (may be empty)."""
    result = queries.get_all_pool_matches(state_db)
    assert result is not None


def test_get_pool_deposits_by_address(state_db, defaults):
    """Test get_pool_deposits_by_address (may be empty)."""
    result = queries.get_pool_deposits_by_address(state_db, defaults["addresses"][0])
    assert result is not None


def test_get_pool_withdrawals_by_address(state_db, defaults):
    """Test get_pool_withdrawals_by_address (may be empty)."""
    result = queries.get_pool_withdrawals_by_address(state_db, defaults["addresses"][0])
    assert result is not None


def test_get_pool_positions_by_address(state_db, defaults):
    """Test get_pool_positions_by_address returns paginated QueryResult."""
    result = queries.get_pool_positions_by_address(state_db, defaults["addresses"][0])
    assert result is not None
    assert isinstance(result, queries.QueryResult)
    assert isinstance(result.result, list)


def test_get_pool_positions_result_count(state_db, defaults):
    """result_count reflects total matching rows, not just page size."""
    full = queries.get_pool_positions_by_address(state_db, defaults["addresses"][0], limit=100)
    total = full.result_count
    if total > 1:
        page = queries.get_pool_positions_by_address(state_db, defaults["addresses"][0], limit=1)
        assert len(page.result) <= 1
        assert page.result_count == total


# =============================================================================
# Tests for AMM pool quote functions — no-pool and edge-case paths
# =============================================================================


def test_get_pool_positions_by_address_with_cursor(state_db, defaults):
    """get_pool_positions_by_address respects cursor parameter."""
    result = queries.get_pool_positions_by_address(
        state_db, defaults["addresses"][0], cursor=999999
    )
    assert result is not None
    assert isinstance(result, queries.QueryResult)
    assert isinstance(result.result, list)


def test_get_pool_positions_by_address_with_offset(state_db, defaults):
    """get_pool_positions_by_address respects offset parameter."""
    result = queries.get_pool_positions_by_address(state_db, defaults["addresses"][0], offset=0)
    assert result is not None
    assert isinstance(result, queries.QueryResult)


def test_get_pool_quote_deposit_with_pool(state_db):
    """Deposit quote returns proportional amounts and LP estimate."""
    result = queries.get_pool_quote_deposit(state_db, "POOLASSETA", "POOLASSETB", 10_000_000)
    assert result["first_deposit"] is False
    assert result["asset_a"] == "POOLASSETA"
    assert result["asset_b"] == "POOLASSETB"
    assert result["quantity_a_required"] == 10_000_000
    assert result["quantity_b_required"] == 10_000_000
    assert result["quantity_minted_estimate"] > 0


def test_get_pool_quote_deposit_asset_order(state_db):
    """Deposit quote works with assets in either URL order."""
    result = queries.get_pool_quote_deposit(state_db, "POOLASSETB", "POOLASSETA", 10_000_000)
    assert result["first_deposit"] is False
    assert result["asset_a"] == "POOLASSETA"
    assert result["asset_b"] == "POOLASSETB"


def test_get_pool_quote_swap_with_pool(state_db):
    """Swap quote routes through pool and/or book orders."""
    result = queries.get_pool_quote(state_db, "POOLASSETA", "POOLASSETB", 1_000_000)
    assert result["pool_exists"] is True
    assert result["estimated_output"] > 0
    assert result["pool_output"] + result["book_output"] > 0
    assert result["fee_bps"] == 100
    assert result["effective_price"] > 0
    assert result["give_remaining"] == 0


def test_get_pool_quote_swap_no_pool_no_orders(state_db):
    """Swap quote with no pool and no orders returns early."""
    result = queries.get_pool_quote(state_db, "XCP", "DIVISIBLE", 1_000_000)
    assert result["pool_exists"] is False
    assert result["estimated_output"] == 0
    assert result["message"] == "No pool or orders exist for this pair."


def test_get_pool_quote_swap_reversed_asset_order(state_db):
    """Swap quote with reversed asset order (asset2 < asset1)."""
    result = queries.get_pool_quote(state_db, "POOLASSETB", "POOLASSETA", 1_000_000)
    assert result["pool_exists"] is True
    assert result["estimated_output"] > 0
    assert result["pool_output"] > 0


def test_get_pool_quote_swap_hybrid(state_db):
    """Swap quote with both pool and resting book orders (hybrid routing)."""
    result = queries.get_pool_quote(state_db, "POOLASSETA", "POOLASSETB", 10_000_000)
    assert result["pool_exists"] is True
    assert result["pool_output"] >= 0
    assert result["book_output"] > 0
    assert result["book_orders_matched"] >= 1
    assert result["estimated_output"] > 0


def test_get_pool_quote_withdraw_with_pool(state_db):
    """Withdraw quote returns proportional reserve amounts."""
    result = queries.get_pool_quote_withdraw(state_db, "POOLASSETA", "POOLASSETB", 1_000_000)
    assert result["pool_exists"] is True
    assert result["asset_a"] == "POOLASSETA"
    assert result["asset_b"] == "POOLASSETB"
    assert result["quantity_a_estimate"] > 0
    assert result["quantity_b_estimate"] > 0
    assert result["supply"] == 50_000_000


def test_get_pool_by_pair_with_pool(state_db):
    """get_pool_by_pair returns pool when it exists."""
    result = queries.get_pool_by_pair(state_db, "POOLASSETA", "POOLASSETB")
    assert result is not None
    assert result.result["asset_a"] == "POOLASSETA"
    assert result.result["asset_b"] == "POOLASSETB"
    assert result.result["reserve_a"] == 50_000_000
    assert result.result["reserve_b"] == 50_000_000


def test_get_pool_by_pair_reversed_order(state_db):
    """get_pool_by_pair with reversed asset order still finds pool."""
    result = queries.get_pool_by_pair(state_db, "POOLASSETB", "POOLASSETA")
    assert result is not None
    assert result.result["asset_a"] == "POOLASSETA"


def test_get_pool_positions_with_data(state_db, defaults):
    """get_pool_positions_by_address returns LP position when pool exists."""
    result = queries.get_pool_positions_by_address(state_db, defaults["addresses"][0])
    assert result.result_count > 0
    position = result.result[0]
    assert position["asset_a"] == "POOLASSETA"
    assert position["asset_b"] == "POOLASSETB"
    assert position["quantity"] == 50_000_000


def test_get_pool_quote_deposit_no_pool(state_db):
    """Deposit quote for nonexistent pair returns first_deposit=True."""
    result = queries.get_pool_quote_deposit(state_db, "XCP", "DIVISIBLE", 100_000_000)
    assert result["first_deposit"] is True
    assert result["quantity_minted_estimate"] is None


def test_get_pool_quote_withdraw_no_pool(state_db):
    """Withdraw quote for nonexistent pair returns pool_exists=False."""
    result = queries.get_pool_quote_withdraw(state_db, "XCP", "DIVISIBLE", 1_000)
    assert result["pool_exists"] is False


def test_get_pool_price_history(ledger_db):
    """Pool price history returns results."""
    result = queries.get_pool_price_history(ledger_db, "POOLASSETA", "POOLASSETB")
    assert result is not None


def test_get_pool_by_pair_case_insensitive(state_db):
    """get_pool_by_pair returns same result for lower/upper case inputs."""
    upper = queries.get_pool_by_pair(state_db, "POOLASSETA", "POOLASSETB")
    lower = queries.get_pool_by_pair(state_db, "poolasseta", "poolassetb")
    assert upper is not None
    assert lower is not None
    assert upper.result == lower.result


def test_get_pool_deposits_by_pair_case_insensitive(state_db):
    """get_pool_deposits_by_pair is case-insensitive on pair params."""
    upper = queries.get_pool_deposits_by_pair(state_db, "POOLASSETA", "POOLASSETB")
    lower = queries.get_pool_deposits_by_pair(state_db, "poolasseta", "poolassetb")
    assert upper.result == lower.result
    assert upper.result_count == lower.result_count


def test_get_pool_withdrawals_by_pair_case_insensitive(state_db):
    """get_pool_withdrawals_by_pair is case-insensitive on pair params."""
    upper = queries.get_pool_withdrawals_by_pair(state_db, "POOLASSETA", "POOLASSETB")
    lower = queries.get_pool_withdrawals_by_pair(state_db, "poolasseta", "poolassetb")
    assert upper.result == lower.result
    assert upper.result_count == lower.result_count


def test_get_pool_matches_by_pair_case_insensitive(state_db):
    """get_pool_matches_by_pair is case-insensitive on pair params."""
    upper = queries.get_pool_matches_by_pair(state_db, "POOLASSETA", "POOLASSETB")
    lower = queries.get_pool_matches_by_pair(state_db, "poolasseta", "poolassetb")
    assert upper.result == lower.result
    assert upper.result_count == lower.result_count


def test_get_pool_price_history_case_insensitive(ledger_db):
    """get_pool_price_history is case-insensitive on pair params."""
    upper = queries.get_pool_price_history(ledger_db, "POOLASSETA", "POOLASSETB")
    lower = queries.get_pool_price_history(ledger_db, "poolasseta", "poolassetb")
    assert upper.result == lower.result
    assert upper.result_count == lower.result_count


def test_get_all_pool_matches_empty(state_db):
    """All pool matches returns results."""
    result = queries.get_all_pool_matches(state_db)
    assert result is not None


def test_get_all_pool_matches_with_block_index(state_db):
    """All pool matches filtered by block_index."""
    result = queries.get_all_pool_matches(state_db, block_index=310000)
    assert result is not None


def test_get_pool_matches_by_pair_empty(state_db):
    """Pool matches for a pair returns results."""
    result = queries.get_pool_matches_by_pair(state_db, "POOLASSETA", "POOLASSETB")
    assert result is not None


def test_get_pool_quote_withdraw_zero_supply(state_db):
    """Withdraw quote reports zero supply when LP supply is drained."""
    pool = queries.get_pool_by_pair(state_db, "POOLASSETA", "POOLASSETB").result
    state_db.execute("UPDATE assets_info SET supply = 0 WHERE asset = ?", (pool["lp_asset"],))
    result = queries.get_pool_quote_withdraw(state_db, "POOLASSETA", "POOLASSETB", 1_000_000)
    assert result["pool_exists"] is True
    assert result["supply"] == 0
    assert "No LP tokens" in result["message"]


def test_get_pool_quote_case_insensitive(state_db):
    """get_pool_quote returns the same result for upper and lower case asset names."""
    upper = queries.get_pool_quote(state_db, "POOLASSETA", "POOLASSETB", 1_000_000)
    lower = queries.get_pool_quote(state_db, "poolasseta", "poolassetb", 1_000_000)
    assert upper == lower
    assert lower["pool_exists"] is True


def test_get_pool_quote_deposit_case_insensitive(state_db):
    """get_pool_quote_deposit returns the same result for upper and lower case asset names."""
    upper = queries.get_pool_quote_deposit(state_db, "POOLASSETA", "POOLASSETB", 10_000_000)
    lower = queries.get_pool_quote_deposit(state_db, "poolasseta", "poolassetb", 10_000_000)
    assert upper == lower
    assert lower["first_deposit"] is False


def test_get_pool_quote_withdraw_case_insensitive(state_db):
    """get_pool_quote_withdraw returns the same result for upper and lower case asset names."""
    upper = queries.get_pool_quote_withdraw(state_db, "POOLASSETA", "POOLASSETB", 1_000_000)
    lower = queries.get_pool_quote_withdraw(state_db, "poolasseta", "poolassetb", 1_000_000)
    assert upper == lower
    assert lower["pool_exists"] is True


# =============================================================================
# Tests for the COUNT(*) fast-path optimization
# These verify that ``result_count`` stays accurate when ``select_rows``
# bypasses the legacy wrap-COUNT and counts from the underlying table.
# =============================================================================


def test_get_pool_deposits_by_block(ledger_db, current_block_index):
    result = queries.get_pool_deposits_by_block(ledger_db, current_block_index)
    assert result is not None


def test_get_pool_withdrawals_by_block(ledger_db, current_block_index):
    result = queries.get_pool_withdrawals_by_block(ledger_db, current_block_index)
    assert result is not None


def test_get_pool_matches_by_block(ledger_db, current_block_index):
    result = queries.get_pool_matches_by_block(ledger_db, current_block_index)
    assert result is not None


def test_get_pool_matches_by_order(state_db):
    result = queries.get_pool_matches_by_order(state_db, "nonexistent_hash")
    assert result is not None


def test_get_pool_deposits_by_address_with_cursor(state_db, defaults):
    result = queries.get_pool_deposits_by_address(state_db, defaults["addresses"][0], cursor=999)
    assert result is not None


def test_get_pool_withdrawals_by_address_with_cursor(state_db, defaults):
    result = queries.get_pool_withdrawals_by_address(state_db, defaults["addresses"][0], cursor=999)
    assert result is not None


def test_get_pool_quote_no_pool_with_orders(state_db):
    """Book-only path: no pool but orders might exist."""
    result = queries.get_pool_quote(state_db, "XCP", "DIVISIBLE", 1_000_000)
    assert "pool_exists" in result
    assert result["pool_exists"] is False


def test_get_pools_with_sort(state_db):
    result = queries.get_pools(state_db, sort="reserve_a:desc")
    assert result is not None


def test_get_all_pool_matches_with_sort(state_db):
    result = queries.get_all_pool_matches(state_db, sort="forward_quantity:asc")
    assert result is not None


def test_count_fast_path_messages_no_tx_hash_filter(ledger_db):
    """Counting ``messages`` without a tx_hash filter uses the no-JOIN
    fast-path; the count must still match a row-by-row tally."""
    page = queries.select_rows(
        ledger_db,
        "messages",
        limit=10,
        select="message_index AS event_index, event, tx_hash, block_index",
    )
    cursor = ledger_db.cursor()
    actual = cursor.execute("SELECT COUNT(*) AS c FROM messages").fetchone()["c"]
    assert page.result_count == actual


def test_count_fast_path_messages_with_event_filter(ledger_db):
    """Event filter on ``messages`` exercises the no-JOIN fast-path with
    a non-trivial WHERE clause."""
    page = queries.select_rows(
        ledger_db,
        "messages",
        where={"event": "CREDIT"},
        limit=10,
        select="message_index AS event_index, event, tx_hash, block_index",
    )
    cursor = ledger_db.cursor()
    actual = cursor.execute(
        "SELECT COUNT(*) AS c FROM messages WHERE event = ?", ("CREDIT",)
    ).fetchone()["c"]
    assert page.result_count == actual


def test_count_fast_path_messages_with_tx_hash_filter(ledger_db, defaults):
    """Filtering by ``tx_hash`` forces the JOIN path; ensure the wrap-COUNT
    fallback still returns the correct count."""
    sample_tx = ledger_db.cursor().execute("SELECT tx_hash FROM transactions LIMIT 1").fetchone()
    if not sample_tx:
        return
    tx_hash = sample_tx["tx_hash"]
    page = queries.select_rows(
        ledger_db,
        "messages",
        where={"tx_hash": tx_hash},
        limit=10,
        select="message_index AS event_index, event, tx_hash, block_index",
    )
    # No assertion on the exact value other than "matches reality".
    cursor = ledger_db.cursor()
    blob = bytes.fromhex(tx_hash)
    actual = cursor.execute(
        "SELECT COUNT(*) AS c FROM messages WHERE tx_index = (SELECT tx_index FROM transactions WHERE tx_hash = ?)",
        (blob,),
    ).fetchone()["c"]
    assert page.result_count == actual


def test_count_fast_path_hash_fk_table(ledger_db):
    """Counting a ``_HASH_FK_PROJECTIONS`` table skips the legacy hash JOIN."""
    page = queries.select_rows(ledger_db, "dispenses", limit=10)
    cursor = ledger_db.cursor()
    actual = cursor.execute("SELECT COUNT(*) AS c FROM dispenses").fetchone()["c"]
    assert page.result_count == actual


def test_count_fast_path_transactions_with_status_override(ledger_db):
    """``transactions_with_status`` filter on a column that exists on
    ``transactions`` itself uses the underlying-table COUNT override."""
    page = queries.select_rows(
        ledger_db,
        "transactions_with_status",
        where={"transaction_type": "send"},
        limit=10,
    )
    cursor = ledger_db.cursor()
    actual = cursor.execute(
        "SELECT COUNT(*) AS c FROM transactions WHERE transaction_type = ?", ("send",)
    ).fetchone()["c"]
    assert page.result_count == actual


def test_count_fast_path_transactions_with_status_with_valid(ledger_db):
    """When the filter references the ``valid`` column (only on
    ``transactions_status``), the override is rejected and we fall back to
    the wrap-COUNT path."""
    page = queries.select_rows(
        ledger_db,
        "transactions_with_status",
        where={"valid": True},
        limit=10,
    )
    cursor = ledger_db.cursor()
    actual = cursor.execute(
        "SELECT COUNT(*) AS c FROM transactions t "
        "LEFT JOIN transactions_status ts ON t.tx_index = ts.tx_index "
        "WHERE ts.valid = ?",
        (True,),
    ).fetchone()["c"]
    assert page.result_count == actual


def test_count_fast_path_group_by_falls_back(ledger_db):
    """``group_by`` callers must keep the wrap-COUNT semantics so the
    returned count reflects the number of *groups*, not the number of
    pre-group rows."""
    page = queries.select_rows(
        ledger_db,
        "messages",
        where={"block_index": 310000},
        select="event, COUNT(*) AS event_count",
        group_by="event",
        cursor_field="event",
    )
    cursor = ledger_db.cursor()
    actual = cursor.execute(
        "SELECT COUNT(*) AS c FROM (SELECT event FROM messages WHERE block_index = ? GROUP BY event)",
        (310000,),
    ).fetchone()["c"]
    assert page.result_count == actual
