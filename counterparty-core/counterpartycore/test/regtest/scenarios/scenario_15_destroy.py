SCENARIO = [
    {
        "title": "Destroy some XCP",
        "transaction": "destroy",
        "source": "$ADDRESS_4",
        "params": {
            "asset": "XCP",
            "quantity": 1,
            "tag": "destroy",
        },
        "set_variables": {
            "DESTROY_1_TX_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "blocks/188/events",
                "result": [
                    {
                        "event": "ASSET_DESTRUCTION",
                        "event_index": 499,
                        "params": {
                            "asset": "XCP",
                            "block_index": 188,
                            "quantity": 1,
                            "source": "$ADDRESS_4",
                            "status": "valid",
                            "tag": "64657374726f79",
                            "tx_hash": "$TX_HASH",
                            "tx_index": 54,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": 498,
                        "params": {
                            "action": "destroy",
                            "address": "$ADDRESS_4",
                            "asset": "XCP",
                            "block_index": 188,
                            "event": "$TX_HASH",
                            "quantity": 1,
                            "tx_index": 54,
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            }
        ],
    },
]
