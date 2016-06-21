"""
@TODO: libraries
@TODO: compile_rich
"""
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


def test_proc_sha256():
    global db
    s = state()

    message_gas = tester.DEFAULT_STARTGAS

    for message_data, expected_result, expected_gascost in [
        (b'', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 60),
        (ethutils.zpad(b'', 32), '66687aadf862bd776c8fc18b8e9f8e20089714856ee233b3902a591d0d5f2925', 72),
        (ethutils.zpad(b'', 64), 'f5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b', 84),
        (ethutils.zpad(b'TEST', 32), 'd713641ada10b6f1541ea4d8bc678dd71b085f55244b79462403b1696182bc93', 72),
    ]:
        expected_result2 = binascii.hexlify(hashlib.sha256(message_data).digest()).decode('ascii')
        assert expected_result == expected_result2

        _, tx, block = s.mock_tx(tester.a0, tester.a0, 0, message_data, message_gas)  # need to mock a TX to create a VMExt
        ext = processblock.VMExt(db, block, tx)

        cd = vm.CallData([ethutils.safe_ord(x) for x in tx.data], 0, len(tx.data))
        msg = vm.Message(address.Address.normalize(tx.sender), address.Address.normalize(tx.to),
                             tx.value, message_gas, cd, code_address=address.Address.normalize(tx.to))

        success, gas_remaining, result = specials.proc_sha256(ext, msg)  # byte array

        assert success
        assert message_gas - gas_remaining == expected_gascost

        if success:
            result = ethutils.bytearray_to_int(result)
            result = ethutils.int_to_big_endian(result)
            result = binascii.hexlify(result).decode('ascii')

            assert result == expected_result


def test_proc_ripemd160():
    global db
    s = state()

    message_gas = tester.DEFAULT_STARTGAS

    for message_data, expected_result, expected_gascost in [
        (b'', '9c1185a5c5e9fc54612808977ee8f548b2258d31', 600),
        (ethutils.zpad(b'', 32), 'd1a70126ff7a149ca6f9b638db084480440ff842', 720),
        (ethutils.zpad(b'', 64), '9b8ccc2f374ae313a914763cc9cdfb47bfe1c229', 840),
        (ethutils.zpad(b'TEST', 32), '8be050d9755fc5d905a79ca91f90b983eb9df27e', 720),
    ]:
        expected_result2 = binascii.hexlify(hashlib.new('ripemd160', message_data).digest()).decode('ascii')
        assert expected_result == expected_result2

        _, tx, block = s.mock_tx(tester.a0, tester.a0, 0, message_data, message_gas)  # need to mock a TX to create a VMExt
        ext = processblock.VMExt(db, block, tx)

        cd = vm.CallData([ethutils.safe_ord(x) for x in tx.data], 0, len(tx.data))
        msg = vm.Message(address.Address.normalize(tx.sender), address.Address.normalize(tx.to),
                             tx.value, message_gas, cd, code_address=address.Address.normalize(tx.to))

        success, gas_remaining, result = specials.proc_ripemd160(ext, msg)  # byte array

        assert success
        assert message_gas - gas_remaining == expected_gascost

        if success:
            result = ethutils.bytearray_to_int(result)
            result = ethutils.int_to_big_endian(result)
            result = binascii.hexlify(result).decode('ascii')

            assert result == expected_result


