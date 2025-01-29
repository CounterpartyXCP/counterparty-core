import binascii
import time

import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.utils import base58


def test_base58_functions(defaults):
    assert (
        base58.base58_check_encode("010966776006953d5567439e5e39f86a0d273bee", b"\x00")
        == "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM"
    )
    assert (
        base58.base58_check_encode("010966776006953d5567439e5e39f86a0d273bee", b"\x05")
        == "31nVrspaydBz8aMpxH9WkS2DuhgqS1fCuG"
    )

    assert (
        base58.base58_check_decode("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM", b"\x00")
        == b"\x01\tfw`\x06\x95=UgC\x9e^9\xf8j\r';\xee"
    )
    assert (
        base58.base58_check_decode("13PGb7v3nmTDugLDStRJWXw6TzsNLUKJKC", b"\x00")
        == b"\x1a&jGxV\xea\xd2\x9e\xcb\xe6\xaeQ\xad:,\x8dG<\xf4"
    )
    assert (
        base58.base58_check_decode("31nVrspaydBz8aMpxH9WkS2DuhgqS1fCuG", b"\x05")
        == b"\x01\tfw`\x06\x95=UgC\x9e^9\xf8j\r';\xee"
    )
    assert (
        base58.base58_check_decode(defaults["addresses"][0], b"\x6f")
        == b"H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607"
    )

    with pytest.raises(exceptions.VersionByteError, match="incorrect version byte"):
        base58.base58_check_decode("13PGb7v3nmTDugLDStRJWXw6TzsNLUKJKC", b"\x05")

    with pytest.raises(exceptions.VersionByteError, match="incorrect version byte"):
        base58.base58_check_decode("31nVrspaydBz8aMpxH9WkS2DuhgqS1fCuG", b"\x00")

    with pytest.raises(exceptions.Base58Error, match="invalid base58 string"):
        base58.base58_check_decode("26UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM", b"\x00")

    with pytest.raises(exceptions.Base58Error, match="invalid base58 string"):
        base58.base58_check_decode("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvN", b"\x00")

    with pytest.raises(exceptions.Base58Error, match="invalid base58 string"):
        base58.base58_check_decode("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjv0", b"\x00")


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
        by_rust = base58.base58_check_encode(decoded, version)
        assert by_rust == encoded

        by_rust = base58.base58_check_decode(encoded, version)
        assert binascii.hexlify(by_rust).decode("utf-8") == decoded

    # iteration = 100000
    iteration = 10

    start_time = time.time()
    for i in range(iteration):  # noqa: B007
        for decoded, version, encoded in vector:
            base58.base58_check_encode(decoded, version)
            base58.base58_check_decode(encoded, version)
    rust_duration = time.time() - start_time
    print("rust duration for 400K encodes and 400K decodes: ", rust_duration)
