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
