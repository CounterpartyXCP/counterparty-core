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

FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


@pytest.mark.usefixtures("cp_server")
def test_p2sh_encoding(server_db):
    source = ADDR[0]
    destination = ADDR[1]

    with util_test.ConfigContext(OLD_STYLE_API=True):
        utxos = dict(((utxo['txid'], utxo['vout']), utxo) for utxo in backend.get_unspent_txouts(source))

        # pprint.pprint(utxos)

        result = api.compose_transaction(
            server_db, 'send',
            {'source': source,
             'destination': destination,
             'asset': 'XCP',
             'quantity': 100},
            encoding='p2sh',
        )
        assert not isinstance(result, list)
        pretxhex = result

        pretx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(pretxhex))
        sumvin = sum([int(utxos[(bitcoinlib.core.b2lx(vin.prevout.hash), vin.prevout.n)]['amount'] * 1e8) for vin in pretx.vin])
        sumvout = sum([vout.nValue for vout in pretx.vout])
        fee = 10000

        assert len(pretxhex) / 2 == 176
        assert sumvin == 199909140
        assert sumvout < sumvin
        assert sumvout == sumvin - fee
        assert len(pretx.vout) == 3
        # source
        assert str(bitcoinlib.wallet.CBitcoinAddress.from_scriptPubKey(pretx.vout[0].scriptPubKey)) == source
        assert pretx.vout[0].nValue == 7630
        # data P2SH output
        assert repr(pretx.vout[1].scriptPubKey) == "CScript([OP_HASH160, x('98b597ee2cd6cf41c8a946f86b467cfba5bd37e3'), OP_EQUAL])"
        assert pretx.vout[1].nValue == 7800
        # change output
        assert pretx.vout[2].nValue == sumvin - 7630 - 7800 - fee
        assert pretxhex == "0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03ce1d0000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e00000000000017a91498b597ee2cd6cf41c8a946f86b467cfba5bd37e387befbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"

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


        result = api.compose_transaction(
            server_db, 'send',
            {'source': source,
             'destination': destination,
             'asset': 'XCP',
             'quantity': 100},
            p2sh_pretx_txid=pretxid,  # pass the pretxid
            encoding='p2sh'
        )
        assert not isinstance(result, list)
        datatxhex = result

        datatx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(datatxhex))
        sumvin = sum([pretx.vout[n].nValue for n, vin in enumerate(datatx.vin)])
        sumvout = sum([vout.nValue for vout in datatx.vout])
        fee = 10000

        assert len(datatxhex) / 2 == 291
        assert sumvin == 15430
        assert sumvout < sumvin
        assert sumvout == sumvin - fee
        assert len(datatx.vout) == 2
        # destination
        assert str(bitcoinlib.wallet.CBitcoinAddress.from_scriptPubKey(datatx.vout[0].scriptPubKey)) == destination
        assert datatx.vout[0].nValue == 5430
        # opreturn signalling P2SH
        assert repr(datatx.vout[1].scriptPubKey) == "CScript([OP_RETURN, x('8a5dda15fb6f0562da344d2f')])"  # arc4(PREFIX + 'P2SH')
        assert datatx.vout[1].nValue == 0
        assert datatxhex == "0100000002526b4dba7aa2e7d0bebe3ee0f9f3425b405187f50adb883c322e86f4fd318630000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff526b4dba7aa2e7d0bebe3ee0f9f3425b405187f50adb883c322e86f4fd31863001000000751c544553545858585800000000000000000000000100000000000000643fa914d7ec7ac660b5771fc9beeaf1d8363923676fd3fe88210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ad007574008717a91498b597ee2cd6cf41c8a946f86b467cfba5bd37e387ffffffff0236150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000000000000e6a0c8a5dda15fb6f0562da344d2f00000000"

        # verify parsed result
        parsed_source, parsed_destination, parsed_btc_amount, parsed_fee, parsed_data = blocks._get_tx_info(datatxhex)
        assert parsed_source == source
        assert parsed_destination == destination
        assert parsed_data == binascii.unhexlify("00000000" "0000000000000001" "0000000000000064")  # ID=SEND(0x00) ASSET=XCP(0x01) VALUE=100(0x64)
        assert parsed_btc_amount == 5430
        assert parsed_fee == fee


