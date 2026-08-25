import os
import threading
from unittest.mock import MagicMock

import apsw
import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.api import dbbuilder
from counterpartycore.lib.utils import database, hashcodec
from counterpartycore.lib.utils.database import (
    ADDRESS_INDEX_COLUMN_NAMES,
    ASSET_INDEX_COLUMN_NAMES,
)

# =============================================================================
# Tests for migration rollback functions
# =============================================================================


def table_exists(db, table_name):
    """Check if a table exists in the database."""
    result = db.execute(
        "SELECT COUNT(*) AS count FROM sqlite_master WHERE type='table' AND name=?",
        (table_name,),
    ).fetchone()
    return result["count"] > 0


def view_exists(db, view_name):
    """Check if a view exists in the database."""
    result = db.execute(
        "SELECT COUNT(*) AS count FROM sqlite_master WHERE type='view' AND name=?",
        (view_name,),
    ).fetchone()
    return result["count"] > 0


def index_exists(db, index_name):
    """Check if an index exists in the database."""
    result = db.execute(
        "SELECT COUNT(*) AS count FROM sqlite_master WHERE type='index' AND name=?",
        (index_name,),
    ).fetchone()
    return result["count"] > 0


def column_exists(db, table_name, column_name):
    """Check if a column exists in a table."""
    columns = db.execute(f"PRAGMA table_info({table_name})").fetchall()
    return any(col["name"] == column_name for col in columns)


def _create_marker_database(path, value):
    db = apsw.Connection(str(path))
    db.execute("CREATE TABLE marker (value TEXT)")
    db.execute("INSERT INTO marker VALUES (?)", (value,))
    db.close()


def _read_marker_database(path):
    db = apsw.Connection(str(path), flags=apsw.SQLITE_OPEN_READONLY)
    try:
        return db.execute("SELECT value FROM marker").fetchone()[0]
    finally:
        db.close()


def test_staged_state_db_rebuild_does_not_touch_live_database(tmp_path, monkeypatch, ledger_db):
    live_db = tmp_path / "state.db"
    _create_marker_database(live_db, "live")
    monkeypatch.setattr(config, "STATE_DATABASE", str(live_db))
    observed = {}

    def fake_apply(staged_path, _migration_dir, **_kwargs):
        observed["ledger_source"] = config.state_db_ledger_source_database()
        assert os.path.exists(observed["ledger_source"])
        assert not os.path.exists(f"{observed['ledger_source']}-wal")
        _create_marker_database(staged_path, "rebuilt")

    monkeypatch.setattr(database, "apply_outstanding_migration", fake_apply)
    monkeypatch.setattr(
        dbbuilder,
        "_replacement_manifest",
        lambda staged_path, _ledger_path, stop_event=None: {
            "staged_size": os.path.getsize(staged_path)
        },
    )

    dbbuilder.stage_state_db_rebuild()

    assert _read_marker_database(live_db) == "live"
    assert _read_marker_database(dbbuilder.staged_state_db_path()) == "rebuilt"
    assert observed["ledger_source"].endswith(".ledger-snapshot")
    assert not os.path.exists(observed["ledger_source"])
    assert os.path.exists(dbbuilder.staged_state_db_ready_path())


def test_activate_staged_state_db_retains_previous_database(tmp_path, monkeypatch):
    live_db = tmp_path / "state.db"
    staged_db = tmp_path / "state.db.rebuild"
    ready_path = tmp_path / "state.db.rebuild.ready"
    _create_marker_database(live_db, "live")
    _create_marker_database(staged_db, "rebuilt")
    monkeypatch.setattr(config, "STATE_DATABASE", str(live_db))
    manifest = {
        "version": config.VERSION_STRING,
        "migration_digest": "digest",
        "staged_size": os.path.getsize(staged_db),
    }
    ready_path.write_text("{}\n")
    monkeypatch.setattr(dbbuilder, "_read_ready_manifest", lambda _path: manifest)
    monkeypatch.setattr(dbbuilder, "_manifest_is_current", lambda _manifest, _path, **_kwargs: True)
    fsync_directory = MagicMock()
    monkeypatch.setattr(dbbuilder, "_fsync_directory", fsync_directory)

    assert dbbuilder.activate_staged_state_db() is True

    assert _read_marker_database(live_db) == "rebuilt"
    assert _read_marker_database(dbbuilder.previous_state_db_path()) == "live"
    assert not ready_path.exists()
    assert fsync_directory.call_count == 3


