#! /usr/bin/python3
import pytest
import binascii
from io import BytesIO
import bitcoin
import tempfile

from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (transaction)
from counterpartylib.lib.messages import send


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/parseblock_unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.parseblock_unittest_fixture.db'
FIXTURE_OPTIONS = {
    'utxo_locks_max_addresses': 2000
}


def setup_function(function):
    transaction.UTXO_LOCKS = None  # reset UTXO_LOCKS


def construct_tx(db, source, destination, disable_utxo_locks=False):
    tx_info = send.compose(db, source, destination, 'XCP', 1)
    return transaction.construct(db, tx_info, disable_utxo_locks=disable_utxo_locks)


def test_utxolocks(server_db):
    """it shouldn't use the same UTXO"""
    tx1hex = construct_tx(server_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns")
    tx2hex = construct_tx(server_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns")

    tx1f = BytesIO(binascii.unhexlify(tx1hex))
    tx1 = bitcoin.core.CTransaction.stream_deserialize(tx1f)

    tx2f = BytesIO(binascii.unhexlify(tx2hex))
    tx2 = bitcoin.core.CTransaction.stream_deserialize(tx2f)

    assert (tx1.vin[0].prevout.hash, tx1.vin[0].prevout.n) != (tx2.vin[0].prevout.hash, tx2.vin[0].prevout.n)


def test_disable_utxolocks(server_db):
    """with `disable_utxo_locks=True` it should use the same UTXO"""
    tx1hex = construct_tx(server_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", disable_utxo_locks=True)
    tx2hex = construct_tx(server_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", disable_utxo_locks=True)

    tx1f = BytesIO(binascii.unhexlify(tx1hex))
    tx1 = bitcoin.core.CTransaction.stream_deserialize(tx1f)

    tx2f = BytesIO(binascii.unhexlify(tx2hex))
    tx2 = bitcoin.core.CTransaction.stream_deserialize(tx2f)

    assert (tx1.vin[0].prevout.hash, tx1.vin[0].prevout.n) == (tx2.vin[0].prevout.hash, tx2.vin[0].prevout.n)
