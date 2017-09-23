"""
This module tests for compability with Ethereum's Smart Contracts.
"""

"""
import os
import pytest
from pyethereum import tester
import serpent
import logging
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG, format='%(message)s')
logger = logging.getLogger()

# customize VM log output to your needs
# hint: use 'py.test' with the '-s' option to dump logs to the console
pblogger = tester.pb.pblogger
pblogger.log_pre_state = True    # dump storage at account before execution
pblogger.log_post_state = True   # dump storage at account after execution
pblogger.log_block = False       # dump block after TX was applied
pblogger.log_memory = False      # dump memory before each op
pblogger.log_stack = True        # dump stack before each op
pblogger.log_op = True           # log op, gas, stack before each op
pblogger.log_apply_op = True     # log op, gas, stack before each op
pblogger.log_json = False        # generate machine readable output

gasprice = 0
startgas = 10000
"""

### Counterparty compatibility ###
from counterpartylib import server
from counterpartylib.lib import (util, config, database)
from counterpartylib.lib.messages import execute
from counterpartylib.lib.messages.scriptlib import (blocks, rlp, processblock)

import subprocess   # Serpent is Python 3‐incompatible.
import binascii
import os
import sys
import logging
logger = logging.getLogger(__name__)
import tempfile

CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(CURR_DIR, '..')))

logging.basicConfig(level=logging.DEBUG, format='%(message)s')

TIMESTAMP = 1410973349
tx_index = 1

class serpent(object):
    def compile(code):
        evmcode = subprocess.check_output(['serpent', 'compile', code])
        evmcode = evmcode[:-1] # Strip newline.
        return binascii.unhexlify(bytes(evmcode))

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


class FakeBlock(blocks.Block):
    def __init__(self, db):
        self.db = db
        self.timestamp = TIMESTAMP
        self.number = 9001
        self.prevhash = 'facefeed'
        self.difficulty = 1337


class tester(object):
    gas_limit = 100000

    class serpent(object):
        def compile_lll(lll_code):
            code = subprocess.check_output(['serpent', 'compile_lll', lll_code])
            code = code[:-1] # Strip newline.
            return binascii.unhexlify(bytes(code))

    class state(object):

        # N/A
        def mine (self, n, coinbase):
            global TIMESTAMP
            TIMESTAMP += 50000

        def snapshot(self):
            cursor = db.cursor()
            name = 'xyz'
            cursor.execute('''SAVEPOINT {}'''.format(name))
            return name

        def revert(self, name):
            cursor = db.cursor()
            cursor.execute('''ROLLBACK TO SAVEPOINT {}'''.format(name))

        def create_contract(self, code, endowment=0, sender=''):
            if not sender:
                sender = '82a978b3f5962a5b0957d9ee9eef472ee55b42f1' # PyEthereum uses ECDSA to derive this string from `sender = 0`.

            util.credit(db, sender, config.XCP, max(endowment*2, 100000000), action='unit test', event='facefeed')

            success, data = tester.state.do_send(self, sender, '', endowment, data=code)
            contract_id = data
            return contract_id

        def evm(self, evmcode, endowment=0, sender=''):
            # Publish code.
            contract_id = tester.state.create_contract(self, evmcode, endowment=endowment, sender=sender)

            # Return contract_id.
            return contract_id

        def contract(self, code, sender='', endowment=0):

            # Compile fake code.
            if code:
                evmcode = serpent.compile(code)
            else:
                evmcode = b''

            return tester.state.evm(self, evmcode, endowment=endowment, sender=sender)

        def do_send (self, sender, to, value, data=[]):
            global tx_index

            if not sender:
                sender = util.contract_sha3('foo'.encode('utf-8'))

            # Construct `tx`.
            tx = { 'source': sender,
                   'block_index': 0,
                   'tx_hash': '{}{}'.format(to, tx_index),
                   'block_time': TIMESTAMP,
                   'tx_index': tx_index
                 }
            tx_index += 1
            tx_obj = execute.Transaction(tx, to, 1, tester.gas_limit, value, data)

            block_obj = FakeBlock(db)

            # Run.
            processblock.MULTIPLIER_CONSTANT_FACTOR = 1
            success, output, gas_remained = processblock.apply_transaction(db, tx_obj, block_obj)

            # Decode, return result.
            return success, output

        def send (self, sender, to, value, data=[]):
            # print('tuple', sender, to, value, data)

            # Encode data.
            data = serpent.encode_datalist(data)
            data = binascii.unhexlify(data)

            # Execute contract.
            # print('qux', data, type(data))
            util.credit(db, sender, config.XCP, value + 100000000, action='unit test', event='facefeed')
            success, output = tester.state.do_send(self, sender, to, value, data=data)
            if output:
                return rlp.decode_datalist(bytes(output))
            else:
                return []

        class block(object):
            def to_dict():
                return True # NOTE: Not applicable.

            def set_code(contract_id, code):
                cursor = db.cursor()
                bindings = {'block_index': 0, 'code': code, 'contract_id': contract_id}
                sql='''update contracts set code = :code where contract_id = :contract_id'''
                cursor.execute(sql, bindings)
                cursor.close()

            def get_storage_data(contract_id, key):
                block = FakeBlock(db)
                return block.get_storage_data(contract_id, key)

            def get_balance(address):
                block = FakeBlock(db)
                return block.get_balance(address)

