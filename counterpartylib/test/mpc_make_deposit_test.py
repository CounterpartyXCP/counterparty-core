import pprint
import tempfile
import pytest
import pycoin
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP, ADDR

from counterpartylib.lib import util


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_alice_bob(server_db):

    result = util.api("mpc_make_deposit", {
        "asset": "XCP",
        "payer_pubkey": DP["addresses"][0][3],
        "payee_pubkey": "0327f017c35a46b759536309e6de256ad44ad609c1c4aed0e2cdb82f62490f75f8",
        "spend_secret_hash": "a7ec62542b0d393d43442aadf8d55f7da1e303cb",
        "expire_time": 5,
        "quantity": 42
    })
