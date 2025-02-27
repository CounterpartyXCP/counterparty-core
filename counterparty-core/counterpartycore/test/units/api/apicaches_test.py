import json

from counterpartycore.lib.api import apiwatcher, caches, queries


def test_address_events_cache(state_db, defaults, ledger_db):
    cache = caches.AddressEventsCache()

    cache_count = cache.cache_db.execute("SELECT COUNT(*) AS count FROM address_events").fetchone()[
        "count"
    ]
    state_db_count = state_db.execute("SELECT COUNT(*) AS count FROM address_events").fetchone()[
        "count"
    ]

    assert cache_count == state_db_count

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

    cache_count_after = cache.cache_db.execute(
        "SELECT COUNT(*) AS count FROM address_events"
    ).fetchone()["count"]
    state_db_count_after = state_db.execute(
        "SELECT COUNT(*) AS count FROM address_events"
    ).fetchone()["count"]

    assert cache_count_after == state_db_count_after
    assert cache_count_after == cache_count + 2

    result = queries.get_events_by_addresses(
        ledger_db,
        addresses=f"{defaults['addresses'][0]},{defaults['addresses'][1]}",
        event_name="SEND",
    )
    assert result.result == [
        {
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
    ]
