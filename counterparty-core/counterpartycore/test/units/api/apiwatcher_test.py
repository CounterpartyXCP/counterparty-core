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
    ("BLOCKS_PARSED_DESC_SQL", apiwatcher.BLOCKS_PARSED_DESC_SQL),
]

# `LAST_PARSED_EVENT_SQL` carries no `event` filter, so the planner reaches for the
# event-index index on its own and the 132s plan was never available to it. It is
# pinned all the same -- one access path across all three queries, and a loud
# failure if the index is ever dropped -- but it cannot take the premise the test
# below guards, which is that the *unhinted* query picks the sort.
EVENT_INDEX_QUERIES = BLOCK_PARSED_QUERIES + [
    ("LAST_PARSED_EVENT_SQL", apiwatcher.LAST_PARSED_EVENT_SQL),
]


@pytest.mark.parametrize(
    ("name", "query"), EVENT_INDEX_QUERIES, ids=[q[0] for q in EVENT_INDEX_QUERIES]
)
def test_event_index_queries_scan_without_sorting(state_db, name, query):
    plan = state_db.execute("EXPLAIN QUERY PLAN " + query).fetchall()  # noqa: S608  # nosec B608
    details = [row["detail"] for row in plan]

    assert any("parsed_events_event_index_idx" in detail for detail in details), (
        f"{name} no longer uses the event-index index: {details}"
    )
    assert not any("USE TEMP B-TREE" in detail for detail in details), (
        f"{name} sorts into a temporary B-tree again: {details}"
    )


@pytest.mark.parametrize(
    ("name", "query"), EVENT_INDEX_QUERIES, ids=[q[0] for q in EVENT_INDEX_QUERIES]
)
def test_event_index_queries_match_the_unhinted_plan(state_db, name, query):
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


# --------------------------------------------------------------------------------------------
# Reorganization detection
# --------------------------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def clear_watcher_failure():
    """`WATCHER_FAILED` is process-wide; never let one test leak into the next."""
    apiwatcher.WATCHER_FAILED.clear()
    yield
    apiwatcher.WATCHER_FAILED.clear()


def _connect(schema, rows_sql, rows):
    db = apiwatcher.apsw.Connection(":memory:")
    db.execute(schema)
    db.executemany(rows_sql, rows)
    db.setrowtrace(apiwatcher.database.rowtracer)
    return db


def _reorg_dbs(parsed_events, messages):
    state_db = _connect(
        "CREATE TABLE parsed_events "
        "(event_index INTEGER, event TEXT, event_hash TEXT, block_index INTEGER)",
        "INSERT INTO parsed_events VALUES (?, ?, ?, ?)",
        parsed_events,
    )
    state_db.execute(
        "CREATE UNIQUE INDEX parsed_events_event_index_idx ON parsed_events (event_index)"
    )
    ledger_db = _connect(
        "CREATE TABLE messages "
        "(message_index INTEGER PRIMARY KEY, event TEXT, event_hash TEXT, block_index INTEGER)",
        "INSERT INTO messages VALUES (?, ?, ?, ?)",
        messages,
    )
    try:
        yield ledger_db, state_db
    finally:
        state_db.close()
        ledger_db.close()


# Blocks 1, 2 and 3, each parsed through to its BLOCK_PARSED event.
WHOLE_BLOCKS = [
    (10, "BLOCK_PARSED", "hash-1", 1),
    (20, "BLOCK_PARSED", "hash-2", 2),
    (30, "BLOCK_PARSED", "hash-3", 3),
]

# The State DB stopped *between* two events of block 3: its CREDIT is copied, the
# BLOCK_PARSED that closes the block is not. `get_next_event_to_parse` orders by
# `message_index` and not by block, so this is where the watcher sits for as long
# as it takes to copy a block -- and for the whole of a catch-up.
MID_BLOCK_EVENTS = [
    (10, "BLOCK_PARSED", "hash-1", 1),
    (20, "BLOCK_PARSED", "hash-2", 2),
    (25, "CREDIT", "credit-3", 3),
]
MID_BLOCK_MESSAGES = MID_BLOCK_EVENTS + [(30, "BLOCK_PARSED", "hash-3", 3)]