tester.k0 = '82a978b3f5962a5b0957d9ee9eef472ee55b42f1'
tester.k1 = '7d577a597b2742b498cb5cf0c26cdcd726d39e6e'
tester.k2 = '82a978b3f5962a5b0957d9ee9eef472ee55b42f1'
tester.a0 = '82a978b3f5962a5b0957d9ee9eef472ee55b42f1'
tester.a1 = 'dceceaf3fc5c0a63d195d69b1a90011b7b19650d'
tester.a2 = 'dceceaf3fc5c0a63d195d69b1a90011b7b19650d'
tester.a3 = '598443f1880ef585b21f1d7585bd0577402861e5'

def setup_function(function):
    server.initialise(database_file=tempfile.gettempdir()+'/counterparty.unittest.db', 
                      rpc_port=9999, rpc_password='pass', 
                      backend_password='pass',
                      testnet=True, testcoin=False)
    try:
        os.remove(config.DATABASE)
    except:
        pass

    # Connect to database.
    global db
    db = database.get_connection(read_only=False, foreign_keys=False)
    from counterpartylib.lib import blocks
    blocks.initialise(db)

def teardown_function(function):
    global db
    del db
    os.remove(config.DATABASE)

### Counterparty compatibility ###


# Test EVM contracts
serpent_code = 'return(msg.data[0] ^ msg.data[1])'
evm_code = serpent.compile(serpent_code)

def test_evm():
    s = tester.state()
    c = s.evm(evm_code)
    o = s.send(tester.k0, c, 0, [2, 5])
    assert o == [32]


# Test serpent compilation of variables using _with_, doing a simple
# arithmetic calculation 20 * 30 + 10 = 610
sixten_code =\
    '''
(with 'x 10
    (with 'y 20
        (with 'z 30
            (seq
                (set 'a (add (mul (get 'y) (get 'z)) (get 'x)))
                (return (ref 'a) 32)
            )
        )
    )
)
'''


def test_sixten():
    s = tester.state()
    c = s.contract('')
    s.block.set_code(c, tester.serpent.compile_lll(sixten_code))
    o1 = s.send(tester.k0, c, 0, [])
    assert o1 == [610]

# Test Serpent's import mechanism

mul2_code = \
    '''
return(msg.data[0]*2)
'''

filename = "mul2_qwertyuioplkjhgfdsa.se"

returnten_code = \
    '''
x = create("%s")
return(call(x, 5))
''' % filename


def test_returnten():
    s = tester.state()
    open(filename, 'w').write(mul2_code)
    c = s.contract(returnten_code)
    o1 = s.send(tester.k0, c, 0, [])
    os.remove(filename)
    assert o1 == [10]


# Test a simple namecoin implementation

namecoin_code =\
    '''
if !contract.storage[msg.data[0]]:
    contract.storage[msg.data[0]] = msg.data[1]
    return(1)
else:
    return(0)
'''


def test_namecoin():
    s = tester.state()
    c = s.contract(namecoin_code)
    o1 = s.send(tester.k0, c, 0, ['"george"', 45])
    assert o1 == [1]
    o2 = s.send(tester.k0, c, 0, ['"george"', 20])
    assert o2 == [0]
    o3 = s.send(tester.k0, c, 0, ['"harry"', 60])
    assert o3 == [1]

    assert s.block.to_dict()

# Test a simple currency implementation

currency_code = '''
init:
    contract.storage[msg.sender] = 1000
code:
    if msg.datasize == 1:
        addr = msg.data[0]
        return(contract.storage[addr])
    else:
        from = msg.sender
        fromvalue = contract.storage[from]
        to = msg.data[0]
        value = msg.data[1]
        if fromvalue >= value:
            contract.storage[from] = fromvalue - value
            contract.storage[to] = contract.storage[to] + value
            return(1)
        else:
            return(0)
'''


