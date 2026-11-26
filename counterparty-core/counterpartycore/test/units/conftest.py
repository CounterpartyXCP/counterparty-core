from counterpartycore.test.mocks.conftest import *  # noqa F403
from counterpartycore.lib.utils import protocolstatus
import pytest


@pytest.fixture(autouse=True)
def verified_protocol_metadata():
    """Unit tests use verified empty upgrade requirements unless explicitly overridden."""
    state = protocolstatus.ProtocolStatus()
    state.publish([])
    protocolstatus.configure(state)
    yield state
    protocolstatus.configure(None)
