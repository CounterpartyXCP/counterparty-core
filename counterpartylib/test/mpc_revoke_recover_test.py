import os
import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.lib.api import dispatcher
from counterpartylib.lib.micropayments.control import get_transferred
from counterpartylib.lib import util
from micropayment_core.util import b2h
from micropayment_core.util import script_address
from micropayment_core.util import hash160hex
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
def test_usage_xcp(server_db, mpcenv):

    asset = mpcenv["asset"]
    alice_address = mpcenv["alice_address"]
    bob_address = mpcenv["bob_address"]
    deposit_address = mpcenv["deposit_address"]

    # check initial balances
    alice_balance = util.get_balance(server_db, alice_address, asset)
    deposit_balance = util.get_balance(server_db, deposit_address, asset)
    bob_balance = util.get_balance(server_db, bob_address, asset)
    assert alice_balance == 1000000
    assert deposit_balance == 0
    assert bob_balance == 1000000

    # ===== PAYER CREATES DEPOSIT =====

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

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    util_test.insert_raw_transaction(deposit_rawtx, server_db)

    # check balances after send to deposit
    alice_balance = util.get_balance(server_db, alice_address, asset)
    deposit_balance = util.get_balance(server_db, deposit_address, asset)
    bob_balance = util.get_balance(server_db, bob_address, asset)
    assert alice_balance == 1000000 - deposit_quantity
    assert deposit_balance == deposit_quantity
    assert bob_balance == 1000000
    assert util.api("mpc_deposit_ttl", {"state": bob_state}) == 41
    assert_transferred(alice_state, bob_state, 0)

    # ===== PAYEE REQUESTS COMMIT =====

    transfer_quantity = 17
    revoke_secret = b2h(os.urandom(32))
    revoke_secret_hash = hash160hex(revoke_secret)
    bob_state = util.api("mpc_request_commit", {
        "state": bob_state,
        "quantity": transfer_quantity,
        "revoke_secret_hash": revoke_secret_hash
    })

    # ===== PAYER CREATES COMMIT =====

    result = util.api("mpc_create_commit", {
        "state": alice_state,
        "quantity": transfer_quantity,
        "revoke_secret_hash": revoke_secret_hash,
        "delay_time": mpcenv["delay_time"]
    })
    alice_state = result["state"]
    commit_script = result["commit_script"]
    commit_rawtx = result["tosign"]["commit_rawtx"]
    deposit_script = result["tosign"]["deposit_script"]
    signed_commit_rawtx = scripts.sign_created_commit(
        get_txs, mpcenv["alice_wif"], commit_rawtx, deposit_script
    )

    # ===== PAYEE UPDATES STATE =====

    bob_state = util.api("mpc_add_commit", {
        "state": bob_state,
        "commit_rawtx": signed_commit_rawtx,
        "commit_script": commit_script,
    })
    assert_transferred(alice_state, bob_state, transfer_quantity)

    # ===== PAYEE RETURNS FUNDS =====

    # payee revokes commits
    bob_state = util.api("mpc_revoke_all", {
        "state": bob_state, "secrets": [revoke_secret],
    })

    # payer revokes commits
    alice_state = util.api("mpc_revoke_all", {
        "state": alice_state, "secrets": [revoke_secret],
    })
    assert_transferred(alice_state, bob_state, 0)

    # ===== PAYEE PUBLISHES REVOKED COMMIT =====

    signed_commit_rawtx = scripts.sign_finalize_commit(
        get_txs, mpcenv["bob_wif"], signed_commit_rawtx,
        bob_state["deposit_script"]
    )
    util_test.insert_raw_transaction(signed_commit_rawtx, server_db)

    commits = util.api("mpc_published_commits", {"state": alice_state})
    assert commits == [signed_commit_rawtx]

    # check balances after publishing commit
    commit_address = script_address(commit_script, netcode=mpcenv["netcode"])
    alice_balance = util.get_balance(server_db, alice_address, asset)
    deposit_balance = util.get_balance(server_db, deposit_address, asset)
    commit_balance = util.get_balance(server_db, commit_address, asset)
    bob_balance = util.get_balance(server_db, bob_address, asset)
    assert alice_balance == 1000000 - deposit_quantity
    assert deposit_balance == deposit_quantity - transfer_quantity
    assert commit_balance == transfer_quantity
    assert bob_balance == 1000000

    # ===== PAYER RECOVERS REVOKED COMMIT =====

    recoverables = util.api("mpc_recoverables", {"state": alice_state})
    assert len(recoverables["revoke"]) == 1
    assert len(recoverables["change"]) == 0
    assert len(recoverables["expire"]) == 0
    revoke = recoverables["revoke"][0]
    signed_revoke_rawtx = scripts.sign_revoke_recover(
        get_txs, mpcenv["alice_wif"], revoke["revoke_rawtx"],
        revoke["commit_script"], revoke["revoke_secret"]
    )
    asset_quantity, btc_quantity = get_transferred(
        dispatcher, signed_revoke_rawtx, asset
    )
    assert asset_quantity == transfer_quantity
    util_test.insert_raw_transaction(signed_revoke_rawtx, server_db)

    # check balances after publishing commit
    alice_balance = util.get_balance(server_db, alice_address, asset)
    commit_balance = util.get_balance(server_db, commit_address, asset)
    deposit_balance = util.get_balance(server_db, deposit_address, asset)
    bob_balance = util.get_balance(server_db, bob_address, asset)
    assert alice_balance == 1000000 - deposit_quantity + transfer_quantity
    assert deposit_balance == deposit_quantity - transfer_quantity
    assert commit_balance == 0
    assert bob_balance == 1000000

    recoverables = util.api("mpc_recoverables", {"state": alice_state})
    assert len(recoverables["revoke"]) == 0
    assert len(recoverables["change"]) == 0
    assert len(recoverables["expire"]) == 0

    # ===== LET DEPOSIT EXPIRE =====

    for i in range(39):
        util_test.create_next_block(server_db)

    # isnt tripped by commit tx
    recoverables = util.api("mpc_recoverables", {"state": alice_state})
    assert len(recoverables["revoke"]) == 0
    assert len(recoverables["change"]) == 0
    assert len(recoverables["expire"]) == 0

    util_test.create_next_block(server_db)
    recoverables = util.api("mpc_recoverables", {"state": alice_state})
    assert len(recoverables["revoke"]) == 0
    assert len(recoverables["change"]) == 0
    assert len(recoverables["expire"]) == 1
    expire = recoverables["expire"][0]

    # ===== PAYER RECOVERS EXPIRED DEPOSIT =====

    # sign and publish expire recover transaction
    signed_expire_rawtx = scripts.sign_expire_recover(
        get_txs, mpcenv["alice_wif"], expire["expire_rawtx"],
        expire["deposit_script"]
    )
    util_test.insert_raw_transaction(signed_expire_rawtx, server_db)

    # check balances after expire recover
    alice_balance = util.get_balance(server_db, alice_address, asset)
    commit_balance = util.get_balance(server_db, commit_address, asset)
    deposit_balance = util.get_balance(server_db, deposit_address, asset)
    bob_balance = util.get_balance(server_db, bob_address, asset)
    assert alice_balance == 1000000
    assert deposit_balance == 0
    assert commit_balance == 0
    assert bob_balance == 1000000

    # deposit p2sh has three transactions (fund, commit and expire recover)
    deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": deposit_address, "unconfirmed": False}
    )
    assert len(deposit_transactions) == 3


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_usage_btc(server_db, mpcenv):
    pass  # TODO test
