"""
@TODO: libraries
@TODO: compile_rich
"""
import hashlib
import pprint
import copy
import pytest
import binascii
import os
import sys
import logging
import serpent
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (config, database, util)
from counterpartylib.lib.evm import (blocks, processblock, ethutils, abi, address, vm, specials)

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


def test_calldata():
    global db
    s = state()

    message_gas = tester.DEFAULT_STARTGAS
    to, value, asset,  = 'n4NdDG7mAJAESJ8E2E1fwmi6bnZMx1DV54', 100, 'XCP'

    todata = ethutils.zpad(address.Address.normalize(to).bytes32(), 32)
    valuedata = ethutils.zpad(ethutils.int_to_big_endian(value), 32)
    assetdata = ethutils.zpad(bytes('XCP', 'utf-8'), 32)
    message_data = todata + valuedata + assetdata

    _, tx, block = s.mock_tx(tester.a0, tester.a0, 0, message_data, message_gas)  # need to mock a TX to create a VMExt

    databytearray = [ethutils.safe_ord(x) for x in tx.data]
    cd = vm.CallData(databytearray, 0, len(tx.data))
    assert cd.offset == 0
    assert cd.data == databytearray
    assert cd.size == len(tx.data)

    cd = vm.CallData([ethutils.safe_ord(x) for x in tx.data])
    assert cd.offset == 0
    assert cd.data == databytearray
    assert cd.size == len(tx.data)

    assert cd.extract_all() == tx.data
    assert cd.extract32(0) == ethutils.big_endian_to_int(todata)
    assert cd.extract32(32) == ethutils.big_endian_to_int(valuedata)
    assert cd.extract32(64) == ethutils.big_endian_to_int(assetdata)

    memstart = 0
    datastart = 0
    size = len(tx.data)
    mem = []
    mem.extend([0] * (size + memstart))
    cd.extract_copy(mem, memstart, datastart, size)
    assert mem == cd.data

    memstart = 0
    datastart = 0
    size = 32
    mem = []
    mem.extend([0] * (size + memstart))
    cd.extract_copy(mem, memstart, datastart, size)
    assert mem[memstart:memstart + size] == cd.data[datastart:datastart + size]

    memstart = 32
    datastart = 0
    size = 32
    mem = []
    mem.extend([0] * (size + memstart))
    cd.extract_copy(mem, memstart, datastart, size)
    assert mem[memstart:memstart + size] == cd.data[datastart:datastart + size]

    memstart = 0
    datastart = 96
    size = 32
    mem = []
    mem.extend([0] * (size + memstart))
    cd.extract_copy(mem, memstart, datastart, size)
    assert mem[memstart:memstart + size] == [0] * size


def test_message():
    global db
    s = state()

    message_gas = tester.DEFAULT_STARTGAS
    to, value, asset,  = 'n4NdDG7mAJAESJ8E2E1fwmi6bnZMx1DV54', 100, 'XCP'
    message_data = ethutils.zpad(address.Address.normalize(to).bytes32(), 32) + \
                   ethutils.zpad(ethutils.int_to_big_endian(value), 32) + \
                   ethutils.zpad(bytes('XCP', 'utf-8'), 32)

    _, tx, block = s.mock_tx(tester.a0, tester.a0, 0, message_data, message_gas)  # need to mock a TX to create a VMExt

    cd = vm.CallData([ethutils.safe_ord(x) for x in tx.data], 0, len(tx.data))
    msg = vm.Message(address.Address.normalize(tx.sender), address.Address.normalize(tx.to),
                         tx.value, message_gas, cd, code_address=address.Address.normalize(tx.to))

    assert msg.sender == tester.a0
    assert msg.to == tester.a0
    assert msg.value == 0
    assert msg.gas == message_gas
    assert msg.data == cd
    assert msg.depth == 0
    assert msg.logs == []
    assert msg.code_address == tester.a0
    assert msg.is_create == False
    assert msg.transfers_value == True

    assert repr(msg) == "<Message(to:mn6q3dS2...)>"


def test_compustate():
    compustate = vm.Compustate()
    assert compustate.memory == []
    assert compustate.stack == []
    assert compustate.pc == 0
    assert compustate.gas == 0

    compustate = vm.Compustate(gas=100, pc=1, memory=[1], stack=[1])
    assert compustate.memory == [1]
    assert compustate.stack == [1]
    assert compustate.pc == 1
    assert compustate.gas == 100


def test_mem_extend():
    compustate = vm.Compustate(gas=10)
    compustate_before = copy.deepcopy(compustate)

    assert vm.mem_extend(compustate.memory, compustate, op=None, start=0, sz=0)
    assert compustate.memory == []
    assert compustate.gas == compustate_before.gas

    assert vm.mem_extend(compustate.memory, compustate, op=None, start=0, sz=32)
    assert compustate.memory == [0] * 32
    assert compustate.gas == compustate_before.gas - 3

    assert vm.mem_extend(compustate.memory, compustate, op=None, start=32, sz=32)
    assert compustate.memory == [0] * 32 + [0] * 32
    assert compustate.gas == compustate_before.gas - 6

    # won't extend, we're claiming already existing memory
    assert vm.mem_extend(compustate.memory, compustate, op=None, start=0, sz=32)
    assert compustate.memory == [0] * 32 + [0] * 32
    assert compustate.gas == compustate_before.gas - 6

    # won't extend, we're claiming more than we can pay for
    assert not vm.mem_extend(compustate.memory, compustate, op=None, start=64, sz=128)
    assert compustate.memory == [0] * 32 + [0] * 32
    assert compustate.gas == 0


def test_data_copy():
    compustate = vm.Compustate(gas=10)
    compustate_before = copy.deepcopy(compustate)

    assert vm.data_copy(compustate, 0)
    assert compustate.gas == compustate_before.gas

    assert vm.data_copy(compustate, 32)
    assert compustate.gas == compustate_before.gas - 3

    assert not vm.data_copy(compustate, 128)
    assert compustate.gas == 0


def test_helpers():
    assert vm.vm_exception('BOOM') == (0, 0, [])
    assert vm.peaceful_exit('BOOM', 100, [1]) == (1, 100, [1])
