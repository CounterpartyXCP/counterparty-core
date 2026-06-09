"""
Unit tests for counterpartycore.lib.api.queries module.
Tests focus on covering uncovered lines in the module.
"""

from counterpartycore.lib import config
from counterpartycore.lib.api import queries

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


def test_get_address_options(ledger_db, defaults):
    unset_address = defaults["addresses"][4]
    result = queries.get_address(ledger_db, unset_address)
    assert result.result == {
        "address": unset_address,
        "options": 0,
        "block_index": None,
    }

    address_with_options = defaults["addresses"][6]
    ledger_db.execute(
        "INSERT INTO addresses (address, options, block_index) VALUES (?, ?, ?)",
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
    result = queries.get_transactions_by_address(
        ledger_db,
        address=defaults["addresses"][0],
        valid=True,
    )
    assert result is not None


def test_get_transactions_by_addresses_with_valid_filter(ledger_db, defaults):
    """Test get_transactions_by_addresses with valid filter (line 556)."""
    addresses = f"{defaults['addresses'][0]},{defaults['addresses'][1]}"
    result = queries.get_transactions_by_addresses(
        ledger_db,
        addresses=addresses,
        valid=True,
    )
    assert result is not None


# =============================================================================
# Tests for event queries
# =============================================================================


def test_get_all_events_with_event_name(ledger_db):
    """Test get_all_events with event_name filter (line 658)."""
    result = queries.get_all_events(
        ledger_db,
        event_name="CREDIT,DEBIT",
    )
    assert result is not None
    for row in result.result:
        assert row["event"] in ["CREDIT", "DEBIT"]


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
