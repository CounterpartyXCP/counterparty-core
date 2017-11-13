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
    outputs = ('430eac3b9b17e819bf88a50b24ac72a66c799deaf8c6ac0f9c4e4d0a986d2a74',
               '185dcc70358e8d0eda39eb4be6137bebc8bd3ad244a57a21f278a87e471bedc7',
               '2dc849181471ff73eebec40ebad5e0d60e0a9dce549efcf0cfab2f92e4270628',
               None)
    try:
        assert outputs == test_outputs
    except AssertionError:
        msg = "expected outputs don't match test_outputs:\noutputs=\n" + pprint.pformat(outputs) + "\ntest_outputs=\n" + pprint.pformat(test_outputs)
        raise AssertionError(msg)
