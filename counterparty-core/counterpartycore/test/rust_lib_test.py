import binascii
import time

import bitcoin as bitcoinlib
import pytest  # noqa: F401
from bitcoin import bech32 as bech32lib
from counterparty_rs import b58, utils

from counterpartycore.lib import config
from counterpartycore.lib.parser.gettxinfo import get_checksig
from counterpartycore.lib.utils.base58 import base58_check_decode, base58_check_encode
from counterpartycore.lib.utils.opcodes import *  # noqa: F403
from counterpartycore.lib.utils.script import script_to_asm


def test_pycoin_rs():
    vector = [
        (
            "4264cfd7eb65f8cbbdba98bd9815d5461fad8d7e",
            config.P2SH_ADDRESSVERSION_TESTNET,
            "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
        ),
        (
            "641327ad1b3abc18cb6f1650a225f49a47764c22",
            config.ADDRESSVERSION_TESTNET,
            "mpe6p9ah9a6yoK57Xd2GEn8D9EonbLLkWJ",
        ),
        (
            "415354746bc11e9ef91efa85da59f0ad1df61a9d",
            config.ADDRESSVERSION_MAINNET,
            "16xQkLFxYZcGtzyGbHD7tmnaeHavD21Kw5",
        ),
        (
            "edf98b439f45eb4e3239122488cab2773296499d",
            config.P2SH_ADDRESSVERSION_MAINNET,
            "3PPK1dRAerbVZRfkh9BhA1Zxq9HrG4rRwN",
        ),
    ]

    for decoded, version, encoded in vector:
        by_rust = base58_check_encode(decoded, version)
        assert by_rust == encoded

        by_rust = base58_check_decode(encoded, version)
        assert binascii.hexlify(by_rust).decode("utf-8") == decoded

    # iteration = 100000
    iteration = 10

    start_time = time.time()
    for i in range(iteration):  # noqa: B007
        for decoded, version, encoded in vector:
            base58_check_encode(decoded, version)
            base58_check_decode(encoded, version)
    rust_duration = time.time() - start_time
    print("rust duration for 400K encodes and 400K decodes: ", rust_duration)


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
    bech32 = utils.script_to_address(script_pubkey, "testnet")
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
        bech32 = utils.script_to_address(script_pubkey, "testnet")
        assert bech32 == "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx"
    rust_duration = time.time() - start_time
    print(f"{iterations} decode_p2w with rust: {rust_duration}s")

    assert python_duration > rust_duration


def test_b58():
    assert b58.b58_encode(b"hello world") == "3vQB7B6MrGQZaxCuFg4oh"
    assert bytes(b58.b58_decode("3vQB7B6MrGQZaxCuFg4oh")) == b"hello world"

    with pytest.raises(ValueError) as excinfo:
        b58.b58_decode("hello world")
    assert str(excinfo.value) == "Bad input"


def decode_p2w(script_pubkey):
    try:
        bech32 = bech32lib.CBech32Data.from_bytes(0, script_pubkey[2:22])
        return str(bech32), None
    except TypeError as e:  # noqa: F841
        raise Exception("bech32 decoding error")  # noqa: B904


def inverse_hash_py(hashstring):
    return "".join([hashstring[i : i + 2][::-1] for i in range(0, len(hashstring), 2)])[::-1]


def test_inverse_hash():
    h = "b5276739a3e0f32147bd4a921f936c6013dee4a5ca426ee2de868810b068ec0d"
    assert (
        utils.inverse_hash(h) == "0dec68b0108886dee26e42caa5e4de13606c931f924abd4721f3e0a3396727b5"
    )

    # iterations = 1000000
    iterations = 10

    start_time = time.time()
    for i in range(iterations):  # noqa: B007
        inverse_hash_py(h)
    python_duration = time.time() - start_time
    print(f"{iterations} inverse hash with python: {python_duration}s")

    start_time = time.time()
    for i in range(iterations):  # noqa: B007
        utils.inverse_hash(h)
    rust_duration = time.time() - start_time
    print(f"{iterations} inverse hash with rust: {rust_duration}s")

    assert python_duration > rust_duration


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
    bech32 = utils.script_to_address(script_pubkey, "testnet")
    assert bech32 == "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx"

    bech32 = utils.script_to_address(script_pubkey, "mainnet")
    assert bech32 == "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"

    bitcoinlib.SelectParams("mainnet")

    assert decode_p2w(script_pubkey)[0] == utils.script_to_address(script_pubkey, "mainnet")

    script_pubkey = binascii.unhexlify(
        "0020dcbc2340bd1f6cc3ab0a3887020647ec471a279e3c889fb4414df30e3dd59f96"
    )
    assert decode_p2w(script_pubkey) == ("bc1qmj7zxs9arakv82c28zrsypj8a3r35fu7pure55", None)
    assert decode_p2w(script_pubkey)[0] == utils.script_to_address(script_pubkey, "mainnet")

    script_pubkey = binascii.unhexlify(
        "0020dfe1739dc0711f64ced999a2306691ff98fff038b2f40aec2b5ae917610ea0ac"
    )
    assert decode_p2w(script_pubkey) == ("bc1qmlsh88wqwy0kfnkenx3rqe53l7v0lupc6q5xx6", None)
    assert decode_p2w(script_pubkey)[0] == utils.script_to_address(script_pubkey, "mainnet")

    bitcoinlib.SelectParams("testnet")
