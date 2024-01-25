#! /usr/bin/python3

from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test


def test_book(testnet, block_index):
    util_test.reparse(testnet=testnet)
