#! /usr/bin/python3

from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test

def test_book(testnet):
    """Reparse all the transactions in the database to see check blockhain's integrity."""
    conftest.DISABLE_ALL_MOCK_PROTOCOL_CHANGES_AT_BLOCK = True
    util_test.reparse(testnet=testnet)
