from unittest.mock import Mock, patch

import pytest
from counterpartycore.lib.monitors.telemetry.oneshot import TelemetryOneShot


def test_telemetry_oneshot_init():
    """Test simply that the object can be instantiated"""
    # Avoid using autospec=True which causes problems
    with patch("logging.getLogger"):
        oneshot = TelemetryOneShot()
        assert isinstance(oneshot, TelemetryOneShot)


def test_telemetry_oneshot_send_basic():
    """Very basic test of the send method"""
    with patch("logging.getLogger"):
        # Create the instance first
        oneshot = TelemetryOneShot()

        # Then patch the send method of the instance (not of the class)
        with patch.object(oneshot.client, "send") as mock_send:
            # Test data with the __influxdb key
            test_data = {"test": "data", "__influxdb": {"tags": [], "fields": []}}

            oneshot.send(test_data)
            mock_send.assert_called_once_with(test_data)


def test_telemetry_oneshot_retry_logic():
    """Test the retry logic at the functional level"""
    with patch("logging.getLogger"):
        oneshot = TelemetryOneShot()

        # Instead of replacing the send method, patch the underlying client.send
        with patch.object(
            oneshot.client, "send", side_effect=[Exception("Test exception"), None]
        ) as mock_send:
            with patch("time.sleep"):  # Avoid waiting
                # Now, when send is called, it will trigger the retry mechanism
                # without us having to manually replace it
                oneshot.send({"__influxdb": {"tags": [], "fields": []}})

            # Verify that client.send was called twice
            assert mock_send.call_count == 2


def test_telemetry_oneshot_max_retries():
    """Test that the exception is raised after the maximum number of retries"""
    with patch("logging.getLogger"):
        oneshot = TelemetryOneShot()

        # We use a list of exceptions to simulate repeated failures
        exceptions = [Exception("Test exception") for _ in range(12)]

        # Patch the send method so that it always raises an exception
        with (
            patch.object(oneshot.client, "send", side_effect=exceptions),
            patch("time.sleep"),
        ):  # Avoid waiting
            # Verify that the exception is raised after max retries
            with pytest.raises(Exception):  # noqa
                oneshot.send({"__influxdb": {"tags": [], "fields": []}}, retry=10)


def test_telemetry_oneshot_submit_basic():
    """Basic test of the submit method"""
    # Rather than mocking the entire submit method, mock its components
    with (
        patch("counterpartycore.lib.utils.database.LedgerDBConnectionPool"),
        patch(
            "counterpartycore.lib.monitors.telemetry.collectors.influxdb.TelemetryCollectorInfluxDB"
        ),
        patch("logging.getLogger"),
    ):
        oneshot = TelemetryOneShot()

        # Patch the send method of the instance
        oneshot.send = Mock()

        # Call submit directly
        try:
            oneshot.submit()
            # If we get here without exception, it's a success
            assert True
        except Exception as e:
            pytest.fail(f"Unexpected exception: {e}")


def test_telemetry_oneshot_exception_handling():
    """Test that exceptions are properly handled in submit"""
    # Patch to simulate an exception in the database connection
    with patch("counterpartycore.lib.utils.database.LedgerDBConnectionPool") as mock_pool:
        # Create a mock instance that raises an exception when called
        mock_instance = Mock()
        mock_instance.connection.side_effect = Exception("Test exception")
        mock_pool.return_value = mock_instance

        # Other necessary patches
        with patch("logging.getLogger"), patch("sentry_sdk.capture_exception", return_value=None):
            oneshot = TelemetryOneShot()

            # The exception should be captured inside submit
            oneshot.submit()

            # If we get here without exception, it's a success
            assert True
