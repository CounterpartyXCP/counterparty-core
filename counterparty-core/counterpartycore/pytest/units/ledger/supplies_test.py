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
            "address": "49a3ac93cda40086dddfbb475d5af316bc14cabf5b601df75a8ed1d8ab670863:0",
            "address_quantity": 100,
            "escrow": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "68be706b14efcf474c71b77ecea096feb277cff6a935dc6eee2193a15211296c",
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "e1baf7ed6c87c199d3ff8eb9004003f0f6481a1e50562b163c5008a4d75d377d",
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "cc3f4e8670ade33a5fd74cf5f77b1fed57706a814dec4cccee4acaa6a6aa5215",
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "9ebd2346395e6fcdd38b10c1cde7899e624a4fc93442a44b2c354d1d4b6d9f31",
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
            "address": "d03baad4d2942ea9d09bef3d21dfeb58ef44d7ce683d2aaba8ebaa46a8db3314:0",
            "address_quantity": 1,
            "escrow": None,
        },
    ]
