#! /usr/bin/python3

import pytest

from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test


def test_book(skip):
    print("Skip: ", skip)
    if skip:
        pytest.skip("Skipping test book")
    else:
        util_test.reparse(testnet=True)
