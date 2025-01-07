import binascii
import tempfile

import bitcoin as bitcoinlib

from counterpartycore.lib import api, blocks, composer, exceptions, ledger, util  # noqa: F401
from counterpartycore.test import (
    conftest,  # noqa: F401
    util_test,
)
from counterpartycore.test.fixtures.params import ADDR

# this is require near the top to do setup of the test suite
from counterpartycore.test.fixtures.params import DEFAULT_PARAMS as DP  # noqa: F401
from counterpartycore.test.util_test import CURR_DIR

FIXTURE_SQL_FILE = CURR_DIR + "/fixtures/scenarios/unittest_fixture.sql"
FIXTURE_DB = tempfile.gettempdir() + "/fixtures.unittest_fixture.db"


def test_bytespersigop(server_db):
    with util_test.MockProtocolChangesContext(short_tx_type_id=False):
        assert util.enabled("bytespersigop") == False  # noqa: E712

        # ADDR[0], bytespersigop=False, desc 41 bytes, opreturn
        txhex = composer.compose_transaction(
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
            {},
        )

        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex["rawtransaction"]))

        print("test_bytespersigop 4")

        assert len(tx.vin) == 1
        assert len(tx.vout) == 2
        assert "OP_RETURN" in repr(tx.vout[0].scriptPubKey)

        # ADDR[0], bytespersigop=False, desc 42 bytes, multisig
        txhex = composer.compose_transaction(
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
            {},
        )

        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex["rawtransaction"]))

        assert len(tx.vin) == 1
        # assert len(tx.vout) == 3
        assert "OP_CHECKMULTISIG" in repr(tx.vout[0].scriptPubKey)
        assert "OP_CHECKMULTISIG" in repr(tx.vout[1].scriptPubKey)

    # enable byterpersigop
    with util_test.MockProtocolChangesContext(bytespersigop=True):
        assert util.enabled("bytespersigop") == True  # noqa: E712

        # ADDR[0], bytespersigop=True, desc 41 bytes, opreturn
        txhex = composer.compose_transaction(
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
            {},
        )

        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex["rawtransaction"]))

        assert len(tx.vin) == 1
        assert len(tx.vout) == 2
        assert "OP_RETURN" in repr(tx.vout[0].scriptPubKey)

        # ADDR[1], bytespersigop=True, desc 41 bytes, opreturn encoding
        txhex = composer.compose_transaction(
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
            {},
        )

        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex["rawtransaction"]))

        assert len(tx.vin) == 1
        assert len(tx.vout) == 2
        assert "OP_RETURN" in repr(tx.vout[0].scriptPubKey)

        # ADDR[1], bytespersigop=True, desc 20 bytes, FORCED encoding=multisig
        #  will use 2 UTXOs to make the bytes:sigop ratio in our favor
        txhex = composer.compose_transaction(
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
            {"encoding": "multisig"},
        )

        print("rawtransaction: ", txhex["rawtransaction"])
        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex["rawtransaction"]))

        assert len(tx.vin) == 1
        assert len(tx.vout) == 2
        assert "OP_CHECKMULTISIG" in repr(tx.vout[0].scriptPubKey)
