import os
import string
from unittest.mock import Mock, patch

import pygit2
import pytest
from counterpartycore.lib.utils import helpers


def test_is_valid_tx_hash():
    assert not helpers.is_valid_tx_hash("foobar")
    assert helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda1"
    )
    assert not helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda11"
    )
    assert not helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda"
    )
    assert not helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42ddaG"
    )


def test_dhash():
    assert (
        helpers.dhash_string("foobar")
        == "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda1"
    )


def test_int_to_bytes():
    """Test the int_to_bytes function"""
    # Basic cases
    assert helpers.int_to_bytes(0) == b"\x00"
    assert helpers.int_to_bytes(1) == b"\x01"
    assert helpers.int_to_bytes(255) == b"\xff"

    # Numbers requiring multiple bytes
    assert helpers.int_to_bytes(256) == b"\x00\x01"
    assert helpers.int_to_bytes(65535) == b"\xff\xff"
    assert helpers.int_to_bytes(65536) == b"\x00\x00\x01"

    # Very large number
    big_num = 1234567890123456789
    assert helpers.bytes_to_int(helpers.int_to_bytes(big_num)) == big_num


def test_bytes_to_int():
    """Test the bytes_to_int function"""
    # Basic cases
    assert helpers.bytes_to_int(b"\x00") == 0
    assert helpers.bytes_to_int(b"\x01") == 1
    assert helpers.bytes_to_int(b"\xff") == 255

    # Multi-byte values
    assert helpers.bytes_to_int(b"\x00\x01") == 256
    assert helpers.bytes_to_int(b"\xff\xff") == 65535

    # Verify that int_to_bytes and bytes_to_int are inverse operations
    test_numbers = [0, 1, 127, 128, 255, 256, 65535, 65536, 123456789]
    for num in test_numbers:
        assert helpers.bytes_to_int(helpers.int_to_bytes(num)) == num


def test_varint():
    """Test the varint function"""
    # Small numbers
    assert helpers.varint(0) == b"\x00"
    assert helpers.varint(1) == b"\x01"
    assert helpers.varint(127) == b"\x7f"

    # Numbers requiring multiple bytes
    assert helpers.varint(128) == b"\x80\x01"
    assert helpers.varint(129) == b"\x81\x01"
    assert helpers.varint(16384) == b"\x80\x80\x01"

    # Verification with decode_varint
    test_numbers = [0, 1, 127, 128, 255, 16384, 2097152]
    for num in test_numbers:
        encoded = helpers.varint(num)
        decoded, _ = helpers.decode_varint(encoded)
        assert decoded == num


def test_decode_varint():
    """Test the decode_varint function"""
    # Simple cases
    assert helpers.decode_varint(b"\x00") == (0, 1)
    assert helpers.decode_varint(b"\x01") == (1, 1)
    assert helpers.decode_varint(b"\x7f") == (127, 1)

    # Multi-byte varints
    assert helpers.decode_varint(b"\x80\x01") == (128, 2)
    assert helpers.decode_varint(b"\xff\x01") == (255, 2)
    assert helpers.decode_varint(b"\x80\x80\x01") == (16384, 3)

    # Test with offset
    assert helpers.decode_varint(b"\x00\x7f", 1) == (127, 2)
    assert helpers.decode_varint(b"\x00\x80\x01", 1) == (128, 3)

    # Test with additional data
    data = b"\x05hello\x03world"
    length, offset = helpers.decode_varint(data)
    assert length == 5
    assert offset == 1
    assert data[offset : offset + length] == b"hello"


def test_encode_data():
    """Test the encode_data function"""
    # Test with a string
    result = helpers.encode_data("hello")
    assert result == b"\x05hello"

    # Test with an integer
    result = helpers.encode_data(42)
    assert result == b"\x01\x2a"

    # Test with bytes
    result = helpers.encode_data(b"test")
    assert result == b"\x04test"

    # Test with a hexadecimal string
    result = helpers.encode_data("48656c6c6f")  # "Hello" in hexadecimal
    assert result == b"\x05Hello"

    # Test with multiple arguments
    result = helpers.encode_data("abc", 123, b"xyz")
    expected = b"\x03abc\x01\x7b\x03xyz"
    assert result == expected

    # Test with empty strings and zeros
    result = helpers.encode_data("", 0, b"")
    assert result == b"\x00\x01\x00\x00"