@pytest.fixture
def reorg_dbs():
    """A State DB whose `parsed_events` mirror a three-block Ledger DB.

    Blocks 1, 2 and 3 were parsed, each ending on a BLOCK_PARSED event, and the
    Ledger DB still holds exactly those events. Tests rewrite the ledger's
    hashes to stage the branch change they are about.
    """
    yield from _reorg_dbs(WHOLE_BLOCKS, WHOLE_BLOCKS)


@pytest.fixture
def mid_block_dbs():
    """The same pair, caught with block 3 only half copied into the State DB."""
    yield from _reorg_dbs(MID_BLOCK_EVENTS, MID_BLOCK_MESSAGES)


@pytest.fixture
def partial_block_dbs():
    """A State DB that never finished a block, over a ledger that replaced it."""
    yield from _reorg_dbs([(5, "CREDIT", "credit-1", 1)], [(5, "CREDIT", "other-credit", 1)])


@pytest.fixture
def rollbacks(monkeypatch):
    """Records the blocks `check_reorg` asks to roll back to."""
    targets = []
    monkeypatch.setattr(
        apiwatcher.dbbuilder,
        "rollback_state_db",
        lambda state_db, block_index: targets.append(block_index),
    )
    return targets


def test_check_reorg_leaves_a_matching_ledger_alone(reorg_dbs, rollbacks):
    ledger_db, state_db = reorg_dbs

    assert apiwatcher.check_reorg(ledger_db, state_db) is False
    assert rollbacks == []


def test_check_reorg_detects_a_tip_block_replaced_at_the_same_height(reorg_dbs, rollbacks):
    """The shallowest reorganization there is, and the one the historical
    `LIMIT 1 OFFSET 1` comparison could not see: the block the State DB parsed
    last is replaced by another at the same height, so the only event whose hash
    changed is the one that query stepped over."""
    ledger_db, state_db = reorg_dbs
    ledger_db.execute("UPDATE messages SET event_hash = 'other-3' WHERE message_index = 30")

    # The premise: everything below the tip is untouched, so a check that skips
    # the tip compares two identical hashes and reports nothing.
    previous = apiwatcher.fetch_one(state_db, "SELECT * FROM parsed_events WHERE event_index = 20")
    in_ledger = apiwatcher.fetch_one(ledger_db, "SELECT * FROM messages WHERE message_index = 20")
    assert previous["event_hash"] == in_ledger["event_hash"]

    assert apiwatcher.check_reorg(ledger_db, state_db) is True
    assert rollbacks == [3]


def test_check_reorg_rolls_back_to_the_first_block_that_still_matches(reorg_dbs, rollbacks):
    ledger_db, state_db = reorg_dbs
    ledger_db.execute("UPDATE messages SET event_hash = 'other' WHERE message_index IN (20, 30)")

    assert apiwatcher.check_reorg(ledger_db, state_db) is True
    assert rollbacks == [2]


def test_check_reorg_leaves_a_matching_ledger_alone_mid_block(mid_block_dbs, rollbacks):
    """Sitting in the middle of a block is the watcher's normal state between two
    events, not a reorganization: the copied part of the block still matches."""
    ledger_db, state_db = mid_block_dbs

    assert apiwatcher.check_reorg(ledger_db, state_db) is False
    assert rollbacks == []


def test_check_reorg_detects_a_reorg_inside_the_block_being_parsed(mid_block_dbs, rollbacks):
    """The blind spot a BLOCK_PARSED-only comparison leaves: the State DB holds
    part of block 3 when the ledger replaces that block. The last BLOCK_PARSED it
    parsed is block 2's, which the reorganization never touched, so comparing
    blocks reports nothing while the copied events of block 3 are orphaned."""
    ledger_db, state_db = mid_block_dbs
    ledger_db.execute("UPDATE messages SET event_hash = 'other-credit' WHERE message_index = 25")
    ledger_db.execute("UPDATE messages SET event_hash = 'other-3' WHERE message_index = 30")

    # The premise: the newest *block* the State DB parsed still matches.
    last_block = apiwatcher.fetch_one(state_db, apiwatcher.LAST_BLOCK_PARSED_SQL)
    in_ledger = apiwatcher.fetch_one(
        ledger_db,
        "SELECT * FROM messages WHERE block_index = ? AND event = 'BLOCK_PARSED'",
        (last_block["block_index"],),
    )
    assert in_ledger is None or in_ledger["event_hash"] == "hash-2"

    assert apiwatcher.check_reorg(ledger_db, state_db) is True
    assert rollbacks == [3]


