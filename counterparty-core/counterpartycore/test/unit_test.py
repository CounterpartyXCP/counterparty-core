#! /usr/bin/python3
import tempfile

import pytest

from counterpartycore.lib.parser import check

# this is require near the top to do setup of the test suite
from counterpartycore.test import (
    conftest,
    util_test,
)
from counterpartycore.test.util_test import CURR_DIR

FIXTURE_SQL_FILE = CURR_DIR + "/fixtures/scenarios/unittest_fixture.sql"
FIXTURE_DB = tempfile.gettempdir() + "/fixtures.unittest_fixture.db"


@conftest.add_fn_property(DISABLE_ARC4_MOCKING=True)
@pytest.mark.usefixtures("apiserver")
def test_vector(
    tx_name,
    method,
    inputs,
    outputs,
    error,
    records,
    comment,
    mock_protocol_changes,
    config_context,
    pytest_config,
    server_db,
):
    """Test the outputs of unit test vector. If testing parse, execute the transaction data on test db."""

    with util_test.ConfigContext(**config_context):
        # force unit tests to always run against latest protocol changes
        from counterpartycore.test import conftest

        conftest.ALWAYS_LATEST_PROTOCOL_CHANGES = True
        conftest.ENABLE_MOCK_PROTOCOL_CHANGES_AT_BLOCK = True
        conftest.RANDOM_ASSET_INT = 26**12 + 1

        if tx_name in ["fairminter", "fairmint", "utxo", "attach", "detach"] and method == "parse":
            util_test.insert_transaction(inputs[0], server_db)
            # insert message as 2nd arg
            inputs = inputs[:1] + (inputs[0]["data"][1:],) + inputs[1:]
        elif method == "parse":
            util_test.insert_transaction(inputs[0], server_db)
            if tx_name != "dispense":
                # insert message as 2nd arg
                inputs = inputs[:1] + (inputs[0]["data"][4:],) + inputs[1:]

        util_test.check_outputs(
            tx_name,
            method,
            inputs,
            outputs,
            error,
            records,
            comment,
            mock_protocol_changes,
            pytest_config,
            server_db,
        )
        # dont check asset conservation after direct call to credit or debit
        # and also when canceling a non existent bet match
        if f"{tx_name}.{method}" not in [
            "ledger.events.credit",
            "ledger.events.debit",
            "bet.cancel_bet_match",
        ]:
            check.asset_conservation(server_db)
