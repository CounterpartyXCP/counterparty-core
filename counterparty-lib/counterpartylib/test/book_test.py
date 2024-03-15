#! /usr/bin/python3

import pytest

from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test


def test_book(book):
    if book == 'testnet':
        util_test.reparse(testnet=True)
    elif book == 'mainnet':
        util_test.reparse(testnet=False)
    else:
        pytest.skip("Skipping test book")