def test_currency():
    s = tester.state()
    c = s.contract(currency_code, sender=tester.k0)
    o1 = s.send(tester.k0, c, 0, [tester.a2, 200])
    assert o1 == [1]
    o2 = s.send(tester.k0, c, 0, [tester.a2, 900])
    assert o2 == [0]
    o3 = s.send(tester.k0, c, 0, [tester.a0])
    assert o3 == [800]
    o4 = s.send(tester.k0, c, 0, [tester.a2])
    assert o4 == [200]

# Test a data feed

data_feed_code = '''
if !contract.storage[1000]:
    contract.storage[1000] = 1
    contract.storage[1001] = msg.sender
    return(20)
elif msg.datasize == 2:
    if msg.sender == contract.storage[1001]:
        contract.storage[msg.data[0]] = msg.data[1]
        return(1)
    else:
        return(0)
else:
    return(contract.storage[msg.data[0]])
'''


def test_data_feeds():
    s = tester.state()
    c = s.contract(data_feed_code, sender=tester.k0)
    o1 = s.send(tester.k0, c, 0)
    assert o1 == [20]
    o2 = s.send(tester.k0, c, 0, [500])
    assert o2 == [0]
    o3 = s.send(tester.k0, c, 0, [500, 19])
    assert o3 == [1]
    o4 = s.send(tester.k0, c, 0, [500])
    assert o4 == [19]
    o5 = s.send(tester.k1, c, 0, [500, 726])
    assert o5 == [0]
    o6 = s.send(tester.k0, c, 0, [500, 726])
    assert o6 == [1]
    return s, c

# Test an example hedging contract, using the data feed. This tests
# contracts calling other contracts

hedge_code = '''
if !contract.storage[1000]:
    contract.storage[1000] = msg.sender
    contract.storage[1002] = msg.value
    contract.storage[1003] = msg.data[0]
    contract.storage[1004] = msg.data[1]
    return(1)
elif !contract.storage[1001]:
    ethvalue = contract.storage[1002]
    if msg.value >= ethvalue:
        contract.storage[1001] = msg.sender
    c = call(contract.storage[1003],[contract.storage[1004]],1)
    othervalue = ethvalue * c
    contract.storage[1005] = othervalue
    contract.storage[1006] = block.timestamp + 500
    return([2,othervalue],2)
else:
    othervalue = contract.storage[1005]
    ethvalue = othervalue / call(contract.storage[1003],contract.storage[1004])
    if ethvalue >= contract.balance:
        send(contract.storage[1000],contract.balance)
        return(3)
    elif block.timestamp > contract.storage[1006]:
        send(contract.storage[1001],contract.balance - ethvalue)
        send(contract.storage[1000],ethvalue)
        return(4)
    else:
        return(5)
'''


def test_hedge():
    s, c = test_data_feeds()
    c2 = s.contract(hedge_code, sender=tester.k0)
    # Have the first party register, sending 10^16 wei and
    # asking for a hedge using currency code 500
    o1 = s.send(tester.k0, c2, 10**16, [c, 500])
    assert o1 == [1]
    # Have the second party register. It should receive the
    # amount of units of the second currency that it is
    # entitled to. Note that from the previous test this is
    # set to 726
    o2 = s.send(tester.k2, c2, 10**16)
    assert o2 == [2, 7260000000000000000]
    snapshot = s.snapshot()
    # Set the price of the asset down to 300 wei
    o3 = s.send(tester.k0, c, 0, [500, 300])
    assert o3 == [1]
    # Finalize the contract. Expect code 3, meaning a margin call
    o4 = s.send(tester.k0, c2, 0)
    assert o4 == [3]
    s.revert(snapshot)
    # Don't change the price. Finalize, and expect code 5, meaning
    # the time has not expired yet
    o5 = s.send(tester.k0, c2, 0)
    assert o5 == [5]
    s.mine(100, tester.a3)
    # Mine ten blocks, and try. Expect code 4, meaning a normal execution
    # where both get their share
    o6 = s.send(tester.k0, c2, 0)
    assert o6 == [4]


