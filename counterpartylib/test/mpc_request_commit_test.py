import json
import pprint
import tempfile
import pytest
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP, ADDR
from counterpartylib.lib import util


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'
FIXTURES = json.load(open(CURR_DIR + "/fixtures/mpc_request_commit.json"))


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_success(server_db):
    result = util.api("mpc_request_commit", FIXTURES["test_success"]["input"])
    assert FIXTURES["test_success"]["output"] == result
