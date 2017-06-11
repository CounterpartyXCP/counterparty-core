#! /usr/bin/python3
import pytest
import binascii
from io import BytesIO
import bitcoin
import tempfile

from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (config, transaction)
from counterpartylib.lib.messages import send


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/parseblock_unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.parseblock_unittest_fixture.db'
FIXTURE_OPTIONS = {
    'utxo_locks_max_addresses': 2000
}


def setup_function(function):
    transaction.UTXO_LOCKS = None  # reset UTXO_LOCKS


def construct_tx(db, source, destination, disable_utxo_locks=False, custom_inputs=None):
    tx_info = send.compose(db, source, destination, config.XCP, 1)
    return transaction.construct(db, tx_info, disable_utxo_locks=disable_utxo_locks, custom_inputs=custom_inputs)


def test_utxolocks(server_db):
    """it shouldn't use the same UTXO"""
    tx1hex = construct_tx(server_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns")
    tx2hex = construct_tx(server_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns")

    tx1f = BytesIO(binascii.unhexlify(tx1hex))
    tx1 = bitcoin.core.CTransaction.stream_deserialize(tx1f)

    tx2f = BytesIO(binascii.unhexlify(tx2hex))
    tx2 = bitcoin.core.CTransaction.stream_deserialize(tx2f)

    assert (tx1.vin[0].prevout.hash, tx1.vin[0].prevout.n) != (tx2.vin[0].prevout.hash, tx2.vin[0].prevout.n)


def test_utxolocks_custom_input(server_db):
    """it should use the same UTXO"""
    custom_inputs = [{
        'txid': 'b9fc3aa355b77ecb63282fc96e63912a253e98bf9cf441fbfbecc3fb277c4985',
        'txhex': '0100000003114bbc2ce4f18490cd33fa17ad747f2cbb932fe4bd628e7729f18e73caa9c824000000006b4830450220170594244dacb99013340f07ca7da05c91d2f235094481213abf3b3648ff12ab022100ea612f4326e074daeb3f3b92bce7862c7377d16e66930415cb33930e773d8600012103bdd82e7398e604438316511b7be56925256b5b1f64b508432f4b4e3e728db637ffffffff22fcc4468552b950781e3facbf75a27b8d633cb7299f02b4bcc3615d9923bcfb000000006b483045022051ed13a5bf5e9ea753f0b2e4e76d1bea73de912e214314ed96e043ad21f53dee022100f6556d547c5012fcbd3348f71da8fe03eb101f73b7b1b366e3937119cc87a90c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffe5237334401359af1cc80b3b4af969fab42e92e636ef0523df6b68122f23d952000000006b483045022100cd74fe9ca13e44607521f410468979ed9e0b3addef2a9d48e08bf608d72c446c022058753f930f2d394410c3e6e950788e6b0371d4403ef5a9dc194980218de5ac76012102ab7a70956655c4d4cc44b73587ae70a21ab0db9ba8d704b97d911ea3bf1e5d67ffffffff02ffb3a900000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac0065cd1d000000001976a914d1ba3ba3d6f5ad06b148bcc04151ecab84fc397988ac00000000',
        'amount': 0.11121663,
        'vout': 0,
        'confirmations': 74,
        'scriptPubKey': '76a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac',
        'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'
    }]

    tx1hex = construct_tx(server_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", custom_inputs=custom_inputs)
    tx2hex = construct_tx(server_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", custom_inputs=custom_inputs)

    tx1f = BytesIO(binascii.unhexlify(tx1hex))
    tx1 = bitcoin.core.CTransaction.stream_deserialize(tx1f)

    tx2f = BytesIO(binascii.unhexlify(tx2hex))
    tx2 = bitcoin.core.CTransaction.stream_deserialize(tx2f)

    assert (tx1.vin[0].prevout.hash, tx1.vin[0].prevout.n) == (tx2.vin[0].prevout.hash, tx2.vin[0].prevout.n)


def test_disable_utxolocks(server_db):
    """with `disable_utxo_locks=True` it should use the same UTXO"""
    tx1hex = construct_tx(server_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", disable_utxo_locks=True)
    tx2hex = construct_tx(server_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", disable_utxo_locks=True)

    tx1f = BytesIO(binascii.unhexlify(tx1hex))
    tx1 = bitcoin.core.CTransaction.stream_deserialize(tx1f)

    tx2f = BytesIO(binascii.unhexlify(tx2hex))
    tx2 = bitcoin.core.CTransaction.stream_deserialize(tx2f)

    assert (tx1.vin[0].prevout.hash, tx1.vin[0].prevout.n) == (tx2.vin[0].prevout.hash, tx2.vin[0].prevout.n)
