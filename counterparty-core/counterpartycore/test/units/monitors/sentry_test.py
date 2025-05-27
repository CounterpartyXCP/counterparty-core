import os
from unittest import mock

import pytest
from counterpartycore.lib import config
from counterpartycore.lib.monitors import sentry


@pytest.fixture
def reset_environment():
    """Reset environment variables after each test."""
    original_environ = os.environ.copy()
    yield
    os.environ.clear()
    os.environ.update(original_environ)


@pytest.fixture
def mock_sentry_sdk():
    with mock.patch("sentry_sdk.init") as mock_init:
        yield mock_init


@pytest.fixture
def mock_logger():
    # Using patch.object to directly patch the logger instance referenced in the sentry module
    with mock.patch.object(sentry.logger, "info") as mock_info:
        yield mock_info


@pytest.fixture
def mock_db_connection():
    mock_db = mock.MagicMock()
    # Configure the cursor and execute methods to avoid database errors
    mock_cursor = mock.MagicMock()
    mock_db.cursor.return_value = mock_cursor
    mock_cursor.execute.return_value = []

    with mock.patch("counterpartycore.lib.utils.database.get_connection", return_value=mock_db):
        yield mock_db


@pytest.fixture
def mock_ledger_last_message():
    # Mock the last_message function to return a dict with block_index
    mock_message = {"block_index": 123456}
    with mock.patch("counterpartycore.lib.ledger.events.last_message", return_value=mock_message):
        yield mock_message


@pytest.fixture
def mock_telemetry_collector():
    """Create a mock for the telemetry collector and bypass the actual collect method."""
    telemetry_data = {
        "version": "1.0.0",
        "dockerized": True,
        "network": "mainnet",
        "force_enabled": False,
        "last_block": 123456,
    }

    # Instead of mocking the class, mock the collect method directly
    with mock.patch(
        "counterpartycore.lib.monitors.telemetry.collectors.base.TelemetryCollectorBase.collect",
        return_value=telemetry_data,
    ):
        yield telemetry_data


class TestSentryInit:
    def test_init_no_dsn(self, reset_environment, mock_sentry_sdk):
        """Test that init() does nothing when SENTRY_DSN is not defined."""
        if "SENTRY_DSN" in os.environ:
            del os.environ["SENTRY_DSN"]

        sentry.init()
        mock_sentry_sdk.assert_not_called()

    def test_init_with_dsn(self, reset_environment, mock_sentry_sdk, mock_logger):
        """Test init() with SENTRY_DSN defined."""
        os.environ["SENTRY_DSN"] = "https://1234@sentry.io/1234"

        sentry.init()

        mock_sentry_sdk.assert_called_once()
        mock_logger.assert_called_once_with(
            "Initializing Sentry with %s and sample rate of %s...",
            "https://1234@sentry.io/1234",
            0.01,
        )

        # Verify default arguments
        call_args = mock_sentry_sdk.call_args[1]
        assert call_args["dsn"] == "https://1234@sentry.io/1234"
        assert call_args["environment"] == sentry.environment
        assert call_args["release"] == sentry.release
        assert call_args["traces_sample_rate"] == 0.01  # default value
        assert call_args["before_send"] == sentry.before_send
        assert call_args["before_send_transaction"] == sentry.before_send_transaction

    def test_init_with_custom_sample_rate(self, reset_environment, mock_sentry_sdk, mock_logger):
        """Test init() with a custom sample rate."""
        os.environ["SENTRY_DSN"] = "https://1234@sentry.io/1234"
        os.environ["SENTRY_SAMPLE_RATE"] = "0.5"

        sentry.init()

        call_args = mock_sentry_sdk.call_args[1]
        assert call_args["traces_sample_rate"] == 0.5
        mock_logger.assert_called_once_with(
            "Initializing Sentry with %s and sample rate of %s...",
            "https://1234@sentry.io/1234",
            0.5,
        )


