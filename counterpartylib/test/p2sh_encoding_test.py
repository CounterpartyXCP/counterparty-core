import pprint
import tempfile
import binascii
import time
import hashlib
import pytest
import bitcoin as bitcoinlib
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP, ADDR, P2SH_ADDR

import logging
logger = logging.getLogger(__name__)

from counterpartylib.lib import util
from counterpartylib.lib import config
from counterpartylib.lib import api
from counterpartylib.lib import backend
from counterpartylib.lib import blocks
from counterpartylib.lib import exceptions
from counterpartylib.lib.transaction_helper import serializer
from counterpartylib.lib.transaction_helper import p2sh_encoding

FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'

@pytest.mark.usefixtures("cp_server")
def test_p2sh_encoding(server_db):
    conftest.forceEnableProtocolChange('enhanced_sends')
    source = ADDR[0]
    destination = ADDR[1]

    with util_test.ConfigContext(OLD_STYLE_API=True):
        utxos = dict(((utxo['txid'], utxo['vout']), utxo) for utxo in backend.get_unspent_txouts(source))

        # pprint.pprint(utxos)

        fee = 20000
        fee_per_kb = 50000
        result = api.compose_transaction(
            server_db, 'send',
            {'source': source,
             'destination': destination,
             'asset': 'XCP',
             'quantity': 100},
            encoding='p2sh',
            fee_per_kb=fee_per_kb,
            fee=fee
        )
        assert not isinstance(result, list)
        pretxhex = result

        pretx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(pretxhex))

        sumvin = sum([int(utxos[(bitcoinlib.core.b2lx(vin.prevout.hash), vin.prevout.n)]['amount'] * 1e8) for vin in pretx.vin])
        sumvout = sum([vout.nValue for vout in pretx.vout])

        assert len(pretx.vout) == 2
        assert len(pretxhex) / 2 == 142
        assert sumvin == 199909140
        assert sumvout < sumvin
        assert sumvout == (sumvin - fee)


        # data P2SH output
        expected_datatx_length = 435
        expected_datatx_fee = int(expected_datatx_length / 1000 * fee_per_kb)
        assert repr(pretx.vout[0].scriptPubKey) == "CScript([OP_HASH160, x('80070406f277bae04c990e986a4cbfa7c5120308'), OP_EQUAL])"
        assert pretx.vout[0].nValue == expected_datatx_fee
        # change output
        assert pretx.vout[1].nValue == sumvin - expected_datatx_fee - fee

        assert pretxhex == "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02f65400000000000017a91480070406f277bae04c990e986a4cbfa7c512030887febbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        # 01000000                                                          | version
        # 01                                                                | inputs
        # c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae  | txout hash
        # 00000000                                                          | txout index
        # 19                                                                | script length
        # 76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac                | tx_script
        # ffffffff                                                          | Sequence
        # 02                                                                | number of outputs
        # f654000000000000                                                  | output 1 value (21750)
        # 17                                                                | output 1 length (23 bytes)
        # a91480070406f277bae04c990e986a4cbfa7c512030887                    | output 1 script
        # febbe90b00000000                                                  | output 2 value (199867390)
        # 19                                                                | output 2 length (25 bytes)
        # 76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac                | output 2 script
        # 00000000                                                          | locktime

        # first transaction should be considered BTC only
        with pytest.raises(exceptions.BTCOnlyError):
            blocks._get_tx_info(pretxhex)

        # store transaction
        pretxid, _ = util_test.insert_raw_transaction(pretxhex, server_db)

        logger.debug('pretxid %s' % (pretxid))


        # check that when we do another, unrelated, send that it won't use our UTXO
        result = api.compose_transaction(
            server_db, 'send',
            {'source': source,
             'destination': destination,
             'asset': 'XCP',
             'quantity': 100}
        )
        othertx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(result))
        othertxid = bitcoinlib.core.lx(bitcoinlib.core.b2x(othertx.vin[0].prevout.hash))  # reverse hash
        assert not(binascii.hexlify(othertxid).decode('ascii') == pretxid and othertx.vin[0].prevout.n == 0)


        # now compose the data transaction
        result = api.compose_transaction(
            server_db, 'send',
            {'source': source,
             'destination': destination,
             'asset': 'XCP',
             'quantity': 100},
            p2sh_pretx_txid=pretxid,  # pass the pretxid
            encoding='p2sh',
            fee_per_kb=fee_per_kb
        )
        assert not isinstance(result, list)
        datatxhex = result

        datatx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(datatxhex))
        sumvin = sum([pretx.vout[n].nValue for n, vin in enumerate(datatx.vin)])
        sumvout = sum([vout.nValue for vout in datatx.vout])
        fee = 10000

        assert len(datatxhex) / 2 == 212
        assert sumvin == expected_datatx_fee
        assert sumvout < sumvin
        assert sumvout == sumvin - expected_datatx_fee
        assert len(datatx.vout) == 1
        # opreturn signalling P2SH
        assert repr(datatx.vout[0].scriptPubKey) == "CScript([OP_RETURN, x('8a5dda15fb6f0562da344d2f')])"  # arc4(PREFIX + 'P2SH')
        assert datatx.vout[0].nValue == 0
        assert datatxhex == "0100000001d7ae0e13a5a42505dd6ab53d93ca1444050f68910f72a805b728d4fba6e0d384000000008a31544553545858585800000002000000000000000100000000000000646f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec3fa91469239b1c91f30886e520641e25d08529b30bb3c388210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ad007574008717a91480070406f277bae04c990e986a4cbfa7c512030887ffffffff0100000000000000000e6a0c8a5dda15fb6f0562da344d2f00000000"
        # 01000000                                                                                         | version
        # 01                                                                                               | inputs
        # d7ae0e13a5a42505dd6ab53d93ca1444050f68910f72a805b728d4fba6e0d384                                 | txout hash
        # 00000000                                                                                         | txout index (0)
        # 8a                                                                                               | script length (138)
        # 31544553545858585800000002000000000000000100000000000000                                         | tx_script
        #         646f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec3fa91469239b1c91f30886e520641e25d08529b30bb  |   ...
        #         3c388210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ad0075740087    |   ... 
        #         17a91480070406f277bae04c990e986a4cbfa7c512030887                                         |   ...
        # ffffffff                                                                                         | Sequence
        # 01                                                                                               | number of outputs
        # 0000000000000000                                                                                 | output 1 value (0)
        # 0e                                                                                               | output 1 length (23 bytes)
        # 6a0c8a5dda15fb6f0562da344d2f                                                                     | output 1 script
        # 00000000                                                                                         | locktime

        # verify parsed result
        parsed_source, parsed_destination, parsed_btc_amount, parsed_fee, parsed_data = blocks._get_tx_info(datatxhex)
        assert parsed_source == source
        assert parsed_data == binascii.unhexlify("00000002" "0000000000000001" "0000000000000064" "6f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec")  # ID=enhanced_send(0x02) ASSET=XCP(0x01) VALUE=100(0x64) destination_pubkey(0x6f8d...d6ec)
        assert parsed_btc_amount == 0
        assert parsed_fee == expected_datatx_fee


