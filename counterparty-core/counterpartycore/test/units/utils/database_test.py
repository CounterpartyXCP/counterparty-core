from counterpartycore.lib import config
from counterpartycore.lib.utils import database


def test_version(ledger_db, test_helpers):
    database.update_version(ledger_db)
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "config",
                "values": {
                    "name": "VERSION_STRING",
                    "value": config.VERSION_STRING,
                },
            }
        ],
    )
