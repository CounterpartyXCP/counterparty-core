import tempfile
import pytest
import os

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP

from counterpartylib.lib import util

from micropayment_core.keys import address_from_wif
from micropayment_core.keys import pubkey_from_wif
from micropayment_core.util import script_address
from micropayment_core.util import hash160hex
from micropayment_core import scripts
from micropayment_core.util import b2h


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


ALICE_WIF = DP["addresses"][0][2]
ALICE_ADDRESS = address_from_wif(ALICE_WIF)
ALICE_PUBKEY = pubkey_from_wif(ALICE_WIF)
BOB_WIF = DP["addresses"][1][2]
BOB_ADDRESS = address_from_wif(BOB_WIF)
BOB_PUBKEY = pubkey_from_wif(BOB_WIF)

REVOKE_SECRET = (
    "7090c90a55489d3272c6edf46b1d391c971aeea5a8cc6755e6174608752c55a9"
)
REVOKE_SECRET_HASH = hash160hex(REVOKE_SECRET)
SPEND_SECRET_HASH = "a7ec62542b0d393d43442aadf8d55f7da1e303cb"


# deposit
ASSET = "XCP"
NETCODE = "XTN"
DEPOSIT_EXPIRE_TIME = 42
DEPOSIT_SCRIPT = scripts.compile_deposit_script(
    ALICE_PUBKEY, BOB_PUBKEY, SPEND_SECRET_HASH, DEPOSIT_EXPIRE_TIME
)
DEPOSIT_ADDRESS = script_address(DEPOSIT_SCRIPT, NETCODE)
DELAY_TIME = 2


def assert_transferred(payer, payee, quantity):
    assert util.api("mpc_transferred_amount", {"state": payer}) == quantity
    assert util.api("mpc_transferred_amount", {"state": payee}) == quantity


def get_tx(txid):
    return util.api(method="getrawtransaction", params={"tx_hash": txid})


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_ignores_unconfirmed_funds(server_db):

    # check initial balances
    alice_balance = util.get_balance(server_db, ALICE_ADDRESS, ASSET)
    deposit_balance = util.get_balance(server_db, DEPOSIT_ADDRESS, ASSET)
    bob_balance = util.get_balance(server_db, BOB_ADDRESS, ASSET)
    assert alice_balance == 91950000000
    assert deposit_balance == 0
    assert bob_balance == 99999990

    # ===== PAYER CREATES DEPOSIT TX =====

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
            "delay_time": DELAY_TIME
        })

        assert False
    except util.RPCError as e:
        assert "InvalidTransferQuantity" in str(e)
