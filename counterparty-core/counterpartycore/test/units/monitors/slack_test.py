from unittest.mock import Mock, patch

import requests
from counterpartycore.lib.monitors import slack


def test_trigger_webhook_no_url():
    # Test when SLACK_HOOK is not set
    with patch.dict("os.environ", {}, clear=True):
        result = slack.trigger_webhook()
        assert result is False


def test_trigger_webhook_success():
    # Test successful webhook call
    with (
        patch.dict("os.environ", {"SLACK_HOOK": "https://hooks.slack.com/services/xxx"}),
        patch("requests.get") as mock_get,
    ):
        mock_response = Mock()
        mock_response.raise_for_status.return_value = None
        mock_get.return_value = mock_response

        with patch("logging.info") as mock_log_info:
            result = slack.trigger_webhook()

            assert result is True
            mock_get.assert_called_once_with("https://hooks.slack.com/services/xxx", timeout=10)
            mock_log_info.assert_called_once()


def test_trigger_webhook_error():
    # Test webhook call raising an exception
    with (
        patch.dict("os.environ", {"SLACK_HOOK": "https://hooks.slack.com/services/xxx"}),
        patch("requests.get") as mock_get,
    ):
        mock_get.side_effect = requests.exceptions.RequestException("Test error")

        with patch("logging.error") as mock_log_error:
            result = slack.trigger_webhook()

            assert result is False
            mock_get.assert_called_once_with("https://hooks.slack.com/services/xxx", timeout=10)
            mock_log_error.assert_called_once()
