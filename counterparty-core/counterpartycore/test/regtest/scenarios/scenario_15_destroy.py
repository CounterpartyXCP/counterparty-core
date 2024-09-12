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
                "url": "blocks/188/events?event_name=ASSET_DESTRUCTION,DEBIT",
                "result": [
                    {
                        "event": "ASSET_DESTRUCTION",
                        "event_index": "$EVENT_INDEX_4",
                        "params": {
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "quantity": 1,
                            "source": "$ADDRESS_4",
                            "status": "valid",
                            "tag": "64657374726f79",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "action": "destroy",
                            "address": "$ADDRESS_4",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "event": "$TX_HASH",
                            "quantity": 1,
                            "tx_index": "$TX_INDEX",
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
