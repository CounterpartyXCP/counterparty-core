SCENARIO = [
    {
        "title": "Create Dispenser 3",
        "transaction": "dispenser",
        "source": "$ADDRESS_4",
        "params": {
            "asset": "XCP",
            "give_quantity": 1,
            "escrow_quantity": 10000,
            "mainchainrate": 1,  # 1 BTC for 1 XCP
            "status": 0,
        },
        "set_variables": {
            "DISPENSER_3_TX_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "blocks/187/events?event_name=OPEN_DISPENSER,DEBIT",
                "result": [
                    {
                        "event": "OPEN_DISPENSER",
                        "event_index": "$EVENT_INDEX_4",
                        "params": {
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "dispense_count": 0,
                            "escrow_quantity": 10000,
                            "give_quantity": 1,
                            "give_remaining": 10000,
                            "oracle_address": None,
                            "origin": "$ADDRESS_4",
                            "satoshirate": 1,
                            "source": "$ADDRESS_4",
                            "status": 0,
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "action": "open dispenser",
                            "address": "$ADDRESS_4",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "event": "$TX_HASH",
                            "quantity": 10000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            },
        ],
    },
]
