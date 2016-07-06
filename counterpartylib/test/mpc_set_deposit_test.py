import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

# from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP

from counterpartylib.lib import util

from counterpartylib.lib.micropayments.util import wif2address
from counterpartylib.lib.micropayments.util import b2h
from counterpartylib.lib.micropayments.util import wif2pubkey
from counterpartylib.lib.micropayments.util import random_wif
from counterpartylib.lib.micropayments.scripts import compile_deposit_script
from counterpartylib.lib.micropayments.util import script2address
from counterpartylib.lib.util import RPCError


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


ASSET = 'XCP'
ALICE_WIF = DP["addresses"][0][2]
ALICE_ADDRESS = wif2address(ALICE_WIF)
ALICE_PUBKEY = wif2pubkey(ALICE_WIF)
BOB_WIF = random_wif(netcode="XTN")
BOB_ADDRESS = wif2address(BOB_WIF)
BOB_PUBKEY = wif2pubkey(BOB_WIF)
SPEND_SECRET_HASH = "a7ec62542b0d393d43442aadf8d55f7da1e303cb"
DEPOSIT_SCRIPT = compile_deposit_script(
    ALICE_PUBKEY, BOB_PUBKEY, SPEND_SECRET_HASH, 42
)
DEPOSIT_ADDRESS = script2address(DEPOSIT_SCRIPT, "XTN")


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_standard_usage_xcp(server_db):

    state = util.api("mpc_set_deposit", {
        "asset": ASSET,
        "deposit_script": b2h(DEPOSIT_SCRIPT),
        "expected_payee_pubkey": BOB_PUBKEY,
        "expected_spend_secret_hash": SPEND_SECRET_HASH
    })

    assert state == {
        "asset": ASSET,
        'deposit_script': b2h(DEPOSIT_SCRIPT),
        'commits_active': [],
        'commits_requested': [],
        'commits_revoked': []
    }


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_standard_usage_btc(server_db):
    pass  # FIXME test


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_invalid_expected_payee_pubkey(server_db):

    # test pubkey not hex
    try:
        util.api("mpc_set_deposit", {
            "asset": ASSET,
            "deposit_script": b2h(DEPOSIT_SCRIPT),
            "expected_payee_pubkey": "xyz",
            "expected_spend_secret_hash": SPEND_SECRET_HASH
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # test > 33 bytes
    try:
        util.api("mpc_set_deposit", {
            "asset": ASSET,
            "deposit_script": b2h(DEPOSIT_SCRIPT),
            "expected_payee_pubkey": "a" * 68,
            "expected_spend_secret_hash": SPEND_SECRET_HASH
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # test < 33 bytes
    try:
        util.api("mpc_set_deposit", {
            "asset": ASSET,
            "deposit_script": b2h(DEPOSIT_SCRIPT),
            "expected_payee_pubkey": "a" * 64,
            "expected_spend_secret_hash": SPEND_SECRET_HASH
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_invalid_expected_spend_secret_hash(server_db):

    # test is hex
    try:
        util.api("mpc_set_deposit", {
            "asset": ASSET,
            "deposit_script": b2h(DEPOSIT_SCRIPT),
            "expected_payee_pubkey": BOB_PUBKEY,
            "expected_spend_secret_hash": "xyz"
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # test < 20 bytes
    try:
        util.api("mpc_set_deposit", {
            "asset": ASSET,
            "deposit_script": b2h(DEPOSIT_SCRIPT),
            "expected_payee_pubkey": BOB_PUBKEY,
            "expected_spend_secret_hash": "a" * 38
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # test > 20 bytes
    try:
        util.api("mpc_set_deposit", {
            "asset": ASSET,
            "deposit_script": b2h(DEPOSIT_SCRIPT),
            "expected_payee_pubkey": BOB_PUBKEY,
            "expected_spend_secret_hash": "a" * 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_invalid_deposit_script(server_db):
    pass

    # spend secret missmatch
    try:
        util.api("mpc_set_deposit", {
            "asset": ASSET,
            "deposit_script": b2h(DEPOSIT_SCRIPT),
            "expected_payee_pubkey": BOB_PUBKEY,
            "expected_spend_secret_hash": "a" * 40
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # payee pubkey missmatch
    try:
        util.api("mpc_set_deposit", {
            "asset": ASSET,
            "deposit_script": b2h(DEPOSIT_SCRIPT),
            "expected_payee_pubkey": ALICE_PUBKEY,
            "expected_spend_secret_hash": SPEND_SECRET_HASH
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # FIXME opcode missmatch
