"""
@TODO: add more decode_abi tests
@TODO: add bool to translator
"""

import os

import binascii
import pprint

import pytest
import logging
import tempfile
from counterpartylib.lib.evm import abi, ethutils, solidity
from counterpartylib.lib.evm.ethutils import zpad, big_endian_to_int
from counterpartylib.lib import (config, util, database)
from counterpartylib import server
from counterpartylib.lib.evm.address import Address
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR

logger = logging.getLogger()


def setup_module():
    """Initialise the database with default data and wait for server to be ready."""
    server.initialise(
        database_file=tempfile.gettempdir() + '/fixtures.unittest.db',
        testnet=True,
        verbose=True,
        console_logfilter=os.environ.get('COUNTERPARTY_LOGGING', None),
        **util_test.COUNTERPARTYD_OPTIONS)
    util_test.restore_database(config.DATABASE, CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql')
    db = database.get_connection(read_only=False)  # reinit the DB to deal with the restoring
    util.FIRST_MULTISIG_BLOCK_TESTNET = 1


def test_decint():
    assert abi.decint(True) == 1
    assert abi.decint(False) == 0
    assert abi.decint(None) == 0
    assert abi.decint(b'\x80', signed=True) == 128
    assert abi.decint(b'\x80', signed=False) == 128
    assert abi.decint(b'\x80' + b'\x00' * 31) == 2**255
    assert abi.decint(ethutils.encode_int(2**255)) == 2**255

    # these 2 are here for coverage, but it passing a string to this function seems ... not fun
    #  can't even figure out what to pass in to get 128 ...
    assert abi.decint('\x80', signed=True) == 49792
    assert abi.decint('80', signed=True) == 14384

    with pytest.raises(abi.EncodingError):
        abi.decint(ethutils.int_to_big_endian(2**256))

    with pytest.raises(abi.EncodingError):
        abi.decint(2**256)


def test_split32():
    assert abi.split32((b'\x80' + b'\x00' * 31) + (b'\x80' + b'\x00' * 31) + (b'\x80' + b'\x00' * 31)) == [
        (b'\x80' + b'\x00' * 31),
        (b'\x80' + b'\x00' * 31),
        (b'\x80' + b'\x00' * 31)
    ]


def test_method_id():
    assert abi.method_id("testing", ['uint', 'string']) == 1757740966
    assert abi.method_id("testing", ['int', 'string']) == 597284682
    assert abi.method_id("testing1", ['uint', 'string']) == 655633791
    assert abi.method_id("testing", ['uint', 'string', 'real']) == 908466444
    assert abi.method_id("testing", ['uint', 'string', 'int[]']) == 3624578441
    assert abi.method_id("testing", ['uint', 'string', 'real[]']) == 1512009967


def test_event_id():
    assert abi.event_id("testing", ['uint', 'string']) == 47388602704038250307321141802556537138353267607313153589011501108000334140522
    assert abi.event_id("testing", ['int', 'string']) == 16102763185812378265181316846405570478510123236642994446405424426181447813586
    assert abi.event_id("testing1", ['uint', 'string']) == 17675852040277289587562860521505691085186189050619676254098385956118454687959
    assert abi.event_id("testing", ['uint', 'string', 'real']) == 24492206898876409151043887744883378098333794218860744712657534959760839209441
    assert abi.event_id("testing", ['uint', 'string', 'int[]']) == 97718441479119825803197876558522575518578577091982638483825229497302703334206
    assert abi.event_id("testing", ['uint', 'string', 'real[]']) == 40763708087341862307382800872706179706276532355091733285990606195176302394827


def test_process_type():
    assert abi.process_type('ureal128x128') == ('ureal', '128x128', [])
    with pytest.raises(AssertionError):
        abi.process_type('ureal')
    with pytest.raises(AssertionError):
        abi.process_type('ureal8')
    with pytest.raises(AssertionError):
        abi.process_type('ureal127x127')

    assert abi.process_type('hash8') == ('hash', '8', [])
    with pytest.raises(AssertionError):
        abi.process_type('hash')

    assert abi.process_type('int8') == ('int', '8', [])
    with pytest.raises(AssertionError):
        abi.process_type('int')
    with pytest.raises(AssertionError):
        abi.process_type('int257')
    with pytest.raises(AssertionError):
        abi.process_type('int9')

    assert abi.process_type('uint8') == ('uint', '8', [])
    with pytest.raises(AssertionError):
        abi.process_type('uint')

    assert abi.process_type('string') == ('string', '', [])
    assert abi.process_type('string8') == ('string', '8', [])
    with pytest.raises(AssertionError):
        abi.process_type('stringFAKE')
    with pytest.raises(AssertionError):
        abi.process_type('string33')

    assert abi.process_type('bytes') == ('bytes', '', [])
    assert abi.process_type('bytes8') == ('bytes', '8', [])
    with pytest.raises(AssertionError):
        abi.process_type('bytesFAKE')
    with pytest.raises(AssertionError):
        abi.process_type('bytes33')

    assert abi.process_type('address') == ('address', '', [])
    with pytest.raises(AssertionError):
        abi.process_type('address32')

    assert abi.process_type('address[5]') == ('address', '', [[5]])
    assert abi.process_type('address[]') == ('address', '', [[]])
    with pytest.raises(AssertionError):
        abi.process_type('address32[]')


def test_get_size():
    assert abi.get_size(('string', '', [])) == None
    assert abi.get_size(('string', '32', [])) == 32
    assert abi.get_size(('int', '8', [])) == 32
    assert abi.get_size(('address', '', [])) == 32
    assert abi.get_size(('address', '', [[]])) == None
    assert abi.get_size(('address', '', [[5]])) == 32 * 5


def test_abi_encode_single_invalid_type():
    with pytest.raises(abi.EncodingError):
        abi.encode_single(['notatype', '', []], 1)


def test_abi_encode_int():
    assert abi.encode_single(['uint', '16', []], 128) == ethutils.zpad(b'\x80', 32)
    assert abi.encode_single(['uint', '128', []], 128) == ethutils.zpad(b'\x80', 32)
    assert abi.encode_single(['uint', '8', []], 128) == ethutils.zpad(b'\x80', 32)

    assert abi.encode_single(['int', '16', []], 128) == ethutils.zpad(b'\x80', 32)
    assert abi.encode_single(['int', '128', []], 128) == ethutils.zpad(b'\x80', 32)
    with pytest.raises(abi.ValueOutOfBounds):
        abi.encode_single(['int', '8', []], 128)

    assert abi.encode_single(['int', '256', []], -2**255) == (b'\x80'+b'\x00'*31)

    assert abi.encode_single(['int', '8', []], -128) == zpad(b'\x80', 32)
    with pytest.raises(abi.ValueOutOfBounds):
        assert abi.encode_single(['int', '8', []], -129)

    assert abi.encode_single(['int', '8', []], 127) == zpad(b'\x7f', 32)
    with pytest.raises(abi.ValueOutOfBounds):
        assert abi.encode_single(['int', '8', []], 128)

    assert abi.encode_abi(['uint8'], [128]) == ethutils.zpad(b'\x80', 32)
    assert abi.encode_abi(['uint8', 'uint8'], [128, 128]) == ethutils.zpad(b'\x80', 32) + ethutils.zpad(b'\x80', 32)


def test_abi_encode_str1():
    assert abi.encode_single(('bytes', '', []), b"t1") == b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02t1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
    assert big_endian_to_int(abi.encode_single(('bytes', '', []), b"t1")) == 284139044416465432730597154176973926959828477843846413988242344473275234516992


def test_abi_encode_var_sized_array():
    # <lenbyte:zpad32><hash20:zpad32><hash20:zpad32><hash20:zpad32>
    assert abi.enc(('hash', '20', [[]]), [b'\x01' * 20] * 3) == zpad(b'\x03', 32) + (zpad(b'\x01' * 20, 32) * 3)

    # <lenbyte:zpad32><addrbytes:zpad32><addrbytes:zpad32><addrbytes:zpad32>
    assert abi.enc(('address', '', [[]]), [Address.normalize("tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt").bytes()] * 3) == \
           zpad(b'\x03', 32) + (Address.normalize("tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt").bytes32() * 3)

    # <offset:zpad32><lenbyte:zpad32><hash20:zpad32><hash20:zpad32><hash20:zpad32>
    assert abi.encode_abi(['hash20[]'], [[b'\x01' * 20] * 3]) == \
           ethutils.zpad(binascii.unhexlify("20"), 32) + zpad(b'\x03', 32) + (zpad(b'\x01' * 20, 32) * 3)

    # <offset:zpad32><offset:zpad32><lenbyte:zpad32><hash20:zpad32><hash20:zpad32><hash20:zpad32><lenbyte:zpad32><hash20:zpad32><hash20:zpad32><hash20:zpad32>
    assert abi.encode_abi(['hash20[]', 'hash20[]'], [[b'\x01' * 20] * 3, [b'\x01' * 20] * 3]) == \
           ethutils.zpad(binascii.unhexlify("40"), 32) + ethutils.zpad(binascii.unhexlify("c0"), 32) + zpad(b'\x03', 32) + (zpad(b'\x01' * 20, 32) * 3) + zpad(b'\x03', 32) + (zpad(b'\x01' * 20, 32) * 3)

    # <offset:zpad32><lenbyte:zpad32><addrbytes:zpad32><addrbytes:zpad32><addrbytes:zpad32>
    assert abi.encode_abi(['address[]'], [[Address.normalize("tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt").bytes()] * 3]) == \
           ethutils.zpad(binascii.unhexlify("20"), 32) + zpad(b'\x03', 32) + (Address.normalize("tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt").bytes32() * 3)


def test_abi_encode_fixed_sized_array():
    # <hash20:zpad32><hash20:zpad32><hash20:zpad32>
    assert abi.enc(('hash', '20', [[3]]), [b'\x01' * 20] * 3) == (zpad(b'\x01' * 20, 32) * 3)

    # <addrbytes:zpad32><addrbytes:zpad32><addrbytes:zpad32>
    assert abi.enc(('address', '', [[3]]), [Address.normalize("tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt").bytes()] * 3) == \
           (Address.normalize("tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt").bytes32() * 3)

    # <hash20:zpad32><hash20:zpad32><hash20:zpad32>
    assert abi.encode_abi(['hash20[3]'], [[b'\x01' * 20] * 3]) == \
           (zpad(b'\x01' * 20, 32) * 3)

    # <hash20:zpad32><hash20:zpad32><hash20:zpad32><hash20:zpad32><hash20:zpad32><hash20:zpad32>
    assert abi.encode_abi(['hash20[3]', 'hash20[3]'], [[b'\x01' * 20] * 3, [b'\x01' * 20] * 3]) == \
           (zpad(b'\x01' * 20, 32) * 3) + (zpad(b'\x01' * 20, 32) * 3)

    # <offset:zpad32><lenbyte:zpad32><addrbytes:zpad32><addrbytes:zpad32><addrbytes:zpad32>
    assert abi.encode_abi(['address[3]'], [[Address.normalize("tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt").bytes()] * 3]) == \
           (Address.normalize("tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt").bytes32() * 3)


def test_abi_encode_mixed_sizes():
    # the offset of the var length hash20[] is amongst the non var length, but the content after
    # <uint8(32):zpad32>
    # <offset:zpad32>
    # <uint8(32):zpad32>
    # <offset:zpad32>
    # <lenbyte:zpad32><hash20:zpad32><hash20:zpad32><hash20:zpad32>
    # <lenbyte:zpad32><hash20:zpad32><hash20:zpad32><hash20:zpad32>
    assert abi.encode_abi(['uint8', 'hash20[]', 'uint8', 'hash20[]'], [128, [b'\x01' * 20] * 3, 128, [b'\x01' * 20] * 3]) == \
           zpad(b'\x80', 32) + \
           ethutils.zpad(binascii.unhexlify("80"), 32) + \
           zpad(b'\x80', 32) + \
           ethutils.zpad(binascii.unhexlify("0100"), 32) + \
           zpad(b'\x03', 32) + \
           (zpad(b'\x01' * 20, 32) * 3) + \
           zpad(b'\x03', 32) + \
           (zpad(b'\x01' * 20, 32) * 3)


def test_abi_encode_ureal():
    assert abi.encode_single(['ureal', '128x128', []], 0) == (b'\x00'*32)
    assert abi.encode_single(['ureal', '128x128', []], 1.125) == (b'\x00'*15 + b'\x01\x20' + b'\x00'*15)
    assert abi.encode_single(['ureal', '128x128', []], 2**127-1) == (b'\x7f' + b'\xff'*15 + b'\x00'*16)

    assert abi.encode_abi(['ureal128x128'], [2**127-1]) == (b'\x7f' + b'\xff'*15 + b'\x00'*16)
    assert abi.encode_abi(['ureal128x128', 'ureal128x128'], [2**127-1, 2**127-1]) == (b'\x7f' + b'\xff'*15 + b'\x00'*16) + (b'\x7f' + b'\xff'*15 + b'\x00'*16)


def test_abi_encode_real():
    assert abi.encode_single(['real', '128x128', []], 1.125) == (b'\x00'*15 + b'\x01\x20' + b'\x00'*15)
    assert abi.encode_single(['real', '128x128', []], -1.125) == (b'\xff'*15 + b'\xfe' + b'\xe0' + b'\x00'*15)

    assert abi.encode_abi(['real128x128'], [-1.125]) == (b'\xff'*15 + b'\xfe' + b'\xe0' + b'\x00'*15)
    assert abi.encode_abi(['real128x128', 'real128x128'], [-1.125, -1.125]) == (b'\xff'*15 + b'\xfe' + b'\xe0' + b'\x00'*15) + (b'\xff'*15 + b'\xfe' + b'\xe0' + b'\x00'*15)


def test_abi_encode_hash():
    assert abi.encode_single(['hash', '8', []], b'\x00'*8) == b'\x00'*32
    assert abi.encode_single(['hash', '8', []], '00'*8) == b'\x00'*32

    assert abi.encode_abi(['hash8'], ['00'*8]) == b'\x00'*32


def test_abi_encode_bool():
    assert abi.encode_single(['bool', '', []], True) == zpad(b'\x01', 32)
    assert abi.encode_single(['bool', '', []], False) == zpad(b'\x00', 32)

    assert abi.encode_abi(['bool'], [True]) == zpad(b'\x01', 32)


def test_abi_decode_bool():
    assert abi.decode_single(['bool', '', []], zpad(b'\x01', 32)) == True
    assert abi.decode_single(['bool', '', []], zpad(b'\x00', 32)) == False

    assert abi.decode_abi(['bool'], zpad(b'\x01', 32)) == [True]


def test_abi_decode_single_hash():
    typ = ['hash', '8', []]
    assert b'\x01'*8 == abi.decode_single(typ, abi.encode_single(typ, b'\x01'*8))


def test_abi_encode_single_bytes():
    typ = ['bytes', '8', []]
    assert abi.encode_single(typ, b'\x01\x02') == b'\x01\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'

    typ = ['bytes', '', []]
    assert abi.encode_single(typ, b'\x01\x02') == b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x01\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'


def test_abi_decode_single_bytes():
    typ = ['bytes', '8', []]
    assert (b'\x01\x02' + b'\x00'*6) == abi.decode_single(typ, abi.encode_single(typ, b'\x01\x02'))

    typ = ['bytes', '', []]
    assert b'\x01\x02' == abi.decode_single(typ, abi.encode_single(typ, b'\x01\x02'))


def test_abi_encode_address():
    address = 'tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt'
    assert abi.encode_single(['address', '', []], address) == b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x11\x9e\xfc\xb7s\xcf7h\xd0K\xdfy\x7f|6\x05\x80\x8d\xce\n'

    with pytest.raises(abi.EncodingError):
        abi.encode_single(['address', '', []], "notanaddress")


def test_abi_decode_address():
    address = 'tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt'
    assert abi.decode_single(['address', '', []], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x11\x9e\xfc\xb7s\xcf7h\xd0K\xdfy\x7f|6\x05\x80\x8d\xce\n') == address


def test_abi_decode_single_real():
    real_data = abi.encode_single(['real', '128x128', []], 1)
    assert abi.decode_single(['real', '128x128', []], real_data) == 1

    real_data = abi.encode_single(['real', '128x128', []], 2**127-1)
    assert abi.decode_single(['real', '128x128', []], real_data) == (2**127-1)*1.0

    real_data = abi.encode_single(['real', '128x128', []], -1)
    assert abi.decode_single(['real', '128x128', []], real_data) == -1

    real_data = abi.encode_single(['real', '128x128', []], -2**127)
    assert abi.decode_single(['real', '128x128', []], real_data) == -2**127


def test_contract_translator1():
    code = """
contract testme {}
"""

    _abi = solidity.get_solidity().mk_full_signature(code, optimize=False)
    translator = abi.ContractTranslator(_abi)

    assert translator.constructor_data is None
    assert translator.function_data == {}
    assert translator.event_data == {}

    with pytest.raises(ValueError):
        translator.encode_function_call("fn", [])

    with pytest.raises(ValueError):
        translator.encode_constructor_arguments([])


def test_contract_translator2():
    code = """
contract testme {
    event testevent(uint arg1, uint8 arg2, int arg3, int8 arg4, string arg5, address arg6, bytes arg7, address[] arg8);

    function testme(uint arg1, uint8 arg2, int arg3, int8 arg4, string arg5, address arg6, bytes arg7, address[] arg8) {

    }

    function fn(uint arg1, uint8 arg2, int arg3, int8 arg4, string arg5, address arg6, bytes arg7, address[] arg8) {

    }

    function fn2() returns (uint arg1, uint8 arg2, int arg3, int8 arg4, string arg5, address arg6, bytes arg7, address[] arg8) {

    }
}
"""

    _abi = solidity.get_solidity().mk_full_signature(code, optimize=False)
    translator = abi.ContractTranslator(_abi)

    assert translator.constructor_data == {
        'encode_types': ['uint256', 'uint8', 'int256', 'int8', 'string', 'address', 'bytes', 'address[]'],
        'signature': [('uint256', 'arg1'), ('uint8', 'arg2'), ('int256', 'arg3'), ('int8', 'arg4'), ('string', 'arg5'), ('address', 'arg6'), ('bytes', 'arg7'), ('address[]', 'arg8')]
    }
    assert translator.function_data == {
        'fn2': {
            'encode_types': [],
            'signature': [],
            'decode_types': ['uint256', 'uint8', 'int256', 'int8', 'string', 'address', 'bytes', 'address[]'],
            'is_constant': False,
            'prefix': 2563926545
        },
        'fn': {
            'encode_types': ['uint256', 'uint8', 'int256', 'int8', 'string', 'address', 'bytes', 'address[]'],
            'signature': [('uint256', 'arg1'), ('uint8', 'arg2'), ('int256', 'arg3'), ('int8', 'arg4'), ('string', 'arg5'), ('address', 'arg6'), ('bytes', 'arg7'), ('address[]', 'arg8')],
            'decode_types': [],
            'is_constant': False,
            'prefix': 2382282203
        }
    }
    assert translator.event_data == {
        108868822796353946861798347848216868693081281178430221945745259594108497829215: {
            'indexed': [False, False, False, False, False, False, False, False],
            'anonymous': False,
            'types': ['uint256', 'uint8', 'int256', 'int8', 'string', 'address', 'bytes', 'address[]'],
            'names': ['arg1', 'arg2', 'arg3', 'arg4', 'arg5', 'arg6', 'arg7', 'arg8'],
            'name': 'testevent'
        }
    }

    address = Address.normalize("tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt")
    assert translator.encode_function_call('fn2', []) == b'\x98\xd2j\x11'
    assert translator.encode_function_call('fn', []) == b'\x8d\xfe\xbd\xdb'

    # map to the hex below
    # prefix
    # 1
    # 1
    # 1
    # 1
    # string offset
    # address
    # bytes offset
    # address[] offset
    # string length
    # string
    # bytes length
    # bytes
    # address[] length
    # address[0]
    assert binascii.hexlify(translator.encode_function_call('fn', [
        1, 1, 1, 1, "test", address, b"test", [address]
    ])) == b'8dfebddb' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000100' \
           b'000000000000000000000080119efcb773cf3768d04bdf797f7c3605808dce0a' \
           b'0000000000000000000000000000000000000000000000000000000000000140' \
           b'0000000000000000000000000000000000000000000000000000000000000180' \
           b'0000000000000000000000000000000000000000000000000000000000000004' \
           b'7465737400000000000000000000000000000000000000000000000000000000' \
           b'0000000000000000000000000000000000000000000000000000000000000004' \
           b'7465737400000000000000000000000000000000000000000000000000000000' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'000000000000000000000080119efcb773cf3768d04bdf797f7c3605808dce0a'

    # map to the hex below
    # 1
    # 1
    # 1
    # 1
    # string offset
    # address
    # bytes offset
    # address[] offset
    # string length
    # string
    # bytes length
    # bytes
    # address[] length
    # address[0]
    assert binascii.hexlify(translator.encode_constructor_arguments([
        1, 1, 1, 1, "test", address, b"test", [address]
    ])) == b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000100' \
           b'000000000000000000000080119efcb773cf3768d04bdf797f7c3605808dce0a' \
           b'0000000000000000000000000000000000000000000000000000000000000140' \
           b'0000000000000000000000000000000000000000000000000000000000000180' \
           b'0000000000000000000000000000000000000000000000000000000000000004' \
           b'7465737400000000000000000000000000000000000000000000000000000000' \
           b'0000000000000000000000000000000000000000000000000000000000000004' \
           b'7465737400000000000000000000000000000000000000000000000000000000' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'000000000000000000000080119efcb773cf3768d04bdf797f7c3605808dce0a'

    assert translator.decode("fn2", binascii.unhexlify(
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'0000000000000000000000000000000000000000000000000000000000000100' \
           b'000000000000000000000080119efcb773cf3768d04bdf797f7c3605808dce0a' \
           b'0000000000000000000000000000000000000000000000000000000000000140' \
           b'0000000000000000000000000000000000000000000000000000000000000180' \
           b'0000000000000000000000000000000000000000000000000000000000000004' \
           b'7465737400000000000000000000000000000000000000000000000000000000' \
           b'0000000000000000000000000000000000000000000000000000000000000004' \
           b'7465737400000000000000000000000000000000000000000000000000000000' \
           b'0000000000000000000000000000000000000000000000000000000000000001' \
           b'000000000000000000000080119efcb773cf3768d04bdf797f7c3605808dce0a')) == \
        [1, 1, 1, 1, b"test", address.base58(), b"test", [address.base58()]]


