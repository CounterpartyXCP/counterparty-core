from unittest.mock import MagicMock, patch

import pytest
from counterpartycore.lib import config
from counterpartycore.lib.cli.server import rebuild


@pytest.fixture
def rebuild_mock_dependencies():
    """Fixture to simulate external dependencies"""
    with (
        patch("counterpartycore.lib.monitors.slack.send_slack_message") as mock_slack,
        patch("counterpartycore.lib.cli.bootstrap.clean_data_dir") as mock_clean,
        patch("counterpartycore.lib.cli.server.start_all") as mock_start_all,
    ):
        yield {"slack": mock_slack, "clean_data_dir": mock_clean, "start_all": mock_start_all}


def test_rebuild_success(rebuild_mock_dependencies):
    """Test the case where rebuild executes successfully"""
    # Arrange
    args = MagicMock()

    # Act
    rebuild(args)

    # Assert
    rebuild_mock_dependencies["slack"].assert_any_call("Starting new rebuild.")
    rebuild_mock_dependencies["clean_data_dir"].assert_called_once_with(config.DATA_DIR)
    rebuild_mock_dependencies["start_all"].assert_called_once_with(args, stop_when_ready=True)
    rebuild_mock_dependencies["slack"].assert_called_with("Rebuild complete.")
    assert rebuild_mock_dependencies["slack"].call_count == 2


def test_rebuild_exception(rebuild_mock_dependencies):
    """Test the case where an exception occurs during rebuild"""
    # Arrange
    args = MagicMock()
    rebuild_mock_dependencies["clean_data_dir"].side_effect = Exception("Test error")

    # Act & Assert
    with pytest.raises(Exception, match="Test error"):
        rebuild(args)

    # Verify that appropriate Slack messages were sent
    rebuild_mock_dependencies["slack"].assert_any_call("Starting new rebuild.")
    rebuild_mock_dependencies["slack"].assert_any_call("Rebuild failed: Test error")
    assert rebuild_mock_dependencies["slack"].call_count == 2


def test_rebuild_start_all_exception(rebuild_mock_dependencies):
    """Test the case where start_all raises an exception"""
    # Arrange
    args = MagicMock()
    rebuild_mock_dependencies["start_all"].side_effect = Exception("Start failed")

    # Act & Assert
    with pytest.raises(Exception, match="Start failed"):
        rebuild(args)

    # Verify that appropriate messages were sent
    rebuild_mock_dependencies["slack"].assert_any_call("Starting new rebuild.")
    rebuild_mock_dependencies["slack"].assert_any_call("Rebuild failed: Start failed")