def test_check_reorg_detects_a_reorg_that_truncates_the_block_being_parsed(
    mid_block_dbs, rollbacks
):
    """A rollback that has not yet re-added the replacement block: the event the
    State DB last copied simply no longer exists in the ledger."""
    ledger_db, state_db = mid_block_dbs
    ledger_db.execute("DELETE FROM messages WHERE block_index = 3")

    assert apiwatcher.check_reorg(ledger_db, state_db) is True
    assert rollbacks == [3]


def test_check_reorg_rolls_back_to_the_genesis_when_only_a_partial_block_was_parsed(
    partial_block_dbs, rollbacks
):
    """`search_matching_event` walks BLOCK_PARSED rows, and there are none: the
    State DB never finished a block, so there is no block to keep."""
    ledger_db, state_db = partial_block_dbs

    assert apiwatcher.check_reorg(ledger_db, state_db) is True
    assert rollbacks == [0]


def test_check_reorg_rolls_back_to_the_genesis_when_nothing_matches(reorg_dbs, rollbacks):
    ledger_db, state_db = reorg_dbs
    ledger_db.execute("DELETE FROM messages")

    assert apiwatcher.check_reorg(ledger_db, state_db) is True
    assert rollbacks == [0]


def test_check_reorg_is_a_no_op_on_an_empty_state_db(reorg_dbs, rollbacks):
    ledger_db, state_db = reorg_dbs
    state_db.execute("DELETE FROM parsed_events")

    assert apiwatcher.check_reorg(ledger_db, state_db) is False
    assert rollbacks == []


def test_get_last_block_touched_sees_the_block_being_copied(mid_block_dbs, reorg_dbs):
    """`get_last_block_parsed` reports the last block *completed*; this one the
    block the watcher is inside. They agree on a whole block and diverge on a
    half-copied one, which is the case a rollback target has to be measured
    against (see `staterollback.rollback_reason`)."""
    _, mid_block_state_db = mid_block_dbs
    _, whole_blocks_state_db = reorg_dbs

    assert apiwatcher.get_last_block_parsed(whole_blocks_state_db, no_cache=True) == 3
    assert apiwatcher.get_last_block_touched(whole_blocks_state_db) == 3

    assert apiwatcher.get_last_block_parsed(mid_block_state_db, no_cache=True) == 2
    assert apiwatcher.get_last_block_touched(mid_block_state_db) == 3


def test_get_last_block_touched_is_zero_on_an_empty_state_db(reorg_dbs):
    _, state_db = reorg_dbs
    state_db.execute("DELETE FROM parsed_events")

    assert apiwatcher.get_last_block_touched(state_db) == 0


def test_check_reorg_targets_a_block_the_state_db_actually_holds(mid_block_dbs, rollbacks):
    """The contract `staterollback.rollback_reason` relies on: whatever
    `check_reorg` asks to roll back to, the State DB holds rows at or above it,
    so the rollback is never dismissed as having nothing to undo."""
    ledger_db, state_db = mid_block_dbs
    ledger_db.execute("UPDATE messages SET event_hash = 'other-credit' WHERE message_index = 25")

    assert apiwatcher.check_reorg(ledger_db, state_db) is True
    assert rollbacks == [3]
    assert rollbacks[0] <= apiwatcher.get_last_block_touched(state_db)


def test_search_matching_event_starts_at_the_last_parsed_block(reorg_dbs):
    """It must consider the tip too: with the tip skipped, a State DB whose only
    orphaned block is its last one would roll back one block further than the
    reorganization actually reached."""
    ledger_db, state_db = reorg_dbs
    ledger_db.execute("UPDATE messages SET event_hash = 'other-3' WHERE message_index = 30")

    matching = apiwatcher.search_matching_event(ledger_db, state_db)

    assert matching["block_index"] == 2


def test_get_ledger_data_version_changes_when_another_connection_commits(tmp_path):
    """The signal `ReorgWatch` is keyed on: SQLite only bumps `data_version` for
    changes committed by a *different* connection, which is exactly the watcher's
    relationship to the ledger writer."""
    path = str(tmp_path / "ledger.db")
    writer = apiwatcher.apsw.Connection(path)
    writer.execute("CREATE TABLE t (x)")
    reader = apiwatcher.apsw.Connection(path)
    reader.setrowtrace(apiwatcher.database.rowtracer)

    before = apiwatcher.get_ledger_data_version(reader)
    reader.execute("SELECT * FROM t").fetchall()
    assert apiwatcher.get_ledger_data_version(reader) == before

    writer.execute("INSERT INTO t VALUES (1)")
    after = apiwatcher.get_ledger_data_version(reader)

    reader.close()
    writer.close()
    assert after != before


