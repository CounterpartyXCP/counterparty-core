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
        "73bf8f3dfb2290285989b721876cbe40beadff7bff5116e3200b7cf9fb9afc55",
    )


def test_p2sh_scenario_5(empty_ledger_db, bitcoind_mock, defaults):
    check_standard_scenario(
        empty_ledger_db,
        bitcoind_mock,
        defaults,
        defaults["p2tr_addresses"][0],
        defaults["p2sh_addresses"][0],
        "d2bfeca5ce081a015353a9f9537e643f5480db6f23ce809dee1fb944049487c0",
    )
