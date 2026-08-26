"""Tests for counterpartycore.lib.api.apiwatcher.

Covers:
- shutdown: cross-thread SQLite interrupt, InterruptError handling, daemon thread
- the BLOCK_PARSED lookups: query plan (no temporary sort) and ordering semantics
- DETACH_FROM_UTXO source_address typo fix
- update_xcp_supply status='valid' guard
- update_assets_info description_locked propagation
- update_address_events removed `no_cache` parameter
"""

import inspect
import json
import re
import threading
import time
from unittest.mock import MagicMock

import pytest
from counterpartycore.lib.api import apiwatcher


def test_api_watcher_stop_interrupts_sqlite_connections():
    watcher = apiwatcher.APIWatcher.__new__(apiwatcher.APIWatcher)
    threading.Thread.__init__(watcher, name="Watcher")
    watcher.stop_event = threading.Event()
    watcher.db_lock = threading.Lock()
    watcher.state_db = MagicMock()
    watcher.ledger_db = MagicMock()
    watcher.current_state_thread = None
    watcher.join = MagicMock()
    watcher.is_alive = MagicMock(return_value=False)

    watcher.stop()

    watcher.state_db.interrupt.assert_called_once_with()
    watcher.ledger_db.interrupt.assert_called_once_with()
    watcher.join.assert_called_once_with(timeout=5)


def test_api_watcher_stop_does_not_interrupt_a_connection_being_closed(monkeypatch):
    """apsw calls sqlite3_interrupt() holding the GIL, but close() releases it
    around sqlite3_close_v2(): an unsynchronised interrupt can reach a handle
    that is already being freed, so the two must never overlap."""
    monkeypatch.setattr(apiwatcher.database, "get_db_connection", lambda *a, **k: MagicMock())
    monkeypatch.setattr(apiwatcher, "update_last_parsed_events_cache", lambda *a, **k: None)

    watcher = apiwatcher.APIWatcher(MagicMock())
    # Return straight to `run`'s finally, without entering `follow`.
    monkeypatch.setattr(apiwatcher, "catch_up", lambda *a, **k: watcher.stop_event.set())

    closing = threading.Event()
    in_close = threading.Event()
    overlapped = []

    def slow_close():
        closing.set()
        in_close.set()
        time.sleep(0.05)
        in_close.clear()

    def record_interrupt():
        overlapped.append(in_close.is_set())

    watcher.state_db.close.side_effect = slow_close
    watcher.state_db.interrupt.side_effect = record_interrupt
    watcher.ledger_db.interrupt.side_effect = record_interrupt

    watcher.start()
    assert closing.wait(timeout=5), "watcher never reached its close"
    watcher.stop(deadline=time.monotonic() + 5)

    assert not watcher.is_alive()
    # Both interrupts waited for the close to finish. Without the lock they run
    # immediately and see a close in flight.
    assert overlapped == [False, False]


def test_api_watcher_is_a_daemon_thread(monkeypatch):
    """A bounded join only bounds anything if the thread cannot outlive the
    interpreter: a non-daemon thread that survives `stop()` still blocks process
    exit, which is the hang this bound exists to prevent."""
    monkeypatch.setattr(apiwatcher.database, "get_db_connection", lambda *a, **k: MagicMock())
    monkeypatch.setattr(apiwatcher, "update_last_parsed_events_cache", lambda *a, **k: None)

    watcher = apiwatcher.APIWatcher(MagicMock())

    assert watcher.daemon is True


def test_api_watcher_handles_shutdown_interrupt(monkeypatch):
    watcher = apiwatcher.APIWatcher.__new__(apiwatcher.APIWatcher)
    threading.Thread.__init__(watcher, name="Watcher")
    watcher.stop_event = threading.Event()
    watcher.db_lock = threading.Lock()
    watcher.state_db = MagicMock()
    watcher.ledger_db = MagicMock()
    watcher.current_state_thread = None

    def interrupted_catch_up(_ledger_db, _state_db, _watcher):
        watcher.stop_event.set()
        raise apiwatcher.apsw.InterruptError("interrupted")

    monkeypatch.setattr(apiwatcher, "catch_up", interrupted_catch_up)

    watcher.run()

    watcher.state_db.close.assert_called_once_with()
    watcher.ledger_db.close.assert_called_once_with()


