import pytest
from counterpartycore.lib import exceptions
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
