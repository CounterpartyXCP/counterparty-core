import os
from unittest.mock import Mock, patch

import pytest
from counterpartycore.lib import config


@pytest.fixture(autouse=True)
def mock_logger():
    """Fixture to mock logger for all tests"""
    with patch("logging.getLogger") as mock_get_logger:
        mock_logger = Mock()
        mock_get_logger.return_value = mock_logger
        yield mock_logger


@pytest.fixture
def mock_db():
    """Fixture to create a mock database connection"""
    mock_db = Mock()
    mock_cursor = Mock()
    mock_db.cursor.return_value = mock_cursor
    return mock_db


@pytest.fixture
def mock_collector():
    """Fixture to create a mock telemetry collector"""
    collector = Mock()
    collector.collect.return_value = {"test": "data"}
    collector.close.return_value = None
    return collector


@pytest.fixture
def mock_client():
    """Fixture to create a mock telemetry client"""
    client = Mock()
    client.send.return_value = None
    return client


@pytest.fixture(autouse=True)
def clean_environment():
    """Fixture to clean environment variables before and after tests"""
    # Save original environment
    original_env = os.environ.copy()

    # Clean specific environment variables
    for key in [
        "SENTRY_DSN",
        "SENTRY_ENVIRONMENT",
        "SENTRY_RELEASE",
        "SENTRY_SAMPLE_RATE",
        "SLACK_HOOK",
        "DOCKER_HOST",
        "KUBERNETES_SERVICE_HOST",
    ]:
        if key in os.environ:
            del os.environ[key]

    yield

    # Restore original environment
    os.environ.clear()
    os.environ.update(original_env)


@pytest.fixture(autouse=True)
def reset_config_attributes():
    """Fixture to reset any modified config attributes"""
    # Save original attributes
    original_attrs = {}
    for attr in [
        "TESTNET3",
        "TESTNET4",
        "FORCE",
        "INFLUX_DB_URL",
        "INFLUX_DB_TOKEN",
        "INFLUX_DB_ORG",
        "INFLUX_DB_BUCKET",
        "LOGGER_NAME",
        "XCP_NAME",
        "APP_NAME",
    ]:
        if hasattr(config, attr):
            original_attrs[attr] = getattr(config, attr)

    yield

    # Restore original attributes
    for attr, value in original_attrs.items():
        setattr(config, attr, value)
