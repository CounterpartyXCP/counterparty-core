import binascii
import os
import time

import bitcoin as bitcoinlib
from bitcoin import bech32 as bech32lib
from bitcoinutils.keys import PrivateKey
from counterparty_rs import utils
from counterpartycore.lib.parser.gettxinfo import get_checksig
from counterpartycore.lib.utils import script
from counterpartycore.lib.utils.opcodes import *  # noqa: F403
from counterpartycore.lib.utils.script import script_to_asm


def test_get_asm():
    def with_rust():
        asm = script_to_asm(b"v\xa9\x14H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607\x88\xac")
        assert asm == [
            OP_DUP,  # noqa: F405
            OP_HASH160,  # noqa: F405
            b"H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607",
            OP_EQUALVERIFY,  # noqa: F405
            OP_CHECKSIG,  # noqa: F405
        ]

        asm = script_to_asm(
            b"jLP:\xb4\x08\xa6y\xf1\x08\xa1\x9e5\x88h\x15\xc4\xc4h\xcau\xa0g\x99\xf8d\xa1\xfa\xd6\xbc\x08\x13\xf5\xfe2`\xe4!\xa3\x02\x02\xf2\xe7oF\xac\xdb),e#q\xcaH\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x9f\xad\xc2\x0c\x0bE=\xe6ghr\xc9\xe4\x1f\xad\x80\x1e\x8b"
        )
        assert asm == [
            OP_RETURN,  # noqa: F405
            b":\xb4\x08\xa6y\xf1\x08\xa1\x9e5\x88h\x15\xc4\xc4h\xcau\xa0g\x99\xf8d\xa1\xfa\xd6\xbc\x08\x13\xf5\xfe2`\xe4!\xa3\x02\x02\xf2\xe7oF\xac\xdb),e#q\xcaH\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x9f\xad\xc2\x0c\x0bE=\xe6ghr\xc9\xe4\x1f\xad\x80\x1e\x8b",
        ]

    iteration = 100000

    start_time = time.time()
    for i in range(iteration):  # noqa: B007
        with_rust()
    rust_duration = time.time() - start_time
    print(f"rust duration for {iteration} iterations: ", rust_duration)

    asm = script_to_asm(
        b"Q!\x03\\\xa5\x1e\xa1u\xf1\x08\xa1\xc65\x88h=\xc4\xc4:qF\xc4g\x99\xf8d\xa3\x00&<\x08\x13\xf5\xfe5!\x020\x9a\x14\xa1\xa3\x02\x02\xf2\xe7oF\xac\xdb)\x17u#q\xcaB\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x17!\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9wS\xae"
    )
    assert asm == [
        1,
        b"\x03\\\xa5\x1e\xa1u\xf1\x08\xa1\xc65\x88h=\xc4\xc4:qF\xc4g\x99\xf8d\xa3\x00&<\x08\x13\xf5\xfe5",
        b"\x020\x9a\x14\xa1\xa3\x02\x02\xf2\xe7oF\xac\xdb)\x17u#q\xcaB\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x17",
        b"\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9w",
        3,
        OP_CHECKMULTISIG,  # noqa: F405
    ]

    script = "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
    asm = script_to_asm(binascii.unhexlify(script))
    assert asm == [
        OP_DUP,  # noqa: F405
        OP_HASH160,  # noqa: F405
        b"\xa3\xec`\xfbR/\xdfb\xc9\x0e\xec\x19\x81Wx\x13\xd8\xf8\xa5\x8a",
        OP_EQUALVERIFY,  # noqa: F405
        OP_CHECKSIG,  # noqa: F405
    ]
    pubkeyhash = get_checksig(asm)
    assert pubkeyhash == b"\xa3\xec`\xfbR/\xdfb\xc9\x0e\xec\x19\x81Wx\x13\xd8\xf8\xa5\x8a"


def script_to_address():
    def decode_p2w(script_pubkey):
        bech32 = bitcoinlib.bech32.CBech32Data.from_bytes(0, script_pubkey[2:22])
        return str(bech32), None

    script_pubkey = b"\x00\x14u\x1ev\xe8\x19\x91\x96\xd4T\x94\x1cE\xd1\xb3\xa3#\xf1C;\xd6"
    bech32 = utils.script_to_address(script_pubkey, "testnet3")
    assert bech32 == "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx"

    bech32 = utils.script_to_address(script_pubkey, "mainnet")
    assert bech32 == "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"

    # iterations = 1000000
    iterations = 100

    print()

    start_time = time.time()
    for i in range(iterations):  # noqa: B007
        bech32 = decode_p2w(script_pubkey)
        assert bech32 == ("tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx", None)
    python_duration = time.time() - start_time
    print(f"{iterations} decode_p2w with python: {python_duration}s")

    start_time = time.time()
    for i in range(iterations):  # noqa: B007
        bech32 = utils.script_to_address(script_pubkey, "testnet3")
        assert bech32 == "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx"
    rust_duration = time.time() - start_time
    print(f"{iterations} decode_p2w with rust: {rust_duration}s")

    assert python_duration > rust_duration


