import hashlib
import pprint

import pytest
import binascii
import os
import sys
import logging
import serpent
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (config, database)
from counterpartylib.lib.evm import (blocks, processblock, ethutils, abi, address, vm)

from counterpartylib.test.evm import contracts_tester as tester
from counterpartylib.test import util_test
from counterpartylib.lib.evm.solidity import get_solidity

solidity = get_solidity()

# globals initialized by setup_function
db, cursor, logger = None, None, None
CLEANUP_FILES = []


def state():
    """"create a tester.state with latest block"""
    global db

    cursor = db.cursor()
    cursor.execute('''SELECT * FROM blocks ORDER BY block_index DESC LIMIT 1''')
    latest_block = list(cursor.fetchall())[0]
    cursor.close()

    return tester.state(db, latest_block['block_hash'])


def setup_module():
    """Initialise the database with unittest fixtures"""
    # global the DB/cursor for other functions to access
    global db, cursor, logger

    db = util_test.init_database(CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql', 'fixtures.countracts_test.db')
    logger = logging.getLogger(__name__)
    db.setrollbackhook(lambda: logger.debug('ROLLBACK'))
    database.update_version(db)


def teardown_module():
    """Delete the temporary database."""
    util_test.remove_database_files(config.DATABASE)


def setup_function(function):
    global db, cursor

    # start transaction so we can rollback on teardown
    cursor = db.cursor()
    cursor.execute('''BEGIN''')


def teardown_function(function):
    global db, cursor
    cursor.execute('''ROLLBACK''')

    # cleanup files marked for cleanup
    for file in CLEANUP_FILES:
        if os.path.isfile(file):
            os.remove(file)


def open_cleanonteardown(filename, *args, **kwargs):
    CLEANUP_FILES.append(filename)

    return open(filename, *args, **kwargs)


def test_evm1():
    code = '''
contract testme {
    function main(uint a, uint b) returns (uint) {
        return a ** b;
    }
}
'''

    translator = abi.ContractTranslator(solidity.mk_full_signature(code))
    s = state()
    c = s.abi_contract(code, language='solidity')
    assert c.main(2, 5) == 32


def test_constructor():
    contract_code = '''
contract testme {
    uint cnt;

    function testme() {
        cnt = 10;
    }

    function ping() returns (uint) {
        cnt = cnt + 1;
        return cnt;
    }
}
'''

    s = state()
    c = s.abi_contract(contract_code, language='solidity')

    assert c.ping() == 11;
    assert c.ping() == 12;


# Test import mechanism
def test_returnten():
    mul2_code = '''
contract mul2 {
    function double(uint v) returns (uint) {
        return v * 2;
    }
}
'''
    filename = "mul2_qwertyuioplkjhgfdsa.sol"

    returnten_code = '''
import "%s";

contract testme {
    function main() returns (uint) {
        mul2 x = new mul2();
        return x.double(5);
    }
}''' % filename
    s = state()
    open_cleanonteardown(filename, 'w').write(mul2_code)
    c = s.abi_contract(returnten_code, language='solidity')
    assert c.main() == 10


# Test inherit
def test_inherit():
    mul2_code = '''
contract mul2 {
    function double(uint v) returns (uint) {
        return v * 2;
    }
}
'''
    filename = "mul2_qwertyuioplkjhgfdsa.sol"

    returnten_code = '''
import "%s";

contract testme is mul2 {
    function main() returns (uint) {
        return double(5);
    }
}''' % filename
    s = state()
    open_cleanonteardown(filename, 'w').write(mul2_code)
    c = s.abi_contract(returnten_code, language='solidity')
    assert c.main() == 10


# Test inherit
def test_external():
    mul2_code = '''
contract mul2 {
    function double(uint v) returns (uint) {
        return v * 2;
    }
}
'''
    filename = "mul2_qwertyuioplkjhgfdsa.sol"

    returnten_code = '''
import "%s";

contract testme {
    address mymul2;

    function setmul2(address _mul2) {
        mymul2 = _mul2;
    }

    function main() returns (uint) {
        return mul2(mymul2).double(5);
    }
}''' % filename
    s = state()
    open_cleanonteardown(filename, 'w').write(mul2_code)

    c1 = s.abi_contract(mul2_code, language='solidity')
    c = s.abi_contract(returnten_code, language='solidity')

    c.setmul2(c1.address)
    assert c.main() == 10


def test_this_call():
    """test the difference between `this.fn()` and `fn()`; `this.fn()` should use `CALL`, which costs more gas"""
    returnten_code = '''
contract testme {
    function double(uint v) returns (uint) {
        return v * 2;
    }

    function doubleexternal() returns (uint) {
        return this.double(5);
    }

    function doubleinternal() returns (uint) {
        return double(5);
    }
}'''
    s = state()

    c = s.abi_contract(returnten_code, sender=tester.k0, language='solidity')
    b = s.block.get_balance(tester.k0)
    assert c.doubleexternal() == 10
    assert b - s.block.get_balance(tester.k0) == 21824  # gas used

    b = s.block.get_balance(tester.k0)
    assert c.doubleinternal() == 10
    assert b - s.block.get_balance(tester.k0) == 21479  # gas used


def test_private_fns():
    returnten_code = '''
contract testme {
    function double(uint v) private returns (uint) {
        return v * 2;
    }

    function doublepub() returns (uint) {
        return double(5);
    }
}'''
    s = state()

    c = s.abi_contract(returnten_code, sender=tester.k0, language='solidity')
    assert c.doublepub() == 10

    e = None
    try:
        c.double(10)
    except AttributeError as _e:
        e = _e
    assert e is not None and isinstance(e, AttributeError)

    # this is a call to `double(10)`, but we can't construct that through normal means because it knows it's private (see above)
    data = b'\xee\xe9r\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\n'
    o = s._send(tester.DEFAULT_SENDER, c.address, 0, data, tester.DEFAULT_STARTGAS)
    assert o['output'] == b""


# Test inherit
def test_constructor_args():
    mul2_code = '''
contract mul2 {
    function double(uint v) returns (uint) {
        return v * 2;
    }
}
'''
    filename = "mul2_qwertyuioplkjhgfdsa.sol"

    returnten_code = '''
import "%s";

contract testme {
    address mymul2;

    function testme(address _mul2) {
        mymul2 = _mul2;
    }

    function main() returns (uint) {
        return mul2(mymul2).double(5);
    }
}''' % filename
    s = state()
    open_cleanonteardown(filename, 'w').write(mul2_code)

    c1 = s.abi_contract(mul2_code, language='solidity')
    c = s.abi_contract(returnten_code, constructor_parameters=[c1.address], language='solidity')

    assert c.main() == 10


# Test a simple namecoin implementation
def test_namecoin():
    namecoin_code = '''
contract namecoin {
    mapping(string => uint) data;

    function set(string k, uint v) returns (uint) {
        if (data[k] == 0) {
            data[k] = v;
            return 1;
        } else {
            return 0;
        }
    }

    function get(string k) returns (uint) {
        return data[k];
    }
}
'''

    s = state()
    c = s.abi_contract(namecoin_code, language='solidity')

    o1 = c.set("george", 45)
    assert o1 == 1
    assert c.get("george")

    o2 = c.set("george", 20)
    assert o2 == 0
    assert c.get("george")

    o3 = c.set("harry", 60)
    assert o3 == 1
    assert c.get("harry")


# Test a simple text return
def test_simple_text_return():
    simple_text_return_code = '''
contract testme {
    function returntext() returns (string) {
        return "testing123";
    }
}
'''

    s = state()
    c = s.abi_contract(simple_text_return_code, language='solidity')
    assert c.returntext() == bytes("testing123", "utf8")


# Test a simple send
def test_send():
    send_code = '''
contract testme {
    function send(uint v) {
        msg.sender.send(v);
    }
}
'''

    s = state()
    c = s.abi_contract(send_code, language='solidity')

    startbalance = s.block.get_balance(tester.a2)
    value = 1000000  # amount send into the contract
    v = 30000  # v= for the contract, amount we get back
    gcost = 53408  # gascost
    c.send(v, value=value, sender=tester.a2)
    assert s.block.get_balance(tester.a2) == startbalance - gcost - value + v


def test_send_arg():
    send_arg_code = '''
contract testme {
    function send(address s, uint v) {
        s.send(v);
    }
}
'''

    s = state()
    c = s.abi_contract(send_arg_code, language='solidity')

    startbalance = s.block.get_balance(tester.a2)
    v = 30000  # v = for the contract, amount we get back
    c.send(tester.a2, v, value=10000000, sender=tester.a1)
    assert s.block.get_balance(tester.a2) == startbalance + v


def test_send_hardcoded():
    send_hardcoded_code = '''
contract testme {
    function send(uint v) {
        address s = address(%s);
        s.send(v);
    }
}
'''

    a2 = address.Address.normalize(tester.a2)

    s = state()
    c = s.abi_contract(send_hardcoded_code % (a2.int(), ), language='solidity')

    startbalance = s.block.get_balance(tester.a2)
    v = 30000  # v = for the contract, amount we get back
    c.send(v, value=10000000, sender=tester.a1)
    assert s.block.get_balance(tester.a2) == startbalance + v


# Test a simple currency implementation
def test_currency():
    currency_code = '''
contract testme {
    mapping(address => uint) balances;

    function testme() {
        balances[msg.sender] = 1000;
    }

    function query(address a) returns (uint) {
        return balances[a];
    }

    function send(address to, uint value) returns (uint) {
        address from = msg.sender;

        if (balances[msg.sender] >= value) {
            balances[msg.sender] = balances[msg.sender] - value;
            balances[to] = balances[to] + value;

            return 1;
        } else {
            return 0;
        }
    }
}
'''

    s = state()
    c = s.abi_contract(currency_code, sender=tester.k0, language='solidity')

    o1 = c.query(tester.k0)
    assert o1 == 1000
    o1 = c.send(tester.a2, 200, sender=tester.a0)
    assert o1 == 1
    o2 = c.send(tester.a2, 900, sender=tester.a0)
    assert o2 == 0
    o3 = c.query(tester.a0)
    assert o3 == 800
    o4 = c.query(tester.a2)
    assert o4 == 200


# Test a data feed
data_feed_code = '''
contract datafeedContract {
    address creator;
    mapping(uint => uint) values;

    function datafeedContract() {
        creator = msg.sender;
    }

    function set(uint k, uint v) returns (uint) {
        if (msg.sender == creator) {
            values[k] = v;
            return 1;
        } else {
            return 0;
        }
    }

    function get(uint k) returns (uint) {
        return values[k];
    }
}
'''


def test_data_feeds():
    s = state()
    c = s.abi_contract(data_feed_code, sender=tester.k0, language='solidity')
    o2 = c.get(500)
    assert o2 == 0
    o3 = c.set(500, 19, sender=tester.k0)
    assert o3 == 1
    o4 = c.get(500)
    assert o4 == 19
    o5 = c.set(500, 726, sender=tester.k1)
    assert o5 == 0
    o6 = c.set(500, 726)
    assert o6 == 1
    return s, c


# Test an example hedging contract, using the data feed.
# This tests contracts calling other contracts
def test_hedge():
    hedge_code = '''
%s

contract testme {
    address partyone;
    address partytwo;
    uint hedgeValue;
    address datafeed;
    uint index;
    uint fiatValue;
    uint maturity;

    function main(address _datafeed, uint _index) returns (uint) {
        // step 1; setup partyone
        if (partyone == 0x0) {
            partyone = msg.sender;
            hedgeValue = msg.value;
            datafeed = _datafeed;
            index = _index;

            return 1;
        } else if (partytwo == 0x0) {
            if (msg.value >= hedgeValue) {
                partytwo = msg.sender;
            }

            uint c = datafeedContract(datafeed).get(index);
            fiatValue = hedgeValue * c;
            maturity = block.timestamp + 20000;

            return fiatValue;
        } else {
            uint otherValue = fiatValue;
            uint ethValue = otherValue / datafeedContract(datafeed).get(index);

            if (ethValue > this.balance) {
                partyone.send(this.balance);
                return 3;
            } else if (block.timestamp > maturity) {
                partytwo.send(this.balance - ethValue);
                partyone.send(ethValue);

                return 4;
            } else {
                return 5;
            }
        }
    }
}
''' % data_feed_code

    # run previous test to setup data feeds
    s, c = test_data_feeds()

    # create contract
    c2 = s.abi_contract(hedge_code, sender=tester.k0, language='solidity')

    # Have the first party register, sending 10000000 XCPtoshi and asking for a hedge using currency code 500
    o1 = c2.main(c.address.int(), 500, value=10000000, sender=tester.k0)
    assert o1 == 1

    # Have the second party register.
    # It should receive the amount of units of the second currency that it is entitled to.
    # Note that from the previous test this is set to 726
    o2 = c2.main(address.Address.nulladdress(), 0, value=10000000, sender=tester.k2)
    assert o2 == 7260000000

    # SNAPSHOT
    snapshot = s.snapshot()

    # Set the price of the asset down to 300 wei, through the data feed contract
    o3 = c.set(500, 300)
    assert o3 == 1

    # Finalize the contract. Expect code 3, meaning a margin call
    o4 = c2.main(address.Address.nulladdress(), 0)
    assert o4 == 3

    # REVERT TO SNAPSHOT
    s.revert(snapshot)

    # Don't change the price. Finalize, and expect code 5, meaning the time has not expired yet
    o5 = c2.main(address.Address.nulladdress(), 0)
    assert o5 == 5

    # Mine 100 blocks
    s.mine(100, tester.a3)

    # Expect code 4, meaning a normal execution where both get their share
    o6 = c2.main(address.Address.nulladdress(), 0)
    assert o6 == 4


# Test the LIFO nature of call
def test_lifo():
    arither_code = '''
contract testme {
    uint r;

    function testme() {
        r = 10;
    }

    function f1() {
        r += 1;
    }

    function f2() {
        r *= 10;
        f1();
        r *= 10;
    }

    function f3() returns (uint) {
        return r;
    }
}
'''

    s = state()
    c = s.abi_contract(arither_code, language='solidity')
    c.f2()
    assert c.f3() == 1010


def test_oog():
    contract_code = '''
contract testme {
    mapping(uint => uint) data;

    function loop(uint rounds) returns (uint) {
        uint i = 0;
        while (i < rounds) {
            data[i] = i;
            i++;
        }

        return i;
    }
}
'''
    s = state()
    c = s.abi_contract(contract_code, language='solidity')
    assert c.loop(5) == 5

    e = None
    try:
        c.loop(500)
    except tester.TransactionFailed as _e:
        e = _e
    assert e and isinstance(e, tester.TransactionFailed)


def test_subcall_suicider():
    internal_code = '''
contract testmeinternal {
    address creator;
    uint r;

    function testmeinternal() {
        creator = msg.sender;
    }

    function set(uint v) {
        r = v;
    }

    function get() returns (uint) {
        return r;
    }

    function killme() {
        selfdestruct(creator);
    }
}
'''
    external_code = '''
contract testme {
    address subcontract;
    mapping(uint => uint) data;

    function testme(address _subcontract) {
        subcontract = _subcontract;
    }

    function killandloop(uint rounds) returns (uint) {
        testmeinternal(subcontract).killme();
        return loop(rounds);
    }

    function loop(uint rounds) returns (uint) {
        uint i = 0;
        while (i < rounds) {
            i++;
            data[i] = i;
        }

        return i;
    }
}
'''

    s = state()

    # test normal suicide path
    internal = s.abi_contract(internal_code, language='solidity')
    external = s.abi_contract(internal_code + "\n" + external_code, constructor_parameters=[internal.address], language='solidity')
    internal.set(60)
    assert internal.get() == 60
    assert external.killandloop(10) == 10
    assert internal.get() is None

    # test suicide -> oog path, shouldn't suicide
    internal = s.abi_contract(internal_code, language='solidity')
    external = s.abi_contract(internal_code + "\n" + external_code, constructor_parameters=[internal.address], language='solidity')
    internal.set(60)
    assert internal.get() == 60

    e = None
    try:
        external.killandloop(500)
    except tester.TransactionFailed as _e:
        e = _e
    assert e and isinstance(e, tester.TransactionFailed)
    assert internal.get() == 60


def test_array():
    array_code = '''
contract testme {
    function main() returns (uint[]) {
        uint[] memory a = new uint[](1);
        a[0] = 1;
        return a;
    }
}
'''
    s = state()
    c = s.abi_contract(array_code, language='solidity')
    assert c.main() == [1]



def test_array2():
    array_code2 = """
contract testme {
    function main() returns (uint[3]) {
        uint[3] memory a;
        return a;
    }
}
"""
    s = state()
    c = s.abi_contract(array_code2, language='solidity')
    assert c.main() == [0, 0, 0]



def test_array3():
    array_code3 = """
contract testme {
    function main() returns (uint[]) {
        uint[] memory a = new uint[](3);
        return a;
    }
}
"""
    s = state()
    c = s.abi_contract(array_code3, language='solidity')
    assert c.main() == [0, 0, 0]


def test_calls():
    calltest_code = """
contract testme {
    mapping(uint => uint) data;

    function main() {
        this.first(1, 2, 3, 4, 5);
        this.second( 2, 3, 4, 5, 6);
        this.third(3, 4, 5, 6, 7);
    }

    function first(uint a, uint b, uint c, uint d, uint e) {
        data[1] = a * 10000 + b * 1000 + c * 100 + d * 10 + e;
    }

    function second(uint a, uint b, uint c, uint d, uint e) {
        data[2] = a * 10000 + b * 1000 + c * 100 + d * 10 + e;
    }

    function third(uint a, uint b, uint c, uint d, uint e) {
        data[3] = a * 10000 + b * 1000 + c * 100 + d * 10 + e;
    }

    function get(uint k) returns (uint) {
        return data[k];
    }
}
"""

    s = state()
    c = s.abi_contract(calltest_code, language='solidity')
    c.main()
    assert 12345 == c.get(1)
    assert 23456 == c.get(2)
    assert 34567 == c.get(3)
    c.first(4, 5, 6, 7, 8)
    assert 45678 == c.get(1)
    c.second(5, 6, 7, 8, 9)
    assert 56789 == c.get(2)


def test_storage_objects():
    storage_object_test_code = """
extern moo: [ping, query_chessboard:ii, query_items:ii, query_person, query_stats:i, testping:ii, testping2:i]

data chessboard[8][8]
data users[100](health, x, y, items[5])
data person(head, arms[2](elbow, fingers[5]), legs[2])

def ping():
    self.chessboard[0][0] = 1
    self.chessboard[0][1] = 2
    self.chessboard[3][0] = 3
    self.users[0].health = 100
    self.users[1].x = 15
    self.users[1].y = 12
    self.users[1].items[2] = 9
    self.users[80].health = self
    self.users[80].items[3] = self
    self.person.head = 555
    self.person.arms[0].elbow = 556
    self.person.arms[0].fingers[0] = 557
    self.person.arms[0].fingers[4] = 558
    self.person.legs[0] = 559
    self.person.arms[1].elbow = 656
    self.person.arms[1].fingers[0] = 657
    self.person.arms[1].fingers[4] = 658
    self.person.legs[1] = 659
    self.person.legs[1] += 1000

def query_chessboard(x, y):
    return(self.chessboard[x][y])

def query_stats(u):
    return([self.users[u].health, self.users[u].x, self.users[u].y]:arr)

def query_items(u, i):
    return(self.users[u].items[i])

def query_person():
    a = array(15)
    a[0] = self.person.head
    a[1] = self.person.arms[0].elbow
    a[2] = self.person.arms[1].elbow
    a[3] = self.person.legs[0]
    a[4] = self.person.legs[1]
    i = 0
    while i < 5:
        a[5 + i] = self.person.arms[0].fingers[i]
        a[10 + i] = self.person.arms[1].fingers[i]
        i += 1
    return(a:arr)

def testping(x, y):
    return([self.users[80].health.testping2(x), self.users[80].items[3].testping2(y)]:arr)

def testping2(x):
    return(x*x)

"""
    storage_object_test_code = """
contract testme {

    struct User {
        uint health;
        uint x;
        uint y;
        uint[5] items;
    }

    struct Arm {
        uint elbow;
        uint[5] fingers;
    }

    struct Person {
        uint head;
        Arm[2] arms;
        uint[2] legs;
    }

    uint[8][8] chessboard;
    User[100] users;
    Person person;

    function ping() {
        chessboard[0][0] = 1;
        chessboard[0][1] = 2;
        chessboard[3][0] = 3;
        users[0].health = 100;
        users[1].x = 15;
        users[1].y = 12;
        users[1].items[2] = 9;
        users[80].health = 10;
        users[80].items[3] = 11;
        person.head = 555;
        person.arms[0].elbow = 556;
        person.arms[0].fingers[0] = 557;
        person.arms[0].fingers[4] = 558;
        person.legs[0] = 559;
        person.arms[1].elbow = 656;
        person.arms[1].fingers[0] = 657;
        person.arms[1].fingers[4] = 658;
        person.legs[1] = 659;
        person.legs[1] += 1000;
    }

    function query_chessboard(uint x, uint y) returns (uint) {
        return chessboard[x][y];
    }

    function query_stats(uint u) returns (uint, uint, uint) {
        return (users[u].health, users[u].x, users[u].y);
    }

    function query_items(uint u, uint i) returns (uint) {
        return users[u].items[i];
    }

    function query_person() returns (uint[15]) {
        uint[15] a;
        a[0] = person.head;
        a[1] = person.arms[0].elbow;
        a[2] = person.arms[1].elbow;
        a[3] = person.legs[0];
        a[4] = person.legs[1];

        uint i = 0;
        while (i < 5) {
            a[5 + i] = person.arms[0].fingers[i];
            a[10 + i] = person.arms[1].fingers[i];
            i += 1;
        }

        return a;
    }
}
"""
    s = state()
    c = s.abi_contract(storage_object_test_code, language='solidity')
    c.ping()
    assert 1 == c.query_chessboard(0, 0)
    assert 2 == c.query_chessboard(0, 1)
    assert 3 == c.query_chessboard(3, 0)
    assert [100, 0, 0] == c.query_stats(0)
    assert [0, 15, 12] == c.query_stats(1)
    assert 0 == c.query_items(1, 3)
    assert 0 == c.query_items(0, 2)
    assert 9 == c.query_items(1, 2)
    assert [555, 556, 656, 559, 1659,
            557, 0, 0, 0, 558,
            657, 0, 0, 0, 658] == c.query_person()


def test_crowdfund():
    """
    test crowdfund smart contract, keep in mind that we create a new block for every contract call
     so we need a generous TTL
    """
    crowdfund_code = """
contract testme {
    struct Contrib {
        address sender;
        uint value;
    }

    struct Campaign {
        address recipient;
        uint goal;
        uint deadline;
        uint contrib_total;
        uint contrib_count;
        mapping(uint => Contrib) contribs;
    }

    mapping(uint => Campaign) campaigns;

    function create_campaign(uint id, address recipient, uint goal, uint timelimit) returns (uint) {
        if (campaigns[id].recipient != 0x0) {
            return 0;
        }

        campaigns[id] = Campaign(recipient, goal, block.timestamp + timelimit, 0, 0);
        return 1;
    }

    function contribute(uint id) returns (uint) {
        // Update contribution total
        uint total_contributed = campaigns[id].contrib_total + msg.value;
        campaigns[id].contrib_total = total_contributed;

        // Record new contribution
        uint sub_index = campaigns[id].contrib_count;
        campaigns[id].contribs[sub_index] = Contrib(msg.sender, msg.value);
        campaigns[id].contrib_count = sub_index + 1;

        // Enough funding?
        if (total_contributed >= campaigns[id].goal) {
            campaigns[id].recipient.send(total_contributed);
            clear(id);
            return 1;
        }

        // Expired?
        if (block.timestamp > campaigns[id].deadline) {
            uint i = 0;
            uint c = campaigns[id].contrib_count;
            while (i < c) {
                campaigns[id].contribs[i].sender.send(campaigns[id].contribs[i].value);
                i += 1;
            }
            clear(id);
            return 2;
        }
    }

    // Progress report [2, id]
    function progress_report(uint id) returns (uint) {
        return campaigns[id].contrib_total;
    }

    // Clearing function for internal use
    function clear(uint id) private {
        delete campaigns[id];
    }
}
"""

    s = state()
    c = s.abi_contract(crowdfund_code, language='solidity')  # tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt

    ttlblocks = 20
    ttl = ttlblocks * 1000  # block_index * 1000 for mock timestamps

    # Create a campaign with id 100, recipient '45', target 100000 and ttl 20 blocks
    recipient100 = address.Address(data=address.Address.normalizedata(45), version=config.ADDRESSVERSION)  # mfWxJ45yp2SFn7UciZyNpvDKrzbnzaxGAt
    assert c.create_campaign(100, recipient100.int(), 100000, ttl) == 1
    # Create a campaign with id 200, recipient '48', target 100000 and ttl 20 blocks
    recipient200 = address.Address(data=address.Address.normalizedata(48), version=config.ADDRESSVERSION)  # mfWxJ45yp2SFn7UciZyNpvDKrzboRgnPSZ
    assert c.create_campaign(200, recipient200.int(), 100000, ttl) == 1

    # Make some contributions to campaign 100
    assert c.contribute(100, value=1, sender=tester.k1) == 0  # mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns
    assert 1 == c.progress_report(100)
    assert c.contribute(100, value=59049, sender=tester.k2) == 0 # mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj
    assert 59050 == c.progress_report(100)

    # Make some contributions to campaign 200
    assert c.contribute(200, value=30000, sender=tester.k3) == 0  # myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM
    assert 30000 == c.progress_report(200)

    # This contribution should trigger the delivery
    assert c.contribute(200, value=70001, sender=tester.k4) == 1  # munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b

    # Expect the 100001 units to be delivered to the destination account for campaign 2
    assert 100001 == s.block.get_balance(recipient200)

    # Mine some blocks to test expire the campaign, not sure how many are needed so just do 20
    mida1 = s.block.get_balance(tester.a1)
    mida3 = s.block.get_balance(tester.a2)
    s.mine(ttlblocks)

    # Ping the campaign after expiry to trigger the refund
    assert c.contribute(100, value=1, sender=tester.a0) == 2

    # Create the campaign again, should have been deleted
    assert c.create_campaign(100, recipient100.int(), 100000, ttl) == 1

    # Expect refunds
    assert mida1 + 1 == s.block.get_balance(tester.a1)
    assert mida3 + 59049 == s.block.get_balance(tester.a2)


def test_ints():
    sdiv_code = """
contract testme {
    function addone256(uint256 k) returns (uint256) {
        return k + 1;
    }
    function subone256(uint256 k) returns (uint256) {
        return k - 1;
    }
    function addone8(uint8 k) returns (uint8) {
        return k + 1;
    }
    function subone8(uint8 k) returns (uint8) {
        return k - 1;
    }
}
"""

    s = state()
    c = s.abi_contract(sdiv_code, language='solidity')

    # test uint8
    MAX8 = 255  # 2 ** 8 - 1
    assert c.addone8(1) == 2
    assert c.addone8(MAX8 - 1) == MAX8
    assert c.addone8(MAX8) == 0
    assert c.subone8(1) == 0
    assert c.subone8(0) == MAX8

    # test uint256
    MAX256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935  # 2 ** 256 - 1
    assert c.addone256(1) == 2
    assert c.addone256(MAX8 - 1) == MAX8
    assert c.addone256(MAX8) == MAX8 + 1
    assert c.addone256(MAX256 - 1) == MAX256
    assert c.addone256(MAX256) == 0
    assert c.subone256(1) == 0
    assert c.subone256(0) == MAX256


def test_sdiv():
    sdiv_code = """
contract testme {
    function kall() returns (uint, uint, uint) {
        return (2 ** 255, 2 ** 255 / 2 ** 253, 2 ** 255 % 3);
    }
}
"""

    s = state()
    c = s.abi_contract(sdiv_code, language='solidity')
    assert [57896044618658097711785492504343953926634992332820282019728792003956564819968, 4, 2] == c.kall()


def test_argcall():
    basic_argcall_code = """
contract testme {
    function argcall(uint[] args) returns (uint) {
        return args[0] + args[1] * 10 + args[2] * 100;
    }

    function argkall(uint[] args) returns (uint) {
        return this.argcall(args);
    }
}
"""

    s = state()
    c = s.abi_contract(basic_argcall_code, language='solidity')
    assert 375 == c.argcall([5, 7, 3])
    assert 376 == c.argkall([6, 7, 3])


slice_code = """
contract slicer {
    function slice(uint[] arr, uint start, uint len) returns (uint[]) {
        if (len > start + arr.length) {
            len = arr.length - start;
        }

        uint m = start + len;
        if (m > arr.length) {
            m = arr.length;
        }

        uint[] memory r = new uint[](len);

        uint i = 0;
        uint c = 0;
        while (i < m) {
            if (i >= start) {
                r[c] = arr[i];
                c++;
            }

            i++;
        }

        return r;
    }
}
"""


@pytest.mark.timeout(100)
def test_slice():
    s = state()
    c = s.abi_contract(slice_code, language='solidity')
    assert c.slice([1, 2, 3, 4], 1, 2) == [2, 3]
    assert c.slice([1, 2, 3, 4], 1, 3) == [2, 3, 4]
    assert c.slice([1, 2, 3, 4], 1, 10) == [2, 3, 4]


sort_code = """
%s // slice_code

contract sorter is slicer {
    function sort(uint[] args) returns (uint[]) {
        if (args.length < 2) {
            return args;
        }

        uint[] memory h = new uint[](args.length);
        uint hpos = 0;
        uint[] memory l = new uint[](args.length);
        uint lpos = 0;

        uint i = 1;
        while (i < args.length) {
            if (args[i] < args[0]) {
                l[lpos] = args[i];
                lpos += 1;
            } else {
                h[hpos] = args[i];
                hpos += 1;
            }

            i += 1;
        }

        uint[] memory x = slice(h, 0, hpos);
        h = sort(x);
        l = sort(slice(l, 0, lpos));

        uint[] memory o = new uint[](args.length);

        i = 0;
        while (i < lpos) {
            o[i] = l[i];
            i += 1;
        }

        o[lpos] = args[0];
        i = 0;
        while (i < hpos) {
            o[lpos + 1 + i] = h[i];
            i += 1;
        }

        return o;
    }
}
""" % slice_code


@pytest.mark.timeout(100)
def test_sort():
    s = state()
    c = s.abi_contract(sort_code, language='solidity')
    assert c.sort([9]) == [9]
    assert c.sort([9, 5]) == [5, 9]
    assert c.sort([9, 3, 5]) == [3, 5, 9]
    assert c.sort([80, 234, 112, 112, 29]) == [29, 80, 112, 112, 234]


sort_tester_code = \
    '''
%s // sort_code

contract indirect_sorter {
    sorter _sorter;

    function indirect_sorter() {
        _sorter = new sorter();
    }

    function test(uint[] arr) returns (uint[]) {
        return _sorter.sort(arr);
    }
}
''' % sort_code


@pytest.mark.timeout(100)
@pytest.mark.skip(reason="solidity doesn't support calls to dynamic array")
def test_indirect_sort():
    s = state()
    c = s.abi_contract(sort_tester_code, language='solidity')
    assert c.test([80, 234, 112, 112, 29]) == [29, 80, 112, 112, 234]


def test_multiarg_code():
    multiarg_code = """
contract testme {
    function kall(uint[] a, uint b, uint[] c, string d, uint e) returns (uint, string, uint) {
        uint x = a[0] + 10 * b + 100 * c[0] + 1000 * a[1] + 10000 * c[1] + 100000 * e;
        return (x, d, bytes(d).length);
    }
}
"""


    s = state()
    c = s.abi_contract(multiarg_code, language='solidity')
    o = c.kall([1, 2, 3], 4, [5, 6, 7], "doge", 8)
    assert o == [862541, b"doge", 4]


def test_ecrecover():
    """
    this is the original test_ecrecover from pyethereum but instead of generating the H,V,R,S we just hardcoded them.
    and the result is an address.
    """
    ecrecover_code = """
contract testme {
    function test_ecrecover(bytes32 h, uint8 v, bytes32 r, bytes32 s) returns (address) {
        return ecrecover(h, v, r, s);
    }
}
"""


    s = state()
    c = s.abi_contract(ecrecover_code, language='solidity')

    H = ethutils.int_to_big_endian(60772363713814795336605161565488663769306106990467902980560042300358765319404)
    V = 27
    R = ethutils.int_to_big_endian(90287243237479221899775907091281500587081321452634188922390320940254754609975)
    S = ethutils.int_to_big_endian(24052755845221258772445669055700842241658207900505567178705869501444775369481)

    result = c.test_ecrecover(H, V, R, S)
    assert result == "n4NdDG7mAJAESJ8E2E1fwmi6bnZMx1DV54"


def test_sha256():
    sha256_code = """
contract testme {
    function main() returns(bytes32, uint, bytes32, uint, bytes32, uint, bytes32, uint, bytes32, uint) {
        return (
            sha256(),
            uint(sha256()),
            sha256(3),
            uint(sha256(3)),
            sha256(uint(3)),
            uint(sha256(uint(3))),
            sha256("dog"),
            uint(sha256("dog")),
            sha256(uint(0), uint(0), uint(0), uint(0), uint(0)),
            uint(sha256(uint(0), uint(0), uint(0), uint(0), uint(0)))
        );
    }
}
"""

    s = state()
    c = s.abi_contract(sha256_code, language='solidity')

    o = c.main()
    assert o[0] == binascii.unhexlify(b'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855')
    assert o[1] == ethutils.big_endian_to_int(binascii.unhexlify(b'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'))
    assert o[2] == binascii.unhexlify(b'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5')
    assert o[3] == ethutils.big_endian_to_int(binascii.unhexlify(b'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5'))
    assert o[4] == binascii.unhexlify(b'd9147961436944f43cd99d28b2bbddbf452ef872b30c8279e255e7daafc7f946')
    assert o[5] == ethutils.big_endian_to_int(binascii.unhexlify(b'd9147961436944f43cd99d28b2bbddbf452ef872b30c8279e255e7daafc7f946'))
    assert o[6] == binascii.unhexlify(b'cd6357efdd966de8c0cb2f876cc89ec74ce35f0968e11743987084bd42fb8944')
    assert o[7] == ethutils.big_endian_to_int(binascii.unhexlify(b'cd6357efdd966de8c0cb2f876cc89ec74ce35f0968e11743987084bd42fb8944'))
    assert o[8] == binascii.unhexlify(b'b393978842a0fa3d3e1470196f098f473f9678e72463cb65ec4ab5581856c2e4')
    assert o[9] == ethutils.big_endian_to_int(binascii.unhexlify(b'b393978842a0fa3d3e1470196f098f473f9678e72463cb65ec4ab5581856c2e4'))


def test_ripemd160():
    ripemd160_code = """
contract testme {
    function main() returns(bytes20, uint, bytes20, uint, bytes20, uint, bytes20, uint, bytes20, uint) {
        return (
            ripemd160(),
            uint(ripemd160()),
            ripemd160(3),
            uint(ripemd160(3)),
            ripemd160(uint(3)),
            uint(ripemd160(uint(3))),
            ripemd160("dog"),
            uint(ripemd160("dog")),
            ripemd160(uint(0), uint(0), uint(0), uint(0), uint(0)),
            uint(ripemd160(uint(0), uint(0), uint(0), uint(0), uint(0)))
        );
    }
}
"""

    s = state()
    c = s.abi_contract(ripemd160_code, language='solidity')

    o = c.main()
    assert o[0] == binascii.unhexlify(b'9c1185a5c5e9fc54612808977ee8f548b2258d31')
    assert o[1] == ethutils.big_endian_to_int(binascii.unhexlify(b'9c1185a5c5e9fc54612808977ee8f548b2258d31'))
    assert o[2] == binascii.unhexlify(b'b2afadd73b9922f395573a52e7032b7597ff8c3e')
    assert o[3] == ethutils.big_endian_to_int(binascii.unhexlify(b'b2afadd73b9922f395573a52e7032b7597ff8c3e'))
    assert o[4] == binascii.unhexlify(b'44d90e2d3714c8663b632fcf0f9d5f22192cc4c8')
    assert o[5] == ethutils.big_endian_to_int(binascii.unhexlify(b'44d90e2d3714c8663b632fcf0f9d5f22192cc4c8'))
    assert o[6] == binascii.unhexlify(b'2a5756a3da3bc6e4c66a65028f43d31a1290bb75')
    assert o[7] == ethutils.big_endian_to_int(binascii.unhexlify(b'2a5756a3da3bc6e4c66a65028f43d31a1290bb75'))
    assert o[8] == binascii.unhexlify(b'9164cab7f680fd7a790080f2e76e049811074349')
    assert o[9] == ethutils.big_endian_to_int(binascii.unhexlify(b'9164cab7f680fd7a790080f2e76e049811074349'))


def test_sha3():
    sha3_code = """
contract testme {
    function main() returns(bytes32, uint, bytes32, uint, bytes32, uint, bytes32, uint, bytes32, uint) {
        return (
            sha3(),
            uint(sha3()),
            sha3(3),
            uint(sha3(3)),
            sha3(uint(3)),
            uint(sha3(uint(3))),
            sha3("dog"),
            uint(sha3("dog")),
            sha3(uint(0), uint(0), uint(0), uint(0), uint(0)),
            uint(sha3(uint(0), uint(0), uint(0), uint(0), uint(0)))
        );
    }
}
"""

    s = state()
    c = s.abi_contract(sha3_code, language='solidity')

    o = c.main()
    assert o[0] == binascii.unhexlify(b'c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470')
    assert o[1] == ethutils.big_endian_to_int(binascii.unhexlify(b'c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470'))
    assert o[2] == binascii.unhexlify(b'69c322e3248a5dfc29d73c5b0553b0185a35cd5bb6386747517ef7e53b15e287')
    assert o[3] == ethutils.big_endian_to_int(binascii.unhexlify(b'69c322e3248a5dfc29d73c5b0553b0185a35cd5bb6386747517ef7e53b15e287'))
    assert o[4] == binascii.unhexlify(b'c2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b')
    assert o[5] == ethutils.big_endian_to_int(binascii.unhexlify(b'c2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b'))
    assert o[6] == binascii.unhexlify(b'41791102999c339c844880b23950704cc43aa840f3739e365323cda4dfa89e7a')
    assert o[7] == ethutils.big_endian_to_int(binascii.unhexlify(b'41791102999c339c844880b23950704cc43aa840f3739e365323cda4dfa89e7a'))
    assert o[8] == binascii.unhexlify(b'dfded4ed5ac76ba7379cfe7b3b0f53e768dca8d45a34854e649cfc3c18cbd9cd')
    assert o[9] == ethutils.big_endian_to_int(binascii.unhexlify(b'dfded4ed5ac76ba7379cfe7b3b0f53e768dca8d45a34854e649cfc3c18cbd9cd'))


def test_prevhashes():
    global db
    prevhashes_code = """
contract testme {

    function get_prevhash(uint k) returns (bytes32) {
        return block.blockhash(block.number - k);
    }

    function get_prevhashes(uint k) returns (bytes32[]) {
        bytes32[] memory o = new bytes32[](k);

        uint i = 0;
        while (i < k) {
            o[i] = block.blockhash(block.number - i);
            i += 1;
        }

        return o;
    }
}
"""
    s = state()
    c = s.abi_contract(prevhashes_code, language='solidity')

    assert binascii.hexlify(c.get_prevhash(0)) == b"b5a4cd1270bc437e909d9569079ad17437a65822ee9e4c378670732a1430ed67"
    assert binascii.hexlify(c.get_prevhash(1)) == b"b5a4cd1270bc437e909d9569079ad17437a65822ee9e4c378670732a1430ed67"
    assert binascii.hexlify(c.get_prevhash(1)) == b"219e9a113a7c66443183171e389bfd5eaf957f5b8ab825358d72fa8e0cc8c16c"

    # Hashes of last 14 blocks including existing one
    o1 = c.get_prevhashes(14)

    cursor = db.cursor()
    blocks = list(cursor.execute('''SELECT * FROM blocks ORDER BY block_index DESC LIMIT %d''' % (14, )))
    cursor.close()
    t1 = [binascii.unhexlify(b['block_hash']) for b in blocks]

    assert o1 == t1

    # Test 256 limit: only 1 <= g <= 256 generation ancestors get hashes shown
    o2 = c.get_prevhashes(270)

    cursor = db.cursor()
    blocks = list(cursor.execute('''SELECT * FROM blocks ORDER BY block_index DESC LIMIT %d''' % (256, )))
    cursor.close()
    t2 = [binascii.unhexlify(b['block_hash']) for b in blocks] + ([b'\x00' * 32] * (270 - 256))

    assert o2 == t2


@pytest.mark.skip(reason='assembly')
def test_mcopy():
    mcopy_code = """
def mcopy_test(foo:str, a, b, c):
    info = string(32*3 + len(foo))
    info[0] = a
    info[1] = b
    info[2] = c
    mcopy(info+(items=3), foo, len(foo))
    return(info:str)
"""
    s = state()
    c = s.abi_contract(mcopy_code, language='solidity')
    assert c.mcopy_test("123", 5, 6, 259) == \
           b'\x00' * 31 + b'\x05' + b'\x00' * 31 + b'\x06' + b'\x00' * 30 + b'\x01\x03' + b'123'


@pytest.mark.skip(reason='assembly')
def test_mcopy2():
    mcopy_code_2 = """
def mcopy_test():
    myarr = array(3)
    myarr[0] = 99
    myarr[1] = 111
    myarr[2] = 119

    mystr = string(96)
    mcopy(mystr, myarr, items=3)
    return(mystr:str)
"""

    s = state()
    c = s.abi_contract(mcopy_code_2, language='solidity')
    assert c.mcopy_test() == \
           b''.join([ethutils.zpad(ethutils.int_to_big_endian(x), 32) for x in [99, 111, 119]])


def test_string_manipulation():
    string_manipulation_code = """
contract testme {
    function f1(string str) returns (string) {
        bytes(str)[0] = "a";
        bytes(str)[1] = "b";

        return str;
    }
}
"""


    s = state()
    c = s.abi_contract(string_manipulation_code, language='solidity')
    assert c.f1("cde") == b"abe"


def test_double_array():
    double_array_code = """
contract testme {
    function foo(uint[] a, uint[] b) returns (uint, uint) {
        uint i = 0;
        uint tot = 0;

        while (i < a.length) {
            tot = tot * 10 + a[i];
            i += 1;
        }

        uint j = 0;
        uint tot2 = 0;

        while (j < b.length) {
            tot2 = tot2 * 10 + b[j];
            j += 1;
        }

        return (tot, tot2);
    }

    function bar(uint[] a, string m, uint[] b) returns (uint, uint) {
        return (this.foo(a, b));
    }
}
"""
    s = state()
    c = s.abi_contract(double_array_code, language='solidity')
    assert c.foo([1, 2, 3], [4, 5, 6, 7]) == [123, 4567]
    assert c.bar([1, 2, 3], "moo", [4, 5, 6, 7]) == [123, 4567]


def test_abi_address_output():
    abi_address_output_test_code = """
contract testme {
    mapping(uint => address) addrs;

    function get_address(uint key) returns (address) {
        return addrs[key];
    }

    function register(uint key, address addr) {
        if (addrs[key] == 0x0) {
            addrs[key] = addr;
        }
    }
}
"""

    s = state()
    c = s.abi_contract(abi_address_output_test_code, language='solidity')
    c.register(123, tester.a0)
    c.register(123, tester.a1)
    c.register(125, tester.a2)
    assert c.get_address(123) == tester.a0
    assert c.get_address(125) == tester.a2


def test_inner_abi_address_output1():
    abi_address_output_test_code = """
contract subtestme {
    mapping(uint => address) addrs;

    function _get_address(uint key) returns (address) {
        return addrs[key];
    }

    function _register(uint key, address addr) {
        if (addrs[key] == 0x0) {
            addrs[key] = addr;
        }
    }
}

contract testme {
    address sub;

    function testme() {
        sub = new subtestme();
    }

    function get_address(uint key) returns (address) {
        return subtestme(sub)._get_address(key);
    }

    function register(uint key, address addr) {
        return subtestme(sub)._register(key, addr);
    }
}
"""

    s = state()
    c = s.abi_contract(abi_address_output_test_code, language='solidity')
    logger.warn('---------------------------------------------')
    c.register(123, tester.a0)
    c.register(123, tester.a1)
    c.register(125, tester.a2)
    assert c.get_address(123) == tester.a0
    assert c.get_address(125) == tester.a2



def test_inner_abi_address_output2():
    abi_address_output_test_code = """
contract subtestme {
    mapping(uint => address) addrs;

    function _get_address(uint key) returns (address) {
        return addrs[key];
    }

    function _register(uint key, address addr) {
        if (addrs[key] == 0x0) {
            addrs[key] = addr;
        }
    }
}

contract testme {
    subtestme sub;

    function testme() {
        sub = new subtestme();
    }

    function get_address(uint key) returns (address) {
        return subtestme(sub)._get_address(key);
    }

    function register(uint key, address addr) {
        return subtestme(sub)._register(key, addr);
    }
}
"""

    s = state()
    c = s.abi_contract(abi_address_output_test_code, language='solidity')
    logger.warn('---------------------------------------------')
    c.register(123, tester.a0)
    c.register(123, tester.a1)
    c.register(125, tester.a2)
    assert c.get_address(123) == tester.a0
    assert c.get_address(125) == tester.a2


def test_raw_logging():
    raw_logging_code = """
contract testme {
    function moo() {
        log0("msg1");
        log1("msg2", "t1");
        log2("msg3", "t1", "t2");
    }
}
"""

    s = state()
    c = s.abi_contract(raw_logging_code, language='solidity')
    o = []
    s.log_listeners.append(lambda x: o.append(x))

    c.moo()

    assert o[0].data == b'msg1'
    assert o[1].data == b'msg2'
    assert o[2].data == b'msg3'


def test_event_logging():
    event_logging_code = """
contract testme {
    event foo(
        string x,
        string y
    );

    function moo() {
        foo("bob", "cow");
    }
}
"""

    s = state()
    c = s.abi_contract(event_logging_code, language='solidity')
    o = []
    s.log_listeners.append(lambda x: o.append(c._translator.listen(x)))

    c.moo()

    assert o == [{"_event_type": b"foo", "x": b"bob", "y": b"cow"}]