@pytest.mark.parametrize("failing_barrier", [1, 2, 3])
def test_activation_is_recoverable_at_every_directory_barrier(
    tmp_path, monkeypatch, failing_barrier
):
    live_db = tmp_path / "state.db"
    staged_db = tmp_path / "state.db.rebuild"
    ready_path = tmp_path / "state.db.rebuild.ready"
    _create_marker_database(live_db, "live")
    _create_marker_database(staged_db, "rebuilt")
    ready_path.write_text("{}\n")
    monkeypatch.setattr(config, "STATE_DATABASE", str(live_db))
    monkeypatch.setattr(dbbuilder, "_read_ready_manifest", lambda _path: {})
    monkeypatch.setattr(dbbuilder, "_manifest_is_current", lambda _manifest, _path, **_kwargs: True)
    barrier_calls = 0

    def fail_selected_barrier(_path):
        nonlocal barrier_calls
        barrier_calls += 1
        if barrier_calls == failing_barrier:
            raise OSError("simulated power-loss boundary")

    monkeypatch.setattr(dbbuilder, "_fsync_directory", fail_selected_barrier)
    with pytest.raises(OSError, match="power-loss boundary"):
        dbbuilder.activate_staged_state_db()

    monkeypatch.setattr(dbbuilder, "_fsync_directory", lambda _path: None)
    dbbuilder.activate_staged_state_db()

    assert _read_marker_database(live_db) == "rebuilt"
    assert _read_marker_database(dbbuilder.previous_state_db_path()) == "live"
    assert not ready_path.exists()


def test_missing_staged_database_requires_live_manifest_match(tmp_path, monkeypatch):
    live_db = tmp_path / "state.db"
    ready_path = tmp_path / "state.db.rebuild.ready"
    _create_marker_database(live_db, "rebuilt")
    ready_path.write_text("{}\n")
    monkeypatch.setattr(config, "STATE_DATABASE", str(live_db))
    monkeypatch.setattr(dbbuilder, "_read_ready_manifest", lambda _path: {})
    monkeypatch.setattr(
        dbbuilder, "_manifest_is_current", lambda _manifest, _path, **_kwargs: False
    )

    with pytest.raises(exceptions.DatabaseError, match="does not match its manifest"):
        dbbuilder.activate_staged_state_db()

    assert ready_path.exists()
    assert _read_marker_database(live_db) == "rebuilt"


def test_incomplete_staged_state_db_is_never_activated(tmp_path, monkeypatch):
    live_db = tmp_path / "state.db"
    staged_db = tmp_path / "state.db.rebuild"
    _create_marker_database(live_db, "live")
    _create_marker_database(staged_db, "partial")
    ledger_snapshot = tmp_path / "state.db.rebuild.ledger-snapshot"
    _create_marker_database(ledger_snapshot, "partial-ledger")
    (tmp_path / "state.db.rebuild-journal").write_text("journal")
    (tmp_path / "state.db.rebuild.ready.tmp").write_text("partial marker")
    monkeypatch.setattr(config, "STATE_DATABASE", str(live_db))

    assert dbbuilder.activate_staged_state_db() is False

    assert _read_marker_database(live_db) == "live"
    assert not staged_db.exists()
    assert not ledger_snapshot.exists()
    assert not (tmp_path / "state.db.rebuild-journal").exists()
    assert not (tmp_path / "state.db.rebuild.ready.tmp").exists()


def test_failed_space_preflight_retains_previous_recovery_copy(tmp_path, monkeypatch):
    live_db = tmp_path / "state.db"
    previous_db = tmp_path / "state.db.previous"
    _create_marker_database(live_db, "live")
    _create_marker_database(previous_db, "previous")
    monkeypatch.setattr(config, "STATE_DATABASE", str(live_db))

    def fail_preflight():
        assert previous_db.exists()
        raise exceptions.DatabaseError("insufficient space")

    monkeypatch.setattr(dbbuilder, "_ensure_staged_rebuild_space", fail_preflight)

    with pytest.raises(exceptions.DatabaseError, match="insufficient space"):
        dbbuilder.stage_state_db_rebuild()
    assert previous_db.exists()


def test_rebuild_releases_previous_only_when_preflight_requires_it(tmp_path, monkeypatch):
    live_db = tmp_path / "state.db"
    previous_db = tmp_path / "state.db.previous"
    _create_marker_database(live_db, "live")
    _create_marker_database(previous_db, "previous")
    monkeypatch.setattr(config, "STATE_DATABASE", str(live_db))
    monkeypatch.setattr(dbbuilder, "_ensure_staged_rebuild_space", lambda: True)

    def stop_before_backup(_path, stop_event=None):
        assert not previous_db.exists()
        raise exceptions.StateDBRebuildCancelled("stop after reclaim assertion")

    monkeypatch.setattr(dbbuilder, "_backup_ledger_database", stop_before_backup)

    with pytest.raises(exceptions.StateDBRebuildCancelled):
        dbbuilder.stage_state_db_rebuild()


