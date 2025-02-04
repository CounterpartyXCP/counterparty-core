import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger import caches, events


def test_events_functions(ledger_db, defaults):
    result = events.last_message(ledger_db)
    assert result["block_index"] == 1929
    assert result["message_index"] == 3995
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


def test_replay_events(ledger_db):
    rps_events = [
        [
            "DEBIT",
            "insert",
            "debits",
            '{"action":"open RPS","address":"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc","asset":"XCP","block_index":308504,"event":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e","quantity":100000000,"tx_index":20260}',
        ],
        [
            "OPEN_RPS",
            "insert",
            "rps",
            '{"block_index":308504,"expiration":500,"expire_index":309004,"move_random_hash":"d02caf1175a967cb5830d0a19d43bb63de6025315b0eb09c80963f96237792e7","possible_moves":5,"source":"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc","status":"open","tx_hash":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e","tx_index":20260,"wager":100000000}',
        ],
        [
            "DEBIT",
            "insert",
            "debits",
            '{"action":"open RPS","address":"12tJDMYbSuVBW6SBkd5yLsx7P4CDwTod9L","asset":"XCP","block_index":308506,"event":"1a3748c324d1ade4ecfcc6950278ece8c35f3225740c38ce0eab3ecbfaa0960b","quantity":100000000,"tx_index":20264}',
        ],
        [
            "OPEN_RPS",
            "insert",
            "rps",
            '{"block_index":308506,"expiration":500,"expire_index":309006,"move_random_hash":"54ccf2a6fe9e92424c843de14f380d9bd79915572be5d382caf70e76a194b71f","possible_moves":5,"source":"12tJDMYbSuVBW6SBkd5yLsx7P4CDwTod9L","status":"open","tx_hash":"1a3748c324d1ade4ecfcc6950278ece8c35f3225740c38ce0eab3ecbfaa0960b","tx_index":20264,"wager":100000000}',
        ],
        [
            "RPS_UPDATE",
            "update",
            "rps",
            '{"status":"matched","tx_hash":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e"}',
            "tx_hash",
        ],
        [
            "RPS_UPDATE",
            "update",
            "rps",
            '{"status":"matched","tx_hash":"1a3748c324d1ade4ecfcc6950278ece8c35f3225740c38ce0eab3ecbfaa0960b"}',
            "tx_hash",
        ],
        [
            "RPS_MATCH",
            "insert",
            "rps_matches",
            '{"block_index":308506,"id":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e_1a3748c324d1ade4ecfcc6950278ece8c35f3225740c38ce0eab3ecbfaa0960b","match_expire_index":308526,"possible_moves":5,"status":"pending","tx0_address":"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc","tx0_block_index":308504,"tx0_expiration":500,"tx0_hash":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e","tx0_index":20260,"tx0_move_random_hash":"d02caf1175a967cb5830d0a19d43bb63de6025315b0eb09c80963f96237792e7","tx1_address":"12tJDMYbSuVBW6SBkd5yLsx7P4CDwTod9L","tx1_block_index":308506,"tx1_expiration":500,"tx1_hash":"1a3748c324d1ade4ecfcc6950278ece8c35f3225740c38ce0eab3ecbfaa0960b","tx1_index":20264,"tx1_move_random_hash":"54ccf2a6fe9e92424c843de14f380d9bd79915572be5d382caf70e76a194b71f","wager":100000000}',
        ],
        [
            "CREDIT",
            "insert",
            "credits",
            '{"address":"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc","asset":"XCP","block_index":308509,"calling_function":"recredit wager","event":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e_1a3748c324d1ade4ecfcc6950278ece8c35f3225740c38ce0eab3ecbfaa0960b","quantity":100000000,"tx_index":20273}',
        ],
        [
            "CREDIT",
            "insert",
            "credits",
            '{"address":"12tJDMYbSuVBW6SBkd5yLsx7P4CDwTod9L","asset":"XCP","block_index":308509,"calling_function":"recredit wager","event":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e_1a3748c324d1ade4ecfcc6950278ece8c35f3225740c38ce0eab3ecbfaa0960b","quantity":100000000,"tx_index":20273}',
        ],
        [
            "RPS_MATCH_UPDATE",
            "update",
            "rps_matches",
            '{"id":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e_1a3748c324d1ade4ecfcc6950278ece8c35f3225740c38ce0eab3ecbfaa0960b","status":"concluded: tie"}',
            "id",
        ],
        [
            "RPS_RESOLVE",
            "insert",
            "rpsresolves",
            '{"block_index":308509,"move":3,"random":"2aeb66e29c4962457867100df828562f","rps_match_id":"5f206584e5198c593b273cb91543ab26143b4e70f4f5d96f6c6e2c35f9835f8e_1a3748c324d1ade4ecfcc6950278ece8c35f3225740c38ce0eab3ecbfaa0960b","source":"12tJDMYbSuVBW6SBkd5yLsx7P4CDwTod9L","status":"valid","tx_hash":"f10857a8f71f85ce61e68df4d21face419ae9bc3660e71241ee93c264a2256ae","tx_index":20273}',
        ],
    ]
    print(rps_events)
    # events.replay_events(ledger_db, rps_events)
