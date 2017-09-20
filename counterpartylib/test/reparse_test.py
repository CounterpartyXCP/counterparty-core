#! /usr/bin/python3
import tempfile
import pytest

from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib import server
from counterpartylib.lib import (config, check, database)


def test_book(testnet):
    """Reparse all the transactions in the database to see check blockhain's integrity."""
    conftest.DISABLE_ALL_MOCK_PROTOCOL_CHANGES_AT_BLOCK = True
    util_test.reparse(testnet=testnet)