def test_stale_manifest_never_replaces_live_database(tmp_path, monkeypatch):
    live_db = tmp_path / "state.db"
    staged_db = tmp_path / "state.db.rebuild"
    ready_path = tmp_path / "state.db.rebuild.ready"
    _create_marker_database(live_db, "live")
    _create_marker_database(staged_db, "rebuilt")
    ready_path.write_text("{}\n")
    monkeypatch.setattr(config, "STATE_DATABASE", str(live_db))
    monkeypatch.setattr(
        dbbuilder,
        "_read_ready_manifest",
        lambda _path: {
            "version": config.VERSION_STRING,
            "migration_digest": "digest",
            "staged_size": os.path.getsize(staged_db),
        },
    )
    monkeypatch.setattr(
        dbbuilder, "_manifest_is_current", lambda _manifest, _path, **_kwargs: False
    )

    assert dbbuilder.activate_staged_state_db() is False
    assert _read_marker_database(live_db) == "live"
    assert not staged_db.exists()
    assert not ready_path.exists()


def test_manifest_lineage_rejects_a_replaced_ledger_branch(tmp_path, monkeypatch):
    ledger_path = tmp_path / "ledger.db"
    ledger = apsw.Connection(str(ledger_path))
    ledger.execute(
        "CREATE TABLE messages (message_index INTEGER PRIMARY KEY, event_hash TEXT, "
        "block_index INTEGER, event TEXT)"
    )
    ledger.executemany(
        "INSERT INTO messages VALUES (?, ?, ?, ?)",
        [
            (1, "old-block", 100, "BLOCK_PARSED"),
            (2, "old-tip", 100, "CREDIT"),
        ],
    )
    ledger.close()
    monkeypatch.setattr(config, "DATABASE", str(ledger_path))
    manifest = {
        "source_event_index": 2,
        "source_event_hash": "old-tip",
        "source_event_block_index": 100,
        "source_block_event_index": 1,
        "source_block_event_hash": "old-block",
        "source_block_index": 100,
    }

    assert dbbuilder._manifest_matches_live_ledger(manifest) is True

    ledger = apsw.Connection(str(ledger_path))
    ledger.execute("UPDATE messages SET event_hash = 'new-block' WHERE message_index = 1")
    ledger.execute("UPDATE messages SET event_hash = 'new-tip' WHERE message_index = 2")
    ledger.close()

    assert dbbuilder._manifest_matches_live_ledger(manifest) is False


def test_manifest_rejects_a_different_builder_commit(monkeypatch):
    manifest = {
        "version": config.VERSION_STRING,
        "builder_commit": "old-image",
        "migration_digest": "digest",
    }
    monkeypatch.setattr(config, "CURRENT_COMMIT", "new-image")
    monkeypatch.setattr(dbbuilder, "_migration_digest", lambda: "digest")
    monkeypatch.setattr(dbbuilder, "_state_db_matches_manifest", lambda _path, _manifest: True)
    monkeypatch.setattr(dbbuilder, "_manifest_matches_live_ledger", lambda _manifest: True)

    assert dbbuilder._manifest_is_current(manifest, "state.db") is False


def test_latest_ledger_block_manifest_query_avoids_temp_sort():
    ledger_db = apsw.Connection(":memory:")
    ledger_db.set_row_trace(database.rowtracer)
    ledger_db.execute(
        "CREATE TABLE messages (message_index INTEGER PRIMARY KEY, event_hash TEXT, "
        "block_index INTEGER, event TEXT)"
    )
    ledger_db.execute("CREATE INDEX messages_event_idx ON messages (event)")
    plan = ledger_db.execute(
        f"EXPLAIN QUERY PLAN {dbbuilder.LAST_LEDGER_BLOCK_EVENT_SQL}"
    ).fetchall()
    ledger_db.close()

    assert not any("USE TEMP B-TREE" in row["detail"] for row in plan)


def test_ledger_snapshot_backup_is_cancellable(tmp_path, monkeypatch):
    ledger_path = tmp_path / "ledger.db"
    ledger = apsw.Connection(str(ledger_path))
    ledger.execute("CREATE TABLE data (value TEXT)")
    ledger.executemany("INSERT INTO data VALUES (?)", [("x" * 1024,)] * 1_000)
    ledger.close()
    monkeypatch.setattr(config, "DATABASE", str(ledger_path))
    stop_event = threading.Event()
    stop_event.set()

    with pytest.raises(exceptions.StateDBRebuildCancelled):
        dbbuilder._backup_ledger_database(
            str(tmp_path / "snapshot.db"),
            stop_event=stop_event,
        )


