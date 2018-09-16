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
    #outputs = ('284bc9bc8eab4857c068d76df243799ae1604a36cdacb30cd0fa2cf85747ddca',
    #           '728f5a1d3d983b2f4b37df57b3a7ba6192bb89971022114d27dd19ae845352ef',
    #           '29f8edf6d3548b2e3f6fd90303fa5a72e0189d7e1f11fbc3d211eb3a17701962',
    outputs = ('430eac3b9b17e819bf88a50b24ac72a66c799deaf8c6ac0f9c4e4d0a986d2a74',
               'bc61e5fbb427b302a05e06a03929d8b9717f11468666fcda00533cd8aecbba03',
               '4938394e40cd7584bf2f5033c8013b19d3c83af07caddb6595a88c1954dc85d9',
               None)
    try:
        assert outputs == test_outputs
    except AssertionError:
        msg = "expected outputs don't match test_outputs:\noutputs=\n" + pprint.pformat(outputs) + "\ntest_outputs=\n" + pprint.pformat(test_outputs)
        raise AssertionError(msg)
