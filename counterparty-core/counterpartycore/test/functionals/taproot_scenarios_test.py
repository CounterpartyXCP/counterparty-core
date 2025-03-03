from counterpartycore.test.functionals.multisig_scenarios_test import check_standard_scenario


def test_taproot_scenario_1(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["p2tr_addresses"][0],
        defaults["addresses"][0],
        "6f488077d790fa369c53bccd1d09a548201fad6c56f48cf150f6c2f0e7062a01",
    )


def test_taproot_scenario_2(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["addresses"][0],
        defaults["p2tr_addresses"][0],
        "",
    )
