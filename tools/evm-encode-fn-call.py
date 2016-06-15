import json
import os
import re
import shutil
import argparse

import binascii

from counterpartylib import server
from counterpartylib.lib import config
from counterpartylib.lib.evm import abi, ethutils


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument('--debug', dest='debug', default=False, action='store_true')
    parser.add_argument('--abi', dest='abi', required=True)
    parser.add_argument('fn')
    parser.add_argument('args', nargs='+')

    args = parser.parse_args()

    DEBUG = args.debug

    config.TESTNET = True
    config.ADDRESSVERSION = config.ADDRESSVERSION_TESTNET
    config.P2SH_ADDRESSVERSION = config.P2SH_ADDRESSVERSION_TESTNET
    config.BLOCK_FIRST = config.BLOCK_FIRST_TESTNET
    config.BURN_START = config.BURN_START_TESTNET
    config.BURN_END = config.BURN_END_TESTNET
    config.UNSPENDABLE = config.UNSPENDABLE_TESTNET

    translator = abi.ContractTranslator(json.loads(args.abi))
    function_name = args.fn

    assert translator.function_data[function_name]
    description = translator.function_data[function_name]

    assert len(description['encode_types']) == len(args.args), str(args.args) + " != " + str(description['encode_types'])

    data = translator.encode_function_call(function_name, args.args)

    print(binascii.hexlify(data).decode('ascii'))

    if DEBUG:
        function_selector = ethutils.zpad(ethutils.encode_int(description['prefix']), 4)

        if data[:4] == function_selector:
            data = data[4:]
            print(function_name)
            print('data; ', abi.decode_abi(description['encode_types'], data) if data is not None else None)


if __name__ == "__main__":
    main()
