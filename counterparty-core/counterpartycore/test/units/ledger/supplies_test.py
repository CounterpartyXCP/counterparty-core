from counterpartycore.lib.ledger import supplies


def test_supplies_functions(ledger_db, defaults):
    assert supplies.xcp_created(ledger_db) == 604514652382
    assert supplies.xcp_destroyed(ledger_db) == 800000000
    assert supplies.xcp_supply(ledger_db) == 603714652382
    assert supplies.destructions(ledger_db) == {"XCP": 800000000}
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
        "SAIDFAIRMIN": 0,
        "TAIDFAIRMIN": 1,
        "TESTDISP": 1000,
        "A160361285792733729": 50,
    }

    assert supplies.supplies(ledger_db) == {
        "XCP": 603714652382,
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
        "SAIDFAIRMIN": 0,
        "TAIDFAIRMIN": 1,
        "A160361285792733729": 50,
        "TESTDISP": 1000,
    }

    assert supplies.holders(ledger_db, "XCP") == [
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 91599999693,
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
            "address": "659c929d79db6fc80112ea874655368279e73789f47a6f15ac696728a493cc18:0",
            "address_quantity": 100,
            "escrow": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "fdcd5ddf0834b1f6e7d7e4b95e923dd51a3ad4da5795c0f5f271a51fc3abb42e",
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "c468756975a0e57427849092f52be0ec30ea083d97121e1163a52a1575185b61",
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "dee16688ddbd3b664ef213fe9b7ee1fd11e01884455be214a3fc1a869db61827",
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "address_quantity": 100000000,
            "escrow": "fc504d4f75c1c0bd98618c6f59c99ba61dad9b6a88e7b0009f9bb42f3e7e6730",
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
            "address": "2771b620acbe6fa1319386dd64dc77c13f36c0d89f69b81e09c8b263f6ec4061:0",
            "address_quantity": 1,
            "escrow": None,
        },
    ]

    ledger_db.execute(
        """
        INSERT INTO destructions (asset, quantity, source, status) 
        VALUES ('foobar', 1000, ?, 'valid')
        """,
        (defaults["addresses"][0],),
    )
    assert len(supplies.destructions(ledger_db).keys()) == 2

    assert supplies.asset_issued_total_no_cache(ledger_db, "DIVISIBLE") == 100000000000

    assert supplies.asset_destroyed_total_no_cache(ledger_db, "foobar") == 1000

    assert supplies.held(ledger_db) == {
        "A160361285792733729": 50,
        "A95428959342453541": 100000000,
        "BTC": 1466667,
        "CALLABLE": 1000,
        "DIVIDEND": 100,
        "DIVISIBLE": 100000000000,
        "FREEFAIRMIN": 10,
        "LOCKED": 1000,
        "LOCKEDPREV": 1000,
        "MAXI": 9223372036854775807,
        "NODIVISIBLE": 1000,
        "PARENT": 100000000,
        "PAYTOSCRIPT": 1000,
        "QAIDFAIRMIN": 20,
        "RAIDFAIRMIN": 20,
        "TAIDFAIRMIN": 1,
        "TESTDISP": 1000,
        "XCP": 603714652382,
    }
