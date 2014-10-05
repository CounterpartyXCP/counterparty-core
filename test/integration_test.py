#! /usr/bin/python3
import pytest
import util_test

def test_scenario(scenario_name, transactions, getrawtransaction_db):
    if pytest.config.option.savescenarios:
        util_test.save_scenario(scenario_name, getrawtransaction_db)
    new_dump, new_log, new_raw_transactions = util_test.run_scenario(transactions, getrawtransaction_db)
    old_dump, old_log, old_raw_transactions = util_test.load_scenario_ouput(scenario_name)
    util_test.compare_strings(new_dump, old_dump)
    util_test.compare_strings(new_log, old_log)
    util_test.compare_strings(new_raw_transactions, old_raw_transactions)