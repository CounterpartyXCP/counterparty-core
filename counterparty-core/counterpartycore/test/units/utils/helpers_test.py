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
