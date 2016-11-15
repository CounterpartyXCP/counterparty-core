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


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_expire_recover_xcp(server_db):

    # check initial balances
    alice_balance = util.get_balance(server_db, ALICE_ADDRESS, ASSET)
    deposit_balance = util.get_balance(server_db, DEPOSIT_ADDRESS, ASSET)
    assert alice_balance == 91950000000
    assert deposit_balance == 0

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
    deposit_rawtx = scripts.sign_deposit(get_tx, ALICE_WIF, result["topublish"])

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    util_test.insert_raw_transaction(deposit_rawtx, server_db)

    # check funds moved to deposit p2sh address
    alice_balance = util.get_balance(server_db, ALICE_ADDRESS, ASSET)
    deposit_balance = util.get_balance(server_db, DEPOSIT_ADDRESS, ASSET)
    assert alice_balance == 91950000000 - deposit_quantity
    assert deposit_balance == deposit_quantity

    assert util.api("mpc_deposit_ttl", {"state": alice_state}) == 41

    # ===== LET DEPOSIT EXPIRE =====

    # create blocks until deposit expired
    while util.api("mpc_deposit_ttl", {"state": alice_state}) > 0:
        recoverables = util.api("mpc_recoverables", {"state": alice_state})
        assert(len(recoverables["expire"]) == 0)
        util_test.create_next_block(server_db)

    # ===== PAYER RECOVERS EXPIRED DEPOSIT =====

    # sign and publish expire recover transaction
    recoverables = util.api("mpc_recoverables", {"state": alice_state})
    for expire in recoverables["expire"]:
        signed_expire_rawtx = scripts.sign_expire_recover(
            get_tx, ALICE_WIF, expire["expire_rawtx"], expire["deposit_script"]
        )
        util_test.insert_raw_transaction(signed_expire_rawtx, server_db)

    # ckech funds recovered from deposit p2sh address
    alice_balance = util.get_balance(server_db, ALICE_ADDRESS, ASSET)
    deposit_balance = util.get_balance(server_db, DEPOSIT_ADDRESS, ASSET)
    assert alice_balance == 91950000000
    assert deposit_balance == 0

    # deposit p2sh should have two transaction (fund and expire recover)
    deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": DEPOSIT_ADDRESS, "unconfirmed": False}
    )
    assert len(deposit_transactions) == 2


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_expire_recover_btc(server_db):
    pass  # TODO test
