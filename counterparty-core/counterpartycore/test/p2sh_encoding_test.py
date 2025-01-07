import binascii
import hashlib
import logging
import tempfile
import time

import bitcoin as bitcoinlib
import pytest

# this is require near the top to do setup of the test suite
from counterpartycore.test import (
    conftest,  # noqa: F401
    util_test,
)
from counterpartycore.test.fixtures.params import ADDR
from counterpartycore.test.util_test import CURR_DIR

logger = logging.getLogger(__name__)

from counterpartycore.lib import (  # noqa: E402
    config,
    deserialize,
    gettxinfo,
    p2sh,
    script,
    util,
)

FIXTURE_SQL_FILE = CURR_DIR + "/fixtures/scenarios/unittest_fixture.sql"
FIXTURE_DB = tempfile.gettempdir() + "/fixtures.unittest_fixture.db"


@pytest.mark.usefixtures()
def test_p2sh_encoding_composed(server_db):
    source = ADDR[0]  # noqa: F841
    destination = ADDR[1]  # noqa: F841

    with (
        util_test.ConfigContext(DISABLE_ARC4_MOCKING=True, OLD_STYLE_API=True),
        util_test.MockProtocolChangesContext(enhanced_sends=True, p2sh_encoding=True),
    ):
        # BTC Mainnet tx d90dc8637fd2ab9ae39b7c2929c793c5d28d7dea672afb02fb4001637085e9a1
        datatxhex = "010000000102d2b137e49e930ef3e436b342713d8d07bd378e773c915a5938993d81dc7e6000000000fdab0147304402207848293e88563750f647e949cb594cdbec0beb4070faac73040d77d479420f8302201e0ac32788e98bd984279102b7382576d7ddb4b125d1d507725cbd12d97a2908014d60014d1401434e5452505254590300010042276049e5518791be2ffe2c301f5dfe9ef85dd0400001720034b0410000000000000001500000006a79811e000000000000000054000079cec1665f4800000000000000050000000ca91f2d660000000000000005402736c8de6e34d54000000000000001500c5e4c71e081ceb00000000000000054000000045dc03ec4000000000000000500004af1271cf5fc00000000000000054001e71f8464432780000000000000015000002e1e4191f0d0000000000000005400012bc4aaac2a54000000000000001500079c7e774e411c00000000000000054000000045dc0a6f00000000000000015000002e1e486f661000000000000000540001c807abe13908000000000000000475410426156245525daa71f2e84a40797bcf28099a2c508662a8a33324a703597b9aa2661a79a82ffb4caaa9b15f4094622fbfa85f8b9dc7381f991f5a265421391cc3ad0075740087ffffffff0100000000000000000e6a0c31d52bf3b404aefaf596cfd000000000"
        config.PREFIX = b"CNTRPRTY"
        parsed_source, parsed_destination, parsed_btc_amount, parsed_fee, parsed_data, extra = (
            gettxinfo._get_tx_info(
                server_db,
                deserialize.deserialize_tx(datatxhex, parse_vouts=True),
                util.CURRENT_BLOCK_INDEX,
            )
        )
        print("!!!!!!!!!!!!!!!!>1")
        print(parsed_source)
        print(parsed_destination)
        print(parsed_btc_amount)
        print(parsed_fee)
        print(parsed_data)
        print(extra)
        print("!!!!!!!!!!!!!!!!<1")


@pytest.mark.usefixtures("cp_server")
def test_p2sh_script_decoding():
    script_hex = "1c8a5dda15fb6f05628a061e67576e926dc71a7fa2f0cceb97452b4d564101a914c088c83aeddd211096df9f5f0df1f3b885ac7fe70188210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ad0075740087"
    script_sig = bitcoinlib.core.script.CScript(binascii.unhexlify(script_hex))

    print("script_sig", repr(script_sig), list(script_sig), len(list(script_sig)))

    chunks = list(script_sig)
    if len(chunks) == 3:
        sig = chunks[0]
        datachunk = chunks[1]
        redeemScript = chunks[2]
    else:
        sig = None
        datachunk = chunks[0]
        redeemScript = chunks[1]

    print("sig", binascii.hexlify(sig) if sig else sig)
    print("datachunk", binascii.hexlify(datachunk) if datachunk else datachunk)
    print("redeemScript", binascii.hexlify(redeemScript) if redeemScript else redeemScript)

    if not redeemScript:
        redeemScript = datachunk
        datachunk = sig
        sig = None

    assert datachunk and redeemScript

    print("sig", binascii.hexlify(sig) if sig else sig)
    print("datachunk", binascii.hexlify(datachunk) if datachunk else datachunk)
    print("redeemScript", binascii.hexlify(redeemScript) if redeemScript else redeemScript)

    assert datachunk == binascii.unhexlify(
        "8a5dda15fb6f05628a061e67576e926dc71a7fa2f0cceb97452b4d56"
    )


