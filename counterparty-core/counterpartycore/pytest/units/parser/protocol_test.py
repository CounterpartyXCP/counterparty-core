import pytest
from counterpartycore.lib import config
from counterpartycore.lib.parser import protocol
from counterpartycore.pytest.mocks.counterpartydbs import ProtocolChangesDisabled


def test_enabled():
    assert protocol.enabled("numeric_asset_names")

    config.REGTEST = False
    with pytest.raises(KeyError, match="foobar"):
        protocol.enabled("foobar")
    config.REGTEST = True

    with ProtocolChangesDisabled(["numeric_asset_names"]):
        assert not protocol.enabled("numeric_asset_names")