def test_proc_ecrecover():
    global db
    s = state()

    message_gas = tester.DEFAULT_STARTGAS

    H = ethutils.int_to_big_endian(60772363713814795336605161565488663769306106990467902980560042300358765319404)
    V = ethutils.int_to_big_endian(27)
    R = ethutils.int_to_big_endian(90287243237479221899775907091281500587081321452634188922390320940254754609975)
    S = ethutils.int_to_big_endian(24052755845221258772445669055700842241658207900505567178705869501444775369481)

    message_data = ethutils.zpad(H, 32) + ethutils.zpad(V, 32) + ethutils.zpad(R, 32) + ethutils.zpad(S, 32)
    expected_result = "n4NdDG7mAJAESJ8E2E1fwmi6bnZMx1DV54"
    expected_gascost = 3000

    _, tx, block = s.mock_tx(tester.a0, tester.a0, 0, message_data, message_gas)  # need to mock a TX to create a VMExt
    ext = processblock.VMExt(db, block, tx)

    cd = vm.CallData([ethutils.safe_ord(x) for x in tx.data], 0, len(tx.data))

    msg = vm.Message(address.Address.normalize(tx.sender), address.Address.normalize(tx.to),
                         tx.value, message_gas, cd, code_address=address.Address.normalize(tx.to))

    success, gas_remaining, result = specials.proc_ecrecover(ext, msg)  # byte array

    assert success
    assert message_gas - gas_remaining == expected_gascost

    if success:
        result = ethutils.bytearray_to_int(result)
        result = address.Address.normalize(result)

        assert result == expected_result


def test_proc_identity():
    """WHAT IS THIS?"""
    global db
    s = state()

    message_gas = tester.DEFAULT_STARTGAS

    for message_data, expected_result, expected_gascost in [
        (b'', '', 15),
        (ethutils.zpad(b'', 32), '', 18),
        (ethutils.zpad(b'', 64), '', 21),
        (ethutils.zpad(b'TEST', 32), '54455354', 18),
    ]:
        _, tx, block = s.mock_tx(tester.a0, tester.a0, 0, message_data, message_gas)  # need to mock a TX to create a VMExt
        ext = processblock.VMExt(db, block, tx)

        cd = vm.CallData([ethutils.safe_ord(x) for x in tx.data], 0, len(tx.data))
        msg = vm.Message(address.Address.normalize(tx.sender), address.Address.normalize(tx.to),
                             tx.value, message_gas, cd, code_address=address.Address.normalize(tx.to))

        success, gas_remaining, result = specials.proc_identity(ext, msg)  # byte array

        assert success
        assert message_gas - gas_remaining == expected_gascost

        if success:
            result = ethutils.bytearray_to_int(result)
            result = ethutils.int_to_big_endian(result)
            result = binascii.hexlify(result).decode('ascii')

            assert result == expected_result


def test_proc_sendasset():
    global db
    s = state()

    sender = tester.a0
    message_gas = tester.DEFAULT_STARTGAS

    for to, value, asset, expected_result, expected_gascost in [
        ('n4NdDG7mAJAESJ8E2E1fwmi6bnZMx1DV54', 100, 'XCP', True, 600),
    ]:
        senderb = util.get_balance(db, sender, asset)
        recipientb = util.get_balance(db, to, asset)

        message_data = ethutils.zpad(address.Address.normalize(to).bytes32(), 32) + \
                       ethutils.zpad(ethutils.int_to_big_endian(value), 32) + \
                       ethutils.zpad(bytes('XCP', 'utf-8'), 32)

        _, tx, block = s.mock_tx(tester.a0, tester.a0, 0, message_data, message_gas)  # need to mock a TX to create a VMExt
        ext = processblock.VMExt(db, block, tx)

        cd = vm.CallData([ethutils.safe_ord(x) for x in tx.data], 0, len(tx.data))
        msg = vm.Message(address.Address.normalize(tx.sender), address.Address.normalize(tx.to),
                             tx.value, message_gas, cd, code_address=address.Address.normalize(tx.to))

        success, gas_remaining, result = specials.proc_sendasset(ext, msg)  # byte array

        assert success
        assert message_gas - gas_remaining == expected_gascost

        if success:
            result = ethutils.bytearray_to_int(result)
            result = bool(result)

            assert result == expected_result

            assert util.get_balance(db, sender, asset) == senderb - value
            assert util.get_balance(db, to, asset) == recipientb + value
