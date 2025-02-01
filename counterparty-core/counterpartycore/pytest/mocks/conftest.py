import logging
from contextlib import contextmanager

import pytest
from counterpartycore.lib import config
from counterpartycore.lib.utils.helpers import to_short_json
from counterpartycore.pytest.mocks.apis import apiv1_app, apiv1_client, apiv2_app, apiv2_client
from counterpartycore.pytest.mocks.bitcoind import bitcoind_mock, blockchain_mock, monkeymodule
from counterpartycore.pytest.mocks.counterpartydbs import (
    build_dbs,
    check_records,
    current_block_index,
    defaults,
    empty_ledger_db,
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
    "apiv1_app",
    "apiv2_app",
    "apiv2_client",
    "apiv1_client",
    "bitcoind_mock",
    "blockchain_mock",
    "build_dbs",
    "current_block_index",
    "defaults",
    "ledger_db",
    "monkeymodule",
    "state_db",
    "test_helpers",
    "empty_ledger_db",
]
