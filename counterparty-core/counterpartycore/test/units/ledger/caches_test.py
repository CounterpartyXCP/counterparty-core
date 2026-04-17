from unittest.mock import patch

from counterpartycore.lib import config
from counterpartycore.lib.ledger import caches


def test_asset_cache(ledger_db, defaults):
    ledger_db.execute(
        """
        INSERT INTO destructions (asset, quantity, source, status) 
        VALUES ('foobar', 1000, ?, 'valid')
        """,
        (defaults["addresses"][0],),
    )

    caches.AssetCache(ledger_db).add_issuance(
        {
            "rowid": 1,
            "asset": "foobar",
            "asset_longname": "longfoobar",
            "quantity": 1000,
            "status": "valid",
        }
    )
    assert caches.AssetCache().assets_total_issued["foobar"] == 1000

    caches.AssetCache().add_issuance(
        {
            "asset": "foobar",
            "asset_longname": "longfoobar",
            "quantity": 1000,
            "status": "valid",
        }
    )
    assert caches.AssetCache().assets_total_issued["foobar"] == 2000

    caches.AssetCache().add_issuance(
        {
            "asset": "foobar",
            "asset_longname": "longfoobar",
            "quantity": 500,
            "status": "invalid",
        }
    )
    assert caches.AssetCache().assets_total_issued["foobar"] == 2000

    assert caches.AssetCache().assets_total_destroyed["foobar"] == 1000

    caches.AssetCache().add_destroyed(
        {
            "asset": "foobar",
            "asset_longname": "longfoobar",
            "quantity": 500,
            "status": "valid",
        }
    )
    assert caches.AssetCache().assets_total_destroyed["foobar"] == 1500

    caches.AssetCache().add_destroyed(
        {
            "asset": "foobar",
            "asset_longname": "longfoobar",
            "quantity": 300,
            "status": "invalid",
        }
    )
    assert caches.AssetCache().assets_total_destroyed["foobar"] == 1500

    caches.AssetCache().add_destroyed(
        {
            "rowid": 1,
            "asset": "foobaz",
            "asset_longname": "longfoobar",
            "quantity": 500,
            "status": "valid",
        }
    )
    assert caches.AssetCache().assets_total_destroyed["foobaz"] == 500


def test_orders_cache(ledger_db):
    orders_count_1 = (
        caches.OrdersCache(ledger_db)
        .cache_db.execute("SELECT COUNT(*) AS count FROM orders")
        .fetchone()["count"]
    )

    caches.OrdersCache(ledger_db).insert_order({"block_index": config.MEMPOOL_BLOCK_INDEX})

    orders_count_2 = (
        caches.OrdersCache(ledger_db)
        .cache_db.execute("SELECT COUNT(*) AS count FROM orders")
        .fetchone()["count"]
    )
    assert orders_count_1 == orders_count_2

    open_orders = (
        caches.OrdersCache(ledger_db)
        .cache_db.execute(
            "SELECT * FROM orders WHERE status = 'open' AND give_asset = 'XCP' AND get_asset = 'BTC'"
        )
        .fetchall()
    )

    order_1 = open_orders[0]

    caches.OrdersCache(ledger_db).update_order(
        order_1["tx_hash"],
        {
            "status": "expired",
        },
    )
    orders_count_3 = (
        caches.OrdersCache(ledger_db)
        .cache_db.execute("SELECT COUNT(*) AS count FROM orders")
        .fetchone()["count"]
    )
    assert orders_count_1 == orders_count_3 + 1

    matchings = caches.OrdersCache(ledger_db).get_matching_orders(
        order_1["tx_hash"],
        give_asset=order_1["give_asset"],
        get_asset=order_1["get_asset"],
    )
    assert matchings[0]["get_asset"] == order_1["give_asset"]
    assert matchings[0]["give_asset"] == order_1["get_asset"]


def test_utxo_cache(ledger_db):
    caches.UTXOBalancesCache(ledger_db).add_balance("utxo1")
    assert caches.UTXOBalancesCache().has_balance("utxo1")
    caches.UTXOBalancesCache(ledger_db).remove_balance("utxo1")
    assert not caches.UTXOBalancesCache().has_balance("utxo1")


