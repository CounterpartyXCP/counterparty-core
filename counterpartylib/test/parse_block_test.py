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
    outputs = ('4a6e1b2952af82fb95c44c8c329e6a9fbb3b611d47857ebdf99941411395f903',
               '2485501fc2131f36666e07ce9d27a0e3605024ff8d1372ddfd810e91bb7aed60',
               'a57d41bf16928a691b151b8318a3c154904d7597e4ea84c81ee05cc9f9c9a6b6',
               None)
    try:
        assert outputs == test_outputs
    except AssertionError:
        msg = "expected outputs don't match test_outputs:\noutputs=\n" + pprint.pformat(outputs) + "\ntest_outputs=\n" + pprint.pformat(test_outputs)
        raise AssertionError(msg)
