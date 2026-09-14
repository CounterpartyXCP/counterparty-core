#
# file: counterpartycore/test/units/api/addressevents_test.py
#
# `address_events` is derived by the watcher, by migration 0001 and by
# `dbbuilder.backfill_address_events()`. All three go through the rules in
# `api/addressevents.py`, so the API answers the same whichever built the
# State DB -- including the UTXO-owner alias, which only this path adds.
#
import json

from counterpartycore.lib.api import addressevents


def a_utxo_balance(state_db):
    return state_db.execute(
        "SELECT utxo, utxo_address FROM balances WHERE utxo IS NOT NULL LIMIT 1"
    ).fetchone()


def credit_event(address, message_index=10**9, block_index=999):
    return {
        "event": "CREDIT",
        "message_index": message_index,
        "block_index": block_index,
        "bindings": json.dumps({"address": address, "asset": "XCP", "quantity": 1}),
    }


def rows_for(state_db, message_index):
    return {
        row["address"]
        for row in state_db.execute(
            "SELECT address FROM address_events WHERE event_index = ?", (message_index,)
        ).fetchall()
    }


def test_search_address_from_utxo_finds_the_owner(state_db):
    balance = a_utxo_balance(state_db)
    assert (
        addressevents.search_address_from_utxo(state_db, balance["utxo"])
        == (balance["utxo_address"])
    )


def test_search_address_from_utxo_returns_none_for_an_unknown_utxo(state_db):
    assert addressevents.search_address_from_utxo(state_db, "00" * 32 + ":7") is None


def test_utxo_address_is_recorded_alongside_the_utxo(state_db):
    """A balance held by a UTXO is credited to the UTXO, but the address that
    owns it has to find the event too."""
    balance = a_utxo_balance(state_db)
    event = credit_event(balance["utxo"])

    addressevents.update_address_events(state_db, event)

    assert rows_for(state_db, event["message_index"]) == {
        balance["utxo"],
        balance["utxo_address"],
    }


def test_unowned_utxo_records_only_the_utxo(state_db):
    unknown_utxo = "00" * 32 + ":7"
    event = credit_event(unknown_utxo)

    addressevents.update_address_events(state_db, event)

    assert rows_for(state_db, event["message_index"]) == {unknown_utxo}


def test_plain_address_is_not_looked_up_as_a_utxo(state_db):
    event = credit_event("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc")

    addressevents.update_address_events(state_db, event)

    assert rows_for(state_db, event["message_index"]) == {"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}


def test_fields_absent_from_the_bindings_are_skipped(state_db):
    # `NEW_TRANSACTION` lists both `source` and `destination`; a transaction
    # without a destination must not record a `None` address.
    event = {
        "event": "NEW_TRANSACTION",
        "message_index": 10**9 + 1,
        "block_index": 999,
        "bindings": json.dumps({"source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}),
    }

    addressevents.update_address_events(state_db, event)

    assert rows_for(state_db, event["message_index"]) == {"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}


def test_unknown_event_records_nothing(state_db):
    event = credit_event("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc")
    event["event"] = "NOT_AN_EVENT"

    addressevents.update_address_events(state_db, event)

    assert rows_for(state_db, event["message_index"]) == set()
