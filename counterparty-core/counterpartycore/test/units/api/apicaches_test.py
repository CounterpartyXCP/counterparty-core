import json

from counterpartycore.lib.api import apiwatcher, queries


def test_address_events(state_db, defaults, ledger_db):
    """Test that address_events table includes the event column and queries work correctly"""
    # Verify the event column exists in state_db.address_events
    state_db_count = state_db.execute("SELECT COUNT(*) AS count FROM address_events").fetchone()[
        "count"
    ]

    # Verify we can query by event type
    state_db_with_event = state_db.execute(
        "SELECT COUNT(*) AS count FROM address_events WHERE event IS NOT NULL"
    ).fetchone()["count"]
    assert state_db_with_event == state_db_count  # All rows should have event populated

    send_event = {
        "event": "SEND",
        "message_index": 9999999,
        "block_index": 9999999,
        "bindings": json.dumps(
            {
                "asset": "XCP",
                "quantity": 100000000,
                "source": defaults["addresses"][0],
                "destination": defaults["addresses"][1],
            }
        ),
    }

    ledger_db.execute(
        """
        INSERT INTO messages (message_index, block_index, event, bindings)
        VALUES (:message_index, :block_index, :event, :bindings)
    """,
        send_event,
    )

    apiwatcher.update_address_events(state_db, send_event)

    state_db_count_after = state_db.execute(
        "SELECT COUNT(*) AS count FROM address_events"
    ).fetchone()["count"]

    assert state_db_count_after == state_db_count + 2

    # Verify event column was populated correctly
    new_events = state_db.execute(
        "SELECT * FROM address_events WHERE event_index = ?", (9999999,)
    ).fetchall()
    assert len(new_events) == 2
    assert all(e["event"] == "SEND" for e in new_events)

    result = queries.get_events_by_addresses(
        ledger_db,
        state_db,
        addresses=f"{defaults['addresses'][0]},{defaults['addresses'][1]}",
        event_name="SEND",
    )
    # Check that our new event is in the results
    new_event = [e for e in result.result if e["event_index"] == 9999999]
    assert len(new_event) == 1
    assert new_event[0] == {
        "event_index": 9999999,
        "event": "SEND",
        "params": {
            "asset": "XCP",
            "quantity": 100000000,
            "source": defaults["addresses"][0],
            "destination": defaults["addresses"][1],
        },
        "tx_hash": None,
        "block_index": 9999999,
    }


def test_address_events_filtering_with_limit(state_db, defaults, ledger_db):
    """Test that event filtering is applied before pagination, not after"""
    # Use a different address to avoid interference from other tests
    address = defaults["addresses"][5]

    # Create 10 OPEN_ORDER events and 5 SEND events for the same address
    for i in range(10):
        order_event = {
            "event": "OPEN_ORDER",
            "message_index": 20000000 + i,
            "block_index": 20000000 + i,
            "bindings": json.dumps(
                {
                    "source": address,
                    "give_asset": "XCP",
                    "give_quantity": 1000,
                    "get_asset": "BTC",
                    "get_quantity": 1000,
                }
            ),
        }
        ledger_db.execute(
            """
            INSERT INTO messages (message_index, block_index, event, bindings)
            VALUES (:message_index, :block_index, :event, :bindings)
        """,
            order_event,
        )
        apiwatcher.update_address_events(state_db, order_event)

    for i in range(5):
        send_event = {
            "event": "ENHANCED_SEND",
            "message_index": 20000100 + i,
            "block_index": 20000100 + i,
            "bindings": json.dumps(
                {
                    "source": address,
                    "destination": defaults["addresses"][6],
                    "asset": "XCP",
                    "quantity": 100,
                }
            ),
        }
        ledger_db.execute(
            """
            INSERT INTO messages (message_index, block_index, event, bindings)
            VALUES (:message_index, :block_index, :event, :bindings)
        """,
            send_event,
        )
        apiwatcher.update_address_events(state_db, send_event)

    # Request 8 ENHANCED_SEND events with limit=8
    result = queries.get_events_by_addresses(
        ledger_db, state_db, addresses=address, event_name="ENHANCED_SEND", limit=8
    )

    # Should return all 5 ENHANCED_SEND events we just created
    new_enhanced_sends = [e for e in result.result if e["event_index"] >= 20000100]
    assert len(new_enhanced_sends) == 5
    assert all(event["event"] == "ENHANCED_SEND" for event in new_enhanced_sends)

    # Request 3 ENHANCED_SEND events with limit=3
    result = queries.get_events_by_addresses(
        ledger_db, state_db, addresses=address, event_name="ENHANCED_SEND", limit=3
    )

    # Should return exactly 3 ENHANCED_SEND events
    assert len(result.result) == 3
    assert all(event["event"] == "ENHANCED_SEND" for event in result.result)

    # Request 8 OPEN_ORDER events with limit=8
    result = queries.get_events_by_addresses(
        ledger_db, state_db, addresses=address, event_name="OPEN_ORDER", limit=8
    )

    # Should return 8 OPEN_ORDER events (out of 10 we just created)
    new_orders = [e for e in result.result if e["event_index"] >= 20000000]
    assert len(new_orders) == 8
    assert all(event["event"] == "OPEN_ORDER" for event in new_orders)
