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
    outputs = ('44cf374045f44caf86c7b7de61de3e712f4ba3c39523ab95bc68149ef8aede18',
               '9c2c0940e0a2a8f4c6dde1cfd69efe8e3b467fac0950b385554044ab1f863bf5',
               '2c1fd5d2e7ba3afe702c63fc0b6d0f6582c8061c42e4cee2899def08b454d0ae',
               None)
    try:
        assert outputs == test_outputs
    except AssertionError:
        msg = "expected outputs don't match test_outputs:\noutputs=\n" + pprint.pformat(outputs) + "\ntest_outputs=\n" + pprint.pformat(test_outputs)
        raise AssertionError(msg)