''' Test that p2sh sources are not supported by the API at this time '''
@pytest.mark.usefixtures("cp_server")
def test_p2sh_encoding_p2sh_source_not_supported(server_db):
    conftest.forceEnableProtocolChange('enhanced_sends')
    source = P2SH_ADDR[0]
    destination = ADDR[1]

    with util_test.ConfigContext(OLD_STYLE_API=True):
        fee = 20000
        fee_per_kb = 50000
        
        with pytest.raises(exceptions.TransactionError):
            result = api.compose_transaction(
                server_db, 'send',
                {'source': source,
                 'destination': destination,
                 'asset': 'XCP',
                 'quantity': 100},
                encoding='p2sh',
                fee_per_kb=fee_per_kb,
                fee=fee
            )


''' Manually form a transaction from a p2sh source '''
@pytest.mark.usefixtures("cp_server")
def test_p2sh_encoding_manual_multisig_transaction(server_db):
    conftest.forceEnableProtocolChange('enhanced_sends')
    source = P2SH_ADDR[0]
    destination = ADDR[1]

    with util_test.ConfigContext(OLD_STYLE_API=True):
        p2sh_source_multisig_pubkeys_binary = [binascii.unhexlify(p) for p in [DP['pubkey'][ADDR[0]], DP['pubkey'][ADDR[1]], DP['pubkey'][ADDR[2]]]]
        scriptSig, redeemScript, outputScript = p2sh_encoding.make_p2sh_encoding_redeemscript(
            b'deadbeef01',
            n=0, pubKey=None, 
            multisig_pubkeys=p2sh_source_multisig_pubkeys_binary, 
            multisig_pubkeys_required=2
        )
        redeemScript = bitcoinlib.core.script.CScript(redeemScript)
        assert repr(redeemScript) == "CScript([OP_HASH160, x('28fc9fc8c6318c76eb74a841f76423777a120073'), OP_EQUALVERIFY, 2, x('{}'), x('{}'), x('{}'), 3, OP_CHECKMULTISIGVERIFY, 0, OP_DROP, OP_DEPTH, 0, OP_EQUAL])".format(DP['pubkey'][ADDR[0]], DP['pubkey'][ADDR[1]], DP['pubkey'][ADDR[2]])

        # setup transaction
        fee = 20000
        fee_per_kb = 50000
        pretxhex = api.compose_transaction(
            server_db, 'send',
            {'source': source,
             'destination': destination,
             'asset': 'XCP',
             'quantity': 100,
            },
            p2sh_source_multisig_pubkeys=[DP['pubkey'][ADDR[0]], DP['pubkey'][ADDR[1]], DP['pubkey'][ADDR[2]]],
            p2sh_source_multisig_pubkeys_required=2,
            encoding='p2sh',
            fee_per_kb=fee_per_kb,
            fee=fee
        )
        # debugTransaction = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(pretxhex))

        # store transaction
        pretxid, _ = util_test.insert_raw_transaction(pretxhex, server_db)
        logger.debug('pretxid %s' % (pretxid))

        # now compose the data transaction
        result = api.compose_transaction(
            server_db, 'send',
            {'source': source,
             'destination': destination,
             'asset': 'XCP',
             'quantity': 100},
            p2sh_source_multisig_pubkeys=[DP['pubkey'][ADDR[0]], DP['pubkey'][ADDR[1]], DP['pubkey'][ADDR[2]]],
            p2sh_source_multisig_pubkeys_required=2,
            p2sh_pretx_txid=pretxid,  # pass the pretxid
            encoding='p2sh',
            fee_per_kb=fee_per_kb
        )
        assert not isinstance(result, list)
        datatxhex = result

        datatx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(datatxhex))

        # parse the transaction
        parsed_source, parsed_destination, parsed_btc_amount, parsed_fee, parsed_data = blocks._get_tx_info(datatxhex)
        assert parsed_source == source
        assert parsed_data == binascii.unhexlify("00000002" "0000000000000001" "0000000000000064" "6f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec")  # ID=enhanced_send(0x02) ASSET=XCP(0x01) VALUE=100(0x64) destination_pubkey(0x6f8d...d6ec)
        assert parsed_btc_amount == 0