def test_staged_rebuild_from_ledger_is_complete_and_activatable(tmp_path, monkeypatch, ledger_db):
    live_db = tmp_path / "state.db"
    _create_marker_database(live_db, "live")
    monkeypatch.setattr(config, "STATE_DATABASE", str(live_db))

    dbbuilder.stage_state_db_rebuild()
    staged_db = database.get_db_connection(
        dbbuilder.staged_state_db_path(), read_only=True, check_wal=False
    )
    try:
        staged_events = staged_db.execute("SELECT COUNT(*) AS count FROM parsed_events").fetchone()[
            "count"
        ]
        ledger_events = ledger_db.execute("SELECT COUNT(*) AS count FROM messages").fetchone()[
            "count"
        ]
        assert staged_events == ledger_events
        assert table_exists(staged_db, "assets_info")
        assert table_exists(staged_db, "balances")
        assert view_exists(staged_db, "orders_info")
    finally:
        staged_db.close()

    assert dbbuilder.activate_staged_state_db() is True
    activated_db = database.get_db_connection(str(live_db), read_only=True, check_wal=False)
    try:
        assert table_exists(activated_db, "parsed_events")
        assert activated_db.execute("PRAGMA quick_check(1)").fetchone()["quick_check"] == "ok"
    finally:
        activated_db.close()


def test_fallback_rollback_rebuilds_address_events_to_ledger_tip(state_db, ledger_db):
    expected_count = state_db.execute("SELECT COUNT(*) AS count FROM address_events").fetchone()[
        "count"
    ]
    first_address_block = state_db.execute(
        "SELECT MIN(block_index) AS block_index FROM address_events"
    ).fetchone()["block_index"]
    assert expected_count > 0
    assert first_address_block is not None

    dbbuilder.rollback_state_db(state_db, block_index=first_address_block)

    assert (
        state_db.execute("SELECT COUNT(*) AS count FROM address_events").fetchone()["count"]
        == expected_count
    )
    assert (
        state_db.execute("SELECT COUNT(*) AS count FROM parsed_events").fetchone()["count"]
        == ledger_db.execute("SELECT COUNT(*) AS count FROM messages").fetchone()["count"]
    )


def test_migration_0001_rollback(state_db, ledger_db):
    """Test rollback of 0001.create_and_populate_address_events migration."""
    # Verify table exists before rollback
    assert table_exists(state_db, "address_events")

    # Rollback
    dbbuilder.rollback_migration(state_db, "0001.create_and_populate_address_events")

    # Verify table no longer exists
    assert not table_exists(state_db, "address_events")

    # Re-apply migration (ledger_db fixture ensures config.DATABASE is available)
    dbbuilder.apply_migration(state_db, "0001.create_and_populate_address_events")
    assert table_exists(state_db, "address_events")


def test_migration_0002_rollback(state_db, ledger_db):
    """Test rollback of 0002.create_and_populate_parsed_events migration."""
    assert table_exists(state_db, "parsed_events")

    dbbuilder.rollback_migration(state_db, "0002.create_and_populate_parsed_events")

    assert not table_exists(state_db, "parsed_events")

    # Re-apply migration (ledger_db fixture ensures config.DATABASE is available)
    dbbuilder.apply_migration(state_db, "0002.create_and_populate_parsed_events")
    assert table_exists(state_db, "parsed_events")


def test_migration_0003_rollback(state_db, ledger_db):
    """Test rollback of 0003.create_and_populate_all_expirations migration."""
    assert table_exists(state_db, "all_expirations")

    dbbuilder.rollback_migration(state_db, "0003.create_and_populate_all_expirations")

    assert not table_exists(state_db, "all_expirations")

    # Re-apply migration (ledger_db fixture ensures config.DATABASE is available)
    dbbuilder.apply_migration(state_db, "0003.create_and_populate_all_expirations")
    assert table_exists(state_db, "all_expirations")


def test_migration_0004_rollback(state_db, ledger_db):
    """Test rollback of 0004.create_and_populate_assets_info migration."""
    assert table_exists(state_db, "assets_info")

    dbbuilder.rollback_migration(state_db, "0004.create_and_populate_assets_info")

    assert not table_exists(state_db, "assets_info")

    # Re-apply migration (ledger_db fixture ensures config.DATABASE is available)
    dbbuilder.apply_migration(state_db, "0004.create_and_populate_assets_info")
    assert table_exists(state_db, "assets_info")