class TestBeforeSend:
    def test_before_send_adds_tags_and_extra(
        self, mock_db_connection, mock_ledger_last_message, mock_telemetry_collector
    ):
        """Test that before_send() correctly adds tags and extras."""
        # Case: empty event
        empty_event = {}
        result = sentry.before_send(empty_event, None)

        # Verify that the database connection was closed
        mock_db_connection.close.assert_called_once()

        # Verify that tags were added
        assert ["core_version", "1.0.0"] in result["tags"]
        assert ["docker", True] in result["tags"]
        assert ["network", "mainnet"] in result["tags"]
        assert ["force_enabled", False] in result["tags"]

        # Verify that extra was added
        assert result["extra"]["last_block"] == 123456

    def test_before_send_with_existing_tags(
        self, mock_db_connection, mock_ledger_last_message, mock_telemetry_collector
    ):
        """Test that before_send() preserves existing tags."""
        event = {"tags": [["existing_tag", "value"]]}
        result = sentry.before_send(event, None)

        # Verify that existing tags are preserved
        assert ["existing_tag", "value"] in result["tags"]
        # And that new tags are added
        assert ["core_version", "1.0.0"] in result["tags"]

    def test_before_send_with_existing_extra(
        self, mock_db_connection, mock_ledger_last_message, mock_telemetry_collector
    ):
        """Test that before_send() preserves existing extras."""
        event = {"extra": {"existing_extra": "value"}}
        result = sentry.before_send(event, None)

        # Verify that existing extras are preserved
        assert result["extra"]["existing_extra"] == "value"
        # And that new extras are added
        assert result["extra"]["last_block"] == 123456


class TestBeforeSendTransaction:
    def test_before_send_transaction_with_normal_transaction(self):
        """Test that before_send_transaction() lets normal transactions pass through."""
        event = {"transaction": "NormalTransaction"}
        result = sentry.before_send_transaction(event, None)
        assert result == event  # Event should pass unchanged

    def test_before_send_transaction_with_redirect(self):
        """Test that before_send_transaction() filters RedirectToRpcV1."""
        event = {"transaction": "RedirectToRpcV1"}
        result = sentry.before_send_transaction(event, None)
        assert result is None  # Event should be filtered out

    def test_before_send_transaction_without_transaction(self):
        """Test that before_send_transaction() handles the case without a transaction."""
        event = {}  # No transaction
        result = sentry.before_send_transaction(event, None)
        assert result == event  # Event should pass unchanged


class TestEnvironmentVariables:
    def test_environment_default(self, reset_environment):
        """Test the default value of environment."""
        # Check the default value
        if "SENTRY_ENVIRONMENT" in os.environ:
            del os.environ["SENTRY_ENVIRONMENT"]

        # Reimport to test global variables
        import importlib

        importlib.reload(sentry)

        assert sentry.environment == "development"

    def test_environment_custom(self, reset_environment):
        """Test environment with a custom value."""
        os.environ["SENTRY_ENVIRONMENT"] = "production"

        # Reimport to test global variables
        import importlib

        importlib.reload(sentry)

        assert sentry.environment == "production"

    def test_release_default(self, reset_environment):
        """Test the default value of release."""
        if "SENTRY_RELEASE" in os.environ:
            del os.environ["SENTRY_RELEASE"]

        # Store the original value
        original_version = config.__version__
        try:
            # Set a test version
            config.__version__ = "test_version"

            # Reimport to test global variables
            import importlib

            importlib.reload(sentry)

            assert sentry.release == "test_version"
        finally:
            # Restore the original value
            config.__version__ = original_version

    def test_release_custom(self, reset_environment):
        """Test release with a custom value."""
        os.environ["SENTRY_RELEASE"] = "custom_version"

        # Reimport to test global variables
        import importlib

        importlib.reload(sentry)

        assert sentry.release == "custom_version"
