#! /usr/bin/python3
import tempfile
import pytest
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR

FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'

@pytest.mark.usefixtures("api_server")
def test_vector(tx_name, method, inputs, outputs, error, records, comment, mock_protocol_changes, server_db):
    """Test the outputs of unit test vector. If testing parse, execute the transaction data on test db."""

    # force unit tests to always run against latest protocol changes
    from counterpartylib.test import conftest
    conftest.ALWAYS_LATEST_PROTOCOL_CHANGES = True

    if method == 'parse':
        util_test.insert_transaction(inputs[0], server_db)
        inputs += (inputs[0]['data'][4:],) # message arg
    util_test.check_outputs(tx_name, method, inputs, outputs, error, records, comment, mock_protocol_changes, server_db)