# The queries as the production code will actually run them, so that dropping an
# `INDEXED BY` clause from apiwatcher fails these tests instead of silently
# regressing to the plan that cost 132s on a cold mainnet State DB.
BLOCK_PARSED_QUERIES = [
    ("LAST_BLOCK_PARSED_SQL", apiwatcher.LAST_BLOCK_PARSED_SQL),
    ("PREVIOUS_BLOCK_PARSED_SQL", apiwatcher.PREVIOUS_BLOCK_PARSED_SQL),
    ("EARLIER_BLOCKS_PARSED_SQL", apiwatcher.EARLIER_BLOCKS_PARSED_SQL),
]


@pytest.mark.parametrize(
    ("name", "query"), BLOCK_PARSED_QUERIES, ids=[q[0] for q in BLOCK_PARSED_QUERIES]
)
def test_block_parsed_queries_scan_the_event_index_without_sorting(state_db, name, query):
    plan = state_db.execute("EXPLAIN QUERY PLAN " + query).fetchall()  # noqa: S608  # nosec B608
    details = [row["detail"] for row in plan]

    assert any("parsed_events_event_index_idx" in detail for detail in details), (
        f"{name} no longer uses the event-index index: {details}"
    )
    assert not any("USE TEMP B-TREE" in detail for detail in details), (
        f"{name} sorts into a temporary B-tree again: {details}"
    )


@pytest.mark.parametrize(
    ("name", "query"), BLOCK_PARSED_QUERIES, ids=[q[0] for q in BLOCK_PARSED_QUERIES]
)
def test_block_parsed_queries_match_the_unhinted_plan(state_db, name, query):
    """`INDEXED BY` must change only the access path, never the result."""
    unhinted = query.replace(" INDEXED BY parsed_events_event_index_idx", "")
    assert unhinted != query, f"{name} lost its INDEXED BY clause"

    hinted_rows = state_db.execute(query).fetchall()  # noqa: S608  # nosec B608
    unhinted_rows = state_db.execute(unhinted).fetchall()  # noqa: S608  # nosec B608

    assert hinted_rows == unhinted_rows


