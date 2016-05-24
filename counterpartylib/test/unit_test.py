#! /usr/bin/python3
import sys, os, time, tempfile
import pytest
import logging
import util_test
from util_test import CURR_DIR
from fixtures.vectors import UNITTEST_VECTOR
from fixtures.params import DEFAULT_PARAMS as DP

from counterpartylib.lib import (config, util, api, database, log)
import server

FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'

@pytest.mark.usefixtures("api_server")
def test_vector(tx_name, method, inputs, outputs, error, records, comment, mock_protocol_changes, server_db):
    """Test the outputs of unit test vector. If testing parse, execute the transaction data on test db."""
    if method == 'parse':
        util_test.insert_transaction(inputs[0], server_db)
        inputs += (inputs[0]['data'][4:],) # message arg
    util_test.check_outputs(tx_name, method, inputs, outputs, error, records, comment, mock_protocol_changes, server_db)

# def test_gen(server_db, rawtransactions_db):
#     """Test cases generator.

#     This snippet generates test cases that can be used to add new tests.
#     You need to customize it to output specific transaction (tx_info) or database changes.
#     Run unit test with -s switch to see the output of print, ie. py.test test/unit_test.py -s.
#     """
#     from counterpartylib.lib import transaction
#     from counterpartylib.lib.messages import bet
#     tx_info = bet.compose(server_db, DP['addresses'][0][0], DP['addresses'][0][0], 0, 1488000000, DP['small'] * 2, DP['small'] * 2, 0.0, 5040, DP['expiration'])
#     print('tx_info')
#     print(tx_info)
#     tx_hex = transaction.construct(server_db, tx_info, encoding='multisig', allow_unconfirmed_inputs=True)
#     print('tx_hex')
#     print(tx_hex)
#     tx = util_test.insert_raw_transaction(tx_hex, server_db, rawtransactions_db)
#     print('tx')
#     print(tx)
#     message = list(server_db.cursor().execute("SELECT * FROM bets WHERE (feed_address=?)", (DP['addresses'][0][0],)))
#     print('database')
#     print(message)
