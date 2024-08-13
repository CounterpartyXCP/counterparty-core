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
        "8ced38ca850aff8538e582703e7e04369f2011c1829857fe4d6f5dc6c2c32960",
        "a3f5a62444e08286f06686d5eb1b6de837a2c7f06020c90a92c5aae69814cf88",
        "8a7b43704c7c8e9e769891071cbee24a8755c3519ec4f7e0c2696986150b97d2",
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