def test_migration_0005_rollback(state_db, ledger_db):
    """Test rollback of 0005.create_and_populate_events_count migration."""
    assert table_exists(state_db, "events_count")

    dbbuilder.rollback_migration(state_db, "0005.create_and_populate_events_count")

    assert not table_exists(state_db, "events_count")

    # Re-apply migration (ledger_db fixture ensures config.DATABASE is available)
    dbbuilder.apply_migration(state_db, "0005.create_and_populate_events_count")
    assert table_exists(state_db, "events_count")


def test_migration_0006_rollback(state_db, ledger_db):
    """Test rollback of 0006.create_and_populate_consolidated_tables migration."""
    consolidated_tables = [
        "fairminters",
        "balances",
        "addresses",
        "dispensers",
        "bet_matches",
        "bets",
        "order_matches",
        "orders",
        "rps",
        "rps_matches",
    ]

    # Verify all tables exist before rollback
    for table in consolidated_tables:
        assert table_exists(state_db, table), f"Table {table} should exist before rollback"

    dbbuilder.rollback_migration(state_db, "0006.create_and_populate_consolidated_tables")

    # Verify all tables are removed
    for table in consolidated_tables:
        assert not table_exists(state_db, table), f"Table {table} should not exist after rollback"

    # Re-apply migration (ledger_db fixture ensures config.DATABASE is available)
    dbbuilder.apply_migration(state_db, "0006.create_and_populate_consolidated_tables")
    for table in consolidated_tables:
        assert table_exists(state_db, table), f"Table {table} should exist after re-apply"


def test_migration_0007_rollback(state_db, ledger_db):
    """Test rollback of 0007.create_views migration."""
    assert view_exists(state_db, "asset_holders")
    assert view_exists(state_db, "xcp_holders")

    dbbuilder.rollback_migration(state_db, "0007.create_views")

    assert not view_exists(state_db, "asset_holders")
    assert not view_exists(state_db, "xcp_holders")

    dbbuilder.apply_migration(state_db, "0007.create_views")
    assert view_exists(state_db, "asset_holders")
    assert view_exists(state_db, "xcp_holders")


def test_migration_0008_rollback(state_db, ledger_db):
    """Test rollback of 0008.create_config_table migration."""
    assert table_exists(state_db, "config")

    dbbuilder.rollback_migration(state_db, "0008.create_config_table")

    assert not table_exists(state_db, "config")

    dbbuilder.apply_migration(state_db, "0008.create_config_table")
    assert table_exists(state_db, "config")


def test_migration_0009_rollback(state_db, ledger_db):
    """Test rollback of 0009.create_and_populate_transaction_types_count migration."""
    assert table_exists(state_db, "transaction_types_count")

    dbbuilder.rollback_migration(state_db, "0009.create_and_populate_transaction_types_count")

    assert not table_exists(state_db, "transaction_types_count")

    # Re-apply migration (ledger_db fixture ensures config.DATABASE is available)
    dbbuilder.apply_migration(state_db, "0009.create_and_populate_transaction_types_count")
    assert table_exists(state_db, "transaction_types_count")


def test_migration_0010_rollback(state_db):
    """Test rollback of 0010.fix_bet_match_resolution_event_name migration.

    This migration's rollback does nothing (pass), so we just verify it doesn't raise.
    """
    # Just verify rollback doesn't raise an exception
    dbbuilder.rollback_migration(state_db, "0010.fix_bet_match_resolution_event_name")
    # Re-apply to restore state (this migration doesn't need ledger_db)
    dbbuilder.apply_migration(state_db, "0010.fix_bet_match_resolution_event_name")


def test_migration_0011_rollback(state_db):
    """Test rollback of 0011.create_orders_views migration."""
    assert view_exists(state_db, "orders_info")

    dbbuilder.rollback_migration(state_db, "0011.create_orders_views")

    assert not view_exists(state_db, "orders_info")

    # This migration doesn't need ledger_db
    dbbuilder.apply_migration(state_db, "0011.create_orders_views")
    assert view_exists(state_db, "orders_info")


def test_migration_0012_rollback(state_db, ledger_db):
    """Test rollback of 0012.add_event_column_to_address_events migration.

    This migration adds the 'event' column to address_events.
    The rollback should remove the 'event' column.
    """
    # Verify 'event' column exists before rollback
    assert column_exists(state_db, "address_events", "event")

    dbbuilder.rollback_migration(state_db, "0012.add_event_column_to_address_events")

    # Verify 'event' column no longer exists after rollback
    assert not column_exists(state_db, "address_events", "event")

    # Re-apply migration (ledger_db fixture ensures config.DATABASE is available)
    dbbuilder.apply_migration(state_db, "0012.add_event_column_to_address_events")
    assert column_exists(state_db, "address_events", "event")


