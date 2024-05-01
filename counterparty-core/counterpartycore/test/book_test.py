import pytest

# this is require near the top to do setup of the test suite
from counterpartycore.test import (
    conftest,  # noqa: F401
    util_test,
)


def test_book(skip):
    if skip:
        pytest.skip("Skipping test book")
    else:
        util_test.reparse(testnet=True)
