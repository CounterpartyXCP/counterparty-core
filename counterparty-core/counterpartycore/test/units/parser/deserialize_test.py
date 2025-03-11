import binascii
import time
from io import BytesIO

import bitcoin as bitcoinlib
import pytest
from counterparty_rs import utils as pycoin_rs_utils
from counterpartycore.lib import config
from counterpartycore.lib.api import composer
from counterpartycore.lib.parser import deserialize, gettxinfo
from counterpartycore.lib.utils import helpers


def deserialize_bitcoinlib(tx_hex):
    return bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(tx_hex))


def deserialize_rust(tx_hex):
    return deserialize.deserialize_tx(tx_hex, parse_vouts=True, block_index=900000)


def create_block_hex(transactions_hex):
    block = bitcoinlib.core.CBlock(
        nVersion=2,
        hashPrevBlock=b"\x00" * 32,
        hashMerkleRoot=b"\x00" * 32,
        nTime=0,
        nBits=0,
        nNonce=0,
        vtx=[deserialize_bitcoinlib(tx_hex) for tx_hex in transactions_hex],
    )
    buf = BytesIO()
    block.stream_serialize(buf)
    block_hex = binascii.hexlify(buf.getvalue()).decode("utf-8")
    # print("block hex", block_hex)
    return block_hex


