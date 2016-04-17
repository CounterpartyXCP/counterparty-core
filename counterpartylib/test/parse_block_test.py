#! /usr/bin/python3
import pprint
import sys, os, time, tempfile
import pytest
from counterpartylib.test import util_test
from counterpartylib.test.fixtures.params import DEFAULT_PARAMS as DP
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (config, util, database, blocks)
from counterpartylib import server


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/parseblock_unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.parseblock_unittest_fixture.db'


def test_parse_block(server_db):
    test_outputs = blocks.parse_block(server_db, DP['default_block_index'], 1420914478)
    outputs = ('38c0ad27bd451c18f326680d7f29c7fe98b06a1d2576ca0460dbe4a5a08d4116',
               '414ca3fd9fad5153c5a9d94be9c8b8cd4f78f32b1c1058fc547a22d8a8814793',
               '61d38990c5d25491bfde36f93441b9d788e35a8cd302e147973411580d4a3411',
               None)

    try:
        assert outputs == test_outputs
    except AssertionError:
        msg = "expected outputs don't match test_outputs:\noutputs=\n" + pprint.pformat(outputs) + "\ntest_outputs=\n" + pprint.pformat(test_outputs)
        raise AssertionError(msg)
