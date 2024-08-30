GAS_VECTOR = {
    "gas": {
        "get_transaction_count_for_last_period": [
            {
                "in": (100, 154),  # utxo.ID, 310507 // 2016
                "out": 2,
            }
        ],
        "increment_counter": [
            {
                "in": (100, 310507),  # utxo.ID, 310507
                "records": [
                    {
                        "table": "transaction_count",
                        "values": {
                            "block_index": 310507,
                            "transaction_id": 100,
                            "count": 3,
                        },
                    }
                ],
            }
        ],
        "get_average_transactions": [
            {
                "in": (100, 310507),  # utxo.ID, 310507
                "out": 0,
            }
        ],
    }
}