# Test the LIFO nature of call and the FIFO nature of post
arither_code = '''
init:
    contract.storage[0] = 10
code:
    if msg.data[0] == 0:
        contract.storage[0] += 1
    elif msg.data[0] == 1:
        contract.storage[0] *= 10
        call(contract.address, 0)
        contract.storage[0] *= 10
    elif msg.data[0] == 2:
        contract.storage[0] *= 10
        postcall(tx.gas / 2, contract.address, 0)
        contract.storage[0] *= 10
    elif msg.data[0] == 3:
        return(contract.storage[0])
'''


def test_post():
    s = tester.state()
    c = s.contract(arither_code)
    s.send(tester.k0, c, 0, [1])
    o2 = s.send(tester.k0, c, 0, [3])
    assert o2 == [1010]
    c = s.contract(arither_code)
    s.send(tester.k0, c, 0, [2])
    o2 = s.send(tester.k0, c, 0, [3])
    assert o2 == [1001]


# Test suicides and suicide reverts
suicider_code = '''
if msg.data[0] == 0:
    contract.storage[15] = 40
    call(contract.address, 3)
    i = 0
    while i < msg.data[1]:
        i += 1
elif msg.data[0] == 1:
    contract.storage[15] = 20
    msg(tx.gas - 100, contract.address, 0, [0, msg.data[1]], 2)
elif msg.data[0] == 2:
    return(10)
elif msg.data[0] == 3:
    suicide(0)
elif msg.data[0] == 4:
    return(contract.storage[15])
'''


def test_suicider():
    s = tester.state()
    c = s.contract(suicider_code)
    prev_gas_limit = tester.gas_limit
    tester.gas_limit = 4000
    # Run normally: suicide processes, so the attempt to ping the
    # contract fails
    s.send(tester.k0, c, 0, [1, 10])
    o2 = s.send(tester.k0, c, 0, [2])
    assert o2 == []
    c = s.contract(suicider_code)
    # Run the suicider in such a way that it suicides in a sub-call,
    # then runs out of gas, leading to a revert of the suicide and the
    # storage mutation
    s.send(tester.k0, c, 0, [1, 4000])
    # Check that the suicide got reverted
    o2 = s.send(tester.k0, c, 0, [2])
    assert o2 == [10]
    # Check that the storage op got reverted
    o3 = s.send(tester.k0, c, 0, [4])
    assert o3 == [20]
    tester.gas_limit = prev_gas_limit


# Test reverts

reverter_code = '''
if msg.data[0] == 0:
    msg(1000, contract.address, 0, 1)
    msg(1000, contract.address, 0, 2)
elif msg.data[0] == 1:
    send(1, 9)
    contract.storage[8080] = 4040
    contract.storage[160160] = 2020
elif msg.data[0] == 2:
    send(2, 9)
    contract.storage[8081] = 4039
    contract.storage[160161] = 2019
    call(contract.address, 2)
    contract.storage["waste_some_gas"] = 0
'''


def test_reverter():
    s = tester.state()
    c = s.contract(reverter_code, endowment=10**15)
    s.send(tester.k0, c, 0, [0])
    assert s.block.get_storage_data(c, 8080) == 4040
    assert s.block.get_balance('0'*39+'1') == 9
    assert s.block.get_storage_data(c, 8081) == 0
    assert s.block.get_balance('0'*39+'2') == 0

# Test stateless contracts

add1_code = \
    '''
contract.storage[1] += msg.data[0]
'''

filename2 = "stateless_qwertyuioplkjhgfdsa.se"

stateless_test_code = \
    '''
x = create("%s")
call(x, 6)
call_stateless(x, 4)
call_stateless(x, 60)
call(x, 40)
return(contract.storage[1])
''' % filename2


def test_stateless():
    s = tester.state()
    open(filename2, 'w').write(add1_code)
    c = s.contract(stateless_test_code)
    o1 = s.send(tester.k0, c, 0, [])
    os.remove(filename2)
    assert o1 == [64]


# https://github.com/ethereum/serpent/issues/8
array_code = '''
a = array(1)
a[0] = 1
return(a, 1)
'''

def test_array():
    s = tester.state()
    c = s.contract(array_code)
    assert [1] == s.send(tester.k0, c, 0, [])

array_code2 = '''
a = array(1)
something = 2
a[0] = 1
return(a, 1)
'''

def test_array2():
    s = tester.state()
    c = s.contract(array_code2)
    assert [1] == s.send(tester.k0, c, 0, [])

array_code3="""
a = array(3)
return(a, 3)
"""
def test_array3():
    s = tester.state()
    c = s.contract(array_code3)
    assert [0,0,0] == s.send(tester.k0, c, 0, [])