# Tests for get_asset function
def test_get_asset_cache_hit(ledger_db):
    """Test that get_asset returns cached asset when present in cache."""
    caches.reset_caches()
    asset_cache = caches.AssetCache(ledger_db)

    # Pre-populate the cache
    mock_asset = {"asset": "TESTASSET", "asset_longname": None, "status": "valid"}
    asset_cache.assets["TESTASSET"] = mock_asset

    # Should return from cache without querying DB
    result = asset_cache.get_asset("TESTASSET")
    assert result == mock_asset
    assert result["asset"] == "TESTASSET"


def test_get_asset_cache_miss_regular_asset_found(ledger_db, defaults):
    """Test cache miss with regular asset name that is found in DB."""
    caches.reset_caches()

    # Insert a valid issuance into the DB
    ledger_db.execute(
        """
        INSERT INTO issuances (
            tx_index, tx_hash, msg_index, block_index, asset, quantity,
            divisible, source, issuer, transfer, callable, call_date,
            call_price, description, fee_paid, locked, reset, status,
            asset_longname
        ) VALUES (
            999, 'test_hash_regular', 0, 310000, 'NEWASSET', 1000,
            1, ?, ?, 0, 0, 0,
            0.0, 'Test asset', 0, 0, 0, 'valid',
            NULL
        )
        """,
        (defaults["addresses"][0], defaults["addresses"][0]),
    )

    asset_cache = caches.AssetCache(ledger_db)

    # Clear the asset from cache to force a cache miss
    asset_cache.assets.pop("NEWASSET", None)

    # Should query DB and cache the result
    result = asset_cache.get_asset("NEWASSET")
    assert result is not None
    assert result["asset"] == "NEWASSET"
    # Should now be cached
    assert "NEWASSET" in asset_cache.assets


def test_get_asset_cache_miss_longname_found(ledger_db, defaults):
    """Test cache miss with asset_longname (contains '.') that is found in DB."""
    caches.reset_caches()

    # Insert a valid issuance with a longname into the DB
    ledger_db.execute(
        """
        INSERT INTO issuances (
            tx_index, tx_hash, msg_index, block_index, asset, quantity,
            divisible, source, issuer, transfer, callable, call_date,
            call_price, description, fee_paid, locked, reset, status,
            asset_longname
        ) VALUES (
            1000, 'test_hash_longname', 0, 310000, 'A123456789012345', 1000,
            1, ?, ?, 0, 0, 0,
            0.0, 'Test asset with longname', 0, 0, 0, 'valid',
            'PARENT.CHILD'
        )
        """,
        (defaults["addresses"][0], defaults["addresses"][0]),
    )

    asset_cache = caches.AssetCache(ledger_db)

    # Clear the longname from cache to force a cache miss
    asset_cache.assets.pop("PARENT.CHILD", None)

    # Should query DB using asset_longname field (because of the ".")
    result = asset_cache.get_asset("PARENT.CHILD")
    assert result is not None
    assert result["asset_longname"] == "PARENT.CHILD"
    # Should now be cached
    assert "PARENT.CHILD" in asset_cache.assets


def test_get_asset_cache_miss_not_found(ledger_db):
    """Test cache miss with asset not found in DB (returns None)."""
    caches.reset_caches()
    asset_cache = caches.AssetCache(ledger_db)

    # Asset that doesn't exist
    result = asset_cache.get_asset("NONEXISTENTASSET")
    assert result is None
    # Should NOT be cached since it wasn't found
    assert "NONEXISTENTASSET" not in asset_cache.assets


