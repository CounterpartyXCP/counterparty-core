import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger import caches, events


def test_events_functions(ledger_db, defaults):
    result = events.last_message(ledger_db)
    assert result["block_index"] == 1930
    assert result["message_index"] == 4014
    assert result["event"] == "BLOCK_PARSED"

    assert events.debit(ledger_db, defaults["addresses"][0], "XCP", 1, 0) is None

    with pytest.raises(exceptions.DebitError, match="Cannot debit bitcoins."):
        events.debit(ledger_db, defaults["addresses"][0], "BTC", defaults["quantity"], 0)

    with pytest.raises(exceptions.DebitError, match="Negative quantity."):
        events.debit(ledger_db, defaults["addresses"][0], "BTC", -1 * defaults["quantity"], 0)

    with pytest.raises(exceptions.DebitError, match="Quantity must be an integer."):
        events.debit(ledger_db, defaults["addresses"][0], "BTC", 1.1 * defaults["quantity"], 0)

    with pytest.raises(exceptions.DebitError, match="Insufficient funds."):
        events.debit(ledger_db, defaults["addresses"][0], "XCP", 2**40, 0)

    assert events.credit(ledger_db, defaults["addresses"][0], "XCP", 1, 0) is None

    with pytest.raises(exceptions.CreditError, match="Cannot debit bitcoins."):
        events.credit(ledger_db, defaults["addresses"][0], "BTC", defaults["quantity"], 0)

    with pytest.raises(exceptions.CreditError, match="Negative quantity."):
        events.credit(ledger_db, defaults["addresses"][0], "BTC", -1 * defaults["quantity"], 0)

    with pytest.raises(exceptions.CreditError, match="Quantity must be an integer."):
        events.credit(ledger_db, defaults["addresses"][0], "BTC", 1.1 * defaults["quantity"], 0)


def test_insert_record(ledger_db, defaults):
    caches.AssetCache(ledger_db)
    events.insert_record(
        ledger_db,
        "destructions",
        {
            "asset": "foobar",
            "source": defaults["addresses"][0],
            "quantity": 500,
        },
        "ASSET_DESTRUCTION",
        event_info={"key": "value"},
    )
    last_record = ledger_db.execute("SELECT * FROM destructions WHERE asset = 'foobar'").fetchone()
    assert last_record["asset"] == "foobar"


def get_utxo(ledger_db, address):
    return ledger_db.execute(
        "SELECT * FROM balances WHERE utxo_address = ? AND quantity > 0",
        (address,),
    ).fetchone()


def test_remove_balance(ledger_db, defaults):
    with pytest.raises(exceptions.DebitError, match="Insufficient funds."):
        events.remove_from_balance(
            ledger_db,
            defaults["addresses"][0],
            "foobaz",
            1000,
            200,
        )


def test_remove_all_utxo_balance(ledger_db, defaults):
    utxo = get_utxo(ledger_db, defaults["addresses"][0])
    caches.UTXOBalancesCache(ledger_db).add_balance(utxo["utxo"])
    events.remove_from_balance(
        ledger_db,
        utxo["utxo"],
        utxo["asset"],
        utxo["quantity"],
        200,
    )
    assert not caches.UTXOBalancesCache(ledger_db).has_balance(utxo["utxo"])


def test_debit_max(ledger_db, defaults):
    with pytest.raises(exceptions.DebitError, match="Quantity can't be higher than MAX_INT."):
        events.debit(ledger_db, defaults["addresses"][0], "foobar", config.MAX_INT + 1, 200)

    with pytest.raises(exceptions.DebitError, match="Negative quantity"):
        events.debit(ledger_db, defaults["addresses"][0], "foobar", -1, 200)

    with pytest.raises(exceptions.DebitError, match="Quantity must be an integer."):
        events.debit(ledger_db, defaults["addresses"][0], "foobar", "1", 200)

    with pytest.raises(exceptions.DebitError, match="Cannot debit bitcoins."):
        events.debit(ledger_db, defaults["addresses"][0], "BTC", 100, 200)

    with pytest.raises(AssertionError):
        events.debit(ledger_db, "a" * 40, "foobar", 100, 200)


def test_credi_max(ledger_db, defaults):
    with pytest.raises(exceptions.CreditError, match="Quantity can't be higher than MAX_INT."):
        events.credit(ledger_db, defaults["addresses"][0], "foobar", config.MAX_INT + 1, 200)

    with pytest.raises(AssertionError):
        events.credit(ledger_db, "a" * 40, "foobar", 100, 200)


