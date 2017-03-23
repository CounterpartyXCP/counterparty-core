import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.lib import util


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_usage_xcp(server_db, mpcenv):
    try:
        util.api("mpc_set_deposit", {
            "asset": "DEADBEEF",
            "deposit_script": mpcenv["deposit_script"],
            "expected_payee_pubkey": mpcenv["bob_pubkey"],
            "expected_spend_secret_hash": mpcenv["spend_secret_hash"]
        })
        assert False
    except util.RPCError as e:
        assert "AssetDoesNotExist" in str(e)