@pytest.mark.usefixtures("cp_server")
def test_p2sh_script_decoding():
    scriptHex = "1c8a5dda15fb6f05628a061e67576e926dc71a7fa2f0cceb97452b4d564101a914c088c83aeddd211096df9f5f0df1f3b885ac7fe70188210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ad0075740087"
    scriptSig = bitcoinlib.core.script.CScript(binascii.unhexlify(scriptHex))

    print('scriptSig', repr(scriptSig), list(scriptSig), len(list(scriptSig)))

    chunks = list(scriptSig)
    if len(chunks) == 3:
        sig = chunks[0]
        datachunk = chunks[1]
        redeemScript = chunks[2]
    else:
        sig = None
        datachunk = chunks[0]
        redeemScript = chunks[1]

    print('sig', binascii.hexlify(sig) if sig else sig)
    print('datachunk', binascii.hexlify(datachunk) if datachunk else datachunk)
    print('redeemScript', binascii.hexlify(redeemScript) if redeemScript else redeemScript)

    if not redeemScript:
        redeemScript = datachunk
        datachunk = sig
        sig = None

    assert datachunk and redeemScript

    print('sig', binascii.hexlify(sig) if sig else sig)
    print('datachunk', binascii.hexlify(datachunk) if datachunk else datachunk)
    print('redeemScript', binascii.hexlify(redeemScript) if redeemScript else redeemScript)

    assert datachunk == binascii.unhexlify('8a5dda15fb6f05628a061e67576e926dc71a7fa2f0cceb97452b4d56')


