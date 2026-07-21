import pytest
from counterpartycore.lib import config
from counterpartycore.lib.parser import protocol
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_enabled():
    assert protocol.enabled("numeric_asset_names")

    config.REGTEST = False
    with pytest.raises(KeyError, match="foobar"):
        protocol.enabled("foobar")
    config.REGTEST = True

    with ProtocolChangesDisabled(["numeric_asset_names"]):
        assert not protocol.enabled("numeric_asset_names")

    config.ENABLE_ALL_PROTOCOL_CHANGES = True
    assert protocol.enabled("barbaz")
    config.ENABLE_ALL_PROTOCOL_CHANGES = False


def test_enabled_on_different_networks():
    """Test enabled() with different network configurations."""
    # Save original values
    original_regtest = config.REGTEST
    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_signet = config.SIGNET

    try:
        # Test with TESTNET3
        config.REGTEST = False
        config.TESTNET3 = True
        config.TESTNET4 = False
        config.SIGNET = False
        # This should use testnet3_block_index
        result = protocol.enabled("numeric_asset_names", block_index=999999999)
        assert result is True

        # Test with TESTNET4
        config.TESTNET3 = False
        config.TESTNET4 = True
        result = protocol.enabled("numeric_asset_names", block_index=999999999)
        assert result is True

        # Test with SIGNET
        config.TESTNET4 = False
        config.SIGNET = True
        result = protocol.enabled("numeric_asset_names", block_index=999999999)
        assert result is True

        # Test with mainnet
        config.SIGNET = False
        result = protocol.enabled("numeric_asset_names", block_index=999999999)
        assert result is True

        # Test with block_index below the threshold (mainnet)
        result = protocol.enabled("numeric_asset_names", block_index=0)
        assert result is False

    finally:
        # Restore original values
        config.REGTEST = original_regtest
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.SIGNET = original_signet


def test_get_change_block_index():
    """Test get_change_block_index() function."""
    # Save original values
    original_regtest = config.REGTEST
    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_signet = config.SIGNET

    try:
        # Test with REGTEST - should always return 0
        config.REGTEST = True
        config.TESTNET3 = False
        config.TESTNET4 = False
        config.SIGNET = False
        assert protocol.get_change_block_index("numeric_asset_names") == 0

        # Test with TESTNET3
        config.REGTEST = False
        config.TESTNET3 = True
        result = protocol.get_change_block_index("numeric_asset_names")
        assert isinstance(result, int)

        # Test with TESTNET4
        config.TESTNET3 = False
        config.TESTNET4 = True
        result = protocol.get_change_block_index("numeric_asset_names")
        assert isinstance(result, int)

        # Test with SIGNET
        config.TESTNET4 = False
        config.SIGNET = True
        result = protocol.get_change_block_index("numeric_asset_names")
        assert isinstance(result, int)

        # Test with mainnet
        config.SIGNET = False
        result = protocol.get_change_block_index("numeric_asset_names")
        assert isinstance(result, int)
        assert result > 0

    finally:
        # Restore original values
        config.REGTEST = original_regtest
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.SIGNET = original_signet


def test_get_value_by_block_index(ledger_db, current_block_index):
    """Test get_value_by_block_index() function."""
    # Save original values
    original_regtest = config.REGTEST
    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_signet = config.SIGNET

    try:
        # Test with REGTEST
        config.REGTEST = True
        config.TESTNET3 = False
        config.TESTNET4 = False
        config.SIGNET = False
        result = protocol.get_value_by_block_index("max_dispenses_limit", block_index=900000)
        assert result == 1000

        # Test with mainnet at high block index
        config.REGTEST = False
        result = protocol.get_value_by_block_index("max_dispenses_limit", block_index=900000)
        assert result == 1000

        # Test with mainnet at low block index
        result = protocol.get_value_by_block_index("max_dispenses_limit", block_index=1)
        assert result == 0

        # Test with TESTNET3 at high block index (2535092 is the threshold)
        config.TESTNET3 = True
        result = protocol.get_value_by_block_index("max_dispenses_limit", block_index=3000000)
        assert result == 1000

        # Test with TESTNET3 at low block index
        result = protocol.get_value_by_block_index("max_dispenses_limit", block_index=1)
        assert result == 0

        # Test with TESTNET4
        config.TESTNET3 = False
        config.TESTNET4 = True
        result = protocol.get_value_by_block_index("max_dispenses_limit", block_index=1)
        assert result == 1000

        # Test with SIGNET
        config.TESTNET4 = False
        config.SIGNET = True
        result = protocol.get_value_by_block_index("max_dispenses_limit", block_index=1)
        assert result == 1000

        # Test with block_index = None (uses CurrentState)
        config.SIGNET = False
        config.REGTEST = True
        result = protocol.get_value_by_block_index("max_dispenses_limit")
        assert result == 1000

        # Test with block_index = 0 (should use high number)
        result = protocol.get_value_by_block_index("max_dispenses_limit", block_index=0)
        assert result == 1000

    finally:
        # Restore original values
        config.REGTEST = original_regtest
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.SIGNET = original_signet


def test_is_test_network():
    """Test is_test_network() function."""
    # Save original values
    original_regtest = config.REGTEST
    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_signet = config.SIGNET

    try:
        # Test with all false (mainnet)
        config.REGTEST = False
        config.TESTNET3 = False
        config.TESTNET4 = False
        config.SIGNET = False
        assert protocol.is_test_network() is False

        # Test with REGTEST
        config.REGTEST = True
        assert protocol.is_test_network() is True
        config.REGTEST = False

        # Test with TESTNET3
        config.TESTNET3 = True
        assert protocol.is_test_network() is True
        config.TESTNET3 = False

        # Test with TESTNET4
        config.TESTNET4 = True
        assert protocol.is_test_network() is True
        config.TESTNET4 = False

        # Test with SIGNET
        config.SIGNET = True
        assert protocol.is_test_network() is True

    finally:
        # Restore original values
        config.REGTEST = original_regtest
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.SIGNET = original_signet


def test_after_block_or_test_network():
    """Test after_block_or_test_network() function."""
    # Save original values
    original_regtest = config.REGTEST
    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_signet = config.SIGNET

    try:
        # Test on mainnet (not test network)
        config.REGTEST = False
        config.TESTNET3 = False
        config.TESTNET4 = False
        config.SIGNET = False

        # After target block
        assert protocol.after_block_or_test_network(1000, 500) is True
        # Before target block
        assert protocol.after_block_or_test_network(100, 500) is False
        # Equal to target block
        assert protocol.after_block_or_test_network(500, 500) is True

        # Test on test network (should always return True)
        config.REGTEST = True
        assert protocol.after_block_or_test_network(100, 500) is True
        assert protocol.after_block_or_test_network(1000, 500) is True

    finally:
        # Restore original values
        config.REGTEST = original_regtest
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.SIGNET = original_signet
