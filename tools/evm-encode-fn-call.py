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
    function_args = args.args

    assert translator.function_data[function_name]
    description = translator.function_data[function_name]

    assert len(description['encode_types']) == len(function_args), str(function_args) + " != " + str(description['encode_types'])

    # cast ints to int() to avoid funky shit
    for i, arg in enumerate(function_args):
        if description['encode_types'][i].startswith('int') or description['encode_types'][i].startswith('uint'):
            function_args[i] = int(arg)

    data = translator.encode_function_call(function_name, function_args)

    print(binascii.hexlify(data).decode('ascii'))

    if DEBUG:
        function_selector = ethutils.zpad(ethutils.encode_int(description['prefix']), 4)

        if data[:4] == function_selector:
            data = data[4:]
            print(function_name)
            print('data; ', abi.decode_abi(description['encode_types'], data) if data is not None else None)


if __name__ == "__main__":
    main()
