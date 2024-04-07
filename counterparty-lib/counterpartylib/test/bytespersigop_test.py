import binascii
import tempfile

import bitcoin as bitcoinlib

from counterpartylib.lib import ledger, transaction
from counterpartylib.test import util_test
from counterpartylib.test.fixtures.params import ADDR

# this is require near the top to do setup of the test suite
from counterpartylib.test.util_test import CURR_DIR

FIXTURE_SQL_FILE = CURR_DIR + "/fixtures/scenarios/unittest_fixture.sql"
FIXTURE_DB = tempfile.gettempdir() + "/fixtures.unittest_fixture.db"


def test_bytespersigop(server_db):
    assert ledger.enabled("bytespersigop") == False  # noqa: E712

    transaction.initialise()

    # ADDR[0], bytespersigop=False, desc 41 bytes, opreturn
    txhex = transaction.compose_transaction(
        server_db,
        "issuance",
        {
            "source": ADDR[0],
            "asset": "TESTING",
            "quantity": 100,
            "transfer_destination": None,
            "divisible": False,
            "description": "t" * 41,
        },
    )

    tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex))

    assert len(tx.vin) == 1
    assert len(tx.vout) == 2
    assert "OP_RETURN" in repr(tx.vout[0].scriptPubKey)

    # ADDR[0], bytespersigop=False, desc 42 bytes, multisig
    txhex = transaction.compose_transaction(
        server_db,
        "issuance",
        {
            "source": ADDR[0],
            "asset": "TESTING",
            "quantity": 100,
            "transfer_destination": None,
            "divisible": False,
            "description": "t" * 42,
        },
    )

    tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex))

    assert len(tx.vin) == 1
    assert len(tx.vout) == 3
    assert "OP_CHECKMULTISIG" in repr(tx.vout[0].scriptPubKey)
    assert "OP_CHECKMULTISIG" in repr(tx.vout[1].scriptPubKey)

    # enable byterpersigop
    with util_test.MockProtocolChangesContext(bytespersigop=True):
        assert ledger.enabled("bytespersigop") == True  # noqa: E712

        # ADDR[0], bytespersigop=True, desc 41 bytes, opreturn
        txhex = transaction.compose_transaction(
            server_db,
            "issuance",
            {
                "source": ADDR[0],
                "asset": "TESTING",
                "quantity": 100,
                "transfer_destination": None,
                "divisible": False,
                "description": "t" * 41,
            },
        )

        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex))

        assert len(tx.vin) == 1
        assert len(tx.vout) == 2
        assert "OP_RETURN" in repr(tx.vout[0].scriptPubKey)

        # ADDR[1], bytespersigop=True, desc 41 bytes, opreturn encoding
        txhex = transaction.compose_transaction(
            server_db,
            "issuance",
            {
                "source": ADDR[1],
                "asset": "TESTING",
                "quantity": 100,
                "transfer_destination": None,
                "divisible": False,
                "description": "t" * 41,
            },
        )

        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex))

        assert len(tx.vin) == 1
        assert len(tx.vout) == 2
        assert "OP_RETURN" in repr(tx.vout[0].scriptPubKey)

        # ADDR[1], bytespersigop=True, desc 20 bytes, FORCED encoding=multisig
        #  will use 2 UTXOs to make the bytes:sigop ratio in our favor
        txhex = transaction.compose_transaction(
            server_db,
            "issuance",
            {
                "source": ADDR[1],
                "asset": "TESTING",
                "quantity": 100,
                "transfer_destination": None,
                "divisible": False,
                "description": "t" * 20,
            },
            encoding="multisig",
        )

        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex))

        assert len(tx.vin) == 2
        assert len(tx.vout) == 2
        assert "OP_CHECKMULTISIG" in repr(tx.vout[0].scriptPubKey)
