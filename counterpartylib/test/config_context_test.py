#! /usr/bin/python3
import pprint
import tempfile
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.fixtures.params import DEFAULT_PARAMS as DP
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (blocks, config)


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/parseblock_unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.parseblock_unittest_fixture.db'


def test_parse_block(cp_server):
    assert config.BTC_NAME == "Bitcoin"

    with util_test.ConfigContext(BTC_NAME="Bitcoin Testing"):
        assert config.BTC_NAME == "Bitcoin Testing"

        with util_test.ConfigContext(BTC_NAME="Bitcoin Testing Testing"):
            assert config.BTC_NAME == "Bitcoin Testing Testing"

        assert config.BTC_NAME == "Bitcoin Testing"

    assert config.BTC_NAME == "Bitcoin"
