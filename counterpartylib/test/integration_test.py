#! /usr/bin/python3
import pytest

from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test import util_test


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