def test_deserialize():
    original_network_name = config.NETWORK_NAME
    config.NETWORK_NAME = "testnet3"

    hex = "0100000001db3acf37743ac015808f7911a88761530c801819b3b907340aa65dfb6d98ce24030000006a473044022002961f4800cb157f8c0913084db0ee148fa3e1130e0b5e40c3a46a6d4f83ceaf02202c3dd8e631bf24f4c0c5341b3e1382a27f8436d75f3e0a095915995b0bf7dc8e01210395c223fbf96e49e5b9e06a236ca7ef95b10bf18c074bd91a5942fc40360d0b68fdffffff040000000000000000536a4c5058325bd61325dc633fadf05bec9157c23106759cee40954d39d9dbffc17ec5851a2d1feb5d271da422e0e24c7ae8ad29d2eeabf7f9ca3de306bd2bc98e2a39e47731aa000caf400053000c1283000149c8000000000000001976a91462bef4110f98fdcb4aac3c1869dbed9bce8702ed88acc80000000000000017a9144317f779c0a2ccf8f6bc3d440bd9e536a5bff75287fa3e5100000000001976a914bf2646b8ba8b4a143220528bde9c306dac44a01c88ac00000000"
    decoded_tx = deserialize_rust(hex)

    _parsed_vouts = decoded_tx.pop("parsed_vouts")
    # assert str(parsed_vouts) == "Not Parsed"

    assert decoded_tx == {
        "version": 1,
        "segwit": False,
        "coinbase": False,
        "vin": [
            {
                "hash": "24ce986dfb5da60a3407b9b31918800c536187a811798f8015c03a7437cf3adb",
                "n": 3,
                "script_sig": b"G0D\x02 \x02\x96\x1fH\x00\xcb\x15\x7f\x8c\t\x13\x08M\xb0\xee\x14\x8f\xa3\xe1\x13\x0e\x0b^@\xc3\xa4jmO\x83\xce\xaf\x02 ,=\xd8\xe61\xbf$\xf4\xc0\xc54\x1b>\x13\x82\xa2\x7f\x846\xd7_>\n\tY\x15\x99[\x0b\xf7\xdc\x8e\x01!\x03\x95\xc2#\xfb\xf9nI\xe5\xb9\xe0j#l\xa7\xef\x95\xb1\x0b\xf1\x8c\x07K\xd9\x1aYB\xfc@6\r\x0bh",
                "sequence": 4294967293,
                "info": None,
            }
        ],
        "vout": [
            {
                "value": 0,
                "script_pub_key": b"jLPX2[\xd6\x13%\xdcc?\xad\xf0[\xec\x91W\xc21\x06u\x9c\xee@\x95M9\xd9\xdb\xff\xc1~\xc5\x85\x1a-\x1f\xeb]'\x1d\xa4\"\xe0\xe2Lz\xe8\xad)\xd2\xee\xab\xf7\xf9\xca=\xe3\x06\xbd+\xc9\x8e*9\xe4w1\xaa\x00\x0c\xaf@\x00S\x00\x0c\x12\x83\x00\x01I",
            },
            {
                "value": 200,
                "script_pub_key": b"v\xa9\x14b\xbe\xf4\x11\x0f\x98\xfd\xcbJ\xac<\x18i\xdb\xed\x9b\xce\x87\x02\xed\x88\xac",
            },
            {
                "value": 200,
                "script_pub_key": b"\xa9\x14C\x17\xf7y\xc0\xa2\xcc\xf8\xf6\xbc=D\x0b\xd9\xe56\xa5\xbf\xf7R\x87",
            },
            {
                "value": 5324538,
                "script_pub_key": b"v\xa9\x14\xbf&F\xb8\xba\x8bJ\x142 R\x8b\xde\x9c0m\xacD\xa0\x1c\x88\xac",
            },
        ],
        "vtxinwit": [[]],
        "lock_time": 0,
        "tx_hash": "54cc399879446c4eaa7774bb764b319a2680709f99704ce60344587f49ff97e8",
        "tx_id": "54cc399879446c4eaa7774bb764b319a2680709f99704ce60344587f49ff97e8",
    }

    transactions_hex = [
        "0100000001db3acf37743ac015808f7911a88761530c801819b3b907340aa65dfb6d98ce24030000006a473044022002961f4800cb157f8c0913084db0ee148fa3e1130e0b5e40c3a46a6d4f83ceaf02202c3dd8e631bf24f4c0c5341b3e1382a27f8436d75f3e0a095915995b0bf7dc8e01210395c223fbf96e49e5b9e06a236ca7ef95b10bf18c074bd91a5942fc40360d0b68fdffffff040000000000000000536a4c5058325bd61325dc633fadf05bec9157c23106759cee40954d39d9dbffc17ec5851a2d1feb5d271da422e0e24c7ae8ad29d2eeabf7f9ca3de306bd2bc98e2a39e47731aa000caf400053000c1283000149c8000000000000001976a91462bef4110f98fdcb4aac3c1869dbed9bce8702ed88acc80000000000000017a9144317f779c0a2ccf8f6bc3d440bd9e536a5bff75287fa3e5100000000001976a914bf2646b8ba8b4a143220528bde9c306dac44a01c88ac00000000",
        "010000000001010000000000000000000000000000000000000000000000000000000000000000ffffffff640342af0c2cfabe6d6dd04bc3504cba11910d72d3f9bcc603156272ec18d096431da690d1c11650bcec10000000f09f909f092f4632506f6f6c2f6900000000000000000000000000000000000000000000000000000000000000000000000500406f0100000000000522020000000000001976a914c6740a12d0a7d556f89782bf5faf0e12cf25a63988acf1c70e26000000001976a914c85526a428126c00ad071b56341a5a553a5e96a388ac0000000000000000266a24aa21a9ed8fd9974d26b10d3db6664fa2c59e8a504cb97c06e765a54c9096343cbac7716a00000000000000002f6a2d434f5245012953559db5cc88ab20b1960faa9793803d070337bdb2a04b4ccf74792cc6753c27c5fd5f1d6458bf00000000000000002c6a4c2952534b424c4f434b3af55b0e3836fafb2163bc99ce0bc3a950bf3bac5029e340f20459d525005d16580120000000000000000000000000000000000000000000000000000000000000000038aef23c",
        "01000000000102ab5357d8170304254e84cb66947995a1adcb534f562204e81889ee4badd2f1710000000000ffffffff9405cdfa4bb01f7656a1d2ce035bc232123f4fae23ac6d1fca03e135ca0994f00000000000ffffffff02a02526000000000016001450e3623e0095fa422a427421c3841c1e60a676c1f715a40a000000001600140c272ee21eb41191d1d9c2bd92e26fd958b58b440247304402205cc5a5ceaf59b36cfc6fd12f93bdfd54c6e625c09923ada2052576ef2221e9fb02201d7504f58459cce71f12f58eec01b6da3e43558fb8cb47c70eef34e2adf960b20121036d841256f891183be493f016fcbfec057bd5d88cbd8d2f9d06f13a36d9caf58502483045022100d80f2b4557258b528d4eaa313eff53a6db760ad1aaad3f78ff57103ba083984c02202ae089bcaffa38fcc8bfa2d0a7f5c7ef611f861e3309dc7baeb858f5b1a7198e01210298410495c0b4a9365842524467b58a84ca439c364605c510b50d6be442d32c8b00000000",
        "01000000023031e115e560c0d468459d7db35f5ab1992eaa0ab6aa0d6da49e2b8bcf1bb915010000006a47304402205535a9ac25844514828bff3580120d5add488e09b7a6e62018fc265aabf95fe302200b66d4eb23fc348b31d58729b479ae73db9dfc467edf38f8dfd927c48cb46b5801210219fbee4b9cc12188598f244ff0ee352b124cbf9046180a1b25e020c0258f9d64fffffffff2efdee1e775d962f7be96964adb352f9ef748a360749d6b74c69854a5c70a840c0000006a47304402203a28d10c786907fcb71c7bf69c507d58884ea9af2e7fa3b413d4e2867eca601502205fb253d82e4daa2672842ec031584ea7a215774422aa7de3cf8928c240e2faa60121030be5aa6d5de8c6dd89d6ac4d0e2a112caf5b12801349ab30fbdf2b205f0b94b8ffffffff02b60e0100000000001976a914f133f0339987cd84b6017517de2a93f009728d7e88acfdd7c400000000001976a91406c3bc40cde01312e2b24f8d2c23e68ea7d572f888ac00000000",
        # new composer
        "0200000001c2114be987f65bdfded1e62ce57385750cee74768f152cafa25bd6fcb96695440100000000ffffffff0310270000000000001600144067f0d09a8fe3abb902eeab6fae52a4f11034230000000000000000176a15adfe4279a2654803ba1c741fd01ccf19462960e56895860000000000001600144067f0d09a8fe3abb902eeab6fae52a4f110342300000000",
        # old composer
        "02000000000101c2114be987f65bdfded1e62ce57385750cee74768f152cafa25bd6fcb9669544010000001600144067f0d09a8fe3abb902eeab6fae52a4f1103423ffffffff0310270000000000001600144067f0d09a8fe3abb902eeab6fae52a4f11034230000000000000000176a15adfe4279a2654803ba1c741fd01ccf19462960e56895860000000000001600144067f0d09a8fe3abb902eeab6fae52a4f110342302000000000000",
        "0100000001ed8974c165a823af6f70c0e5ee4cf150cc87f4b280d57f13cadf4fdeaf96e75b5b0000006a47304402203623ce2458bdafc18ae89706fb5571854bdb4f12cfff60ff143271ca2526175e02205af544023561704d61d898a53b933db80be4de5acbd1d8ccb9af56da1ff51cc40121021c72bc7a6d4479f9be9a37a667cadaeb9dc26f4551ebd7b38139633f0aa8cd02ffffffff020000000000000000306a2ef15b24417e42b75bf75e82be8d7c8a190dbc364a06616b070dc245b2aa1c91b3397ac366d659b296dbad153c75d5bd040000000000001976a914fd7b2029e9c5b3db9a6cf295d4e3e9be7e061c0a88ac00000000",
    ]
    # create a block with the transactions
    block_hex = create_block_hex(transactions_hex)
    block_info = deserialize.deserialize_block(block_hex, parse_vouts=True, block_index=900000)

    for i, hex in enumerate(transactions_hex):
        decoded_tx_bitcoinlib = deserialize_bitcoinlib(hex)
        decoded_tx_rust = deserialize_rust(hex)
        decoded_from_block = block_info["transactions"][i]

        # compare transactions decoded by bitcoinlib and rust deserialize_block and deserialize_tx
        for decoded_tx in [decoded_tx_rust, decoded_from_block]:
            for j, vin in enumerate(decoded_tx_bitcoinlib.vin):
                assert vin.prevout.hash == binascii.unhexlify(
                    pycoin_rs_utils.inverse_hash(decoded_tx["vin"][j]["hash"])
                )
                assert vin.prevout.n == decoded_tx["vin"][j]["n"]
                assert vin.scriptSig == decoded_tx["vin"][j]["script_sig"]
                assert vin.nSequence == decoded_tx["vin"][j]["sequence"]

            for j, vout in enumerate(decoded_tx_bitcoinlib.vout):
                assert vout.nValue == decoded_tx["vout"][j]["value"]
                assert vout.scriptPubKey == decoded_tx["vout"][j]["script_pub_key"]

            assert decoded_tx_bitcoinlib.has_witness() == (len(decoded_tx["vtxinwit"][0]) > 0)
            assert decoded_tx_bitcoinlib.is_coinbase() == decoded_tx["coinbase"]

            assert decoded_tx_bitcoinlib.GetHash() == binascii.unhexlify(
                pycoin_rs_utils.inverse_hash(decoded_tx["tx_hash"])
            )

    iterations = 25

    start_time = time.time()
    for i in range(iterations):  # noqa: B007
        for hex in transactions_hex:
            deserialize_rust(hex)
    end_time = time.time()
    print(
        f"Time to deserialize {4 * iterations} transactions with Rust: {end_time - start_time} seconds"
    )

    start_time = time.time()
    for i in range(iterations):  # noqa: B007
        for hex in transactions_hex:
            deserialize_bitcoinlib(hex)
    end_time = time.time()
    print(
        f"Time to deserialize  {4 * iterations} transactions with bitcoinlib: {end_time - start_time} seconds"
    )

    config.NETWORK_NAME = original_network_name


