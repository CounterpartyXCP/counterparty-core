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
        "79c602bd5c914a042a4f3d2e331c9e2501fcca8eac96a7e592cb29b053144b5c",
        "4d2420cb47ea68ebba1c8180a69f407056172b4529f9a4e72318dc877ce38bf9",
        "7b2dbd57ffef50cf0f135bed993717cbe5c9156f23f7d8579dffacde07198065",
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
