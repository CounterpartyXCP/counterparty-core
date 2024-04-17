#! /usr/bin/python3
import pprint  # noqa: F401
import tempfile

from counterpartycore.lib import blocks, config, ledger  # noqa: F401
from counterpartycore.test import (
    conftest,  # noqa: F401
    util_test,
)

# this is require near the top to do setup of the test suite
from counterpartycore.test.fixtures.params import DEFAULT_PARAMS as DP  # noqa: F401
from counterpartycore.test.util_test import CURR_DIR

FIXTURE_SQL_FILE = CURR_DIR + "/fixtures/scenarios/parseblock_unittest_fixture.sql"
FIXTURE_DB = tempfile.gettempdir() + "/fixtures.parseblock_unittest_fixture.db"


def test_config_context(cp_server):
    assert config.BTC_NAME == "Bitcoin"

    with util_test.ConfigContext(BTC_NAME="Bitcoin Testing"):
        assert config.BTC_NAME == "Bitcoin Testing"

        with util_test.ConfigContext(BTC_NAME="Bitcoin Testing Testing"):
            assert config.BTC_NAME == "Bitcoin Testing Testing"

        assert config.BTC_NAME == "Bitcoin Testing"

    assert config.BTC_NAME == "Bitcoin"


def test_mock_protocol_changes(cp_server):
    assert ledger.enabled("multisig_addresses") == True  # noqa: E712

    with util_test.MockProtocolChangesContext(multisig_addresses=False):
        assert ledger.enabled("multisig_addresses") == False  # noqa: E712

        with util_test.MockProtocolChangesContext(multisig_addresses=None):
            assert ledger.enabled("multisig_addresses") == None  # noqa: E711

        assert ledger.enabled("multisig_addresses") == False  # noqa: E712

    assert ledger.enabled("multisig_addresses") == True  # noqa: E712
