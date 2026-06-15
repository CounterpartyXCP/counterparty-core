from counterpartycore.lib.api import dbbuilder

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
        "SELECT *, MAX(rowid) FROM balances GROUP BY address, asset ORDER BY asset, address"
    ).fetchall()
    api_balances = state_db.execute("SELECT * FROM balances ORDER BY asset, address").fetchall()
    assert len(ledger_balances) == len(api_balances)
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
            "SELECT * FROM orders WHERE tx_hash = ?", (ledger_order["tx_hash"],)
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
    sql_ledger = (
        "SELECT count(*) AS count FROM (SELECT *, MAX(rowid) FROM order_matches GROUP BY id)"
    )
    sql_api = "SELECT count(*) AS count FROM order_matches"
    assert (
        ledger_db.execute(sql_ledger).fetchone()["count"]
        == state_db.execute(sql_api).fetchone()["count"]
    )

    ledger_order_matches = ledger_db.execute(
        "SELECT *, MAX(rowid) FROM order_matches GROUP BY id ORDER BY id"
    ).fetchall()
    api_order_matches = state_db.execute("SELECT * FROM order_matches ORDER BY id").fetchall()
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
