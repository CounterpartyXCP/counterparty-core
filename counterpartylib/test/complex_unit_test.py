import pprint
import tempfile
import pytest
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP, ADDR

from counterpartylib.lib import util

FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_alice_bob(server_db):
    alice = ADDR[0]
    bob = "miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB"

    # check alices UTXOs
    utxos = util.api('get_unspent_txouts', {"address": alice})
    assert len(utxos) == 1
    assert utxos[0]['address'] == alice
    assert utxos[0]['txid'] == "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1"
    assert utxos[0]['amount'] == 1.9990914
    assert utxos[0]['confirmations'] == 74

    # balance before send
    alice_balance = util.get_balance(server_db, alice, 'XCP')
    bob_balance = util.get_balance(server_db, bob, 'XCP')
    assert alice_balance == 91875000000
    assert bob_balance == 0

    # create send
    v = int(100 * 1e8)
    send1hex = util.api('create_send', {'source': alice, 'destination': bob, 'asset': 'XCP', 'quantity': v})
    assert send1hex == "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9141e9d9c2c34d4dda3cd71603d9ce1e447c3cc5c0588ac00000000000000001e6a1c8a5dda15fb6f05628a061e67576e926dc71a7fa2f0cceb951120a9322f30ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"

    # insert send, this automatically also creates a block
    tx1 = util_test.insert_raw_transaction(send1hex, server_db)

    # balances after send
    alice_balance2 = util.get_balance(server_db, alice, 'XCP')
    bob_balance2 = util.get_balance(server_db, bob, 'XCP')
    assert alice_balance2 == alice_balance - v
    assert bob_balance2 == bob_balance + v

    # check API result
    result = util.api("get_balances", {"filters": [
        {'field': 'address', 'op': '==', 'value': alice},
        {'field': 'asset', 'op': '==', 'value': 'XCP'},
    ]})

    assert result[0]['quantity'] == alice_balance2

    # -- do another TX

    # check alices UTXOs
    utxos = util.api('get_unspent_txouts', {"address": alice})
    assert len(utxos) == 1
    assert utxos[0]['address'] == alice
    assert utxos[0]['txid'] == tx1['tx_hash']
    assert utxos[0]['amount'] == 1.99897135
    assert utxos[0]['confirmations'] == 1

    # balances before send
    alice_balance = util.get_balance(server_db, alice, 'XCP')
    bob_balance = util.get_balance(server_db, bob, 'XCP')
    assert alice_balance == alice_balance2
    assert bob_balance == bob_balance2

    # create send
    v = int(100 * 1e8)
    send2hex = util.api('create_send', {'source': alice, 'destination': bob, 'asset': 'XCP', 'quantity': v})
    assert send2hex == "0100000001cd2d431037d1d0cfe05daeb1d08b975f27488e383f7f169e09d2f405fb618f39020000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9141e9d9c2c34d4dda3cd71603d9ce1e447c3cc5c0588ac00000000000000001e6a1c8a5dda15fb6f05628a061e67576e926dc71a7fa2f0cceb951120a9324a01ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"

    # insert send, this automatically also creates a block
    tx2 = util_test.insert_raw_transaction(send2hex, server_db)

    # balances after send
    alice_balance2 = util.get_balance(server_db, alice, 'XCP')
    bob_balance2 = util.get_balance(server_db, bob, 'XCP')
    assert alice_balance2 == alice_balance - v
    assert bob_balance2 == bob_balance + v

    # -- do another TX, now unconfirmed

    # check alices UTXOs
    utxos = util.api('get_unspent_txouts', {"address": alice})
    assert len(utxos) == 1
    assert utxos[0]['address'] == alice
    assert utxos[0]['txid'] == tx2['tx_hash']
    assert utxos[0]['amount'] == 1.9988513
    assert utxos[0]['confirmations'] == 1

    # balances before send
    alice_balance = util.get_balance(server_db, alice, 'XCP')
    bob_balance = util.get_balance(server_db, bob, 'XCP')
    assert alice_balance == alice_balance2
    assert bob_balance == bob_balance2

    # create send
    v = int(100 * 1e8)
    send3hex = util.api('create_send', {'source': alice, 'destination': bob, 'asset': 'XCP', 'quantity': v})
    assert send3hex == "01000000019aea7b78c8fffa50c51bbadb87824a202b3e6b53727e543e9c6846845205b5ce020000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9141e9d9c2c34d4dda3cd71603d9ce1e447c3cc5c0588ac00000000000000001e6a1c8a5dda15fb6f05628a061e67576e926dc71a7fa2f0cceb951120a93265d2e90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"

    # insert send, as unconfirmed! won't create a block!
    tx3 = util_test.insert_unconfirmed_raw_transaction(send3hex, server_db)

    # balances after send, unaffected
    alice_balance2 = util.get_balance(server_db, alice, 'XCP')
    bob_balance2 = util.get_balance(server_db, bob, 'XCP')
    assert alice_balance2 == alice_balance
    assert bob_balance2 == bob_balance

    # no confirmed UTXOs left, we use the 1 we had
    utxos = util.api('get_unspent_txouts', {"address": alice})
    assert len(utxos) == 0

    # unconfirmed UTXO is there, we can use it!
    utxos = util.api('get_unspent_txouts', {"address": alice, "unconfirmed": True})
    assert len(utxos) == 1
    assert utxos[0]['address'] == alice
    assert utxos[0]['txid'] == tx3['tx_hash']
    assert utxos[0]['amount'] == 1.99873125
    assert utxos[0]['confirmations'] == 0

    # atm there's no way to confirm this unconfirmed TX
    # even doing this won't make it confirmed because it just mocks an empty block
    util_test.create_next_block(server_db)

    utxos = util.api('get_unspent_txouts', {"address": alice})
    assert len(utxos) == 1
    assert utxos[0]['address'] == alice
    assert utxos[0]['txid'] == tx3['tx_hash']
    assert utxos[0]['amount'] == 1.99873125
    assert utxos[0]['confirmations'] == 1

    # we can eventually make this mocking better to be able to do that,
    # but for now you'll have to micro manage if you want to confirm a unconfirmed TX in 1 test
    # by just calling the `insert_raw_transaction` again for it
    tx3b = util_test.insert_raw_transaction(send3hex, server_db)

    # balances after send
    alice_balance2 = util.get_balance(server_db, alice, 'XCP')
    bob_balance2 = util.get_balance(server_db, bob, 'XCP')
    assert alice_balance2 == alice_balance - v
    assert bob_balance2 == bob_balance + v
