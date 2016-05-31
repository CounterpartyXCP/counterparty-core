import os
import pytest
import logging
import tempfile
from counterpartylib.lib.evm import abi
from counterpartylib.lib.evm.ethutils import zpad
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


@pytest.mark.skip()
def test_abi_encode_var_sized_array():
    abi.encode_abi(['address[]'], [[b'\x00' * 20] * 3])


def test_abi_encode_fixed_size_array():
    abi.encode_abi(['uint16[2]'], [[5, 6]])


def test_abi_encode_signed_int():
    assert abi.decode_abi(['int8'], abi.encode_abi(['int8'], [1]))[0] == 1
    assert abi.decode_abi(['int8'], abi.encode_abi(['int8'], [-1]))[0] == -1


def test_abi_encode_single_int():
    assert abi.encode_single(['int', '256', []], -2**255) == (b'\x80'+b'\x00'*31)

    assert abi.encode_single(['int', '8', []], -128) == zpad(b'\x80', 32)
    with pytest.raises(abi.ValueOutOfBounds):
        assert abi.encode_single(['int', '8', []], -129)

    assert abi.encode_single(['int', '8', []], 127) == zpad(b'\x7f', 32)
    with pytest.raises(abi.ValueOutOfBounds):
        assert abi.encode_single(['int', '8', []], 128)


def test_abi_encode_single_ureal():
    assert abi.encode_single(['ureal', '128x128', []], 0) == (b'\x00'*32)
    assert abi.encode_single(['ureal', '128x128', []], 1.125) == (b'\x00'*15 + b'\x01\x20' + b'\x00'*15)
    assert abi.encode_single(['ureal', '128x128', []], 2**127-1) == (b'\x7f' + b'\xff'*15 + b'\x00'*16)


def test_abi_encode_single_real():
    assert abi.encode_single(['real', '128x128', []], 1.125) == (b'\x00'*15 + b'\x01\x20' + b'\x00'*15)
    assert abi.encode_single(['real', '128x128', []], -1.125) == (b'\xff'*15 + b'\xfe' + b'\xe0' + b'\x00'*15)


def test_abi_encode_single_hash():
    assert abi.encode_single(['hash', '8', []], b'\x00'*8) == b'\x00'*32
    assert abi.encode_single(['hash', '8', []], '00'*8) == b'\x00'*32


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

