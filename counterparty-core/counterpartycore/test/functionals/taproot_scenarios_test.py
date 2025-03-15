from counterpartycore.test.functionals.multisig_scenarios_test import check_standard_scenario


def test_taproot_scenario_1(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["p2tr_addresses"][0],
        defaults["addresses"][0],
        "69d117c318f6c2202548b655fda33567599e70d2660c72dca6d1db5e26967c5f",
    )


def test_taproot_scenario_2(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["addresses"][0],
        defaults["p2tr_addresses"][0],
        "13cb36258e94e0d375ea20cfb75110d351146bcec3daac6efd16919f4dd72727",
    )


def test_taproot_scenario_3(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["p2tr_addresses"][0],
        defaults["p2tr_addresses"][1],
        "da1769d1a8817c3fee91281cbc9eee5ce733681ceb70dd7fa45429ffa4ffc8ba",
    )
