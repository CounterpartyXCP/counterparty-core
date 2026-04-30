import decimal
import os
from unittest.mock import Mock, patch

import pygit2
import pytest
from counterpartycore.lib.utils import helpers


def test_chunkify():
    """Test chunkify function."""
    assert helpers.chunkify([1, 2, 3, 4, 5], 2) == [[1, 2], [3, 4], [5]]
    assert helpers.chunkify([1, 2, 3, 4], 2) == [[1, 2], [3, 4]]
    assert helpers.chunkify([1, 2, 3], 1) == [[1], [2], [3]]
    assert helpers.chunkify([], 5) == []
    # Test with n=0 (should use n=1)
    assert helpers.chunkify([1, 2, 3], 0) == [[1], [2], [3]]


def test_flat():
    """Test flat function."""
    assert helpers.flat([1, 2, 3]) == [1, 2, 3]
    assert helpers.flat((1, 2, 3)) == [1, 2, 3]
    assert helpers.flat(range(3)) == [0, 1, 2]


def test_accumulate():
    """Test accumulate function."""
    data = [("a", 1), ("a", 2), ("b", 3), ("b", 4), ("a", 5)]
    result = list(helpers.accumulate(data))
    assert result == [("a", 3), ("b", 7), ("a", 5)]


def test_active_options():
    """Test active_options function."""
    assert helpers.active_options(0b1111, 0b0101) is True
    assert helpers.active_options(0b1010, 0b0101) is False
    assert helpers.active_options(0b0101, 0b0101) is True


def test_make_id():
    """Test make_id function."""
    assert helpers.make_id("hash1", "hash2") == "hash1_hash2"


def test_satoshirate_to_fiat():
    """Test satoshirate_to_fiat function."""
    assert helpers.satoshirate_to_fiat(10000) == 100.0
    assert helpers.satoshirate_to_fiat(12345) == 123.45
    assert helpers.satoshirate_to_fiat(0) == 0.0


def test_format_duration():
    """Test format_duration function."""
    assert helpers.format_duration(3661) == "1h 1m 1s"
    assert helpers.format_duration(0) == "0h 0m 0s"
    assert helpers.format_duration(7200) == "2h 0m 0s"


def test_is_url():
    """Test is_url function."""
    assert helpers.is_url("https://example.com") is True
    assert helpers.is_url("http://example.com/path") is True
    assert helpers.is_url("ftp://files.example.com") is True
    assert helpers.is_url("not-a-url") is False
    assert helpers.is_url("") is False
    assert helpers.is_url("example.com") is False


def test_divide():
    """Test divide function."""
    assert helpers.divide(10, 2) == 5
    assert helpers.divide(10, 0) == 0
    assert helpers.divide(0, 10) == 0
    assert helpers.divide(1, 3) == helpers.D("0.3333333333333333")


def test_bytes_to_string():
    """Test bytes_to_string function."""
    # Valid UTF-8
    assert helpers.bytes_to_string(b"hello") == "hello"
    # Invalid UTF-8 should return hex
    assert helpers.bytes_to_string(b"\xff\xfe") == "fffe"


def test_is_process_alive():
    """Test is_process_alive function."""
    # Current process should be alive
    assert helpers.is_process_alive(os.getpid()) is True
    # Non-existent PID (very high number)
    assert helpers.is_process_alive(999999999) is False


def test_api_json_encoder():
    """Test ApiJsonEncoder with various types."""
    encoder = helpers.ApiJsonEncoder()

    # Test decimal
    assert encoder.default(decimal.Decimal("1.23456789")) == "1.23456789"

    # Test bytes
    assert encoder.default(b"\x01\x02\x03") == "010203"

    # Test callable
    def my_func():
        pass

    assert encoder.default(my_func) == "my_func"

    # Test object with __class__ (custom object)
    class CustomObj:
        def __str__(self):
            return "custom_string"

    assert encoder.default(CustomObj()) == "custom_string"


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
            assert result == "abcdef1234567890"


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


def test_classify_mime_type():
    assert helpers.classify_mime_type("text/plain") == "text"
    assert helpers.classify_mime_type("message/rfc822") == "text"
    assert helpers.classify_mime_type("application/atom+xml") == "text"
    assert helpers.classify_mime_type("application/json") == "text"
    assert helpers.classify_mime_type("application/javascript") == "text"
    assert helpers.classify_mime_type("image/jpeg") == "binary"


def test_content_to_bytes():
    assert helpers.content_to_bytes("texte", "text/plain") == b"texte"
    assert helpers.content_to_bytes("48656c6c6f", "image/jpeg") == b"Hello"


def test_bytes_to_content():
    assert helpers.bytes_to_content(b"texte", "text/plain") == "texte"
    assert helpers.bytes_to_content(b"Hello", "image/jpeg") == "48656c6c6f"


@pytest.mark.parametrize(
    "mime_type,content,expected",
    [
        ("text/plain", "valid content", []),  # Valid MIME type
        (None, "valid content", []),  # None defaults to text/plain
        # Invalid MIME with both errors
        (
            "fake/nonexistent-type",
            "valid content",
            [
                "Invalid mime type: fake/nonexistent-type",
                "Error converting description to bytes: Odd-length string",
            ],
        ),
        # Exception from content_to_bytes only
        ("text/plain", "valid content", ["Error converting description to bytes: Test error"]),
    ],
)
def test_check_content(mime_type, content, expected):
    if "Test error" in str(expected):
        with patch(
            "counterpartycore.lib.utils.helpers.content_to_bytes",
            side_effect=Exception("Test error"),
        ):
            assert helpers.check_content(mime_type, content) == expected
    else:
        assert helpers.check_content(mime_type, content) == expected
