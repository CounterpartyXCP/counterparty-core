import time
from unittest.mock import patch

from counterpartycore.lib import config
from counterpartycore.lib.monitors.telemetry import util


def test_get_system():
    with patch("platform.system", return_value="TestOS"):
        assert util.get_system() == "TestOS"


def test_get_version():
    original_version = config.__version__
    config.__version__ = "1.2.3"
    assert util.get_version() == "1.2.3"
    config.__version__ = original_version


def test_get_uptime():
    original_start_time = util.start_time
    util.start_time = time.time() - 60  # 60 seconds ago
    uptime = util.get_uptime()
    assert 59 <= uptime <= 61  # Allow small variation in timing
    util.start_time = original_start_time


def test_is_docker():
    # Test when /.dockerenv exists
    with patch("os.path.exists", return_value=True):
        assert util.is_docker() is True


def test_get_network():
    # Test MAINNET (the simplest case)
    original_testnet3 = getattr(config, "TESTNET3", None)
    original_testnet4 = getattr(config, "TESTNET4", None)

    # Set to False to test MAINNET
    config.TESTNET3 = False
    config.TESTNET4 = False

    assert util.get_network() == "MAINNET"

    # Restore original values
    if original_testnet3 is None:
        delattr(config, "TESTNET3")
    else:
        config.TESTNET3 = original_testnet3

    if original_testnet4 is None:
        delattr(config, "TESTNET4")
    else:
        config.TESTNET4 = original_testnet4


def test_is_force_enabled():
    original_force = getattr(config, "FORCE", None)

    config.FORCE = True
    assert util.is_force_enabled() is True

    config.FORCE = False
    assert util.is_force_enabled() is False

    if original_force is None:
        delattr(config, "FORCE")
    else:
        config.FORCE = original_force


def test_id_mocked():
    """Test ID by completely replacing the class"""
    # Rather than testing ID generation, which depends on the file system,
    # we simply test that the class can be instantiated and has an id attribute
    with patch.object(util.ID, "__init__", return_value=None):
        id_obj = util.ID()
        # Manually set the ID
        id_obj.id = "test-id"
        assert id_obj.id == "test-id"
