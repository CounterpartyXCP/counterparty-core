SCENARIO = [
    {
        "title": "Send XCP no confirmation",
        "transaction": "send",
        "source": "$ADDRESS_4",
        "no_confirmation": True,
        "params": {
            "asset": "XCP",
            "quantity": 10000,
            "destination": "$ADDRESS_3",
        },
        "set_variables": {
            "SEND_MEMPOOL_1_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "mempool/events?event_name=ENHANCED_SEND,CREDIT,DEBIT",
                "retry": True,
                "result": [
                    {
                        "event": "ENHANCED_SEND",
                        "params": {
                            "asset": "XCP",
                            "block_index": 9999999,
                            "destination": "$ADDRESS_3",
                            "memo": None,
                            "quantity": 10000,
                            "source": "$ADDRESS_4",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "CREDIT",
                        "params": {
                            "address": "$ADDRESS_3",
                            "asset": "XCP",
                            "block_index": 188,
                            "calling_function": "send",
                            "event": "$TX_HASH",
                            "quantity": 10000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "params": {
                            "action": "send",
                            "address": "$ADDRESS_4",
                            "asset": "XCP",
                            "block_index": 188,
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
