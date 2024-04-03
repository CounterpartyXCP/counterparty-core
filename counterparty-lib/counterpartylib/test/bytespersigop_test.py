import pprint
import pytest
import tempfile
import bitcoin as bitcoinlib
import binascii
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.fixtures.params import DEFAULT_PARAMS as DP, ADDR
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test import util_test

from counterpartylib.lib import (blocks, transaction, api, ledger, util, exceptions)


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


def test_bytespersigop(server_db):
    assert ledger.enabled('bytespersigop') == False

    # ADDR[0], bytespersigop=False, desc 41 bytes, opreturn
    txhex = api.compose_transaction(
        server_db, 'issuance',
        {'source': ADDR[0],
         'asset': 'TESTING',
         'quantity': 100,
         'transfer_destination': None,
         'divisible': False,
         'description': 't' * 41},
    )

    tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex))

    assert len(tx.vin) == 1
    assert len(tx.vout) == 2
    assert "OP_RETURN" in repr(tx.vout[0].scriptPubKey)

    # ADDR[0], bytespersigop=False, desc 42 bytes, multisig
    txhex = api.compose_transaction(
        server_db, 'issuance',
        {'source': ADDR[0],
         'asset': 'TESTING',
         'quantity': 100,
         'transfer_destination': None,
         'divisible': False,
         'description': 't' * 42},
    )

    tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex))

    assert len(tx.vin) == 1
    assert len(tx.vout) == 3
    assert "OP_CHECKMULTISIG" in repr(tx.vout[0].scriptPubKey)
    assert "OP_CHECKMULTISIG" in repr(tx.vout[1].scriptPubKey)

    # enable byterpersigop
    with util_test.MockProtocolChangesContext(bytespersigop=True):
        assert ledger.enabled('bytespersigop') == True

        # ADDR[0], bytespersigop=True, desc 41 bytes, opreturn
        txhex = api.compose_transaction(
            server_db, 'issuance',
            {'source': ADDR[0],
             'asset': 'TESTING',
             'quantity': 100,
             'transfer_destination': None,
             'divisible': False,
             'description': 't' * 41},
        )

        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex))

        assert len(tx.vin) == 1
        assert len(tx.vout) == 2
        assert "OP_RETURN" in repr(tx.vout[0].scriptPubKey)

        # ADDR[1], bytespersigop=True, desc 41 bytes, opreturn encoding
        txhex = api.compose_transaction(
            server_db, 'issuance',
            {'source': ADDR[1],
             'asset': 'TESTING',
             'quantity': 100,
             'transfer_destination': None,
             'divisible': False,
             'description': 't' * 41},
        )

        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex))

        assert len(tx.vin) == 1
        assert len(tx.vout) == 2
        assert "OP_RETURN" in repr(tx.vout[0].scriptPubKey)

        # ADDR[1], bytespersigop=True, desc 20 bytes, FORCED encoding=multisig
        #  will use 2 UTXOs to make the bytes:sigop ratio in our favor
        txhex = api.compose_transaction(
            server_db, 'issuance',
            {'source': ADDR[1],
             'asset': 'TESTING',
             'quantity': 100,
             'transfer_destination': None,
             'divisible': False,
             'description': 't' * 20},
            encoding='multisig'
        )

        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex))

        assert len(tx.vin) == 2
        assert len(tx.vout) == 2
        assert "OP_CHECKMULTISIG" in repr(tx.vout[0].scriptPubKey)
