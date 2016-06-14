import json
import os
import time
import logging
import serpent
from counterpartylib.lib import (util, config, database, log)
from counterpartylib.lib.messages import execute
from counterpartylib.lib import blocks, script
from counterpartylib.lib.evm import (blocks as ethblocks, processblock, abi, opcodes, transactions)
from counterpartylib.lib.evm.address import Address
import subprocess
import binascii
import rlp
from rlp.utils import decode_hex, encode_hex, ascii_chr
from counterpartylib.test.fixtures.params import ADDR, MULTISIGADDR, DEFAULT_PARAMS as DP
from counterpartylib.lib.evm import solidity

from counterpartylib.test import util_test

# setup aliases so we don't have to change the original tests
a0 = ADDR[0]
a1 = ADDR[1]
a2 = ADDR[3]  # IMPORTANT!! we skipped ADDR[2] because it has no balance
a3 = ADDR[4]
a4 = ADDR[5]
a5 = ADDR[6]

# we never use the privkey, so kN == aN
k0, k1, k2, k3, k4, k5 = a0, a1, a2, a3, a4, a5

DEFAULT_STARTGAS = 3141592
gas_price = 1

DEFAULT_SENDER = ADDR[0]

languages = {}
languages['solidity'] = solidity.get_solidity()
languages['serpent'] = serpent

logger = logging.getLogger(__name__)

def encode_datalist(vals):
    def enc(n):
        if type(n) == int:
            return n.to_bytes(32, byteorder='big')
        elif type(n) == str and len(n) == 40:
            return b'\x00' * 12 + binascii.unhexlify(n)
        elif type(n) == str:
            return b'\x00' * (32 - len(n)) + n.encode('utf-8')  # TODO: ugly (and multi‐byte characters)
        elif n is True:
            return 1
        elif n is False or n is None:
            return 0

    def henc(n):
        return util.hexlify(enc(n))

    if isinstance(vals, (tuple, list)):
        return ''.join(map(henc, vals))
    elif vals == '':
        return b''
    else:
        assert False
        # Assume you're getting in numbers or 0x...
        # return ''.join(map(enc, list(map(numberize, vals.split(' ')))))


def compile_serpent_lll(lll_code):
    return serpent.compile_lll(lll_code)


def compile_serpent(code):
    return serpent.compile(code)


def dict_without(d, *args):
    o = {}
    for k, v in list(d.items()):
        if k not in args:
            o[k] = v
    return o


def dict_with(d, **kwargs):
    o = {}
    for k, v in list(d.items()):
        o[k] = v
    for k, v in list(kwargs.items()):
        o[k] = v
    return o


# Pseudo-RNG (deterministic for now for testing purposes)
def rand():
    global seed
    seed = pow(seed, 2, 2 ** 512)
    return seed % 2 ** 256


class TransactionFailed(Exception):
    pass


class ContractCreationFailed(Exception):
    pass


class ABIContract(object):
    """
    :type address {Address}
    """

    def __init__(self, _state, _abi, address, _translator=None):
        self.address = address
        self._translator = _translator or abi.ContractTranslator(_abi)
        self.abi = _abi

        def kall_factory(f):

            def kall(*args, **kwargs):
                _state.log_listeners.append(lambda x: logger.warn(self._translator.listen(x)))
                o = _state._send(kwargs.get('sender', DEFAULT_SENDER),
                                 self.address,
                                 kwargs.get('value', 0),
                                 self._translator.encode(f, args),
                                 startgas=kwargs.get('startgas', DEFAULT_STARTGAS),
                                 **dict_without(kwargs, 'startgas', 'sender', 'value', 'output'))
                _state.log_listeners.pop()
                # Compute output data
                if kwargs.get('output', '') == 'raw':
                    outdata = o['output']
                elif not o['output']:
                    outdata = None
                else:
                    outdata = self._translator.decode(f, o['output'])
                    outdata = outdata[0] if len(outdata) == 1 else outdata
                # Format output
                if kwargs.get('profiling', ''):
                    return dict_with(o, output=outdata)
                else:
                    return outdata
            return kall

        for f in self._translator.function_data:
            vars(self)[f] = kall_factory(f)


