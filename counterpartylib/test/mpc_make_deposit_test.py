import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

# from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP
# from counterpartylib.lib import util
from counterpartylib.lib.micropayments.util import hash160hex
from counterpartylib.lib.micropayments.util import wif2address
from counterpartylib.lib.micropayments.util import wif2pubkey
from counterpartylib.lib.micropayments.util import random_wif


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


ASSET = 'XCP'
ALICE_WIF = DP["addresses"][0][2]
ALICE_ADDRESS = wif2address(ALICE_WIF)
ALICE_PUBKEY = wif2pubkey(ALICE_WIF)
BOB_WIF = random_wif(netcode="XTN")
BOB_ADDRESS = wif2address(BOB_WIF)
BOB_PUBKEY = wif2pubkey(BOB_WIF)

SPEND_SECRET = (
    "7090c90a55489d3272c6edf46b1d391c971aeea5a8cc6755e6174608752c55a9"
)
SPEND_SECRET_HASH = hash160hex(SPEND_SECRET)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_standard_usage_xcp(server_db):
    pass  # TODO test

    # result = util.api(
    #     method="mpc_make_deposit",
    #     params={
    #         "asset": ASSET,
    #         "payer_pubkey": ALICE_PUBKEY,
    #         "payee_pubkey": BOB_PUBKEY,
    #         "spend_secret_hash": SPEND_SECRET_HASH,
    #         "expire_time": 1337,  # in blocks
    #         "quantity": 42  # in satoshis
    #     }
    # )
    # alice_state = result["state"]  # get initial state for alice
    # assert alice_state is not None


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_standard_usage_btc(server_db):
    pass  # TODO test
