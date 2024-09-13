SCENARIO = [
    {
        "title": "Broadcast something",
        "transaction": "broadcast",
        "source": "$ADDRESS_1",
        "params": {
            "timestamp": 4003903983,
            "value": 999,
            "fee_fraction": 0.0,
            "text": "Hello, world!",
        },
        "set_variables": {
            "BROADCAST_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=BROADCAST",
                "result": [
                    {
                        "event": "BROADCAST",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "block_index": "$BLOCK_INDEX",
                            "fee_fraction_int": 0,
                            "locked": False,
                            "source": "$ADDRESS_1",
                            "status": "valid",
                            "text": "Hello, world!",
                            "timestamp": 4003903983,
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                            "value": 999.0,
                        },
                        "tx_hash": "$TX_HASH",
                    }
                ],
            },
        ],
    },
    {
        "title": "Broadcast dispenser price",
        "transaction": "broadcast",
        "source": "$ADDRESS_6",
        "params": {
            "timestamp": 4003903983,
            "value": 66600,
            "fee_fraction": 0.0,
            "text": "price-USD",
        },
        "set_variables": {
            "BROADCAST_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=BROADCAST",
                "result": [
                    {
                        "event": "BROADCAST",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "block_index": "$BLOCK_INDEX",
                            "fee_fraction_int": 0,
                            "locked": False,
                            "source": "$ADDRESS_6",
                            "status": "valid",
                            "text": "price-USD",
                            "timestamp": 4003903983,
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                            "value": 66600.0,
                        },
                        "tx_hash": "$TX_HASH",
                    }
                ],
            },
        ],
    },
]
