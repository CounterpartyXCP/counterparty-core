from counterpartycore.lib.messages import gas


def test_get_transaction_count_for_last_period(ledger_db):
    # attach.ID, 310507
    assert gas.get_transaction_count_for_last_period(ledger_db, 101, 310507) == 0


def test_increment_counter(ledger_db, test_helpers):
    gas.increment_counter(ledger_db, 101, 310507)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "transaction_count",
                "values": {
                    "block_index": 310507,
                    "transaction_id": 101,
                    "count": 1,
                },
            }
        ],
    )


def test_get_average_transactions(ledger_db):
    # attach.ID, 310507
    assert gas.get_average_transactions(ledger_db, 101, 310507) == 0
