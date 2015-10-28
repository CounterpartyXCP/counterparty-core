#! /usr/bin/python3
import tempfile
import pytest

import util_test
from util_test import CURR_DIR
import server
from counterpartylib.lib import (config, check, database)

def test_scenario(scenario_name, base_scenario_name, transactions, rawtransactions_db):
    """Run the integration tests.

    Reads scenario.py to get all the integration scenarios to create a holistic integration test run,
    executes it and then compares the json, sql and log output with data in 'scenarios/' folder.
    """
    if pytest.config.option.savescenarios:
        util_test.save_scenario(scenario_name, rawtransactions_db)

    new_dump, new_log, new_raw_transactions = util_test.run_scenario(transactions, rawtransactions_db)
    old_dump, old_log, old_raw_transactions = util_test.load_scenario_ouput(scenario_name)

    assert util_test.compare_strings(old_dump, new_dump) == 0
    assert util_test.compare_strings(old_log, new_log) == 0
    assert util_test.compare_strings(old_raw_transactions, new_raw_transactions) == 0

    if base_scenario_name and base_scenario_name != scenario_name:
        base_dump, base_log, base_raw_transactions = util_test.load_scenario_ouput(base_scenario_name)
        clean_new_dump = util_test.clean_scenario_dump(scenario_name, new_dump)
        clean_base_dump = util_test.clean_scenario_dump(base_scenario_name, base_dump)
        assert util_test.compare_strings(clean_base_dump, clean_new_dump) == 0

def test_book(testnet):
    """Reparse all the transactions in the database to see check blockhain's integrity."""
    util_test.reparse(testnet=testnet)

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

    config.VERSION_MAJOR += 1
    with pytest.raises(check.DatabaseVersionError) as exception:
        check.database_version(db)
    assert exception.value.reparse_block_index == config.BLOCK_FIRST
