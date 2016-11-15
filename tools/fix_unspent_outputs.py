#!/usr/bin/python3

import sys
import os
import re
import shutil
import pprint
import bitcoin as bitcoinlib
import binascii
import json

from decimal import Decimal


class FakeFloat(float):
    def __init__(self, value):
        self._value = value

    def __repr__(self):
        return str(self._value)


def defaultencode(o):
    if isinstance(o, Decimal):
        # Subclass float with custom repr?
        return FakeFloat(o)
    raise TypeError(repr(o) + " is not JSON serializable")


# the CURR_DIR from the util_test.py
CURR_DIR = "counterpartylib/test"


def test_strip_inputs():
    """
    loop over all TXs in unspent_outputs.json and strip out the inputs and then replace unspent_outputs.json with updated version
    """
    bitcoinlib.SelectParams('testnet')
    with open(CURR_DIR + '/fixtures/unspent_outputs.json', 'r') as listunspent_test_file:
        wallet_unspent = json.load(listunspent_test_file)

        for output in wallet_unspent:
            tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(output['txhex']))
            tx = bitcoinlib.core.CMutableTransaction.from_tx(tx)

            tx.vin = []

            output['txhex'] = bitcoinlib.core.b2x(tx.serialize())

            output['amount'] = Decimal(output['amount'])

    with open(CURR_DIR + '/fixtures/unspent_outputs.json', 'w') as listunspent_test_file:
        listunspent_test_file.write(json.dumps(wallet_unspent, indent=4, default=defaultencode, sort_keys=True))


def test_create_coinbases():
    """
    alternative solution: create 'coinbase' TXs that are being spend from
    """
    bitcoinlib.SelectParams('testnet')
    with open(CURR_DIR + '/fixtures/unspent_outputs.json', 'r') as listunspent_test_file:
        wallet_unspent = json.load(listunspent_test_file)

        utxos = {}

        for output in wallet_unspent:
            utxos.setdefault(output['txid'], {})
            utxos[output['txid']][output['vout']] = int(output['amount'] * 1e8)

        for txid, outputs in utxos.items():
            vout = []
            for idx in range(0, max(outputs.keys())+1):
                value = outputs[idx] if idx in outputs else 0
                scriptPubKey = bitcoinlib.core.CScript(b'')

                vout.append(bitcoinlib.core.CTxOut(nValue=value, scriptPubKey=scriptPubKey))

            coinbasetx = bitcoinlib.core.CMutableTransaction(vin=[], vout=vout)


            print(bitcoinlib.core.b2x(coinbasetx.serialize()))


if __name__ == "__main__":
    test_strip_inputs()
