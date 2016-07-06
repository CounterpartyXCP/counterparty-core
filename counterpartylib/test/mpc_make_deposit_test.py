import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

# from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP
from counterpartylib.lib import util
from counterpartylib.lib.micropayments.util import wif2address
from counterpartylib.lib.micropayments.util import wif2pubkey
from counterpartylib.lib.micropayments.util import random_wif
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


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_standard_usage_xcp(server_db):
    pass

    # result = util.api("mpc_make_deposit", {
    #     "asset": ASSET,
    #     "payer_pubkey": ALICE_PUBKEY,
    #     "payee_pubkey": BOB_PUBKEY,
    #     "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
    #     "expire_time": 5,
    #     "quantity": 42
    # })
    # util_test.insert_raw_transaction(result["topublish"], server_db)

    # TODO check after state


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_standard_usage_btc(server_db):
    pass

    # result = util.api("mpc_make_deposit", {
    #     "asset": "BTC",
    #     "payer_pubkey": ALICE_PUBKEY,
    #     "payee_pubkey": BOB_PUBKEY,
    #     "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
    #     "expire_time": 5,
    #     "quantity": 42
    # })
    # util_test.insert_raw_transaction(result["topublish"], server_db)

    # TODO check after state


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_invalid_payer_pubkey(server_db):

    # test pubkey not hex
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": "xyz",
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": 5,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # test > 33 bytes
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": "a" * 68,
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": 5,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # test < 33 bytes
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": "a" * 64,
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": 5,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_invalid_payee_pubkey(server_db):

    # test pubkey not hex
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": "xyz",
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": 5,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # test > 33 bytes
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": "a" * 68,
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": 5,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # test < 33 bytes
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": "a" * 64,
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": 5,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_invalid_spend_secret_hash(server_db):

    # test is hex
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": "xyz",
            "expire_time": 5,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # test < 20 bytes
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": "a" * 38,
            "expire_time": 5,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # test > 20 bytes
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payee_pubkey": "a" * 64,
            "payer_pubkey": ALICE_PUBKEY,
            "spend_secret_hash": "a" * 42,
            "expire_time": 5,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_invalid_expire_time(server_db):

    # non int
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": 5.0,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # < min
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": -1,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # > max
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": 0x0000FFFF + 1,
            "quantity": 42
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_invalid_quantity(server_db):

    # non int
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": 5,
            "quantity": 42.0
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # < min
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": 5,
            "quantity": 0
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type

    # > max
    try:
        util.api("mpc_make_deposit", {
            "asset": ASSET,
            "payer_pubkey": ALICE_PUBKEY,
            "payee_pubkey": BOB_PUBKEY,
            "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
            "expire_time": 5,
            "quantity": 2100000000000001
        })
        assert False
    except RPCError:
        pass  # FIXME check exception type
