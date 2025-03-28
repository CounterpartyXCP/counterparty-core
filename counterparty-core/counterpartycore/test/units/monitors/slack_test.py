import json
import os
from unittest.mock import MagicMock, patch

import pytest

# Import the slack module directly
from counterpartycore.lib.monitors import slack

# Test data
TEST_MESSAGE = "This is a test message"
TEST_WEBHOOK_URL = "https://webhook.example.com"
EXPECTED_PAYLOAD = {"message": TEST_MESSAGE}


@pytest.fixture
def mock_response():
    """Create a mock response object for requests"""
    mock = MagicMock()
    mock.status_code = 200
    mock.json.return_value = {"ok": True}
    return mock


@pytest.fixture
def mock_env():
    """Mock environment variable for webhook URL"""
    with patch.dict(os.environ, {"SLACK_HOOK": TEST_WEBHOOK_URL}):
        yield


def test_send_slack_message_success(mock_response, mock_env):
    """Test successful message sending"""
    with patch("counterpartycore.lib.monitors.slack.requests.post") as mock_post:
        # Configure the mock
        mock_post.return_value = mock_response

        # Call the function
        result = slack.send_slack_message(TEST_MESSAGE)

        # Verify the function called requests.post with the correct arguments
        mock_post.assert_called_once()
        args, kwargs = mock_post.call_args

        # Check the URL
        assert args[0] == TEST_WEBHOOK_URL

        # Check the headers
        assert kwargs["headers"] == {"Content-Type": "application/json"}

        # Check the payload
        sent_payload = json.loads(kwargs["data"])
        assert sent_payload == EXPECTED_PAYLOAD

        # Check the return value
        assert result == {"ok": True}


def test_send_slack_message_no_webhook():
    """Test behavior when webhook URL is not set"""
    with patch.dict(os.environ, {}, clear=True):  # Clear environment variables
        # Call the function
        result = slack.send_slack_message(TEST_MESSAGE)

        # Function should return False if webhook is not set
        assert result is False


def test_send_slack_message_error(mock_env):
    """Test error handling when Slack returns an error"""
    with patch("counterpartycore.lib.monitors.slack.requests.post") as mock_post:
        # Configure the mock for a failed response
        error_response = MagicMock()
        error_response.status_code = 400
        error_response.text = "invalid_payload"
        mock_post.return_value = error_response

        # Call the function and expect a ValueError
        with pytest.raises(ValueError) as excinfo:
            slack.send_slack_message(TEST_MESSAGE)

        # Check the error message
        assert "Error sending message: 400, invalid_payload" in str(excinfo.value)


def test_send_slack_message_network_error(mock_env):
    """Test handling of network errors"""
    with patch("counterpartycore.lib.monitors.slack.requests.post") as mock_post:
        # Configure the mock to raise an exception
        mock_post.side_effect = Exception("Connection error")

        # Call the function and expect the exception to be propagated
        with pytest.raises(Exception) as excinfo:
            slack.send_slack_message(TEST_MESSAGE)

        # Check the error message
        assert "Connection error" in str(excinfo.value)


def test_send_slack_message_empty_message(mock_env):
    """Test sending an empty message"""
    with patch("counterpartycore.lib.monitors.slack.requests.post") as mock_post:
        # Configure the mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"ok": True}
        mock_post.return_value = mock_response

        # Call the function with an empty message
        result = slack.send_slack_message("")

        # Verify the payload has an empty message
        args, kwargs = mock_post.call_args
        sent_payload = json.loads(kwargs["data"])
        assert sent_payload == {"message": ""}

        # Function should still return successfully
        assert result == {"ok": True}


def test_send_slack_message_special_characters(mock_env):
    """Test sending a message with special characters"""
    special_message = "Test with special chars: å®çñö!@#$%^&*()"
    expected_special_payload = {"message": special_message}

    with patch("counterpartycore.lib.monitors.slack.requests.post") as mock_post:
        # Configure the mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"ok": True}
        mock_post.return_value = mock_response

        # Call the function
        slack.send_slack_message(special_message)

        # Verify the payload has the correct special characters
        _args, kwargs = mock_post.call_args
        sent_payload = json.loads(kwargs["data"])
        assert sent_payload == expected_special_payload