@pytest.mark.usefixtures("cp_server")
def test_p2sh_signed_multisig_script_decoding():
    with util_test.ConfigContext(PREFIX=b"CNTRPRTY"):
        txHex = "0100000001bae95e59f83e55035f566dc0e3034f79f0d670dc6d6a0d207a11b4e49e9baecf00000000fd0301483045022100d2d38c2d98285e44a271e91894622fa85044469257dbfc15a49e1ba98cddaf8002202b06bf0ca9d65af9f9c96db13c7585b4cd66cabedba269f9b70659dd8e456c46014cb84c8d434e5452505254591e5a3ae08000000000000000000000000073434950203620737570706f727473207573696e672070327368206164647265737365732061732074686520736f7572636520616464726573732062757420726571756972657320616e206164646974696f6e616c20696e70757420696e207468652064617461207472616e73616374696f6e2e752102e53b79237cacdc221cff4c0fb320223cac3e0fe30a682a22f19a70a3975aa3f8ad0075740087ffffffff0100000000000000000e6a0c804e42751677319b884a2d1b00000000"

        ctx = deserialize.deserialize_tx(txHex, parse_vouts=True)
        vin = ctx["vin"][0]
        asm = script.script_to_asm(vin["script_sig"])
        new_source, new_destination, new_data = p2sh.decode_p2sh_input(asm)

        assert new_data == binascii.unhexlify(
            "1e5a3ae08000000000000000000000000073434950203620737570706f727473207573696e672070327368206164647265737365732061732074686520736f7572636520616464726573732062757420726571756972657320616e206164646974696f6e616c20696e70757420696e207468652064617461207472616e73616374696f6e2e"
        )


def test_benchmark_outkey_vin():
    m = 100000

    t = time.time()
    for n in range(m):  # noqa: B007
        tx = bitcoinlib.core.CTransaction.deserialize(
            binascii.unhexlify(
                "0100000002eff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b000000006c493046022100ec6fa8316a4f5cfd69816e31011022acce0933bd3b01248caa8b49e60de1b98a022100987ba974b2a4f9976a8d61d94009cb7f7986a827dc5730e999de1fb748d2046c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffeff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b010000006a47304402201f8fb2d62df22592cb8d37c68ab26563dbb8e270f7f8409ac0f6d7b24ddb5c940220314e5c767fd12b20116528c028eab2bfbad30eb963bd849993410049cf14a83d01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffff02145fea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000346a32544553540000000a00000000000000010000000005f5e1000000000000000000000000000bebc2000032000000000000271000000000"
            )
        )

    tt = time.time()
    ttn1 = (tt - t) / m

    print(tt - t, f"{ttn1:f}")

    t = time.time()
    for n in range(m):  # noqa: B007
        tx = bitcoinlib.core.CTransaction.deserialize(
            binascii.unhexlify(
                "0100000002eff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b000000006c493046022100ec6fa8316a4f5cfd69816e31011022acce0933bd3b01248caa8b49e60de1b98a022100987ba974b2a4f9976a8d61d94009cb7f7986a827dc5730e999de1fb748d2046c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffeff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b010000006a47304402201f8fb2d62df22592cb8d37c68ab26563dbb8e270f7f8409ac0f6d7b24ddb5c940220314e5c767fd12b20116528c028eab2bfbad30eb963bd849993410049cf14a83d01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffff02145fea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000346a32544553540000000a00000000000000010000000005f5e1000000000000000000000000000bebc2000032000000000000271000000000"
            )
        )
        outkey = [(vin.prevout.hash, vin.prevout.n) for vin in tx.vin]

    tt = time.time()
    ttn2 = (tt - t) / m

    print(tt - t, f"{ttn2:f}")

    t = time.time()
    for n in range(m):  # noqa: B007
        tx = bitcoinlib.core.CTransaction.deserialize(
            binascii.unhexlify(
                "0100000002eff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b000000006c493046022100ec6fa8316a4f5cfd69816e31011022acce0933bd3b01248caa8b49e60de1b98a022100987ba974b2a4f9976a8d61d94009cb7f7986a827dc5730e999de1fb748d2046c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffeff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b010000006a47304402201f8fb2d62df22592cb8d37c68ab26563dbb8e270f7f8409ac0f6d7b24ddb5c940220314e5c767fd12b20116528c028eab2bfbad30eb963bd849993410049cf14a83d01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffff02145fea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000346a32544553540000000a00000000000000010000000005f5e1000000000000000000000000000bebc2000032000000000000271000000000"
            )
        )
        outkey = [(vin.prevout.hash, vin.prevout.n) for vin in tx.vin]
        outkey = hashlib.sha256(str(outkey).encode("ascii")).digest()

    tt = time.time()
    ttn3 = (tt - t) / m

    print(tt - t, f"{ttn3:f}")

    # not sure what to do here since the speed depends on the machine ...
    assert ttn1 < 0.0001
    assert ttn2 < 0.0001
    assert ttn3 < 0.0001

    # maybe assert relative
    assert ttn3 < ttn1 * 2
