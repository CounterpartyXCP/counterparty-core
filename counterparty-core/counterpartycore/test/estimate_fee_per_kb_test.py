#! /usr/bin/python3
import binascii
import tempfile

import bitcoin as bitcoinlib

from counterpartycore.lib import backend, transaction
from counterpartycore.test import (
    util_test,
)
from counterpartycore.test.fixtures.params import ADDR

# this is require near the top to do setup of the test suite
from counterpartycore.test.fixtures.params import DEFAULT_PARAMS as DP  # noqa: F401
from counterpartycore.test.util_test import CURR_DIR

FIXTURE_SQL_FILE = CURR_DIR + "/fixtures/scenarios/unittest_fixture.sql"
FIXTURE_DB = tempfile.gettempdir() + "/fixtures.unittest_fixture.db"


def pytest_generate_tests(metafunc):
    metafunc.parametrize(
        (
            "fee_per_kb",
            "fee_per_kb_used",
        ),
        [(10000, 25000), (25000, None), (35000, None), (50000, None), (100000, None)],
    )


def test_estimate_fee_per_kb(fee_per_kb, fee_per_kb_used, server_db, monkeypatch):
    def _fee_per_kb(conf_target, mode):
        return fee_per_kb

    monkeypatch.setattr("counterpartycore.lib.backend.fee_per_kb", _fee_per_kb)

    utxos = dict(
        ((utxo["txid"], utxo["vout"]), utxo) for utxo in backend.get_unspent_txouts(ADDR[0])
    )

    with util_test.ConfigContext(ESTIMATE_FEE_PER_KB=True):
        transaction.initialise()

        txhex = transaction.compose_transaction(
            server_db,
            "send",
            {"source": ADDR[0], "destination": ADDR[1], "asset": "XCP", "quantity": 100},
        )

        pretx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(txhex))
        sumvin = sum(
            [
                int(utxos[(bitcoinlib.core.b2lx(vin.prevout.hash), vin.prevout.n)]["amount"] * 1e8)
                for vin in pretx.vin
            ]
        )
        sumvout = sum([vout.nValue for vout in pretx.vout])
        unsignedsize = 183
        signedsize = 263

        fee = int((signedsize / 1000) * (fee_per_kb_used or fee_per_kb))

        assert len(txhex) / 2 == unsignedsize
        assert sumvin == 199909140
        assert sumvout < sumvin
        assert sumvout == sumvin - fee
