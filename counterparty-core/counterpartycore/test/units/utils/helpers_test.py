import os
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
