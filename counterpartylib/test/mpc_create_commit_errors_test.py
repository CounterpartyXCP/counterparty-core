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
    alice_state = result["state"]
    deposit_rawtx = result["topublish"]
    deposit_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                         result["topublish"])

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    util_test.insert_unconfirmed_raw_transaction(deposit_rawtx, server_db)

    # ===== PAYEE REQUESTS COMMIT =====

    try:
        transfer_quantity = 33
        revoke_secret = b2h(os.urandom(32))
        revoke_secret_hash = hash160hex(revoke_secret)

        result = util.api("mpc_create_commit", {
            "state": alice_state,
            "quantity": transfer_quantity,
            "revoke_secret_hash": revoke_secret_hash,
            "delay_time": mpcenv["delay_time"]
        })

        assert False
    except util.RPCError as e:
        assert "InvalidTransferQuantity" in str(e)
