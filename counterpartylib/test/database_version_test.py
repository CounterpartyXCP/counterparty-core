#! /usr/bin/python3
import tempfile
import pytest

from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib import server
from counterpartylib.lib import (config, check, database)


def test_check_database_version():
    server.initialise(database_file=tempfile.gettempdir() + '/fixtures.unittest.db', testnet=True, **util_test.COUNTERPARTYD_OPTIONS)
    util_test.restore_database(config.DATABASE, CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql')
    db = database.get_connection(read_only=False)
    database.update_version(db)

    version_major, version_minor = database.version(db)
    assert config.VERSION_MAJOR == version_major
    assert config.VERSION_MINOR == version_minor

    check.database_version(db)

    config.VERSION_MINOR += 1
    with pytest.raises(check.DatabaseVersionError) as exception:
        check.database_version(db)
    assert exception.value.reparse_block_index == None
    config.VERSION_MINOR -= 1

    config.VERSION_MAJOR += 1
    with pytest.raises(check.DatabaseVersionError) as exception:
        check.database_version(db)
    assert exception.value.reparse_block_index == config.BLOCK_FIRST
    config.VERSION_MAJOR -= 1