def test_benchmark_outkey_vin():
    m = 100000

    t = time.time()
    for n in range(m):
        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify("0100000002eff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b000000006c493046022100ec6fa8316a4f5cfd69816e31011022acce0933bd3b01248caa8b49e60de1b98a022100987ba974b2a4f9976a8d61d94009cb7f7986a827dc5730e999de1fb748d2046c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffeff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b010000006a47304402201f8fb2d62df22592cb8d37c68ab26563dbb8e270f7f8409ac0f6d7b24ddb5c940220314e5c767fd12b20116528c028eab2bfbad30eb963bd849993410049cf14a83d01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffff02145fea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000346a32544553540000000a00000000000000010000000005f5e1000000000000000000000000000bebc2000032000000000000271000000000"))

    tt = time.time()
    ttn1 = ((tt - t) / m)

    print(tt - t, "%f" % ttn1)

    t = time.time()
    for n in range(m):
        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify("0100000002eff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b000000006c493046022100ec6fa8316a4f5cfd69816e31011022acce0933bd3b01248caa8b49e60de1b98a022100987ba974b2a4f9976a8d61d94009cb7f7986a827dc5730e999de1fb748d2046c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffeff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b010000006a47304402201f8fb2d62df22592cb8d37c68ab26563dbb8e270f7f8409ac0f6d7b24ddb5c940220314e5c767fd12b20116528c028eab2bfbad30eb963bd849993410049cf14a83d01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffff02145fea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000346a32544553540000000a00000000000000010000000005f5e1000000000000000000000000000bebc2000032000000000000271000000000"))
        outkey = [(vin.prevout.hash, vin.prevout.n) for vin in tx.vin]


    tt = time.time()
    ttn2 = ((tt - t) / m)

    print(tt - t, "%f" % ttn2)

    t = time.time()
    for n in range(m):
        tx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify("0100000002eff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b000000006c493046022100ec6fa8316a4f5cfd69816e31011022acce0933bd3b01248caa8b49e60de1b98a022100987ba974b2a4f9976a8d61d94009cb7f7986a827dc5730e999de1fb748d2046c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffeff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b010000006a47304402201f8fb2d62df22592cb8d37c68ab26563dbb8e270f7f8409ac0f6d7b24ddb5c940220314e5c767fd12b20116528c028eab2bfbad30eb963bd849993410049cf14a83d01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffff02145fea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000346a32544553540000000a00000000000000010000000005f5e1000000000000000000000000000bebc2000032000000000000271000000000"))
        outkey = [(vin.prevout.hash, vin.prevout.n) for vin in tx.vin]
        outkey = hashlib.sha256(str(outkey).encode('ascii')).digest()


    tt = time.time()
    ttn3 = ((tt - t) / m)

    print(tt - t, "%f" % ttn3)

    # not sure what to do here since the speed depends on the machine ...
    assert ttn1 < 0.0001
    assert ttn2 < 0.0001
    assert ttn3 < 0.0001

    # maybe assert relative
    assert ttn3 < ttn1 * 2