def test_decode_data():
    """Test the decode_data function"""
    # Simple cases
    assert helpers.decode_data(b"\x05hello") == [b"hello"]
    assert helpers.decode_data(b"\x01\x2a") == [b"\x2a"]
    assert helpers.decode_data(b"\x04test") == [b"test"]

    # Test with multiple values
    encoded = b"\x03abc\x01\x7b\x03xyz"
    decoded = helpers.decode_data(encoded)
    assert decoded == [b"abc", b"\x7b", b"xyz"]

    # Test with empty data
    assert helpers.decode_data(b"\x00") == [b""]

    # Test with TypeError
    with pytest.raises(TypeError):
        helpers.decode_data("not bytes")


def test_round_trip():
    """Complete test of encoding followed by decoding"""
    test_cases = [
        ["simple string"],
        [42],
        [b"binary data"],
        ["abc", 123, b"xyz"],
        ["", 0, b""],  # Cases with empty values
        ["a" * 1000],  # Long string
        [2**20],  # Large number
    ]

    for case in test_cases:
        encoded = helpers.encode_data(*case)
        decoded = helpers.decode_data(encoded)

        # Transform original values into what we expect after decoding
        expected = []
        for item in case:
            if isinstance(item, str):
                if all(c in string.hexdigits for c in item):
                    try:
                        expected.append(bytes.fromhex(item))
                    except ValueError:
                        expected.append(item.encode("utf-8"))
                else:
                    expected.append(item.encode("utf-8"))
            elif isinstance(item, int):
                expected.append(helpers.int_to_bytes(item))
            elif isinstance(item, bytes):
                expected.append(item)

        assert decoded == expected


# Additional tests for edge cases
def test_edge_cases():
    # Test with extreme values
    assert helpers.int_to_bytes(0) == b"\x00"
    assert helpers.bytes_to_int(b"") == 0  # Verify behavior with empty bytes

    # Strings with non-ASCII characters
    utf8_string = "こんにちは"  # Hello in Japanese
    encoded = helpers.encode_data(utf8_string)
    decoded = helpers.decode_data(encoded)
    assert decoded[0] == utf8_string.encode("utf-8")

    # Test with a number near Python integer limits
    large_int = 2**63 - 1  # Max value for a 64-bit signed integer
    assert helpers.bytes_to_int(helpers.int_to_bytes(large_int)) == large_int


@pytest.fixture
def mock_repo():
    """Fixture to create a simulated git repository"""
    mock_repo = Mock()
    mock_head = Mock()
    mock_repo.head = mock_head
    mock_repo.head_is_detached = False
    return mock_repo


def test_get_commit_hash_normal_case(mock_repo):
    """Tests getting the commit hash in a normal case (on a branch)"""
    # Mock configuration
    mock_repo.head.target = "abcdef1234567890"
    mock_repo.head.shorthand = "main"

    with patch("pygit2.discover_repository", return_value="."):
        with patch("pygit2.Repository", return_value=mock_repo):
            # Function call
            result = helpers.get_current_commit_hash()

            # Result verification
            assert result == "main - abcdef1234567890"


def test_get_commit_hash_detached_head(mock_repo):
    """Tests getting the commit hash when HEAD is detached"""
    # Mock configuration
    mock_repo.head.target = "abcdef1234567890"
    mock_repo.head.shorthand = "some-branch"  # This name will be ignored
    mock_repo.head_is_detached = True

    with patch("pygit2.discover_repository", return_value="."):
        with patch("pygit2.Repository", return_value=mock_repo):
            # Function call
            result = helpers.get_current_commit_hash()

            # Result verification
            assert result == "HEAD detached - abcdef1234567890"


def test_get_commit_hash_no_repo():
    """Tests getting the commit hash when not in a git repository"""
    # Simulate pygit2.discover_repository raising a GitError
    with patch("pygit2.discover_repository", side_effect=pygit2.GitError):
        # Function call
        result = helpers.get_current_commit_hash()

        # Result verification
        assert result is None


def test_get_commit_hash_git_error():
    """Tests getting the commit hash when a GitError occurs"""
    # Simulate pygit2.Repository raising a GitError
    with patch("pygit2.discover_repository", return_value="."):
        with patch("pygit2.Repository", side_effect=pygit2.GitError):
            # Function call
            result = helpers.get_current_commit_hash()

            # Result verification
            assert result is None


def test_get_commit_hash_from_env():
    os.environ["CURRENT_COMMIT"] = "abcdef1234567890"
    result = helpers.get_current_commit_hash()
    assert result == "abcdef1234567890"
