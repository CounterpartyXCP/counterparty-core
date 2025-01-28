from counterpartycore.lib.ledger import supplies


def test_supplies_functions(ledger_db):
    assert supplies.xcp_created(ledger_db) == 604514652382
    assert supplies.xcp_destroyed(ledger_db) == 700000000
    assert supplies.xcp_supply(ledger_db) == 603814652382
    assert supplies.destructions(ledger_db) == {"XCP": 700000000}
    assert supplies.asset_supply(ledger_db, "DIVISIBLE") == 100000000000

    assert supplies.creations(ledger_db) == {
        "XCP": 604514652382,
        "CALLABLE": 1000,
        "DIVIDEND": 100,
        "DIVISIBLE": 100000000000,
        "FREEFAIRMIN": 10,
        "LOCKED": 1000,
        "LOCKEDPREV": 1000,
        "MAXI": 9223372036854775807,
        "NODIVISIBLE": 1000,
        "PAIDFAIRMIN": 0,
        "PAYTOSCRIPT": 1000,
        "A95428959342453541": 100000000,
        "PARENT": 100000000,
        "QAIDFAIRMIN": 20,
        "RAIDFAIRMIN": 20,
        "TESTDISP": 1000,
        "A160361285792733729": 50,
    }

    assert supplies.supplies(ledger_db) == {
        "XCP": 603814652382,
        "A95428959342453541": 100000000,
        "CALLABLE": 1000,
        "DIVIDEND": 100,
        "DIVISIBLE": 100000000000,
        "FREEFAIRMIN": 10,
        "LOCKED": 1000,
        "LOCKEDPREV": 1000,
        "MAXI": 9223372036854775807,
        "NODIVISIBLE": 1000,
        "PAIDFAIRMIN": 0,
        "PARENT": 100000000,
        "PAYTOSCRIPT": 1000,
        "QAIDFAIRMIN": 20,
        "RAIDFAIRMIN": 20,
        "A160361285792733729": 50,
        "TESTDISP": 1000,
    }

    assert supplies.holders(ledger_db, "XCP") == [
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 91699999693,
            "escrow": None,
        },
        {
            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "address_quantity": 100000000,
            "escrow": None,
        },
        {
            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
            "address_quantity": 300000000,
            "escrow": None,
        },
        {
            "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM",
            "address_quantity": 92999974580,
            "escrow": None,
        },
        {
            "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
            "address_quantity": 92949974273,
            "escrow": None,
        },
        {
            "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            "address_quantity": 92949974167,
            "escrow": None,
        },
        {
            "address": "mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK",
            "address_quantity": 14999996,
            "escrow": None,
        },
        {
            "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
            "address_quantity": 46449986773,
            "escrow": None,
        },
        {
            "address": "bcrt1qfaw3f6ryl9jn4f5l0x7qdccxyl82snmwkrcfh9",
            "address_quantity": 92999971893,
            "escrow": None,
        },
        {
            "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
            "address_quantity": 3892761,
            "escrow": None,
        },
        {
            "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
            "address_quantity": 92945878046,
            "escrow": None,
        },
        {"address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef", "address_quantity": 0, "escrow": None},
        {
            "address": "55e839189f020ed270ff5152929cda11888966d927481c41faff90751f24c35b:0",
            "address_quantity": 100,
            "escrow": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "90b3fead6eea83f245478958aec0a4c81ecce20c9299a4a10b4cbd224dae2f7e",
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "271bab798ef940c345794396d7045bb0f544413fd20dca7bd4614e4fdaf35464",
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "c014d65c47a97cd2087715d6e3753502a93b5ce0f8b1de0401e1bee8f124494e",
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "2cac216cee2461f8fcd8269ec0299d1dfe7144694cbd32d68efd42ead74b1d89",
        },
        {"address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "address_quantity": 100, "escrow": None},
    ]

    assert supplies.holders(ledger_db, "DIVISIBLE") == [
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 98799999999,
            "escrow": None,
        },
        {
            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "address_quantity": 100000000,
            "escrow": None,
        },
        {
            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
            "address_quantity": 1000000000,
            "escrow": None,
        },
        {
            "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
            "address_quantity": 100000000,
            "escrow": None,
        },
        {
            "address": "1cd83080b97f818a5eba6af59dc85c7e222d5bddbb569f9313c55ab2c7527733:0",
            "address_quantity": 1,
            "escrow": None,
        },
    ]
