import pytest
from counterpartycore.lib import config
from counterpartycore.lib.parser import protocol
from counterpartycore.lib.utils import multisig
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


def test_prepare_address_for_consensus_hash(monkeypatch):
    """Test various scenarios for prepare_address_for_consensus_hash function"""

    # Test case 1: Address is None
    # Should return the string 'None' truncated to 36 chars
    result = protocol.prepare_address_for_consensus_hash(None)
    assert result == "None"

    # Test case 2: Regular address (not multisig)
    monkeypatch.setattr(multisig, "is_multisig", lambda x: False)
    address = "1A2B3C4D5E6F7G8H9I0J"
    result = protocol.prepare_address_for_consensus_hash(address)
    assert result == address

    # Test case 3: Long address (not multisig) - should be truncated
    monkeypatch.setattr(multisig, "is_multisig", lambda x: False)
    long_address = "A" * 50  # 50 character address
    result = protocol.prepare_address_for_consensus_hash(long_address)
    assert result == "A" * 36
    assert len(result) == 36

    # Test case 4: Multisig address, truncate_multisig_address not enabled
    monkeypatch.setattr(multisig, "is_multisig", lambda x: True)
    monkeypatch.setattr(protocol, "enabled", lambda x: False)
    multisig_address = "2MultiSigAddressExample12345678901234567890"
    result = protocol.prepare_address_for_consensus_hash(multisig_address)
    assert result == multisig_address  # Should return the full address

    # Test case 5: Multisig address, truncate_multisig_address enabled
    monkeypatch.setattr(multisig, "is_multisig", lambda x: True)
    monkeypatch.setattr(protocol, "enabled", lambda x: True)
    multisig_address = "2MultiSigAddressExample12345678901234567890"
    result = protocol.prepare_address_for_consensus_hash(multisig_address)
    assert result == multisig_address[:36]  # Should return truncated address
    assert len(result) == 36

    # Test case 6: Non-string address (like an integer)
    monkeypatch.setattr(multisig, "is_multisig", lambda x: False)
    address = 12345
    result = protocol.prepare_address_for_consensus_hash(address)
    assert result == "12345"  # Should convert to string


def test_isolated_cases(monkeypatch):
    """Test each branch of the function in isolation"""

    # Case 1: All conditions true
    # address is not None, is_multisig returns True, enabled returns False
    monkeypatch.setattr(multisig, "is_multisig", lambda x: True)
    monkeypatch.setattr(protocol, "enabled", lambda x: False)
    address = "MultisigAddress"
    result = protocol.prepare_address_for_consensus_hash(address)
    assert result == address

    # Case 2: address is None
    # First condition fails, should truncate
    result = protocol.prepare_address_for_consensus_hash(None)
    assert result == "None"

    # Case 3: is_multisig returns False
    # Second condition fails, should truncate
    monkeypatch.setattr(multisig, "is_multisig", lambda x: False)
    monkeypatch.setattr(protocol, "enabled", lambda x: False)
    address = "RegularAddress"
    result = protocol.prepare_address_for_consensus_hash(address)
    assert result == address[:36]

    # Case 4: enabled returns True
    # Third condition fails, should truncate
    monkeypatch.setattr(multisig, "is_multisig", lambda x: True)
    monkeypatch.setattr(protocol, "enabled", lambda x: True)
    address = "MultisigAddress"
    result = protocol.prepare_address_for_consensus_hash(address)
    assert result == address[:36]
