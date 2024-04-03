#! /usr/bin/python3
import pprint
import tempfile

from counterpartylib.lib import blocks, config, ledger
from counterpartylib.test import (
    conftest,
    util_test,
)

# this is require near the top to do setup of the test suite
from counterpartylib.test.fixtures.params import DEFAULT_PARAMS as DP
from counterpartylib.test.util_test import CURR_DIR

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
    assert ledger.enabled("multisig_addresses") == True

    with util_test.MockProtocolChangesContext(multisig_addresses=False):
        assert ledger.enabled("multisig_addresses") == False

        with util_test.MockProtocolChangesContext(multisig_addresses=None):
            assert ledger.enabled("multisig_addresses") == None

        assert ledger.enabled("multisig_addresses") == False

    assert ledger.enabled("multisig_addresses") == True