def _get_existing_block(ledger_db):
    """Helper to get an existing block from the database for foreign key constraints."""
    result = ledger_db.execute(
        "SELECT block_index, block_hash, block_time FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    return result


def _insert_test_transaction(ledger_db, tx_index, tx_hash, source, utxos_info, transaction_type):
    """Helper to insert a test transaction using existing block data."""
    block = _get_existing_block(ledger_db)
    ledger_db.execute(
        """
        INSERT INTO transactions (
            tx_index, tx_hash, block_index, block_hash, block_time,
            source, destination, btc_amount, fee, data, supported,
            utxos_info, transaction_type
        ) VALUES (?, ?, ?, ?, ?, ?, NULL, 0, 10000, NULL, 1, ?, ?)
        """,
        (
            tx_index,
            tx_hash,
            block["block_index"],
            block["block_hash"],
            block["block_time"],
            source,
            utxos_info,
            transaction_type,
        ),
    )


# Tests for _add_known_sources_descendants function
def test_add_known_sources_descendants_with_transactions(ledger_db, defaults):
    """Test _add_known_sources_descendants with KNOWN_SOURCES containing transactions and descendants."""
    caches.reset_caches()

    # Insert test transactions that form a chain
    # First transaction: source from KNOWN_SOURCES -> destination utxo1
    _insert_test_transaction(
        ledger_db,
        tx_index=90001,
        tx_hash="known_source_tx_hash",
        source=defaults["addresses"][0],
        utxos_info="source_utxo:0 utxo1:0 2",
        transaction_type="utxomove",
    )

    # Second transaction: consumes utxo1 -> destination utxo2
    _insert_test_transaction(
        ledger_db,
        tx_index=90002,
        tx_hash="descendant_tx_hash",
        source=defaults["addresses"][0],
        utxos_info="utxo1:0 utxo2:0 2",
        transaction_type="utxomove",
    )

    # Mock KNOWN_SOURCES to use our test transaction
    mock_known_sources = {
        "known_source_tx_hash": "source_utxo:0",
    }

    with patch("counterpartycore.lib.ledger.caches.KNOWN_SOURCES", mock_known_sources):
        utxo_cache = caches.UTXOBalancesCache(ledger_db)

        # utxo1 should be consumed (removed from cache)
        # utxo2 should be in cache (final destination)
        assert "utxo2:0" in utxo_cache.utxos_with_balance
        # utxo1 was consumed by the second transaction
        assert utxo_cache.utxos_with_balance.get(
            "utxo1:0"
        ) is None or not utxo_cache.utxos_with_balance.get("utxo1:0")


def test_add_known_sources_descendants_detach_handling(ledger_db, defaults):
    """Test that detach transactions don't add destination to cache."""
    caches.reset_caches()

    # Insert a detach transaction
    _insert_test_transaction(
        ledger_db,
        tx_index=90003,
        tx_hash="known_detach_tx_hash",
        source=defaults["addresses"][0],
        utxos_info="source_detach:0 detach_dest:0 2",
        transaction_type="utxomove",
    )

    # Insert a second transaction that consumes the destination of the first,
    # but it's a detach so its destination should NOT be added
    _insert_test_transaction(
        ledger_db,
        tx_index=90004,
        tx_hash="detach_consume_tx",
        source=defaults["addresses"][0],
        utxos_info="detach_dest:0 final_detach_dest:0 2",
        transaction_type="detach",
    )

    mock_known_sources = {
        "known_detach_tx_hash": "source_detach:0",
    }

    with patch("counterpartycore.lib.ledger.caches.KNOWN_SOURCES", mock_known_sources):
        utxo_cache = caches.UTXOBalancesCache(ledger_db)

        # detach destination should NOT be added to cache
        assert "final_detach_dest:0" not in utxo_cache.utxos_with_balance


def test_add_known_sources_descendants_empty_source(ledger_db):
    """Test that KNOWN_SOURCES with empty source are skipped."""
    caches.reset_caches()

    mock_known_sources = {
        "empty_source_tx_hash": "",  # Empty source should be skipped
    }

    with patch("counterpartycore.lib.ledger.caches.KNOWN_SOURCES", mock_known_sources):
        # Should not crash and should initialize successfully
        utxo_cache = caches.UTXOBalancesCache(ledger_db)
        assert utxo_cache is not None


def test_add_known_sources_descendants_no_matching_tx(ledger_db):
    """Test that KNOWN_SOURCES with tx_hash not in DB are handled gracefully."""
    caches.reset_caches()

    mock_known_sources = {
        "nonexistent_tx_hash": "some_source:0",  # Transaction not in DB
    }

    with patch("counterpartycore.lib.ledger.caches.KNOWN_SOURCES", mock_known_sources):
        # Should not crash and should initialize successfully
        utxo_cache = caches.UTXOBalancesCache(ledger_db)
        assert utxo_cache is not None


def test_add_known_sources_descendants_short_utxos_info(ledger_db, defaults):
    """Test handling of utxos_info with less than 2 parts."""
    caches.reset_caches()

    # Insert a transaction with short utxos_info
    _insert_test_transaction(
        ledger_db,
        tx_index=90005,
        tx_hash="short_utxos_tx_hash",
        source=defaults["addresses"][0],
        utxos_info="only_source",
        transaction_type="utxomove",
    )

    mock_known_sources = {
        "short_utxos_tx_hash": "only_source",
    }

    with patch("counterpartycore.lib.ledger.caches.KNOWN_SOURCES", mock_known_sources):
        # Should not crash and should handle short utxos_info gracefully
        utxo_cache = caches.UTXOBalancesCache(ledger_db)
        assert utxo_cache is not None


def test_add_known_sources_descendants_empty_destination(ledger_db, defaults):
    """Test handling of utxos_info with empty destination."""
    caches.reset_caches()

    # Insert a transaction with empty destination
    _insert_test_transaction(
        ledger_db,
        tx_index=90006,
        tx_hash="empty_dest_tx_hash",
        source=defaults["addresses"][0],
        utxos_info="source_empty:0  2",
        transaction_type="utxomove",
    )

    mock_known_sources = {
        "empty_dest_tx_hash": "source_empty:0",
    }

    with patch("counterpartycore.lib.ledger.caches.KNOWN_SOURCES", mock_known_sources):
        # Should not crash
        utxo_cache = caches.UTXOBalancesCache(ledger_db)
        assert utxo_cache is not None


def test_add_known_sources_descendants_multiple_sources(ledger_db, defaults):
    """Test handling of transactions with multiple comma-separated sources."""
    caches.reset_caches()

    # Insert a known source transaction
    _insert_test_transaction(
        ledger_db,
        tx_index=90007,
        tx_hash="multi_source_known_tx",
        source=defaults["addresses"][0],
        utxos_info="source_multi:0 multi_dest:0 2",
        transaction_type="utxomove",
    )

    # Insert a transaction with multiple sources where multi_dest is first
    # (LIKE pattern matches from the beginning of utxos_info)
    _insert_test_transaction(
        ledger_db,
        tx_index=90008,
        tx_hash="multi_source_consumer_tx",
        source=defaults["addresses"][0],
        utxos_info="multi_dest:0,other:0 final_multi:0 2",
        transaction_type="attach",
    )

    mock_known_sources = {
        "multi_source_known_tx": "source_multi:0",
    }

    with patch("counterpartycore.lib.ledger.caches.KNOWN_SOURCES", mock_known_sources):
        utxo_cache = caches.UTXOBalancesCache(ledger_db)

        # multi_dest:0 should be consumed and final_multi:0 should be added
        assert "final_multi:0" in utxo_cache.utxos_with_balance
        # multi_dest:0 should be removed from cache (consumed)
        assert utxo_cache.utxos_with_balance.get("multi_dest:0") is None


def test_add_known_sources_descendants_attach_transaction(ledger_db, defaults):
    """Test that attach transactions (non-detach) properly add destinations."""
    caches.reset_caches()

    # Insert a known source transaction
    _insert_test_transaction(
        ledger_db,
        tx_index=90009,
        tx_hash="attach_known_tx",
        source=defaults["addresses"][0],
        utxos_info="attach_source:0 attach_dest1:0 2",
        transaction_type="utxomove",
    )

    # Insert an attach transaction (non-detach)
    _insert_test_transaction(
        ledger_db,
        tx_index=90010,
        tx_hash="attach_consume_tx",
        source=defaults["addresses"][0],
        utxos_info="attach_dest1:0 attach_final:0 2",
        transaction_type="attach",
    )

    mock_known_sources = {
        "attach_known_tx": "attach_source:0",
    }

    with patch("counterpartycore.lib.ledger.caches.KNOWN_SOURCES", mock_known_sources):
        utxo_cache = caches.UTXOBalancesCache(ledger_db)

        # attach destination SHOULD be added to cache (unlike detach)
        assert "attach_final:0" in utxo_cache.utxos_with_balance


def _insert_invalid_attach_transaction(ledger_db, tx_index, tx_hash, source, utxos_info):
    """Helper to insert an invalid attach transaction using existing block data."""
    block = _get_existing_block(ledger_db)
    ledger_db.execute(
        """
        INSERT INTO transactions (
            tx_index, tx_hash, block_index, block_hash, block_time,
            source, destination, btc_amount, fee, data, supported,
            utxos_info, transaction_type
        ) VALUES (?, ?, ?, ?, ?, ?, NULL, 0, 10000, NULL, 1, ?, ?)
        """,
        (
            tx_index,
            tx_hash,
            block["block_index"],
            block["block_hash"],
            block["block_time"],
            source,
            utxos_info,
            "attach",
        ),
    )
    # Mark the transaction as invalid
    ledger_db.execute(
        "INSERT INTO transactions_status (tx_index, valid) VALUES (?, ?)",
        (tx_index, False),
    )


def test_invalid_attach_transactions(ledger_db, defaults):
    """Test that invalid attach transactions add destination to cache."""
    caches.reset_caches()

    # Insert an invalid attach transaction
    _insert_invalid_attach_transaction(
        ledger_db,
        tx_index=90011,
        tx_hash="invalid_attach_tx_hash",
        source=defaults["addresses"][0],
        utxos_info="invalid_source:0 invalid_dest:0 2",
    )

    # Initialize cache - should pick up the invalid attach destination
    utxo_cache = caches.UTXOBalancesCache(ledger_db)

    # The destination from the invalid attach should be in the cache
    assert "invalid_dest:0" in utxo_cache.utxos_with_balance


def test_add_known_sources_descendants_utxo_already_processed(ledger_db, defaults):
    """Test that UTXOs already in processed set are skipped (continue branch)."""
    caches.reset_caches()

    # Create a chain where the same UTXO would be added to pending_utxos multiple times
    # This happens when two transactions in KNOWN_SOURCES both point to the same destination
    # or when multiple transactions in the chain converge to the same destination

    # First known source transaction -> dest1
    _insert_test_transaction(
        ledger_db,
        tx_index=90012,
        tx_hash="known_tx_1",
        source=defaults["addresses"][0],
        utxos_info="source1:0 shared_dest:0 2",
        transaction_type="utxomove",
    )

    # Second known source transaction -> also dest1 (same destination)
    _insert_test_transaction(
        ledger_db,
        tx_index=90013,
        tx_hash="known_tx_2",
        source=defaults["addresses"][0],
        utxos_info="source2:0 shared_dest:0 2",
        transaction_type="utxomove",
    )

    # Transaction that consumes shared_dest:0
    _insert_test_transaction(
        ledger_db,
        tx_index=90014,
        tx_hash="consume_shared_tx",
        source=defaults["addresses"][0],
        utxos_info="shared_dest:0 final_dest_shared:0 2",
        transaction_type="utxomove",
    )

    mock_known_sources = {
        "known_tx_1": "source1:0",
        "known_tx_2": "source2:0",
    }

    with patch("counterpartycore.lib.ledger.caches.KNOWN_SOURCES", mock_known_sources):
        # Should not crash, and should correctly process shared_dest:0 only once
        utxo_cache = caches.UTXOBalancesCache(ledger_db)

        # shared_dest:0 should be consumed (not in cache or False)
        # final_dest_shared:0 should be in cache
        assert "final_dest_shared:0" in utxo_cache.utxos_with_balance


def test_invalid_attach_transaction_short_utxos_info(ledger_db, defaults):
    """Test that invalid attach transactions with short utxos_info are handled."""
    caches.reset_caches()

    # Insert an invalid attach transaction with short utxos_info (< 2 parts)
    block = _get_existing_block(ledger_db)
    ledger_db.execute(
        """
        INSERT INTO transactions (
            tx_index, tx_hash, block_index, block_hash, block_time,
            source, destination, btc_amount, fee, data, supported,
            utxos_info, transaction_type
        ) VALUES (?, ?, ?, ?, ?, ?, NULL, 0, 10000, NULL, 1, ?, ?)
        """,
        (
            90015,
            "invalid_attach_short_utxos",
            block["block_index"],
            block["block_hash"],
            block["block_time"],
            defaults["addresses"][0],
            "only_source",  # Short utxos_info
            "attach",
        ),
    )
    ledger_db.execute(
        "INSERT INTO transactions_status (tx_index, valid) VALUES (?, ?)",
        (90015, False),
    )

    # Should not crash
    utxo_cache = caches.UTXOBalancesCache(ledger_db)
    assert utxo_cache is not None


def test_invalid_attach_transaction_empty_destination(ledger_db, defaults):
    """Test that invalid attach transactions with empty destination are handled."""
    caches.reset_caches()

    # Insert an invalid attach transaction with empty destination
    block = _get_existing_block(ledger_db)
    ledger_db.execute(
        """
        INSERT INTO transactions (
            tx_index, tx_hash, block_index, block_hash, block_time,
            source, destination, btc_amount, fee, data, supported,
            utxos_info, transaction_type
        ) VALUES (?, ?, ?, ?, ?, ?, NULL, 0, 10000, NULL, 1, ?, ?)
        """,
        (
            90016,
            "invalid_attach_empty_dest",
            block["block_index"],
            block["block_hash"],
            block["block_time"],
            defaults["addresses"][0],
            "source:0  2",  # Empty destination (space as second element)
            "attach",
        ),
    )
    ledger_db.execute(
        "INSERT INTO transactions_status (tx_index, valid) VALUES (?, ?)",
        (90016, False),
    )

    # Should not crash and should not add empty destination
    utxo_cache = caches.UTXOBalancesCache(ledger_db)
    assert utxo_cache is not None
    # Empty string should not be in cache
    assert "" not in utxo_cache.utxos_with_balance


def test_cleanup_spent_utxos(ledger_db):
    """Test that cleanup_spent_utxos removes False entries from cache."""
    caches.reset_caches()
    utxo_cache = caches.UTXOBalancesCache(ledger_db)

    # Add some UTXOs with balance
    utxo_cache.add_balance("utxo_active_1")
    utxo_cache.add_balance("utxo_active_2")

    # Mark some as spent (False)
    utxo_cache.remove_balance("utxo_spent_1")
    utxo_cache.remove_balance("utxo_spent_2")
    utxo_cache.remove_balance("utxo_spent_3")

    # Verify initial state
    assert utxo_cache.utxos_with_balance.get("utxo_active_1") is True
    assert utxo_cache.utxos_with_balance.get("utxo_active_2") is True
    assert utxo_cache.utxos_with_balance.get("utxo_spent_1") is False
    assert utxo_cache.utxos_with_balance.get("utxo_spent_2") is False
    assert utxo_cache.utxos_with_balance.get("utxo_spent_3") is False

    # Cleanup spent UTXOs
    utxo_cache.cleanup_spent_utxos()

    # Verify only active UTXOs remain
    assert "utxo_active_1" in utxo_cache.utxos_with_balance
    assert "utxo_active_2" in utxo_cache.utxos_with_balance
    assert "utxo_spent_1" not in utxo_cache.utxos_with_balance
    assert "utxo_spent_2" not in utxo_cache.utxos_with_balance
    assert "utxo_spent_3" not in utxo_cache.utxos_with_balance


def test_cleanup_if_exists_with_existing_cache(ledger_db):
    """Test that cleanup_if_exists works when singleton exists."""
    caches.reset_caches()

    # Create the singleton
    utxo_cache = caches.UTXOBalancesCache(ledger_db)
    utxo_cache.add_balance("utxo1")
    utxo_cache.remove_balance("utxo_spent")

    # Verify spent UTXO is in cache
    assert "utxo_spent" in utxo_cache.utxos_with_balance

    # Call cleanup_if_exists
    caches.UTXOBalancesCache.cleanup_if_exists()

    # Verify spent UTXO was removed
    assert "utxo_spent" not in utxo_cache.utxos_with_balance
    assert "utxo1" in utxo_cache.utxos_with_balance


def test_cleanup_if_exists_without_existing_cache():
    """Test that cleanup_if_exists does not create singleton if it doesn't exist."""
    caches.reset_caches()

    # Verify singleton doesn't exist
    from counterpartycore.lib.utils import helpers

    assert caches.UTXOBalancesCache not in helpers.SingletonMeta._instances

    # Call cleanup_if_exists - should not create singleton
    caches.UTXOBalancesCache.cleanup_if_exists()

    # Verify singleton still doesn't exist
    assert caches.UTXOBalancesCache not in helpers.SingletonMeta._instances


def test_has_balance_does_not_cache_negative_db_results(ledger_db):
    """Test that has_balance does not cache negative results from DB queries."""
    caches.reset_caches()
    utxo_cache = caches.UTXOBalancesCache(ledger_db)

    # Query for a UTXO that doesn't exist in DB
    non_existent_utxo = "non_existent_utxo_12345:99"
    result = utxo_cache.has_balance(non_existent_utxo)

    # Should return False
    assert result is False

    # Should NOT be cached (to prevent unbounded memory growth)
    assert non_existent_utxo not in utxo_cache.utxos_with_balance
