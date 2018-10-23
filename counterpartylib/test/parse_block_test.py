#! /usr/bin/python3
import pprint
import tempfile
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.fixtures.params import DEFAULT_PARAMS as DP
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (blocks)


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/parseblock_unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.parseblock_unittest_fixture.db'


def test_parse_block(server_db):
    test_outputs = blocks.parse_block(server_db, DP['default_block_index'], 1420914478)
    outputs = ('8fd6e608405de90b1da9f1f2b17578eb2ab736ec54716558ad4a8b63987d5b91',
               'a825bc3f82fd92c142c818ed8ebc1e660eb39f9c0e7f6e188a35c06b2fb7dcb2',
               '66cd5bdbf6c9c343258ed2cdf9c7fb6e4360bf74169e30aa6835e919a70a54ef',
               None)
    try:
        assert outputs == test_outputs
    except AssertionError:
        msg = "expected outputs don't match test_outputs:\noutputs=\n" + pprint.pformat(outputs) + "\ntest_outputs=\n" + pprint.pformat(test_outputs)
        raise AssertionError(msg)