def test_get_messages(ledger_db):
    messages = events.get_messages(ledger_db)
    assert len(messages) == 100

    assert events.get_messages(ledger_db, block_index=messages[0]["block_index"]) == [
        m for m in messages if m["block_index"] == messages[0]["block_index"]
    ]

    block_indexes = [messages[0]["block_index"], messages[1]["block_index"]]
    assert events.get_messages(ledger_db, block_index_in=block_indexes) == [
        m for m in messages if m["block_index"] in block_indexes
    ]

    message_indexes = [messages[0]["message_index"], messages[1]["message_index"]]
    assert events.get_messages(ledger_db, message_index_in=message_indexes) == (
        [m for m in messages if m["message_index"] in message_indexes]
    )


def test_replay_events(ledger_db, defaults):
    rps_events = [
        [
            "DEBIT",
            "insert",
            "debits",
            f'{{"action":"open RPS","address":"{defaults["addresses"][0]}","asset":"XCP","block_index":308504,"event":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e","quantity":100000000,"tx_index":20260}}',
        ],
        [
            "OPEN_RPS",
            "insert",
            "rps",
            f'{{"block_index":308504,"expiration":500,"expire_index":309004,"move_random_hash":"d02caf1175a967cb5830d0a19d43bb63de6025315b0eb09c80963f96237792e7","possible_moves":5,"source":"{defaults["addresses"][0]}","status":"open","tx_hash":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e","tx_index":20260,"wager":100000000}}',
        ],
        [
            "RPS_UPDATE",
            "update",
            "rps",
            '{"status":"matched","tx_hash":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e"}',
            "tx_hash",
        ],
        [
            "CREDIT",
            "insert",
            "credits",
            f'{{"address":"{defaults["addresses"][0]}","asset":"XCP","block_index":308509,"calling_function":"recredit wager","event":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e_1a3748c324d1ade4ecfcc6950278ece8c35f3225740c38ce0eab3ecbfaa0960b","quantity":100000000,"tx_index":20273}}',
        ],
    ]
    debits_before = ledger_db.execute(
        "SELECT COUNT(*) AS count FROM debits WHERE address = ? and action = ?",
        (defaults["addresses"][0], "open RPS"),
    ).fetchone()["count"]
    credits_before = ledger_db.execute(
        "SELECT COUNT(*) AS count FROM credits WHERE address = ? and calling_function = ?",
        (defaults["addresses"][0], "recredit wager"),
    ).fetchone()["count"]
    rps_before = ledger_db.execute(
        "SELECT COUNT(*) AS count FROM rps WHERE source = ? and status = ?",
        (defaults["addresses"][0], "matched"),
    ).fetchone()["count"]

    events.replay_events(ledger_db, rps_events)

    debits_after = ledger_db.execute(
        "SELECT COUNT(*) AS count FROM debits WHERE address = ? and action = ?",
        (defaults["addresses"][0], "open RPS"),
    ).fetchone()["count"]
    credits_after = ledger_db.execute(
        "SELECT COUNT(*) AS count FROM credits WHERE address = ? and calling_function = ?",
        (defaults["addresses"][0], "recredit wager"),
    ).fetchone()["count"]
    rps_after = ledger_db.execute(
        "SELECT COUNT(*) AS count FROM rps WHERE source = ? and status = ?",
        (defaults["addresses"][0], "matched"),
    ).fetchone()["count"]

    assert debits_before + 1 == debits_after
    assert credits_before + 1 == credits_after
    assert rps_before + 1 == rps_after


def test_replay_events_error(ledger_db, defaults):
    with pytest.raises(exceptions.DatabaseError, match="id_name is required for update action"):
        events.replay_events(
            ledger_db,
            [
                [
                    "RPS_UPDATE",
                    "update",
                    "rps",
                    '{"status":"matched","tx_hash":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e"}',
                    None,
                ]
            ],
        )
    with pytest.raises(exceptions.DatabaseError, match="Unknown action: delete"):
        events.replay_events(
            ledger_db,
            [
                [
                    "RPS_UPDATE",
                    "delete",
                    "rps",
                    '{"status":"matched","tx_hash":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e"}',
                    "tx_hash",
                ]
            ],
        )
