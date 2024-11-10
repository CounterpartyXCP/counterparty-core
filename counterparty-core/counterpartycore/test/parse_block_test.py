#! /usr/bin/python3
import pprint
import tempfile

from counterpartycore.lib import blocks
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
        "cb23f8da1133df452987ffae9aecbdf89f4ce7a94aa333a96af866135b86cdda",
        "37cc718b2f137ebf253df3fda8b687f5d62d7ed14a2e12397792eb0db24f220b",
        "113eb9a87efe0e54e97a4eeec1bbd3a17e14f8f25ac97d9daf435f2b6f30372c",
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