def decode_p2w(script_pubkey):
    try:
        bech32 = bech32lib.CBech32Data.from_bytes(0, script_pubkey[2:22])
        return str(bech32), None
    except TypeError as e:  # noqa: F841
        raise Exception("bech32 decoding error")  # noqa: B904


def test_script_to_asm():
    asm = utils.script_to_asm(b"v\xa9\x14H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607\x88\xac")
    assert asm == [
        b"v",
        b"\xa9",
        b"H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607",
        b"\x88",
        b"\xac",
    ]
    """ [
        'OP_DUP',
        'OP_HASH160',
        b'H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607',
        'OP_EQUALVERIFY',
        'OP_CHECKSIG'
    ] """

    asm = utils.script_to_asm(
        b"Q!\x03\\\xa5\x1e\xa1u\xf1\x08\xa1\xc65\x88h=\xc4\xc4:qF\xc4g\x99\xf8d\xa3\x00&<\x08\x13\xf5\xfe5!\x020\x9a\x14\xa1\xa3\x02\x02\xf2\xe7oF\xac\xdb)\x17u#q\xcaB\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x17!\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9wS\xae"
    )
    assert asm == [
        b"\x01",
        b"\x03\\\xa5\x1e\xa1u\xf1\x08\xa1\xc65\x88h=\xc4\xc4:qF\xc4g\x99\xf8d\xa3\x00&<\x08\x13\xf5\xfe5",
        b"\x020\x9a\x14\xa1\xa3\x02\x02\xf2\xe7oF\xac\xdb)\x17u#q\xcaB\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x17",
        b"\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9w",
        b"\x03",
        b"\xae",  # OP_CHECKMULTISIG
    ]


def test_decode_p2w():
    script_pubkey = b"\x00\x14u\x1ev\xe8\x19\x91\x96\xd4T\x94\x1cE\xd1\xb3\xa3#\xf1C;\xd6"
    bech32 = utils.script_to_address(script_pubkey, "testnet3")
    assert bech32 == "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx"

    bech32 = utils.script_to_address(script_pubkey, "mainnet")
    assert bech32 == "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"

    bitcoinlib.SelectParams("mainnet")

    assert decode_p2w(script_pubkey)[0] == utils.script_to_address(script_pubkey, "mainnet")

    script_pubkey = binascii.unhexlify(
        "0020dcbc2340bd1f6cc3ab0a3887020647ec471a279e3c889fb4414df30e3dd59f96"
    )
    assert decode_p2w(script_pubkey) == ("bc1qmj7zxs9arakv82c28zrsypj8a3r35fu7pure55", None)
    assert (
        decode_p2w(script_pubkey)[0] == "bc1qmj7zxs9arakv82c28zrsypj8a3r35fu7pure55"
    )  # instead bc1qmj7zxs9arakv82c28zrsypj8a3r35fu78jyfldzpfhesu0w4n7tqw23az4

    script_pubkey = binascii.unhexlify(
        "0020dfe1739dc0711f64ced999a2306691ff98fff038b2f40aec2b5ae917610ea0ac"
    )
    assert decode_p2w(script_pubkey) == ("bc1qmlsh88wqwy0kfnkenx3rqe53l7v0lupc6q5xx6", None)
    assert (
        decode_p2w(script_pubkey)[0] == "bc1qmlsh88wqwy0kfnkenx3rqe53l7v0lupc6q5xx6"
    )  # instead bc1qmlsh88wqwy0kfnkenx3rqe53l7v0lupckt6q4mpttt53wcgw5zkqyw35cd

    script_pubkey = binascii.unhexlify(
        "51200f9dab1a72f7c48da8a1df2f913bef649bfc0d77072dffd11329b8048293d7a3"
    )
    # correct address
    assert (
        utils.script_to_address(script_pubkey, "mainnet")
        == "bc1pp7w6kxnj7lzgm29pmuhezwl0vjdlcrthqukll5gn9xuqfq5n673smy4m63"
    )
    # incorrect address
    assert (
        utils.script_to_address(script_pubkey, "mainnet")
        == "bc1pp7w6kxnj7lzgm29pmuhezwl0vjdlcrthqukll5gn9xuqfq5n673smy4m63"
    )

    script_pubkey = binascii.unhexlify(
        "00207086320071974eef5e72eaa01dd9096e10c0383483855ea6b344259c244f73c2"
    )
    # correct address
    assert (
        utils.script_to_address(script_pubkey, "mainnet")
        == "bc1qwzrryqr3ja8w7hnja2spmkgfdcgvqwp5swz4af4ngsjecfz0w0pqud7k38"
    )


def test_taproot_script_to_address():
    random = os.urandom(32)
    source_private_key = PrivateKey(b=random)
    source_pubkey = source_private_key.get_public_key()
    source_address = source_pubkey.get_taproot_address()
    print("Source address", source_address.to_string())

    script_pubkey = source_address.to_script_pub_key()

    check_address = script.script_to_address(script_pubkey.to_hex())
    print("Check address", check_address)

    assert source_address.to_string() == check_address