def test_migration_0013_rollback(state_db):
    """Test rollback of 0013.add_performance_indexes migration."""
    performance_indexes = [
        "assets_info_asset_longname_nocase_idx",
        "balances_address_idx",
        "balances_utxo_address_idx",
        "dispensers_source_idx",
    ]

    # Verify all indexes exist before rollback
    for idx in performance_indexes:
        assert index_exists(state_db, idx), f"Index {idx} should exist before rollback"

    dbbuilder.rollback_migration(state_db, "0013.add_performance_indexes")

    # Verify all indexes are removed
    for idx in performance_indexes:
        assert not index_exists(state_db, idx), f"Index {idx} should not exist after rollback"

    # This migration doesn't need ledger_db
    dbbuilder.apply_migration(state_db, "0013.add_performance_indexes")
    for idx in performance_indexes:
        assert index_exists(state_db, idx), f"Index {idx} should exist after re-apply"


def test_migration_0015_rollback(state_db):
    """Test rollback of 0015.add_dispenser_origin_index migration."""
    assert index_exists(state_db, "dispensers_origin_idx")

    dbbuilder.rollback_migration(state_db, "0015.add_dispenser_origin_index")

    assert not index_exists(state_db, "dispensers_origin_idx")

    dbbuilder.apply_migration(state_db, "0015.add_dispenser_origin_index")

    assert index_exists(state_db, "dispensers_origin_idx")


# =============================================================================
# Tests for consolidated tables
# =============================================================================


def test_consolidated_balances(state_db, ledger_db, apiv2_client):
    # balances
    sql_ledger = (
        "SELECT count(*) AS count FROM (SELECT *, MAX(rowid) FROM balances GROUP BY address, asset)"
    )
    sql_api = "SELECT count(*) AS count FROM balances"
    assert (
        ledger_db.execute(sql_ledger).fetchone()["count"]
        == state_db.execute(sql_api).fetchone()["count"]
    )

    ledger_balances = ledger_db.execute(
        "SELECT *, MAX(rowid) FROM balances GROUP BY address, asset"
    ).fetchall()
    api_balances = state_db.execute("SELECT * FROM balances").fetchall()
    assert len(ledger_balances) == len(api_balances)

    # The Ledger DB stores the compact ``asset_index`` (so SQL ``ORDER BY asset``
    # sorts by index) while the State DB stores asset names; both decode to the
    # same names on read, so align the two lists by (name, address, utxo).
    def _balance_key(b):
        return (b["asset"] or "", b["address"] or "", b["utxo"] or "")

    ledger_balances = sorted(ledger_balances, key=_balance_key)
    api_balances = sorted(api_balances, key=_balance_key)
    for ledger_balance, api_balance in zip(ledger_balances, api_balances, strict=True):
        assert ledger_balance["address"] == api_balance["address"]
        assert ledger_balance["asset"] == api_balance["asset"]
        assert ledger_balance["quantity"] == api_balance["quantity"]
        if ledger_balance["quantity"] > 0 and ledger_balance["address"]:
            api_result = apiv2_client.get(
                f"/v2/addresses/{ledger_balance['address']}/balances/{ledger_balance['asset']}"
            ).json
            found = False
            for balance in api_result["result"]:
                if balance["quantity"] == ledger_balance["quantity"]:
                    found = True
                    break
            assert found


def test_consolidated_orders(state_db, ledger_db, apiv2_client):
    sql_ledger = "SELECT count(*) AS count FROM (SELECT *, MAX(rowid) FROM orders GROUP BY tx_hash)"
    sql_api = "SELECT count(*) AS count FROM orders"
    assert (
        ledger_db.execute(sql_ledger).fetchone()["count"]
        == state_db.execute(sql_api).fetchone()["count"]
    )

    ledger_orders = ledger_db.execute(
        "SELECT *, MAX(rowid) FROM orders GROUP BY tx_hash ORDER BY tx_hash"
    ).fetchall()
    for ledger_order in ledger_orders:
        api_order = state_db.execute(
            "SELECT * FROM orders WHERE tx_hash = ?",
            (hashcodec.hash_to_db(ledger_order["tx_hash"]),),
        ).fetchone()
        assert ledger_order["status"] == api_order["status"]
        assert ledger_order["give_asset"] == api_order["give_asset"]
        assert ledger_order["get_asset"] == api_order["get_asset"]
        assert ledger_order["get_remaining"] == api_order["get_remaining"]
        assert ledger_order["give_remaining"] == api_order["give_remaining"]
        assert ledger_order["source"] == api_order["source"]
        api_result = apiv2_client.get(f"/v2/orders/{ledger_order['tx_hash']}").json
        assert api_result["result"]["status"] == ledger_order["status"]
        assert api_result["result"]["give_asset"] == ledger_order["give_asset"]
        assert api_result["result"]["get_asset"] == ledger_order["get_asset"]
        assert api_result["result"]["get_remaining"] == ledger_order["get_remaining"]
        assert api_result["result"]["give_remaining"] == ledger_order["give_remaining"]
        assert api_result["result"]["source"] == ledger_order["source"]


