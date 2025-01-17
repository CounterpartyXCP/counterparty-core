#! /usr/bin/python3
import pprint
import tempfile

from counterpartycore.lib.parser import blocks
from counterpartycore.test import (
    conftest,  # noqa: F401
)

# this is require near the top to do setup of the test suite
from counterpartycore.test.fixtures.params import DEFAULT_PARAMS as DP
from counterpartycore.test.util_test import CURR_DIR

FIXTURE_SQL_FILE = CURR_DIR + "/fixtures/scenarios/parseblock_unittest_fixture.sql"
FIXTURE_DB = tempfile.gettempdir() + "/fixtures.parseblock_unittest_fixture.db"


def test_parse_block(server_db):
    test_outputs = blocks.parse_block(server_db, DP["default_block_index"], 1420914478)
    outputs = (
        "5b552bb7df9b51ee288d374c5fafc39dfa9aaad7e3c10773af65925b43027db1",
        "49a36795243e562f8a6444c2f67ed6f1f0394b7b5ef7d63fd1af5ec49312eb6f",
        "691224f734f9bceee86f040342c0724b45252ca581f94b43fb24777cdb1b6496",
    )
    try:
        assert outputs == test_outputs
    except AssertionError:
        msg = (
            "expected outputs don't match test_outputs:\noutputs=\n"
            + pprint.pformat(outputs)
            + "\ntest_outputs=\n"
            + pprint.pformat(test_outputs)
        )
        raise AssertionError(msg)  # noqa: B904
