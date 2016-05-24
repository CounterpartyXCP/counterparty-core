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
    outputs = ('9e1ec54f5520d25ad9decae20d9c0f67d06aa9f79dabc18707665f0c176240e7',
               '78911312b8c15e6e35a0b20ebbd3e8016bf3b64c85ce71b71621d969cd01845c',
               'b98726b098009f21e8d9628bef4955d1224d4ccc523fec26c1683a8ea865ad0a',
               None)

    try:
        assert outputs == test_outputs
    except AssertionError:
        msg = "expected outputs don't match test_outputs:\noutputs=\n" + pprint.pformat(outputs) + "\ntest_outputs=\n" + pprint.pformat(test_outputs)
        raise AssertionError(msg)
