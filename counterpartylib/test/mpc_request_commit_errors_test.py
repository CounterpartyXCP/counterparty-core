import tempfile
import pytest
import os

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.lib import util
from micropayment_core.util import hash160hex
from micropayment_core import scripts
from micropayment_core.util import b2h


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


def assert_transferred(payer, payee, quantity):
    assert util.api("mpc_transferred_amount", {"state": payer}) == quantity
    assert util.api("mpc_transferred_amount", {"state": payee}) == quantity


def get_txs(txids):
    return util.api(
        method="getrawtransaction_batch", params={"txhash_list": txids}
    )


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_invalid_quantity(server_db, mpcenv):

    # send funds to deposit address
    quantity = 1000000
    send1hex = util.api('create_send', {
        'source': mpcenv["alice_address"],
        'destination': mpcenv["deposit_address"],
        'asset': 'XCP',
        'quantity': quantity,
        'regular_dust_size': 300000
    })

    # insert send, this automatically also creates a block
    util_test.insert_raw_transaction(send1hex, server_db)

    # check balances after send to deposit
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    assert alice_balance == 1000000 - quantity
    assert deposit_balance == quantity

    try:
        util.api("mpc_request_commit", {
            "state": {
                "asset": "XCP",
                "deposit_script": mpcenv["deposit_script"],
                "commits_requested": [],
                "commits_active": [],
                "commits_revoked": []
            },
            "quantity": quantity + 1,
            "revoke_secret_hash": "f483" * 10
        })
        assert False
    except util.RPCError as e:
        assert "InvalidTransferQuantity" in str(e)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_ignores_unconfirmed_funds(server_db, mpcenv):

    # check initial balances
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    bob_balance = util.get_balance(server_db, mpcenv["bob_address"],
                                   mpcenv["asset"])
    assert alice_balance == 1000000
    assert deposit_balance == 0
    assert bob_balance == 1000000

    # ===== PAYER CREATES DEPOSIT TX =====

    deposit_quantity = 41
    result = util.api(
        method="mpc_make_deposit",
        params={
            "asset": "XCP",
            "payer_pubkey": mpcenv["alice_pubkey"],
            "payee_pubkey": mpcenv["bob_pubkey"],
            "spend_secret_hash": mpcenv["spend_secret_hash"],
            "expire_time": mpcenv["deposit_expire_time"],  # in blocks
            "quantity": deposit_quantity  # in satoshis
        }
    )
    # alice_state = result["state"]
    deposit_rawtx = result["topublish"]
    deposit_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                         result["topublish"])

    # ===== PAYEE SETS DEPOSIT =====

    bob_state = util.api("mpc_set_deposit", {
        "asset": "XCP",
        "deposit_script": mpcenv["deposit_script"],
        "expected_payee_pubkey": mpcenv["bob_pubkey"],
        "expected_spend_secret_hash": mpcenv["spend_secret_hash"]
    })

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    util_test.insert_unconfirmed_raw_transaction(deposit_rawtx, server_db)

    # ===== PAYEE REQUESTS COMMIT =====

    try:
        transfer_quantity = 33
        revoke_secret = b2h(os.urandom(32))
        revoke_secret_hash = hash160hex(revoke_secret)
        bob_state = util.api("mpc_request_commit", {
            "state": bob_state,
            "quantity": transfer_quantity,
            "revoke_secret_hash": revoke_secret_hash
        })
        assert False
    except util.RPCError as e:
        assert "InvalidTransferQuantity" in str(e)
