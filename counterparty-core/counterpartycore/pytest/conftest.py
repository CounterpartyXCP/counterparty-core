import pytest

from counterpartycore.lib.utils.helpers import to_short_json
from counterpartycore.pytest.mocks.counterpartydbs import check_records

from .mocks.bitcoind import bitcoind_mock, blockchain_mock, monkeymodule
from .mocks.counterpartydbs import addresses, build_dbs, current_block_index, ledger_db, state_db


class TestHelper:
    @staticmethod
    def to_short_json(data):
        return to_short_json(data)

    @staticmethod
    def check_records(ledger_db, records):
        return check_records(ledger_db, records)


@pytest.fixture
def test_helpers():
    return TestHelper


__all__ = [
    "bitcoind_mock",
    "ledger_db",
    "build_dbs",
    "monkeymodule",
    "state_db",
    "blockchain_mock",
    "current_block_index",
    "test_helpers",
    "addresses",
]
