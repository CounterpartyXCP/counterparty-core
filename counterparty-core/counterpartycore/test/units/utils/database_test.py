import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.parser import check
from counterpartycore.lib.utils import database


def test_version(ledger_db, test_helpers):
    assert database.version(ledger_db) == (0, 0)

    database.update_version(ledger_db)
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "pragma",
                "field": "user_version",
                "value": (config.VERSION_MAJOR * 1000) + config.VERSION_MINOR,
            }
        ],
    )

    assert database.version(ledger_db) == (config.VERSION_MAJOR, config.VERSION_MINOR)

    check.database_version(ledger_db)

    config.VERSION_MAJOR += 1
    with pytest.raises(exceptions.VersionError) as exception:
        check.database_version(ledger_db)
    assert exception.value.from_block_index == config.BLOCK_FIRST
    assert exception.value.required_action == "rollback"
    config.VERSION_MAJOR -= 1