@pytest.fixture
def realistic_parsed_events():
    """A `parsed_events` big enough for SQLite to reproduce the production plan.

    On the shared fixture the table is small enough that the planner sometimes
    picks a full scan, which hides the regression these queries exist to prevent.
    The 132s incident needed a table where `parsed_events_event_idx` looks
    attractive and the BLOCK_PARSED rows it finds are expensive to sort.
    """
    db = apiwatcher.apsw.Connection(":memory:")
    db.execute(
        "CREATE TABLE parsed_events "
        "(event_index INTEGER, event TEXT, event_hash TEXT, block_index INTEGER)"
    )
    db.execute("CREATE UNIQUE INDEX parsed_events_event_index_idx ON parsed_events (event_index)")
    db.execute("CREATE INDEX parsed_events_event_idx ON parsed_events (event)")
    db.executemany(
        "INSERT INTO parsed_events VALUES (?, ?, ?, ?)",
        [(i, "BLOCK_PARSED" if i % 10 == 0 else "OTHER", str(i), i // 10) for i in range(50000)],
    )
    db.execute("ANALYZE")
    try:
        yield db
    finally:
        db.close()


@pytest.mark.parametrize(
    ("name", "query"), BLOCK_PARSED_QUERIES, ids=[q[0] for q in BLOCK_PARSED_QUERIES]
)
def test_block_parsed_queries_avoid_the_sort_that_the_planner_would_choose(
    realistic_parsed_events, name, query
):
    unhinted = query.replace(" INDEXED BY parsed_events_event_index_idx", "")
    unhinted_plan = [
        row[3]
        for row in realistic_parsed_events.execute("EXPLAIN QUERY PLAN " + unhinted)  # noqa: S608  # nosec B608
    ]
    hinted_plan = [
        row[3]
        for row in realistic_parsed_events.execute("EXPLAIN QUERY PLAN " + query)  # noqa: S608  # nosec B608
    ]

    # Guards the premise: without the hint SQLite really does choose the sort.
    assert any("USE TEMP B-TREE" in detail for detail in unhinted_plan), (
        f"{name}: the planner no longer picks the slow plan, this test is moot: {unhinted_plan}"
    )
    assert not any("USE TEMP B-TREE" in detail for detail in hinted_plan), (
        f"{name} sorts into a temporary B-tree again: {hinted_plan}"
    )
    assert realistic_parsed_events.execute(query).fetchall() == (  # noqa: S608  # nosec B608
        realistic_parsed_events.execute(unhinted).fetchall()  # noqa: S608  # nosec B608
    )


def test_get_last_block_parsed_preserves_event_order(state_db):
    expected = state_db.execute(
        """
        SELECT block_index
        FROM parsed_events
        WHERE event = 'BLOCK_PARSED'
        ORDER BY event_index DESC
        LIMIT 1
        """
    ).fetchone()["block_index"]

    assert apiwatcher.get_last_block_parsed(state_db, no_cache=True) == expected


def test_block_parsed_queries_fail_loudly_without_their_index(state_db):
    """`INDEXED BY` is a requirement, not a hint: losing the index must not
    silently fall back to the slow plan. Migration 0002 carries the matching
    comment."""
    state_db.execute("DROP INDEX parsed_events_event_index_idx")
    try:
        for name, query in BLOCK_PARSED_QUERIES:
            with pytest.raises(apiwatcher.apsw.SQLError, match="no such index"):
                state_db.execute(query).fetchall()  # noqa: S608  # nosec B608
            assert name  # keeps the loop variable meaningful in failure output
    finally:
        state_db.execute(
            "CREATE UNIQUE INDEX parsed_events_event_index_idx ON parsed_events (event_index)"
        )


def test_get_last_block_parsed_uses_latest_event_not_highest_block(state_db):
    max_event_index = state_db.execute(
        "SELECT COALESCE(MAX(event_index), 0) AS max_event_index FROM parsed_events"
    ).fetchone()["max_event_index"]
    state_db.execute(
        "INSERT INTO parsed_events (event_index, event, event_hash, block_index) VALUES (?, ?, ?, ?)",
        (max_event_index + 1, "BLOCK_PARSED", "older-height-newer-event", 100),
    )
    state_db.execute(
        "INSERT INTO parsed_events (event_index, event, event_hash, block_index) VALUES (?, ?, ?, ?)",
        (max_event_index + 2, "OTHER", "trailing-event", 999),
    )

    assert apiwatcher.get_last_block_parsed(state_db, no_cache=True) == 100


def test_get_last_block_parsed_empty_table(state_db):
    state_db.execute("DELETE FROM parsed_events")

    assert apiwatcher.get_last_block_parsed(state_db, no_cache=True) == 0


def test_detach_from_utxo_field_name_correct():
    """DETACH_FROM_UTXO must reference `source_address` (not the legacy typo
    `sourc_address`); the streamed handler keys off this dict and silently
    dropped the source row for every detach until the typo was fixed."""
    fields = apiwatcher.EVENTS_ADDRESS_FIELDS["DETACH_FROM_UTXO"]
    assert "source_address" in fields
    assert "sourc_address" not in fields
    assert "destination" in fields


def test_update_address_events_signature():
    """update_address_events no longer accepts a `no_cache` kwarg; this is
    a regression guard against an accidental re-introduction that would
    silently make callers' kwargs go nowhere."""
    sig = inspect.signature(apiwatcher.update_address_events)
    assert list(sig.parameters.keys()) == ["state_db", "event"]


def test_update_xcp_supply_skips_invalid_status(state_db):
    """When the streaming handler sees an invalid issuance/sweep with a
    non-zero fee_paid, it must NOT debit XCP supply -- migration 0004
    derives supply via valid-only ledger queries, so a divergence here
    causes snapshot vs streamed nodes to diverge."""

    # Snapshot supply before
    cursor = state_db.cursor()
    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    supply_before = row["supply"] if row else 0

    invalid_event = {
        "event": "ASSET_ISSUANCE",
        "bindings": json.dumps(
            {
                "status": "invalid: insufficient funds",
                "fee_paid": 50000000,
                "asset": "BOGUS",
            }
        ),
    }
    apiwatcher.update_xcp_supply(state_db, invalid_event)

    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    supply_after = row["supply"] if row else 0
    assert supply_after == supply_before


def test_update_xcp_supply_applies_for_valid(state_db):
    """A valid issuance with non-zero fee_paid must reduce XCP supply
    on the streamed handler side."""

    cursor = state_db.cursor()
    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    if row is None:
        pytest.skip("No XCP row in assets_info to mutate")
    supply_before = row["supply"]

    valid_event = {
        "event": "ASSET_ISSUANCE",
        "bindings": json.dumps(
            {
                "status": "valid",
                "fee_paid": 12345,
                "asset": "WHATEVER",
            }
        ),
    }
    apiwatcher.update_xcp_supply(state_db, valid_event)

    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    assert row["supply"] == supply_before - 12345


def test_update_xcp_supply_skips_zero_fee(state_db):
    """fee_paid == 0 is a no-op even on a valid event."""
    cursor = state_db.cursor()
    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    if row is None:
        pytest.skip("No XCP row in assets_info to mutate")
    supply_before = row["supply"]

    event = {
        "event": "ASSET_ISSUANCE",
        "bindings": json.dumps({"status": "valid", "fee_paid": 0}),
    }
    apiwatcher.update_xcp_supply(state_db, event)

    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    assert row["supply"] == supply_before


def test_update_xcp_supply_ignores_non_destroy_events(state_db):
    """Events outside XCP_DESTROY_EVENTS must not touch supply at all."""
    cursor = state_db.cursor()
    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    if row is None:
        pytest.skip("No XCP row in assets_info to mutate")
    supply_before = row["supply"]

    event = {
        "event": "DEBIT",
        "bindings": json.dumps({"status": "valid", "fee_paid": 9999}),
    }
    apiwatcher.update_xcp_supply(state_db, event)

    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    assert row["supply"] == supply_before


def test_update_assets_info_propagates_description_locked(state_db):
    """An ASSET_ISSUANCE event with description_locked=True must update
    the column; the streamed handler used to ignore this flag and that
    drift broke snapshot vs streamed parity."""
    cursor = state_db.cursor()
    asset_row = cursor.execute(
        "SELECT asset FROM assets_info WHERE asset NOT IN ('XCP', 'BTC') LIMIT 1"
    ).fetchone()
    if asset_row is None:
        pytest.skip("No mutable asset to test description_locked")
    asset = asset_row["asset"]

    cursor.execute("UPDATE assets_info SET description_locked = 0 WHERE asset = ?", (asset,))

    event = {
        "event": "ASSET_ISSUANCE",
        "bindings": json.dumps(
            {
                "status": "valid",
                "asset": asset,
                "asset_longname": None,
                "asset_id": "1",
                "issuer": "addr",
                "divisible": True,
                "description": "x",
                "mime_type": "text/plain",
                "quantity": 0,
                "block_index": 200,
                "locked": False,
                "description_locked": True,
                "fee_paid": 0,
            }
        ),
    }
    apiwatcher.update_assets_info(state_db, event)

    row = cursor.execute(
        "SELECT description_locked FROM assets_info WHERE asset = ?", (asset,)
    ).fetchone()
    assert bool(row["description_locked"]) is True


def test_update_assets_info_skips_invalid_status(state_db):
    """Only valid issuance events update assets_info."""
    cursor = state_db.cursor()
    asset_row = cursor.execute(
        "SELECT asset, description FROM assets_info WHERE asset NOT IN ('XCP', 'BTC') LIMIT 1"
    ).fetchone()
    if asset_row is None:
        pytest.skip("No mutable asset to test")
    asset, original_desc = asset_row["asset"], asset_row["description"]

    event = {
        "event": "ASSET_ISSUANCE",
        "bindings": json.dumps(
            {
                "status": "invalid",
                "asset": asset,
                "asset_longname": None,
                "asset_id": "1",
                "issuer": "addr",
                "divisible": True,
                "description": "SHOULD NOT WIN",
                "mime_type": "text/plain",
                "quantity": 0,
                "block_index": 200,
                "locked": False,
            }
        ),
    }
    apiwatcher.update_assets_info(state_db, event)

    row = cursor.execute("SELECT description FROM assets_info WHERE asset = ?", (asset,)).fetchone()
    assert row["description"] == original_desc


def test_pool_events_in_update_events_id_fields():
    assert "POOL_UPDATE" in apiwatcher.UPDATE_EVENTS_ID_FIELDS
    assert apiwatcher.UPDATE_EVENTS_ID_FIELDS["POOL_UPDATE"] == ["asset_a", "asset_b"]


def test_pool_events_in_events_address_fields():
    for event in (
        "OPEN_POOL",
        "POOL_UPDATE",
        "NEW_POOL_DEPOSIT",
        "NEW_POOL_WITHDRAWAL",
        "POOL_MATCH",
    ):
        assert event in apiwatcher.EVENTS_ADDRESS_FIELDS


def test_pool_tables_in_state_db_tables():
    for table in ("pools", "pool_deposits", "pool_withdrawals", "pool_matches"):
        assert table in apiwatcher.STATE_DB_TABLES


def test_update_address_events_skips_unknown_event(state_db):
    event = {"event": "UNKNOWN_EVENT_XYZ", "bindings": "{}"}
    apiwatcher.update_address_events(state_db, event)  # should not raise


def test_update_assets_info_no_description_locked(state_db):
    """description_locked absent from bindings -> column not updated."""
    cursor = state_db.cursor()
    asset_row = cursor.execute(
        "SELECT asset, description_locked FROM assets_info WHERE asset NOT IN ('XCP', 'BTC') LIMIT 1"
    ).fetchone()
    if asset_row is None:
        return
    asset = asset_row["asset"]
    original = bool(asset_row["description_locked"])

    event = {
        "event": "ASSET_ISSUANCE",
        "bindings": json.dumps(
            {
                "status": "valid",
                "asset": asset,
                "asset_longname": None,
                "asset_id": "1",
                "issuer": "addr",
                "divisible": True,
                "description": "x",
                "mime_type": "text/plain",
                "quantity": 0,
                "block_index": 200,
                "locked": False,
                "fee_paid": 0,
            }
        ),
    }
    apiwatcher.update_assets_info(state_db, event)

    row = cursor.execute(
        "SELECT description_locked FROM assets_info WHERE asset = ?", (asset,)
    ).fetchone()
    assert bool(row["description_locked"]) == original


def test_events_address_fields_keys_are_lowercase_underscore():
    """Defensive: every field name listed in EVENTS_ADDRESS_FIELDS must
    look like a real binding key (lowercase + underscores). This would
    have caught the original `sourc_address` typo."""
    pattern = re.compile(r"^[a-z][a-z0-9_]*$")
    for event_name, fields in apiwatcher.EVENTS_ADDRESS_FIELDS.items():
        for field in fields:
            assert pattern.match(field), f"{event_name} declares a malformed field name {field!r}"
