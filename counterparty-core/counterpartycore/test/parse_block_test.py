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
        "71a6242235f8da85884c791cc19456e361fb1bf97cdedf5f8282fc2591ce87a9",
        "b93a5d05ff00ae3eb2bf6af50b038c2d14c70242ca13515f3524a4b1d916f842",
        "894a2abadbe841968597b8fba3d76b042509873981182005f483b113d8a2c26f",
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
