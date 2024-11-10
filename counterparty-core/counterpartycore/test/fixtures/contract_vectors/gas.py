GAS_VECTOR = {
    "gas": {
        "get_transaction_count_for_last_period": [
            {
                "in": (101, 310507),
                "out": 0,
            }
        ],
        "increment_counter": [
            {
                "in": (101, 310507),  # attach.ID, 310507
                "records": [
                    {
                        "table": "transaction_count",
                        "values": {
                            "block_index": 310507,
                            "transaction_id": 101,
                            "count": 1,
                        },
                    }
                ],
            }
        ],
        "get_average_transactions": [
            {
                "in": (101, 310507),  # attach.ID, 310507
                "out": 0,
            }
        ],
    }
}