# --------------------------------------------------------------------------------------------
# ReorgWatch: when the check actually runs
# --------------------------------------------------------------------------------------------


@pytest.fixture
def watch(monkeypatch):
    """A `ReorgWatch` over a fake ledger, with counters for both sides."""
    state = {"data_version": 1, "checks": 0, "reorg": False, "now": 1000.0}
    monkeypatch.setattr(apiwatcher, "get_ledger_data_version", lambda _db: state["data_version"])
    monkeypatch.setattr(apiwatcher.time, "monotonic", lambda: state["now"])

    def check_reorg(_ledger_db, _state_db):
        state["checks"] += 1
        return state["reorg"]

    monkeypatch.setattr(apiwatcher, "check_reorg", check_reorg)
    return apiwatcher.ReorgWatch(MagicMock(), MagicMock()), state


def test_reorg_watch_skips_the_check_while_the_ledger_has_not_moved(watch):
    watcher, state = watch

    for _ in range(50):
        assert watcher.check({"block_index": 7}) is False

    assert state["checks"] == 1


def test_reorg_watch_rechecks_when_the_ledger_commits_inside_the_block(watch):
    """A rollback landing mid-block leaves the block index unchanged, so the
    ledger's data version is the only thing that reveals it."""
    watcher, state = watch
    watcher.check({"block_index": 7})

    state["data_version"] += 1
    watcher.check({"block_index": 7})

    assert state["checks"] == 2


def test_reorg_watch_rechecks_on_each_new_block(watch):
    watcher, state = watch
    watcher.check({"block_index": 7})
    watcher.check({"block_index": 8})

    assert state["checks"] == 2


def test_reorg_watch_still_checks_every_five_seconds_at_rest(watch):
    """The counter is the fast path, not the whole guarantee."""
    watcher, state = watch
    watcher.check()
    state["now"] += apiwatcher.ReorgWatch.FORCE_INTERVAL - 0.1
    watcher.check()
    assert state["checks"] == 1

    state["now"] += 0.2
    watcher.check()

    assert state["checks"] == 2


def test_reorg_watch_reports_a_rollback_without_spinning_on_it(watch):
    """The caller answers a rollback by re-selecting the event it was holding
    and coming straight back. The check has already run against this ledger
    revision, so running it again for the replacement would be a hot loop of
    index lookups for as long as the ledger stays in that state."""
    watcher, state = watch
    state["reorg"] = True

    assert watcher.check({"block_index": 7}) is True
    assert watcher.check({"block_index": 7}) is False
    assert state["checks"] == 1

    # A replacement event from another block is a new lineage, and is checked.
    assert watcher.check({"block_index": 8}) is True
    assert state["checks"] == 2


# --------------------------------------------------------------------------------------------
# The watcher loops: a rollback invalidates the event in hand
# --------------------------------------------------------------------------------------------


class FakeWatch:
    """A `ReorgWatch` that reports a reorganization on its nth call."""

    def __init__(self, reorg_on=()):
        self.reorg_on = set(reorg_on)
        self.calls = []

    def __call__(self, *_args):  # stands in for the class itself
        return self

    def check(self, next_event=None):
        self.calls.append(next_event["block_index"] if next_event else None)
        return len(self.calls) in self.reorg_on


def test_catch_up_discards_the_event_it_held_when_a_reorg_rolls_back(monkeypatch):
    """The event was selected against the branch the rollback has just undone;
    parsing it anyway appends new-branch state on top of state that no longer
    exists."""
    events = [{"block_index": 5, "message_index": 1}, {"block_index": 6, "message_index": 2}]
    remaining = list(events)
    parsed = []
    # calls: 1 = the pre-loop check, 2 = the first event -> reorg
    fake = FakeWatch(reorg_on={2})
    monkeypatch.setattr(apiwatcher, "ReorgWatch", fake)
    monkeypatch.setattr(apiwatcher, "get_event_to_parse_count", lambda *a: len(events))
    monkeypatch.setattr(
        apiwatcher, "get_next_event_to_parse", lambda *a: remaining.pop(0) if remaining else None
    )
    monkeypatch.setattr(
        apiwatcher, "parse_event", lambda _db, event, ledger_db=None: parsed.append(event)
    )

    apiwatcher.catch_up(MagicMock(), MagicMock())

    assert parsed == [events[1]]
    assert fake.calls == [None, 5, 6]