def test_deserialize_mpma(blockchain_mock, monkeypatch):
    helpers.setup_bitcoinutils("mainnet")
    original_network_name = config.NETWORK_NAME
    original_address_version = config.ADDRESSVERSION
    config.NETWORK_NAME = "mainnet"
    config.ADDRESSVERSION = config.ADDRESSVERSION_MAINNET

    blockchain_mock.source_by_txid[
        "094246c10d8b95f39662b92971588a205db77d89ffe0f21816733019a703cff9"
    ] = "18b7eyatTwZ8mvSCXRRxjNjvr3DPwhh6bU"

    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.get_vin_info",
        lambda vin, no_retry: (64777, "", False),
    )

    hex = "0100000001f9cf03a71930731618f2e0ff897db75d208a587129b96296f3958b0dc146420900000000e5483045022100a72e4be0a0f581e1c438c7048413c65c05793e8328a7acaa1ef081cc8c44909a0220718e772276aaa7adf8392a1d39ab44fc8778f622ee0dea9858cd5894290abb2b014c9a4c6f434e545250525459030003000fc815eeb3172efc23fbd39c41189e83e4e0c8150033dafc6a4dcd8bce30b038305e30e5defad4acd6009081f7ee77f0ef849a213670d4e785c26d71375d40467e543326526fa800000000000000060100000000000000018000000000000000006000752102e6dd23598e1d2428ecf7eb59c27fdfeeb7a27c26906e96dc1f3d5ebba6e54d08ad0075740087ffffffff0100000000000000000e6a0c2bb584c84ba87a60dcab46c100000000"
    decoded_tx = deserialize_rust(hex)
    assert not decoded_tx["segwit"]
    p2sh_encoding_source, data, outputs_value = gettxinfo.get_transaction_source_from_p2sh(
        decoded_tx, False
    )
    assert p2sh_encoding_source == "18b7eyatTwZ8mvSCXRRxjNjvr3DPwhh6bU"

    config.NETWORK_NAME = original_network_name
    config.ADDRESSVERSION = original_address_version
    helpers.setup_bitcoinutils("regtest")


