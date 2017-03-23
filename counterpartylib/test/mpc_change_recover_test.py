import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.lib import util
from micropayment_core import scripts


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


def get_txs(txids):
    return util.api(
        method="getrawtransaction_batch", params={"txhash_list": txids}
    )


def assert_transferred(payer, payee, quantity):
    assert util.api("mpc_transferred_amount", {"state": payer}) == quantity
    assert util.api("mpc_transferred_amount", {"state": payee}) == quantity


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_recover_no_commits_xcp(server_db, mpcenv):

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

    # ===== PAYEE SETS DEPOSIT =====

    bob_state = util.api("mpc_set_deposit", {
        "asset": "XCP",
        "deposit_script": mpcenv["deposit_script"],
        "expected_payee_pubkey": mpcenv["bob_pubkey"],
        "expected_spend_secret_hash": mpcenv["spend_secret_hash"]
    })

    assert util.api("mpc_highest_commit", {"state": bob_state}) is None
    assert util.api("mpc_deposit_ttl", {"state": bob_state}) is None

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    before_deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(before_deposit_transactions) == 0

    # insert send, this automatically also creates a block
    util_test.insert_raw_transaction(deposit_rawtx, server_db)

    # check balances after send to deposit
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    bob_balance = util.get_balance(server_db, mpcenv["bob_address"],
                                   mpcenv["asset"])
    assert alice_balance == 1000000 - deposit_quantity
    assert deposit_balance == deposit_quantity
    assert bob_balance == 1000000
    assert util.api("mpc_deposit_ttl", {"state": bob_state}) == 41

    after_deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(after_deposit_transactions) == 1

    # ===== PAYER RECOVERS CHANGE WITH GIVEN SPEND SECRET =====

    # get change recoverable
    recoverables = util.api("mpc_recoverables", {
        "state": alice_state,
        "spend_secret": mpcenv["spend_secret"]
    })
    assert len(recoverables["change"]) == 1
    change = recoverables["change"][0]

    # publish change recoverable
    signed_change_rawtx = scripts.sign_change_recover(
        get_txs, mpcenv["alice_wif"], change["change_rawtx"],
        change["deposit_script"], change["spend_secret"]
    )
    util_test.insert_raw_transaction(signed_change_rawtx, server_db)

    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    assert alice_balance == 1000000


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_recover_no_commits_btc(server_db):
    pass
