from counterpartycore.test.functionals.multisig_scenarios_test import check_standard_scenario


def test_p2sh_scenario_1(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["addresses"][0],
        defaults["p2sh_addresses"][0],
        "ee0c7f0249a0a5c4e89ef6a3d21c78ac744b66556390eef577d5f23b7e85a95a",
    )


def test_p2sh_scenario_2(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["p2sh_addresses"][0],
        defaults["addresses"][0],
        "30c27533c7fa68f60793cd472a33b89ea8363f32a7d3c14e28b6e43f0249896c",
    )


def test_p2sh_scenario_3(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["p2sh_addresses"][0],
        defaults["p2sh_addresses"][1],
        "65f18d6c2dcccf233a3c20719c766e05bdfdbc10ca8818006cf076f1368a4a22",
    )


def test_p2sh_scenario_4(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["p2sh_addresses"][0],
        defaults["p2tr_addresses"][0],
        "49481efecf705d45fca78fc950df39e165eaaf6d27f7ee3ddd4b0e07ac00d679",
    )


def test_p2sh_scenario_5(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["p2tr_addresses"][0],
        defaults["p2sh_addresses"][0],
        "c54754424db5d9bae72e705a7b7421c08eec192cfc901d257c82166ef52342bb",
    )
