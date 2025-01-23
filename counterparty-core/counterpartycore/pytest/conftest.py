import logging
from contextlib import contextmanager

import pytest

from counterpartycore.lib import config
from counterpartycore.lib.utils.helpers import to_short_json
from counterpartycore.pytest.mocks.counterpartydbs import check_records

from .mocks.bitcoind import bitcoind_mock, blockchain_mock, monkeymodule
from .mocks.counterpartydbs import (
    build_dbs,
    current_block_index,
    defaults,
    ledger_db,
    state_db,
)


class TestHelper:
    @staticmethod
    def to_short_json(data):
        return to_short_json(data)

    @staticmethod
    def check_records(ledger_db, records):
        return check_records(ledger_db, records)

    @staticmethod
    @contextmanager
    def capture_log(caplog, message):
        logger = logging.getLogger(config.LOGGER_NAME)
        caplog.at_level(6, logger=config.LOGGER_NAME)
        logger.propagate = True
        yield
        logger.propagate = False
        assert message in caplog.text


@pytest.fixture
def test_helpers():
    return TestHelper


__all__ = [
    "bitcoind_mock",
    "blockchain_mock",
    "build_dbs",
    "current_block_index",
    "defaults",
    "ledger_db",
    "monkeymodule",
    "state_db",
    "test_helpers",
]
