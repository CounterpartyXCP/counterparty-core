# Below are the available fixtures for test files located
# in the `units` and `functionals` folders. All fixtures can be
# used in a standard way with pytest, meaning they can simply be
# passed as parameters to test functions without needing to import them.
#
# - ledger_db
# `ledger_db` is an apsw connection to the SQLite database of Counterparty.
# This database is pre-filled with the test scenario found in
# `/fixtures/ledgerdb.py`. If you need to modify the content of the test database,
# you can do so in this file.
# This database is reset before each test.
#
# - state_db
# `state_db` is an apsw connection to the State DB of Counterparty. It is also
# pre-filled with the test scenario found in `/fixtures/ledgerdb.py`.
#
# - empty_ledger_db
# `empty_ledger_db` is an apsw connection to an empty SQLite database.
# It can be used to test scenarios where the database is empty.
#
# - apiv1_client
# `apiv1_client` is an RPC client for Counterparty's v1 API. To use it,
# simply call the methods of the v1 API. For example:
# ```
# result = apiv1_client(
#        "create_burn",
#        {
#            "source": defaults["addresses"][1],
#            "quantity": defaults["burn_quantity"],
#            "encoding": "multisig",
#        },
#    ).json
# ```
#
# - apiv2_client
# `apiv2_client` is an HTTP client for Counterparty's v2 API. To use it,
# simply call the methods of the v2 API. For example:
# ```
# response = apiv2_client.get("/v2").json
# ```
#
# - defaults
# `defaults` is a dictionary containing default values for tests.
# It contains addresses, assets, quantities, etc.
# For example, `defaults["addresses"][0]` is the first standard address in the list.
# Default values can be modified in `/fixtures/defaults.py`.
#
# - current_block_index
# `current_block_index` is a fixture that returns the index of the last mined block in the
# `ledger_db` database.
#
# - blockchain_mock
# `blockchain_mock` primarily allows constructing a fake transaction to pass to
# the `*.parse` methods. For example:
# ```
# tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
# dividend.parse(
#        ledger_db,
#        tx,
#        b"\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01",
#    )
# ```
#
# - test_helpers
# `test_helpers` is a class that contains utility methods for tests.
# `test_helpers.to_short_json` allows converting an object to short JSON.
# `test_helpers.check_records` allows checking if records exist in the database.
# `test_helpers.capture_log` allows capturing and verifying the logs of a method.
#
# - ProtocolChangesDisabled
# `ProtocolChangesDisabled` is a context manager that temporarily disables
# protocol changes. For example:
# ```
# with ProtocolChangesDisabled(["short_tx_type_id"]):
#     assert messagetype.pack(0, 300000) == binascii.unhexlify("00000000")
# ```

import logging
from contextlib import contextmanager

import pytest
from counterpartycore.lib import config
from counterpartycore.lib.utils.helpers import to_short_json
from counterpartycore.test.mocks.apis import apiv1_app, apiv1_client, apiv2_app, apiv2_client
from counterpartycore.test.mocks.bitcoind import bitcoind_mock, blockchain_mock, monkeymodule
from counterpartycore.test.mocks.counterpartydbs import (
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
        if isinstance(message, list):
            for m in message:
                assert m in caplog.text
        else:
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
