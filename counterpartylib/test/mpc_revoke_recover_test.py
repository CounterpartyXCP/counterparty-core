import os
import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP
from counterpartylib.lib import util
from micropayment_core.util import b2h
from micropayment_core.keys import address_from_wif
from micropayment_core.keys import pubkey_from_wif
from micropayment_core.util import script_address
from micropayment_core.util import hash160hex
from micropayment_core import scripts


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


# actors
ALICE_WIF = DP["addresses"][0][2]  # payer
ALICE_ADDRESS = address_from_wif(ALICE_WIF)
ALICE_PUBKEY = pubkey_from_wif(ALICE_WIF)
BOB_WIF = DP["addresses"][1][2]  # payee
BOB_ADDRESS = address_from_wif(BOB_WIF)
BOB_PUBKEY = pubkey_from_wif(BOB_WIF)


# secrets
SPEND_SECRET = b2h(os.urandom(32))
SPEND_SECRET_HASH = hash160hex(SPEND_SECRET)


# deposit
ASSET = "XCP"
NETCODE = "XTN"
DEPOSIT_EXPIRE_TIME = 42
DEPOSIT_SCRIPT = scripts.compile_deposit_script(
    ALICE_PUBKEY, BOB_PUBKEY, SPEND_SECRET_HASH, DEPOSIT_EXPIRE_TIME
)
DEPOSIT_ADDRESS = script_address(DEPOSIT_SCRIPT, NETCODE)
DELAY_TIME = 2


def get_tx(txid):
    return util.api(method="getrawtransaction", params={"tx_hash": txid})


def assert_transferred(payer, payee, quantity):
    assert util.api("mpc_transferred_amount", {"state": payer}) == quantity
    assert util.api("mpc_transferred_amount", {"state": payee}) == quantity


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_usage_xcp(server_db):

    # check initial balances
    alice_balance = util.get_balance(server_db, ALICE_ADDRESS, ASSET)
    deposit_balance = util.get_balance(server_db, DEPOSIT_ADDRESS, ASSET)
    bob_balance = util.get_balance(server_db, BOB_ADDRESS, ASSET)
    assert alice_balance == 91950000000
    assert deposit_balance == 0
    assert bob_balance == 99999990

    # ===== PAYER CREATES DEPOSIT =====

    deposit_quantity = 41
    result = util.api(
        method="mpc_make_deposit",
        params={
            "asset": "XCP",
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": SPEND_SECRET_HASH,
            "expire_time": DEPOSIT_EXPIRE_TIME,  # in blocks
            "quantity": deposit_quantity  # in satoshis
        }
    )
    alice_state = result["state"]
    deposit_rawtx = result["topublish"]
    deposit_rawtx = scripts.sign_deposit(get_tx, ALICE_WIF, result["topublish"])

    # ===== PAYEE SETS DEPOSIT =====

    bob_state = util.api("mpc_set_deposit", {
        "asset": "XCP",
        "deposit_script": DEPOSIT_SCRIPT,
        "expected_payee_pubkey": BOB_PUBKEY,
        "expected_spend_secret_hash": SPEND_SECRET_HASH
    })

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    util_test.insert_raw_transaction(deposit_rawtx, server_db)

    # check balances after send to deposit
    alice_balance = util.get_balance(server_db, ALICE_ADDRESS, ASSET)
    deposit_balance = util.get_balance(server_db, DEPOSIT_ADDRESS, ASSET)
    bob_balance = util.get_balance(server_db, BOB_ADDRESS, ASSET)
    assert alice_balance == 91950000000 - deposit_quantity
    assert deposit_balance == deposit_quantity
    assert bob_balance == 99999990
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
        "delay_time": DELAY_TIME
    })
    alice_state = result["state"]
    commit_script = result["commit_script"]
    commit_rawtx = result["tosign"]["commit_rawtx"]
    deposit_script = result["tosign"]["deposit_script"]
    signed_commit_rawtx = scripts.sign_created_commit(
        get_tx, ALICE_WIF, commit_rawtx, deposit_script
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
        get_tx, BOB_WIF, signed_commit_rawtx, bob_state["deposit_script"]
    )
    util_test.insert_raw_transaction(signed_commit_rawtx, server_db)

    commits = util.api("mpc_published_commits", {"state": alice_state})
    assert commits == [signed_commit_rawtx]

    # check balances after publishing commit
    commit_address = script_address(commit_script, netcode=NETCODE)
    alice_balance = util.get_balance(server_db, ALICE_ADDRESS, ASSET)
    commit_balance = util.get_balance(server_db, commit_address, ASSET)
    bob_balance = util.get_balance(server_db, BOB_ADDRESS, ASSET)
    assert alice_balance == 91950000000 - deposit_quantity
    assert commit_balance == 17
    assert bob_balance == 99999990

    # ===== PAYER RECOVERS REVOKED COMMIT =====

    recoverables = util.api("mpc_recoverables", {"state": alice_state})
    for revoke in recoverables["revoke"]:
        signed_revoke_rawtx = scripts.sign_revoke_recover(
            get_tx, ALICE_WIF, revoke["revoke_rawtx"],
            revoke["commit_script"], revoke["revoke_secret"]
        )
        util_test.insert_raw_transaction(signed_revoke_rawtx, server_db)

    alice_balance = util.get_balance(server_db, ALICE_ADDRESS, ASSET)
    commit_balance = util.get_balance(server_db, commit_address, ASSET)
    bob_balance = util.get_balance(server_db, BOB_ADDRESS, ASSET)
    assert alice_balance == 91950000000 - deposit_quantity + 17  # -change
    assert commit_balance == 0
    assert bob_balance == 99999990


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_usage_btc(server_db):
    pass  # TODO test
