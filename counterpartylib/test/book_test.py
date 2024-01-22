#! /usr/bin/python3

from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test

# TODO: This test is not anymore relevalt. Must be refactored.
def test_book(testnet, block_index):
    # conftest.DISABLE_ALL_MOCK_PROTOCOL_CHANGES_AT_BLOCK = True
    #util_test.reparse(testnet=testnet, block_index=block_index)
    pass