def test_consolidated_order_matches(state_db, ledger_db, apiv2_client):
    # The composite TEXT ``id`` was dropped from match tables; reconstruct it
    # from the kept ``tx0_hash``/``tx1_hash`` BLOB columns and key by the
    # ``(tx0_index, tx1_index)`` pair.
    match_id_sql = "hex_lower(tx0_hash) || '_' || hex_lower(tx1_hash)"
    sql_ledger = (
        "SELECT count(*) AS count FROM "
        "(SELECT *, MAX(rowid) FROM order_matches GROUP BY tx0_index, tx1_index)"
    )
    sql_api = "SELECT count(*) AS count FROM order_matches"
    assert (
        ledger_db.execute(sql_ledger).fetchone()["count"]
        == state_db.execute(sql_api).fetchone()["count"]
    )

    ledger_order_matches = ledger_db.execute(
        f"SELECT *, {match_id_sql} AS id, MAX(rowid) FROM order_matches "  # noqa: S608
        "GROUP BY tx0_index, tx1_index ORDER BY id"
    ).fetchall()
    api_order_matches = state_db.execute(
        f"SELECT *, {match_id_sql} AS id FROM order_matches ORDER BY id"  # noqa: S608
    ).fetchall()
    assert len(ledger_order_matches) == len(api_order_matches)
    for ledger_order_match, api_order_match in zip(
        ledger_order_matches, api_order_matches, strict=True
    ):
        assert ledger_order_match["id"] == api_order_match["id"]
        assert ledger_order_match["status"] == api_order_match["status"]
        assert ledger_order_match["tx0_hash"] == api_order_match["tx0_hash"]
        assert ledger_order_match["tx1_hash"] == api_order_match["tx1_hash"]
        api_result = apiv2_client.get(f"/v2/orders/{api_order_match['tx0_hash']}/matches").json
        found = False
        for order_match in api_result["result"]:
            if order_match["id"] == ledger_order_match["id"]:
                assert ledger_order_match["status"] == order_match["status"]
                assert ledger_order_match["tx0_hash"] == order_match["tx0_hash"]
                assert ledger_order_match["tx1_hash"] == order_match["tx1_hash"]
                found = True
                break
        assert found


def test_consolidated_assets(state_db, ledger_db, apiv2_client):
    sql_ledger = "SELECT count(*) AS count FROM assets WHERE asset_name NOT IN ('XCP', 'BTC')"
    sql_api = "SELECT count(*) AS count FROM assets_info WHERE asset NOT IN ('XCP', 'BTC')"
    assert (
        ledger_db.execute(sql_ledger).fetchone()["count"]
        == state_db.execute(sql_api).fetchone()["count"]
    )

    ledger_assets_info = ledger_db.execute(
        "SELECT asset_name FROM assets WHERE asset_name NOT IN ('XCP', 'BTC') ORDER BY asset_name"
    ).fetchall()
    api_assets_info = state_db.execute(
        "SELECT asset FROM assets_info WHERE asset NOT IN ('XCP', 'BTC') ORDER BY asset"
    ).fetchall()
    assert len(ledger_assets_info) == len(api_assets_info)
    for ledger_asset_info, api_asset_info in zip(ledger_assets_info, api_assets_info, strict=True):
        assert ledger_asset_info["asset_name"] == api_asset_info["asset"]
        api_result = apiv2_client.get(f"/v2/assets/{api_asset_info['asset']}").json
        assert api_result["result"]["asset"] == api_asset_info["asset"]


