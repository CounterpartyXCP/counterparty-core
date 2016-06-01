import pytest
import binascii
import os
import sys
import logging
import serpent
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (config, database)
from counterpartylib.lib.evm import (blocks, processblock, ethutils, abi, address, solidity)

from counterpartylib.test.evm import contracts_tester as tester
from counterpartylib.test import util_test

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


def test_simple_contract():
    simple_solidity_contract = """
contract zoo {
    function sub2() returns (int256 y) {
        y = 7;
    }
}
"""

    s = state()
    c1 = s.abi_contract(simple_solidity_contract, language='solidity')
    assert c1.sub2() == 7


def test_address_contract_solidity():
    contract = """
contract zoo {
    function main(address a) returns (int256 y) {
        y = 7;
    }
    function sub(address a) returns (address b) {
        return a;
    }
}
"""

    s = state()
    c1 = s.abi_contract(contract, language='solidity')
    assert c1.main(c1.address) == 7
    assert c1.sub(c1.address) == c1.address.base58()


@pytest.mark.skip()
def test_compile_from_file(tmpdir):
    contractsdir = tmpdir.mkdir("contracts")
    librarypath = contractsdir.join("Other.sol")
    librarypath.write("""library Other {
    function seven() returns (int256 y) {
        y = 7;
    }
}
""")
    userpath = contractsdir.join("user.sol")
    userpath.write("""import "Other.sol";
contract user {
    function test() returns (int256 seven) {
        seven = Other.seven();
    }
}
""")
    s = state()
    # library calls need CALLCODE opcode:
    librarycontract = s.abi_contract(None, path=str(librarypath), language='solidity')
    assert librarycontract.seven() == 7
    libraryuser = s.abi_contract(None, path=str(userpath),
            # libraries still need to be supplied with their address:
            libraries={'Other': librarycontract.address},
            language='solidity')

    logger.warn('-----------------------------')
    assert libraryuser.test() == 7


@pytest.mark.skip()
def test_interop():
    serpent_contract = """
extern solidity: [sub2:[]:i]

def main(a):
    return(a.sub2() * 2)

def sub1():
    return(5)

"""

    solidity_contract = """
contract serpent {
    function sub1() returns (int256 y) {}
}

contract zoo {
    function main(address a) returns (int256 y) {
        y = serpent(a).sub1() * 2;
    }
    function sub2() returns (int256 y) {
        y = 7;
    }
    function sub3(address a) returns (address b) {
        b = a;
    }
}
"""

    s = state()
    c1 = s.abi_contract(serpent_contract)
    c2 = s.abi_contract(solidity_contract, language='solidity')
    assert c1.sub1() == 5
    assert c2.sub2() == 7
    assert c2.sub3(c2.address) == c2.address
    assert c1.main(c2.address) == 14
    assert c2.main(c1.address) == 10


@pytest.mark.skip()
def test_constructor():
    CONSTRUCTOR_CONTRACT = '''
contract testme {
    uint value;
    function testme(uint a) {
        value = a;
    }
    function getValue() returns (uint) {
        return value;
    }
}
'''


    s = state()

    contract = s.abi_contract(
        CONSTRUCTOR_CONTRACT,
        language='solidity',
        constructor_parameters=(2, ),
    )
    assert contract.getValue() == 2  # pylint: disable=no-member


@pytest.mark.xfail(reason="bytecode in test seems to be wrong")
def test_solidity_compile_rich():
    compile_rich_contract = """
contract contract_add {
    function add7(uint a) returns(uint d) { return a + 7; }
    function add42(uint a) returns(uint d) { return a + 42; }
}
contract contract_sub {
    function subtract7(uint a) returns(uint d) { return a - 7; }
    function subtract42(uint a) returns(uint d) { return a - 42; }
}
"""

    contract_info = get_solidity().compile_rich(compile_rich_contract)

    assert len(contract_info) == 2
    assert set(contract_info.keys()) == {'contract_add', 'contract_sub'}
    assert set(contract_info['contract_add'].keys()) == {'info', 'code'}
    assert set(contract_info['contract_add']['info'].keys()) == {
        'language', 'languageVersion', 'abiDefinition', 'source',
        'compilerVersion', 'developerDoc', 'userDoc'
    }
    assert contract_info['contract_add']['code'] == (
        "0x606060405260ad8060116000396000f30060606040526000357c0100000000000000"
        "00000000000000000000000000000000000000000090048063651ae239146041578063"
        "cb02919f14606657603f565b005b6050600480359060200150608b565b604051808281"
        "5260200191505060405180910390f35b6075600480359060200150609c565b60405180"
        "82815260200191505060405180910390f35b60006007820190506097565b919050565b"
        "6000602a8201905060a8565b91905056")
    assert contract_info['contract_sub']['code'] == (
        "0x606060405260ad8060116000396000f30060606040526000357c0100000000000000"
        "0000000000000000000000000000000000000000009004806361752024146041578063"
        "7aaef1a014606657603f565b005b6050600480359060200150608b565b604051808281"
        "5260200191505060405180910390f35b6075600480359060200150609c565b60405180"
        "82815260200191505060405180910390f35b60006007820390506097565b919050565b"
        "6000602a8203905060a8565b91905056")
    assert {
        defn['name']
        for defn
        in contract_info['contract_add']['info']['abiDefinition']
    } == {'add7', 'add42'}
    assert {
        defn['name']
        for defn
        in contract_info['contract_sub']['info']['abiDefinition']
    } == {'subtract7', 'subtract42'}