def test_deserialize_error():
    with pytest.raises(ValueError, match="Failed to decode hex transaction"):
        deserialize_rust("0100000001f9cf03a71930731618f2e0ff897db75d208a587129b96296f39")

    with pytest.raises(ValueError, match="Failed to decode hex block"):
        deserialize.deserialize_block(
            "0100000001f9cf03a71930731618f2e0ff897db75d208a587129b96296f39",
            parse_vouts=True,
            block_index=900000,
        )


def test_desrialize_reveal_tx(defaults):
    for data in [
        b"Hello, World!",
        b"a" * 1024 * 400,
    ]:
        reveal_tx = composer.get_dummy_signed_reveal_tx(defaults["addresses"][0], data)
        reveal_tx_hex = reveal_tx.serialize()
        decoded_tx = deserialize_rust(reveal_tx_hex)
        assert decoded_tx["parsed_vouts"] == (
            [],
            0,
            0,
            data,
            [(None, None)],
            b"\x01H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607",
        )

    reveal_tx = composer.get_dummy_signed_reveal_tx(defaults["addresses"][0], b"")
    reveal_tx_hex = reveal_tx.serialize()
    decoded_tx = deserialize_rust(reveal_tx_hex)
    assert decoded_tx["parsed_vouts"] == ([], 0, 0, b"", [(None, None)], b"")