def test_migration_0004_latest_issuance_columns(state_db, ledger_db):
    """Regression: migration 0004 used to select description/divisible/
    mime_type/owner via bare-column SELECT alongside MIN/MAX aggregates.
    SQLite picked bare columns "from one of" the min/max rows,
    implementation-dependent, so snapshot-bootstrapped nodes diverged from
    event-streamed nodes (which write latest-wins via apiwatcher). The
    migration is now derived deterministically from the latest valid
    issuance per asset; this test verifies that property on the current
    state_db.
    """
    rows = state_db.execute(
        "SELECT asset, description, divisible, mime_type, owner FROM assets_info "
        "WHERE asset NOT IN ('XCP', 'BTC')"
    ).fetchall()
    for r in rows:
        latest = ledger_db.execute(
            "SELECT description, divisible, mime_type, issuer FROM issuances "
            "WHERE asset = ? AND status = 'valid' ORDER BY rowid DESC LIMIT 1",
            (r["asset"],),
        ).fetchone()
        if latest is None:
            continue
        assert r["description"] == latest["description"]
        assert r["divisible"] == latest["divisible"]
        assert r["mime_type"] == latest["mime_type"]
        assert r["owner"] == latest["issuer"]


def test_migration_0004_locked_columns_are_booleans(state_db):
    """Regression: migration 0004 used to write SUM(locked) and
    SUM(description_locked) into BOOL columns, yielding integer counts
    (e.g. 3) when the streamed apiwatcher writes 0/1. The migration now
    derives both as MAX(...) ∈ {0,1}; verify no row drifted to a count.
    """
    rows = state_db.execute(
        "SELECT asset, locked, description_locked FROM assets_info "
        "WHERE asset NOT IN ('XCP', 'BTC')"
    ).fetchall()
    for r in rows:
        assert r["locked"] in (0, 1, None), (
            f"asset {r['asset']} has locked={r['locked']} (must be 0/1 boolean)"
        )
        assert r["description_locked"] in (0, 1, None), (
            f"asset {r['asset']} has description_locked={r['description_locked']}"
        )


# Consolidated tables built by migrations 0006/0014 that carry asset/address
# columns. The State DB stores the *decoded* name/address string in them.
_CONSOLIDATED_INDEX_COLUMN_TABLES = (
    "orders",
    "dispensers",
    "balances",
    "order_matches",
    "bet_matches",
    "rps_matches",
    "pools",
)


def test_consolidated_index_columns_are_text(state_db):
    """Regression for the ~55s ``/addresses/<a>/orders`` (and slow dispenser)
    load-test outliers: the asset/address columns are stored as the compact
    INTEGER index on the Ledger DB, and the consolidated-table migrations copy
    that DDL verbatim while inserting the *decoded* TEXT name/address. Left at
    INTEGER affinity the column mismatches ``assets_info.asset`` (TEXT) in the
    ``orders_info`` join / dispenser price subquery, which silently defeats the
    index and degrades into a full scan of ``assets_info`` per row. They must
    keep TEXT affinity.
    """
    index_cols = ASSET_INDEX_COLUMN_NAMES | ADDRESS_INDEX_COLUMN_NAMES
    for table in _CONSOLIDATED_INDEX_COLUMN_TABLES:
        if not table_exists(state_db, table):
            continue
        offenders = [
            (col["name"], col["type"])
            for col in state_db.execute(f"PRAGMA table_info({table})").fetchall()
            if col["name"] in index_cols and col["type"] != "TEXT"
        ]
        assert not offenders, (
            f"{table} has non-TEXT asset/address columns {offenders}; INTEGER "
            "affinity defeats the assets_info join index (full scan per row)"
        )


def test_orders_info_join_uses_assets_info_index(state_db):
    """The ``orders_info`` view LEFT JOINs ``assets_info`` twice to resolve
    divisibility. With TEXT-affinity asset columns those joins must resolve via
    the ``assets_info`` index (a SEARCH), not a full SCAN -- the SCAN form is
    what made the orders endpoints multi-second on mainnet.
    """
    plan = state_db.execute(
        "EXPLAIN QUERY PLAN "
        "SELECT * FROM orders_info WHERE source = 'x' ORDER BY tx_index DESC LIMIT 10"
    ).fetchall()
    details = [(row["detail"] if isinstance(row, dict) else row[-1]) for row in plan]
    # The view aliases ``assets_info`` as ``get_assets`` / ``give_assets``; a
    # full scan shows as e.g. "SCAN get_assets LEFT-JOIN" (the table name is
    # absent), so match the aliases. With TEXT affinity these resolve via an
    # index SEARCH instead.
    scans = [
        d for d in details if d.startswith("SCAN") and ("get_assets" in d or "give_assets" in d)
    ]
    assert not scans, f"orders_info full-scans assets_info instead of an index seek: {details}"