class state(object):
    def __init__(self, db, latest_block_hash):
        self.db = db
        self.block = ethblocks.Block(db, latest_block_hash)
        self.tx_index = blocks.get_next_tx_index(self.db)
        self.TIMESTAMP = int(time.time())
        self.log_listeners = []

    def contract(self, code, sender=DEFAULT_SENDER, endowment=0, language='serpent', lll=False):
        if language not in languages:
            raise NotImplemented
            # languages[language] = __import__(language)
        language = languages[language]

        evm = language.compile(code) if not lll else language.compile_lll(code)

        o = self.evm(evm, sender, endowment)
        assert len(self.block.get_code(o)), "Contract code empty"

        return o

    def abi_contract(self, code, sender=DEFAULT_SENDER, endowment=0, language='serpent', contract_name='', lll=False, constructor_parameters=None, **kwargs):
        """
        :return: {ABIContract}
        """
        if contract_name:
            assert language == 'solidity'
            cn_args = dict(contract_name=contract_name)
        else:
            cn_args = kwargs

        if language not in languages:
            raise NotImplemented
            # languages[language] = __import__(language)
        language = languages[language]

        evm = language.compile(code, **cn_args) if not lll else language.compile_lll(code)
        _abi = language.mk_full_signature(code, **cn_args)
        _translator = abi.ContractTranslator(_abi)

        constructor_call = None
        if constructor_parameters is not None:
            constructor_call = _translator.encode_constructor_arguments(constructor_parameters)

        if constructor_call is not None:
            evm += constructor_call

        address = self.evm(evm, sender, endowment)

        assert len(self.block.get_code(address)), "Contract code empty"

        return ABIContract(self, _abi, address, _translator=_translator)

    def evm(self, evm, sender=DEFAULT_SENDER, endowment=0):
        tx, success, output = self.do_send(sender, '', endowment, evm)
        if not success:
            raise ContractCreationFailed()

        return output

    def call(*args, **kwargs):
        raise Exception("Call deprecated. Please use the abi_contract mechanism "
                        "or send(sender, to, value, data) directly, "
                        "using the abi module to generate data if needed")

    def mock_tx(self, sender, to, value, data, startgas=DEFAULT_STARTGAS):
        # create new block
        block_obj = self.mine()

        sender = Address.normalize(sender)
        to = Address.normalize(to)

        # create mock TX
        tx = {
            'source': sender.base58(),
            'block_hash': block_obj.block_hash,
            'block_index': block_obj.block_index,
            'block_time': block_obj.block_time,
            'tx_hash': 'txhash[{}::{}]'.format(to.base58() if to else '', self.tx_index),
            'tx_index': self.tx_index
        }
        self.tx_index += 1  # increment tx_index

        # insert mock TX into DB
        cursor = self.db.cursor()
        cursor.execute('''INSERT INTO transactions ({}) VALUES ({})'''.format(", ".join(tx.keys()), ", ".join("?" * len(tx.keys()))), tx.values())
        cursor.close()

        tx_obj = transactions.Transaction(tx, nonce=0, to=Address.normalize(to), gasprice=1, startgas=startgas, value=value, data=data)

        # @TODO
        tx_obj.nonce = block_obj.get_nonce(Address.normalize(sender))

        return tx, tx_obj, block_obj

    def do_send(self, sender, to, value, data, startgas=DEFAULT_STARTGAS):
        print('DOSEND', sender, to, value, data)

        if not sender:
            raise NotImplemented
            sender = util.contract_sha3('foo'.encode('utf-8'))

        sender = Address.normalize(sender)
        to = Address.normalize(to)

        tx, tx_obj, block_obj = self.mock_tx(sender, to, value, data, startgas)

        # Run.
        processblock.MULTIPLIER_CONSTANT_FACTOR = 1
        success, output, gas_remained = processblock.apply_transaction(self.db, block_obj, tx_obj)

        print('DOSEND-', success, output, gas_remained)

        # Decode, return result.
        return tx_obj, success, output

    def _send(self, sender, to, value, evmdata=b'', output=None, funid=None, abi=None, startgas=DEFAULT_STARTGAS):
        if funid is not None or abi is not None:
            raise Exception("Send with funid+abi is deprecated. Please use the abi_contract mechanism")

        tx, s, o = self.do_send(sender, to, value, evmdata, startgas)

        if not s:
            raise TransactionFailed()

        return {"output": o}

    def send(self, *args, **kwargs):
        return self._send(*args, **kwargs)['output']

    def trace(self, sender, to, value, data=[]):
        # collect log events (independent of loglevel filters)
        # recorder = LogRecorder()
        self.send(sender, to, value, data)
        # return recorder.pop_records()

    def mine(self, n=1, coinbase=None):
        assert n > 0

        for x in range(0, n):
            block_index, block_hash, block_time = util_test.create_next_block(self.db)

            block_obj = ethblocks.Block(self.db, block_hash)
            block_obj.log_listeners += self.log_listeners

            self.block = block_obj

        return block_obj

    def snapshot(self):
        name = "S" + binascii.hexlify(os.urandom(16)).decode('utf8')  # name must start with alphabetic char so prefix with S
        logger.warn('SNAPSHOT %s' % name)

        cursor = self.db.cursor()
        cursor.execute('''SAVEPOINT {}'''.format(name))

        return name

    def revert(self, name):
        logger.warn('REVERT TO %s' % name)
        cursor = self.db.cursor()
        cursor.execute('''ROLLBACK TO SAVEPOINT {}'''.format(name))