@pytest.mark.usefixtures("cp_server")
def test_p2sh_encoding_p2sh_source(server_db):
    source = P2SH_ADDR[0]
    destination = ADDR[1]

    with util_test.ConfigContext(OLD_STYLE_API=True):
        utxos = dict(((utxo['txid'], utxo['vout']), utxo) for utxo in backend.get_unspent_txouts(source))

        # pprint.pprint(utxos)

        result = api.compose_transaction(
            server_db, 'send',
            {'source': source,
             'destination': destination,
             'asset': 'XCP',
             'quantity': 100},
            encoding='p2sh',
            dust_return_pubkey=DP['pubkey'][ADDR[0]]
        )
        assert not isinstance(result, list)
        pretxhex = result

        pretx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(pretxhex))
        sumvin = sum([int(utxos[(bitcoinlib.core.b2lx(vin.prevout.hash), vin.prevout.n)]['amount'] * 1e8) for vin in pretx.vin])
        sumvout = sum([vout.nValue for vout in pretx.vout])
        fee = 10000

        assert len(pretxhex) / 2 == 170
        assert sumvin == 100000000
        assert sumvout < sumvin
        assert sumvout == sumvin - fee
        assert len(pretx.vout) == 3
        # source
        assert str(bitcoinlib.wallet.CBitcoinAddress.from_scriptPubKey(pretx.vout[0].scriptPubKey)) == source
        assert pretx.vout[0].nValue == 7630
        # data P2SH output
        assert repr(pretx.vout[1].scriptPubKey) == "CScript([OP_HASH160, x('98b597ee2cd6cf41c8a946f86b467cfba5bd37e3'), OP_EQUAL])"
        assert pretx.vout[1].nValue == 7800
        # change output
        assert pretx.vout[2].nValue == sumvin - 7630 - 7800 - fee
        assert pretxhex == "01000000015001af2c4c3bc2c43b6233261394910d10fb157a082d9b3038c65f2d01e4ff200000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87ffffffff03ce1d00000000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87781e00000000000017a91498b597ee2cd6cf41c8a946f86b467cfba5bd37e387aa7df5050000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e8700000000"

        # first transaction should be considered BTC only
        with pytest.raises(exceptions.BTCOnlyError):
            blocks._get_tx_info(pretxhex)

        # store transaction
        pretxid, _ = util_test.insert_raw_transaction(pretxhex, server_db)

        logger.debug('pretxid %s' % (pretxid))

        result = api.compose_transaction(
            server_db, 'send',
            {'source': source,
             'destination': destination,
             'asset': 'XCP',
             'quantity': 100},
            p2sh_pretx_txid=pretxid,  # pass the pretxid
            encoding='p2sh',
            dust_return_pubkey=DP['pubkey'][ADDR[0]]
        )
        assert not isinstance(result, list)
        datatxhex = result

        datatx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(datatxhex))
        sumvin = sum([pretx.vout[n].nValue for n, vin in enumerate(datatx.vin)])
        sumvout = sum([vout.nValue for vout in datatx.vout])
        fee = 10000

        assert len(datatxhex) / 2 == 289
        assert sumvin == 15430
        assert sumvout < sumvin
        assert sumvout == sumvin - fee
        assert len(datatx.vout) == 2
        # destination
        assert str(bitcoinlib.wallet.CBitcoinAddress.from_scriptPubKey(datatx.vout[0].scriptPubKey)) == destination
        assert datatx.vout[0].nValue == 5430
        # opreturn signalling P2SH
        assert repr(datatx.vout[1].scriptPubKey) == "CScript([OP_RETURN, x('8a5dda15fb6f0562da344d2f')])"  # arc4(PREFIX + 'P2SH')
        assert datatx.vout[1].nValue == 0
        assert datatxhex == "01000000025eb13dc32d12bbaa0431b7352caf52f2a173ebcc53cf8eaade9e5706cb72a3110000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87ffffffff5eb13dc32d12bbaa0431b7352caf52f2a173ebcc53cf8eaade9e5706cb72a31101000000751c544553545858585800000000000000000000000100000000000000643fa914d7ec7ac660b5771fc9beeaf1d8363923676fd3fe88210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ad007574008717a91498b597ee2cd6cf41c8a946f86b467cfba5bd37e387ffffffff0236150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000000000000e6a0c8a5dda15fb6f0562da344d2f00000000"

        # verify parsed result
        parsed_source, parsed_destination, parsed_btc_amount, parsed_fee, parsed_data = blocks._get_tx_info(datatxhex)
        assert parsed_source == source
        assert parsed_destination == destination
        assert parsed_data == binascii.unhexlify("00000000" "0000000000000001" "0000000000000064")  # ID=SEND(0x00) ASSET=XCP(0x01) VALUE=100(0x64)
        assert parsed_btc_amount == 5430
        assert parsed_fee == fee


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
