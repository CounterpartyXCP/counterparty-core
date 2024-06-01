import json
import tempfile

import pytest
from apsw import ConstraintError

from counterpartycore.lib import blocks, ledger, util
from counterpartycore.lib.api import api_v1

# this is require near the top to do setup of the test suite
from counterpartycore.test import (
    conftest,  # noqa: F401
    util_test,
)
from counterpartycore.test.fixtures.params import ADDR, DP  # noqa: F401
from counterpartycore.test.util_test import CURR_DIR

FIXTURE_SQL_FILE = CURR_DIR + "/fixtures/scenarios/unittest_fixture.sql"
FIXTURE_DB = tempfile.gettempdir() + "/fixtures.unittest_fixture.db"


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_alice_bob(server_db):
    alice = ADDR[0]
    bob = "miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB"

    # check alices UTXOs
    utxos = util.api("get_unspent_txouts", {"address": alice})
    assert len(utxos) == 1
    assert utxos[0]["address"] == alice
    assert utxos[0]["txid"] == "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1"
    assert utxos[0]["amount"] == 1.9990914
    assert utxos[0]["confirmations"] == 74

    # balance before send
    alice_balance = ledger.get_balance(server_db, alice, "XCP")
    bob_balance = ledger.get_balance(server_db, bob, "XCP")
    assert alice_balance == 91875000000
    assert bob_balance == 0

    # create send
    v = int(100 * 1e8)
    send1hex = util.api(
        "create_send",
        {
            "source": alice,
            "destination": bob,
            "asset": "XCP",
            "quantity": v,
            "regular_dust_size": 5430,
        },
    )
    assert (
        send1hex
        == "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9141e9d9c2c34d4dda3cd71603d9ce1e447c3cc5c0588ac00000000000000001e6a1c8a5dda15fb6f05628a061e67576e926dc71a7fa2f0cceb951120a9322f30ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    )

    # insert send, this automatically also creates a block
    tx1hash, tx1 = util_test.insert_raw_transaction(send1hex, server_db)

    # balances after send
    alice_balance2 = ledger.get_balance(server_db, alice, "XCP")
    bob_balance2 = ledger.get_balance(server_db, bob, "XCP")
    assert alice_balance2 == alice_balance - v
    assert bob_balance2 == bob_balance + v

    # check API result
    result = util.api(
        "get_balances",
        {
            "filters": [
                {"field": "address", "op": "==", "value": alice},
                {"field": "asset", "op": "==", "value": "XCP"},
            ],
        },
    )

    assert result[0]["quantity"] == alice_balance2

    # -- do another TX

    # check alices UTXOs
    utxos = util.api("get_unspent_txouts", {"address": alice})
    assert len(utxos) == 1
    assert utxos[0]["address"] == alice
    assert utxos[0]["txid"] == tx1["tx_hash"]
    assert utxos[0]["amount"] == 1.99897135
    assert utxos[0]["confirmations"] == 1

    # balances before send
    alice_balance = ledger.get_balance(server_db, alice, "XCP")
    bob_balance = ledger.get_balance(server_db, bob, "XCP")
    assert alice_balance == alice_balance2
    assert bob_balance == bob_balance2

    # create send
    v = int(100 * 1e8)
    send2hex = util.api(
        "create_send",
        {
            "source": alice,
            "destination": bob,
            "asset": "XCP",
            "quantity": v,
            "regular_dust_size": 5430,
        },
    )
    assert (
        send2hex
        == "0100000001cd2d431037d1d0cfe05daeb1d08b975f27488e383f7f169e09d2f405fb618f39020000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9141e9d9c2c34d4dda3cd71603d9ce1e447c3cc5c0588ac00000000000000001e6a1c8a5dda15fb6f05628a061e67576e926dc71a7fa2f0cceb951120a9324a01ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    )

    # insert send, this automatically also creates a block
    tx2hash, tx2 = util_test.insert_raw_transaction(send2hex, server_db)

    # balances after send
    alice_balance2 = ledger.get_balance(server_db, alice, "XCP")
    bob_balance2 = ledger.get_balance(server_db, bob, "XCP")
    assert alice_balance2 == alice_balance - v
    assert bob_balance2 == bob_balance + v

    # -- do another TX, now unconfirmed

    # check alices UTXOs
    utxos = util.api("get_unspent_txouts", {"address": alice})
    assert len(utxos) == 1
    assert utxos[0]["address"] == alice
    assert utxos[0]["txid"] == tx2["tx_hash"]
    assert utxos[0]["amount"] == 1.9988513
    assert utxos[0]["confirmations"] == 1

    # balances before send
    alice_balance = ledger.get_balance(server_db, alice, "XCP")
    bob_balance = ledger.get_balance(server_db, bob, "XCP")
    assert alice_balance == alice_balance2
    assert bob_balance == bob_balance2

    # create send
    v = int(100 * 1e8)
    send3hex = util.api(
        "create_send",
        {
            "source": alice,
            "destination": bob,
            "asset": "XCP",
            "quantity": v,
            "regular_dust_size": 5430,
        },
    )
    assert (
        send3hex
        == "01000000019aea7b78c8fffa50c51bbadb87824a202b3e6b53727e543e9c6846845205b5ce020000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9141e9d9c2c34d4dda3cd71603d9ce1e447c3cc5c0588ac00000000000000001e6a1c8a5dda15fb6f05628a061e67576e926dc71a7fa2f0cceb951120a93265d2e90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    )

    # insert send, as unconfirmed! won't create a block!
    tx3 = util_test.insert_unconfirmed_raw_transaction(send3hex, server_db)

    # balances after send, unaffected
    alice_balance2 = ledger.get_balance(server_db, alice, "XCP")
    bob_balance2 = ledger.get_balance(server_db, bob, "XCP")
    assert alice_balance2 == alice_balance
    assert bob_balance2 == bob_balance

    # no confirmed UTXOs left, we use the 1 we had
    utxos = util.api("get_unspent_txouts", {"address": alice})
    assert len(utxos) == 0

    # unconfirmed UTXO is there, we can use it!
    utxos = util.api("get_unspent_txouts", {"address": alice, "unconfirmed": True})
    assert len(utxos) == 1
    assert utxos[0]["address"] == alice
    assert utxos[0]["txid"] == tx3["tx_hash"]
    assert utxos[0]["amount"] == 1.99873125
    assert utxos[0]["confirmations"] == 0

    # atm there's no way to confirm this unconfirmed TX
    # even doing this won't make it confirmed because it just mocks an empty block
    util_test.create_next_block(server_db)

    utxos = util.api("get_unspent_txouts", {"address": alice})
    assert len(utxos) == 1
    assert utxos[0]["address"] == alice
    assert utxos[0]["txid"] == tx3["tx_hash"]
    assert utxos[0]["amount"] == 1.99873125
    assert utxos[0]["confirmations"] == 1

    # we can eventually make this mocking better to be able to do that,
    # but for now you'll have to micro manage if you want to confirm a unconfirmed TX in 1 test
    # by just calling the `insert_raw_transaction` again for it
    tx3bhash, tx3b = util_test.insert_raw_transaction(send3hex, server_db)

    # balances after send
    alice_balance2 = ledger.get_balance(server_db, alice, "XCP")
    bob_balance2 = ledger.get_balance(server_db, bob, "XCP")
    assert alice_balance2 == alice_balance - v
    assert bob_balance2 == bob_balance + v


@pytest.mark.usefixtures("api_server")
def test_update_lock(server_db):
    cursor = server_db.cursor()
    for table in blocks.TABLES:
        # don't test empty tables
        rows_count = cursor.execute(f"SELECT COUNT(*) AS cnt FROM {table}").fetchone()  # noqa: S608
        if rows_count is None or rows_count["cnt"] == 0:
            continue
        with pytest.raises(ConstraintError) as excinfo:
            cursor.execute(
                f"""
                UPDATE {table} SET block_index = :block_index
            """,  # noqa: S608
                {"block_index": 0},
            )
        assert str(excinfo.value) == "ConstraintError: UPDATES NOT ALLOWED"


@pytest.mark.usefixtures("api_server")
def test_updated_tables_endpoints():
    for table in api_v1.API_TABLES:
        if table in ["mempool"]:
            continue
        result = util.api("get_" + table, {})
        assert isinstance(result, list)
        if table == "orders":
            assert result[0] == {
                "tx_index": 11,
                "tx_hash": "1899b2e6ec36ba4bc9d035e6640b0a62b08c3a147c77c89183a77d9ed9081b3a",
                "block_index": 310010,
                "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                "give_asset": "XCP",
                "give_quantity": 100000000,
                "give_remaining": 100000000,
                "get_asset": "BTC",
                "get_quantity": 1000000,
                "get_remaining": 1000000,
                "expiration": 2000,
                "expire_index": 312010,
                "fee_required": 900000,
                "fee_required_remaining": 900000,
                "fee_provided": 6800,
                "fee_provided_remaining": 6800,
                "status": "open",
            }
        elif table == "order_matches":
            assert result[0] == {
                "id": "74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498_1b294dd8592e76899b1c106782e4c96e63114abd8e3fa09ab6d2d52496b5bf81",
                "tx0_index": 492,
                "tx0_hash": "74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498",
                "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                "tx1_index": 493,
                "tx1_hash": "1b294dd8592e76899b1c106782e4c96e63114abd8e3fa09ab6d2d52496b5bf81",
                "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                "forward_asset": "XCP",
                "forward_quantity": 100000000,
                "backward_asset": "BTC",
                "backward_quantity": 800000,
                "tx0_block_index": 310491,
                "tx1_block_index": 310492,
                "block_index": 310492,
                "tx0_expiration": 2000,
                "tx1_expiration": 2000,
                "match_expire_index": 310512,
                "fee_paid": 7200,
                "status": "pending",
            }
        elif table == "bets":
            assert result[0] == {
                "tx_index": 20,
                "tx_hash": "2a2169991597036b6dad687ea1feffd55465a204466f40c35cbba811cb3109b1",
                "block_index": 310020,
                "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                "bet_type": 1,
                "deadline": 1388000001,
                "wager_quantity": 9,
                "wager_remaining": 0,
                "counterwager_quantity": 9,
                "counterwager_remaining": 0,
                "target_value": 0.0,
                "leverage": 5040,
                "expiration": 100,
                "expire_index": 310119,
                "fee_fraction_int": 5000000,
                "status": "filled",
            }
        elif table == "bet_matches":
            assert result[0] == {
                "id": "2a2169991597036b6dad687ea1feffd55465a204466f40c35cbba811cb3109b1_5c6562ddad0bc8a1faaded18813a65522cd273709acd190cf9d3271817eefc93",
                "tx0_index": 20,
                "tx0_hash": "2a2169991597036b6dad687ea1feffd55465a204466f40c35cbba811cb3109b1",
                "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                "tx1_index": 21,
                "tx1_hash": "5c6562ddad0bc8a1faaded18813a65522cd273709acd190cf9d3271817eefc93",
                "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                "tx0_bet_type": 1,
                "tx1_bet_type": 0,
                "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                "initial_value": 1,
                "deadline": 1388000001,
                "target_value": 0.0,
                "leverage": 5040,
                "forward_quantity": 9,
                "backward_quantity": 9,
                "tx0_block_index": 310019,
                "tx1_block_index": 310020,
                "block_index": 310019,
                "tx0_expiration": 100,
                "tx1_expiration": 100,
                "match_expire_index": 310119,
                "fee_fraction_int": 5000000,
                "status": "pending",
            }
        elif table == "dispensers":
            assert result[0] == {
                "tx_index": 108,
                "tx_hash": "9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec",
                "block_index": 310107,
                "source": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
                "asset": "XCP",
                "give_quantity": 100,
                "escrow_quantity": 100,
                "satoshirate": 100,
                "status": 0,
                "give_remaining": 100,
                "oracle_address": None,
                "last_status_tx_hash": None,
                "origin": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
                "dispense_count": 0,
                "close_block_index": None,
                "last_status_tx_source": None,
            }


@pytest.mark.usefixtures("server_db")
def test_messages_table(server_db):
    cursor = server_db.cursor()
    cursor.execute("SELECT * FROM messages ORDER BY block_index")
    result = cursor.fetchall()
    for row in result:
        bindings = json.loads(row["bindings"])
        assert isinstance(bindings, dict)
