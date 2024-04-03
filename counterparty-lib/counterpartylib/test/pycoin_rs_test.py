import time
import binascii

import pytest
import bitcoin as bitcoinlib
from bitcoin.core.script import CScript

from counterpartylib.lib import config
from counterpartylib.lib.script import (
    base58_check_encode,
    base58_check_decode,
    base58_check_decode_py,
    base58_check_encode_py,
    get_asm,
    script_to_asm,
    get_checksig,
)

from counterpartylib.lib.opcodes import *

from counterparty_rs import utils


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
        by_python = base58_check_encode_py(decoded, version)
        by_rust = base58_check_encode(decoded, version)
        assert by_rust == by_python

        by_python = base58_check_decode_py(encoded, version)
        by_rust = base58_check_decode(encoded, version)
        assert by_rust == by_python

    # iteration = 100000
    iteration = 10

    start_time = time.time()
    for i in range(iteration):
        for decoded, version, encoded in vector:
            base58_check_encode(decoded, version)
            base58_check_decode(encoded, version)
    rust_duration = time.time() - start_time
    print("rust duration for 400K encodes and 400K decodes: ", rust_duration)

    start_time = time.time()
    for i in range(iteration):
        for decoded, version, encoded in vector:
            base58_check_encode_py(decoded, version)
            base58_check_decode_py(encoded, version)
    python_duration = time.time() - start_time
    print("python duration for 400K encodes and 400K decodes: ", python_duration)

    assert rust_duration < python_duration


def test_get_asm():
    def with_rust():
        asm = script_to_asm(b"v\xa9\x14H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607\x88\xac")
        assert asm == [
            OP_DUP,
            OP_HASH160,
            b"H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607",
            OP_EQUALVERIFY,
            OP_CHECKSIG,
        ]

        asm = script_to_asm(
            b"jLP:\xb4\x08\xa6y\xf1\x08\xa1\x9e5\x88h\x15\xc4\xc4h\xcau\xa0g\x99\xf8d\xa1\xfa\xd6\xbc\x08\x13\xf5\xfe2`\xe4!\xa3\x02\x02\xf2\xe7oF\xac\xdb),e#q\xcaH\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x9f\xad\xc2\x0c\x0bE=\xe6ghr\xc9\xe4\x1f\xad\x80\x1e\x8b"
        )
        assert asm == [
            OP_RETURN,
            b":\xb4\x08\xa6y\xf1\x08\xa1\x9e5\x88h\x15\xc4\xc4h\xcau\xa0g\x99\xf8d\xa1\xfa\xd6\xbc\x08\x13\xf5\xfe2`\xe4!\xa3\x02\x02\xf2\xe7oF\xac\xdb),e#q\xcaH\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x9f\xad\xc2\x0c\x0bE=\xe6ghr\xc9\xe4\x1f\xad\x80\x1e\x8b",
        ]

    def with_python():
        asm = get_asm(CScript(b"v\xa9\x14H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607\x88\xac"))
        assert asm == [
            OP_DUP,
            OP_HASH160,
            b"H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607",
            OP_EQUALVERIFY,
            OP_CHECKSIG,
        ]

        asm = get_asm(
            CScript(
                b"jLP:\xb4\x08\xa6y\xf1\x08\xa1\x9e5\x88h\x15\xc4\xc4h\xcau\xa0g\x99\xf8d\xa1\xfa\xd6\xbc\x08\x13\xf5\xfe2`\xe4!\xa3\x02\x02\xf2\xe7oF\xac\xdb),e#q\xcaH\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x9f\xad\xc2\x0c\x0bE=\xe6ghr\xc9\xe4\x1f\xad\x80\x1e\x8b"
            )
        )
        assert asm == [
            OP_RETURN,
            b":\xb4\x08\xa6y\xf1\x08\xa1\x9e5\x88h\x15\xc4\xc4h\xcau\xa0g\x99\xf8d\xa1\xfa\xd6\xbc\x08\x13\xf5\xfe2`\xe4!\xa3\x02\x02\xf2\xe7oF\xac\xdb),e#q\xcaH\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x9f\xad\xc2\x0c\x0bE=\xe6ghr\xc9\xe4\x1f\xad\x80\x1e\x8b",
        ]

    iteration = 100000

    print()

    start_time = time.time()
    for i in range(iteration):
        with_rust()
    rust_duration = time.time() - start_time
    print(f"rust duration for {iteration} iterations: ", rust_duration)

    start_time = time.time()
    for i in range(iteration):
        with_python()
    python_duration = time.time() - start_time
    print(f"python duration for {iteration} iterations: ", python_duration)

    asm = script_to_asm(
        b"Q!\x03\\\xa5\x1e\xa1u\xf1\x08\xa1\xc65\x88h=\xc4\xc4:qF\xc4g\x99\xf8d\xa3\x00&<\x08\x13\xf5\xfe5!\x020\x9a\x14\xa1\xa3\x02\x02\xf2\xe7oF\xac\xdb)\x17u#q\xcaB\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x17!\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9wS\xae"
    )
    assert asm == [
        1,
        b"\x03\\\xa5\x1e\xa1u\xf1\x08\xa1\xc65\x88h=\xc4\xc4:qF\xc4g\x99\xf8d\xa3\x00&<\x08\x13\xf5\xfe5",
        b"\x020\x9a\x14\xa1\xa3\x02\x02\xf2\xe7oF\xac\xdb)\x17u#q\xcaB\xb9t`\xf7\x92\x8a\xde\x8e\xcb\x02\xea\x17",
        b"\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9w",
        3,
        OP_CHECKMULTISIG,
    ]

    script = "76a914a3ec60fb522fdf62c90eec1981577813d8f8a58a88ac"
    asm = script_to_asm(binascii.unhexlify(script))
    assert asm == [
        OP_DUP,
        OP_HASH160,
        b"\xa3\xec`\xfbR/\xdfb\xc9\x0e\xec\x19\x81Wx\x13\xd8\xf8\xa5\x8a",
        OP_EQUALVERIFY,
        OP_CHECKSIG,
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
    for i in range(iterations):
        bech32 = decode_p2w(script_pubkey)
        assert bech32 == ("tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx", None)
    python_duration = time.time() - start_time
    print(f"{iterations} decode_p2w with python: {python_duration}s")

    start_time = time.time()
    for i in range(iterations):
        bech32 = utils.script_to_address(script_pubkey, "testnet")
        assert bech32 == "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx"
    rust_duration = time.time() - start_time
    print(f"{iterations} decode_p2w with rust: {rust_duration}s")

    assert python_duration > rust_duration