def test_follow_checks_for_a_reorg_before_every_event(monkeypatch):
    watcher = apiwatcher.APIWatcher.__new__(apiwatcher.APIWatcher)
    watcher.stop_event = threading.Event()
    watcher.state_db = MagicMock()
    watcher.ledger_db = MagicMock()
    events = [{"block_index": 5}, {"block_index": 6}]
    remaining = list(events)
    parsed = []
    fake = FakeWatch()
    monkeypatch.setattr(apiwatcher, "ReorgWatch", fake)

    def next_event(*_args):
        if remaining:
            return remaining.pop(0)
        watcher.stop_event.set()
        return None

    monkeypatch.setattr(apiwatcher, "get_next_event_to_parse", next_event)
    monkeypatch.setattr(
        apiwatcher, "parse_event", lambda _db, event, ledger_db=None: parsed.append(event)
    )

    watcher.follow()

    assert parsed == events
    # The third call is the idle poll of the iteration that found no event left.
    assert fake.calls[:2] == [5, 6]


def test_follow_polls_for_a_reorg_while_idle(monkeypatch):
    """At the tip there is no event to key the check on, and a reorganization is
    the only thing that can change what to do next."""
    watcher = apiwatcher.APIWatcher.__new__(apiwatcher.APIWatcher)
    watcher.stop_event = threading.Event()
    watcher.state_db = MagicMock()
    watcher.ledger_db = MagicMock()
    fake = FakeWatch()
    monkeypatch.setattr(apiwatcher, "ReorgWatch", fake)
    monkeypatch.setattr(apiwatcher, "get_next_event_to_parse", lambda *a: None)

    stopper = threading.Timer(0.3, watcher.stop_event.set)
    stopper.start()
    watcher.follow()
    stopper.cancel()

    assert fake.calls and set(fake.calls) == {None}


# --------------------------------------------------------------------------------------------
# A watcher that stops on an error must say so
# --------------------------------------------------------------------------------------------


def _bare_watcher():
    watcher = apiwatcher.APIWatcher.__new__(apiwatcher.APIWatcher)
    threading.Thread.__init__(watcher, name="Watcher")
    watcher.stop_event = threading.Event()
    watcher.db_lock = threading.Lock()
    watcher.state_db = MagicMock()
    watcher.ledger_db = MagicMock()
    watcher.current_state_thread = None
    return watcher


def test_a_failed_watcher_is_logged_and_flagged(monkeypatch):
    """Re-raising handed the traceback to `threading.excepthook`, which writes to
    stderr and not to the log: the State DB stopped advancing and the API went on
    serving a frozen snapshot with nothing to show for it."""
    watcher = _bare_watcher()
    monkeypatch.setattr(
        apiwatcher, "catch_up", MagicMock(side_effect=ValueError("state db is a pumpkin"))
    )
    logger = MagicMock()
    monkeypatch.setattr(apiwatcher, "logger", logger)

    watcher.run()  # must not propagate: nothing above it would handle it

    assert apiwatcher.watcher_has_failed() is True
    # With the traceback, or the log says the watcher stopped without saying why.
    assert logger.critical.call_args.kwargs == {"exc_info": True}
    watcher.state_db.close.assert_called_once_with()
    watcher.ledger_db.close.assert_called_once_with()


def test_an_unexpected_interrupt_is_flagged_too(monkeypatch):
    watcher = _bare_watcher()
    monkeypatch.setattr(
        apiwatcher, "catch_up", MagicMock(side_effect=apiwatcher.apsw.InterruptError("interrupted"))
    )

    watcher.run()

    assert apiwatcher.watcher_has_failed() is True


def test_an_interrupt_during_shutdown_is_not_a_failure(monkeypatch):
    watcher = _bare_watcher()

    def interrupted_catch_up(*_args):
        watcher.stop_event.set()
        raise apiwatcher.apsw.InterruptError("interrupted")

    monkeypatch.setattr(apiwatcher, "catch_up", interrupted_catch_up)

    watcher.run()

    assert apiwatcher.watcher_has_failed() is False
