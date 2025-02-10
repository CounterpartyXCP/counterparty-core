import os
import tempfile

from counterpartycore.lib import config
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import send
from counterpartycore.lib.messages.versions import send1
from counterpartycore.lib.parser import blocks


def test_parse_tx_simple(ledger_db, defaults, blockchain_mock, test_helpers):
    _source, _destination, data = send.compose(
        ledger_db, defaults["addresses"][0], defaults["addresses"][1], "XCP", 100
    )
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=data)
    blocks.parse_tx(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["addresses"][1],
                    "quantity": 100,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            }
        ],
    )


def test_parse_tx_multisig(ledger_db, defaults, blockchain_mock, test_helpers):
    _source, _destination, data = send1.compose(
        ledger_db, defaults["addresses"][0], defaults["p2ms_addresses"][0], "XCP", 100
    )
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], defaults["p2ms_addresses"][0], data=data
    )
    blocks.parse_tx(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["p2ms_addresses"][0],
                    "quantity": 100,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            }
        ],
    )


def test_check_database_version(ledger_db, test_helpers, caplog, monkeypatch):
    config.UPGRADE_ACTIONS["regtest"] = {
        "10.9.1": [
            ("refresh_state_db",),
            ("reparse", 100),
            ("rollback", 100),
            ("clear_not_supported_cache",),
        ],
    }

    block_first = config.BLOCK_FIRST
    config.BLOCK_FIRST = CurrentState().current_block_index()
    with test_helpers.capture_log(caplog, "New database detected. Updating database version."):
        blocks.check_database_version(ledger_db)
    config.BLOCK_FIRST = block_first

    config.FORCE = True
    with test_helpers.capture_log(caplog, "FORCE mode enabled. Skipping database version check."):
        blocks.check_database_version(ledger_db)
    config.FORCE = False

    version_string = config.VERSION_STRING
    ledger_db.execute("UPDATE config SET value = '9.0.0' WHERE name = 'VERSION_STRING'")
    config.VERSION_STRING = "9.0.0"
    with test_helpers.capture_log(caplog, "Ledger database is up to date."):
        blocks.check_database_version(ledger_db)

    config.VERSION_STRING = "10.9.1"

    def rollback_mock(db, block_index):
        blocks.logger.info("Rolling back to block %s", block_index)

    def reparse_mock(db, block_index):
        blocks.logger.info("Re-parsing from block %s", block_index)

    monkeypatch.setattr("counterpartycore.lib.parser.blocks.rollback", rollback_mock)
    monkeypatch.setattr("counterpartycore.lib.parser.blocks.reparse", reparse_mock)

    cache_dir = config.CACHE_DIR
    config.CACHE_DIR = tempfile.mkdtemp()
    not_supported_file = os.path.join(config.CACHE_DIR, "not_supported_tx_cache.regtest.txt")
    with open(not_supported_file, "w") as f:
        f.write("test")

    with test_helpers.capture_log(
        caplog,
        [
            "Required actions: [('refresh_state_db',), ('reparse', 100), ('rollback', 100), ('clear_not_supported_cache',)]",
            "Re-parsing from block 100",
            "Rolling back to block 100",
            "Database version number updated.",
        ],
    ):
        blocks.check_database_version(ledger_db)

    assert not os.path.exists(not_supported_file)

    config.VERSION_STRING = version_string
    config.CACHE_DIR = cache_dir
