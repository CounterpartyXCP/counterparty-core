import pprint
import tempfile
import pytest
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP, ADDR

from counterpartylib.lib import util, backend

FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'



@pytest.mark.usefixtures("server_db")
def test_searchrawtransactions_output():
    txs = backend.searchrawtransactions(ADDR[0], unconfirmed=True)
    tx = txs[0]

    tx = backend.getrawtransaction('02f95716d3c93a1e81b926d9d8d5f05b6f382c115d9ecf0dd0bc9514b0e08649', verbose=True)

    pprint.pprint(tx)

    # general
    assert tx['txid'] == '02f95716d3c93a1e81b926d9d8d5f05b6f382c115d9ecf0dd0bc9514b0e08649'
    assert tx['confirmations'] == 6
    assert tx['hex'] == '0100000001a7f84ec59ff69951f5dc732c77199e177ab608b030f449899a81f13c921d01f4010000001976a9146c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a15288acffffffff0200a3e111000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b21037af2e06061b54cdfe3657bbc8496d69000b822e2db0c86ccbe376346a700b83353ae38847ee2000000001976a9146c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a15288ac00000000'
    assert tx['size'] == 224
    assert tx['version'] == 1
    assert tx['locktime'] == 0
    assert tx['time'] == None  # not mocked yet
    assert tx['blocktime'] == None  # not mocked yet
    assert tx['blockhash'] == None  # not mocked yet

    # vin
    assert tx['vin'] == []  # not mocked yet

    # vout 0
    assert tx['vout'][0]['value'] == 3.0
    assert tx['vout'][0]['n'] == 0
    assert tx['vout'][0]['scriptPubKey']['addresses'] == ['mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',
                                          'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',
                                          'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj']
    assert tx['vout'][0]['scriptPubKey']['hex'] == '51210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b21037af2e06061b54cdfe3657bbc8496d69000b822e2db0c86ccbe376346a700b83353ae'
    assert tx['vout'][0]['scriptPubKey']['asm'] == '1 0282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0 0378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b 037af2e06061b54cdfe3657bbc8496d69000b822e2db0c86ccbe376346a700b833 3 OP_CHECKMULTISIG'
    assert tx['vout'][0]['scriptPubKey']['type'] == 'multisig'

    # vout 1
    assert tx['vout'][1]['value'] == 37.999422
    assert tx['vout'][1]['n'] == 1
    assert tx['vout'][1]['scriptPubKey']['addresses'] == ['mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj']
    assert tx['vout'][1]['scriptPubKey']['hex'] == '76a9146c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a15288ac'
    assert tx['vout'][1]['scriptPubKey']['asm'] == 'OP_DUP OP_HASH160 6c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a152 OP_EQUALVERIFY OP_CHECKSIG'
    assert tx['vout'][1]['scriptPubKey']['type'] == 'pubkeyhash'


@pytest.mark.usefixtures("api_server")
def test_searchrawtransactions_unconfirmed(server_db):
    assert len(backend.searchrawtransactions(ADDR[0], unconfirmed=True)) == 27
    assert len(backend.searchrawtransactions(ADDR[0], unconfirmed=False)) == 27

    # create send
    v = int(100 * 1e8)
    send1hex = util.api('create_send', {'source': ADDR[0], 'destination': ADDR[1], 'asset': 'XCP', 'quantity': v})

    # insert send, this automatically also creates a block
    tx1 = util_test.insert_raw_transaction(send1hex, server_db)

    assert len(backend.searchrawtransactions(ADDR[0], unconfirmed=True)) == 28
    assert len(backend.searchrawtransactions(ADDR[0], unconfirmed=False)) == 28

    # create send
    v = int(100 * 1e8)
    send2hex = util.api('create_send', {'source': ADDR[0], 'destination': ADDR[1], 'asset': 'XCP', 'quantity': v})

    # insert send, this automatically also creates a block
    tx2 = util_test.insert_unconfirmed_raw_transaction(send2hex, server_db)

    assert len(backend.searchrawtransactions(ADDR[0], unconfirmed=True)) == 29
    assert len(backend.searchrawtransactions(ADDR[0], unconfirmed=False)) == 28
