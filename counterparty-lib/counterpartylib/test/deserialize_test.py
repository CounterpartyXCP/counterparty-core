from counterpartylib.lib.kickstart import blocks_parser, utils
from counterpartylib.lib import backend
import time


def test_deserialize():
    hex = "0100000001db3acf37743ac015808f7911a88761530c801819b3b907340aa65dfb6d98ce24030000006a473044022002961f4800cb157f8c0913084db0ee148fa3e1130e0b5e40c3a46a6d4f83ceaf02202c3dd8e631bf24f4c0c5341b3e1382a27f8436d75f3e0a095915995b0bf7dc8e01210395c223fbf96e49e5b9e06a236ca7ef95b10bf18c074bd91a5942fc40360d0b68fdffffff040000000000000000536a4c5058325bd61325dc633fadf05bec9157c23106759cee40954d39d9dbffc17ec5851a2d1feb5d271da422e0e24c7ae8ad29d2eeabf7f9ca3de306bd2bc98e2a39e47731aa000caf400053000c1283000149c8000000000000001976a91462bef4110f98fdcb4aac3c1869dbed9bce8702ed88acc80000000000000017a9144317f779c0a2ccf8f6bc3d440bd9e536a5bff75287fa3e5100000000001976a914bf2646b8ba8b4a143220528bde9c306dac44a01c88ac00000000"
    parser = blocks_parser.BlockchainParser()
    decoded_tx = parser.deserialize_tx(hex)

    assert decoded_tx == {
        "version": 1,
        "segwit": False,
        "coinbase": False,
        "vin": [
            {
                "hash": b"\xdb:\xcf7t:\xc0\x15\x80\x8fy\x11\xa8\x87aS\x0c\x80\x18\x19\xb3\xb9\x074\n\xa6]\xfbm\x98\xce$",
                "n": 3,
                "scriptSig": b"G0D\x02 \x02\x96\x1fH\x00\xcb\x15\x7f\x8c\t\x13\x08M\xb0\xee\x14\x8f\xa3\xe1\x13\x0e\x0b^@\xc3\xa4jmO\x83\xce\xaf\x02 ,=\xd8\xe61\xbf$\xf4\xc0\xc54\x1b>\x13\x82\xa2\x7f\x846\xd7_>\n\tY\x15\x99[\x0b\xf7\xdc\x8e\x01!\x03\x95\xc2#\xfb\xf9nI\xe5\xb9\xe0j#l\xa7\xef\x95\xb1\x0b\xf1\x8c\x07K\xd9\x1aYB\xfc@6\r\x0bh",
                "nSequence": 4294967293,
                "coinbase": False,
            }
        ],
        "vout": [
            {
                "nValue": 0,
                "scriptPubKey": b"jLPX2[\xd6\x13%\xdcc?\xad\xf0[\xec\x91W\xc21\x06u\x9c\xee@\x95M9\xd9\xdb\xff\xc1~\xc5\x85\x1a-\x1f\xeb]'\x1d\xa4\"\xe0\xe2Lz\xe8\xad)\xd2\xee\xab\xf7\xf9\xca=\xe3\x06\xbd+\xc9\x8e*9\xe4w1\xaa\x00\x0c\xaf@\x00S\x00\x0c\x12\x83\x00\x01I",
            },
            {
                "nValue": 200,
                "scriptPubKey": b"v\xa9\x14b\xbe\xf4\x11\x0f\x98\xfd\xcbJ\xac<\x18i\xdb\xed\x9b\xce\x87\x02\xed\x88\xac",
            },
            {
                "nValue": 200,
                "scriptPubKey": b"\xa9\x14C\x17\xf7y\xc0\xa2\xcc\xf8\xf6\xbc=D\x0b\xd9\xe56\xa5\xbf\xf7R\x87",
            },
            {
                "nValue": 5324538,
                "scriptPubKey": b"v\xa9\x14\xbf&F\xb8\xba\x8bJ\x142 R\x8b\xde\x9c0m\xacD\xa0\x1c\x88\xac",
            },
        ],
        "vtxinwit": [],
        "lock_time": 0,
        "tx_hash": "54cc399879446c4eaa7774bb764b319a2680709f99704ce60344587f49ff97e8",
        "__data__": "0100000001db3acf37743ac015808f7911a88761530c801819b3b907340aa65dfb6d98ce24030000006a473044022002961f4800cb157f8c0913084db0ee148fa3e1130e0b5e40c3a46a6d4f83ceaf02202c3dd8e631bf24f4c0c5341b3e1382a27f8436d75f3e0a095915995b0bf7dc8e01210395c223fbf96e49e5b9e06a236ca7ef95b10bf18c074bd91a5942fc40360d0b68fdffffff040000000000000000536a4c5058325bd61325dc633fadf05bec9157c23106759cee40954d39d9dbffc17ec5851a2d1feb5d271da422e0e24c7ae8ad29d2eeabf7f9ca3de306bd2bc98e2a39e47731aa000caf400053000c1283000149c8000000000000001976a91462bef4110f98fdcb4aac3c1869dbed9bce8702ed88acc80000000000000017a9144317f779c0a2ccf8f6bc3d440bd9e536a5bff75287fa3e5100000000001976a914bf2646b8ba8b4a143220528bde9c306dac44a01c88ac00000000",
    }

    transactions_hex = [
        "0100000001db3acf37743ac015808f7911a88761530c801819b3b907340aa65dfb6d98ce24030000006a473044022002961f4800cb157f8c0913084db0ee148fa3e1130e0b5e40c3a46a6d4f83ceaf02202c3dd8e631bf24f4c0c5341b3e1382a27f8436d75f3e0a095915995b0bf7dc8e01210395c223fbf96e49e5b9e06a236ca7ef95b10bf18c074bd91a5942fc40360d0b68fdffffff040000000000000000536a4c5058325bd61325dc633fadf05bec9157c23106759cee40954d39d9dbffc17ec5851a2d1feb5d271da422e0e24c7ae8ad29d2eeabf7f9ca3de306bd2bc98e2a39e47731aa000caf400053000c1283000149c8000000000000001976a91462bef4110f98fdcb4aac3c1869dbed9bce8702ed88acc80000000000000017a9144317f779c0a2ccf8f6bc3d440bd9e536a5bff75287fa3e5100000000001976a914bf2646b8ba8b4a143220528bde9c306dac44a01c88ac00000000",
        "010000000001010000000000000000000000000000000000000000000000000000000000000000ffffffff640342af0c2cfabe6d6dd04bc3504cba11910d72d3f9bcc603156272ec18d096431da690d1c11650bcec10000000f09f909f092f4632506f6f6c2f6900000000000000000000000000000000000000000000000000000000000000000000000500406f0100000000000522020000000000001976a914c6740a12d0a7d556f89782bf5faf0e12cf25a63988acf1c70e26000000001976a914c85526a428126c00ad071b56341a5a553a5e96a388ac0000000000000000266a24aa21a9ed8fd9974d26b10d3db6664fa2c59e8a504cb97c06e765a54c9096343cbac7716a00000000000000002f6a2d434f5245012953559db5cc88ab20b1960faa9793803d070337bdb2a04b4ccf74792cc6753c27c5fd5f1d6458bf00000000000000002c6a4c2952534b424c4f434b3af55b0e3836fafb2163bc99ce0bc3a950bf3bac5029e340f20459d525005d16580120000000000000000000000000000000000000000000000000000000000000000038aef23c",
        "01000000000102ab5357d8170304254e84cb66947995a1adcb534f562204e81889ee4badd2f1710000000000ffffffff9405cdfa4bb01f7656a1d2ce035bc232123f4fae23ac6d1fca03e135ca0994f00000000000ffffffff02a02526000000000016001450e3623e0095fa422a427421c3841c1e60a676c1f715a40a000000001600140c272ee21eb41191d1d9c2bd92e26fd958b58b440247304402205cc5a5ceaf59b36cfc6fd12f93bdfd54c6e625c09923ada2052576ef2221e9fb02201d7504f58459cce71f12f58eec01b6da3e43558fb8cb47c70eef34e2adf960b20121036d841256f891183be493f016fcbfec057bd5d88cbd8d2f9d06f13a36d9caf58502483045022100d80f2b4557258b528d4eaa313eff53a6db760ad1aaad3f78ff57103ba083984c02202ae089bcaffa38fcc8bfa2d0a7f5c7ef611f861e3309dc7baeb858f5b1a7198e01210298410495c0b4a9365842524467b58a84ca439c364605c510b50d6be442d32c8b00000000",
        "01000000023031e115e560c0d468459d7db35f5ab1992eaa0ab6aa0d6da49e2b8bcf1bb915010000006a47304402205535a9ac25844514828bff3580120d5add488e09b7a6e62018fc265aabf95fe302200b66d4eb23fc348b31d58729b479ae73db9dfc467edf38f8dfd927c48cb46b5801210219fbee4b9cc12188598f244ff0ee352b124cbf9046180a1b25e020c0258f9d64fffffffff2efdee1e775d962f7be96964adb352f9ef748a360749d6b74c69854a5c70a840c0000006a47304402203a28d10c786907fcb71c7bf69c507d58884ea9af2e7fa3b413d4e2867eca601502205fb253d82e4daa2672842ec031584ea7a215774422aa7de3cf8928c240e2faa60121030be5aa6d5de8c6dd89d6ac4d0e2a112caf5b12801349ab30fbdf2b205f0b94b8ffffffff02b60e0100000000001976a914f133f0339987cd84b6017517de2a93f009728d7e88acfdd7c400000000001976a91406c3bc40cde01312e2b24f8d2c23e68ea7d572f888ac00000000",
    ]
    for hex in transactions_hex:
        decoded_tx_bitcoinlib = backend.deserialize(hex)
        decoded_tx_parser = parser.deserialize_tx(hex, use_txid=False)

        for i, vin in enumerate(decoded_tx_bitcoinlib.vin):
            assert vin.prevout.hash == decoded_tx_parser["vin"][i]["hash"]
            assert vin.prevout.n == decoded_tx_parser["vin"][i]["n"]
            assert vin.scriptSig == decoded_tx_parser["vin"][i]["scriptSig"]
            assert vin.nSequence == decoded_tx_parser["vin"][i]["nSequence"]

        for i, vout in enumerate(decoded_tx_bitcoinlib.vout):
            assert vout.nValue == decoded_tx_parser["vout"][i]["nValue"]
            assert vout.scriptPubKey == decoded_tx_parser["vout"][i]["scriptPubKey"]

        assert decoded_tx_bitcoinlib.has_witness() == (len(decoded_tx_parser["vtxinwit"]) > 0)
        assert decoded_tx_bitcoinlib.is_coinbase() == decoded_tx_parser["coinbase"]

        assert utils.ib2h(decoded_tx_bitcoinlib.GetHash()) == decoded_tx_parser["tx_hash"]

    iterations = 25

    start_time = time.time()
    for i in range(iterations):
        for hex in transactions_hex:
            parser.deserialize_tx(hex)
    end_time = time.time()
    print(
        f"Time to deserialize {4 * iterations} transactions with block_parser: {end_time - start_time} seconds"
    )

    start_time = time.time()
    for i in range(iterations):
        for hex in transactions_hex:
            backend.deserialize(hex)
    end_time = time.time()
    print(
        f"Time to deserialize  {4 * iterations} transactions with bitcoinlib: {end_time - start_time} seconds"
    )
