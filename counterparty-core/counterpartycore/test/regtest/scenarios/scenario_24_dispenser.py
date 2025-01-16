SCENARIO = [
    {
        "title": "Create Dispenser XCP",
        "transaction": "dispenser",
        "source": "$ADDRESS_8",
        "params": {
            "asset": "XCP",
            "give_quantity": 1,
            "escrow_quantity": 10000,
            "mainchainrate": 1,  # 1 BTC for 1 XCP
            "status": 0,
        },
        "set_variables": {
            "DISPENSER_XCP_TX_HASH": "$TX_HASH",
            "DISPENSER_XCP_TX_INDEX": "$TX_INDEX",
            "DISPENSER_XCP_BLOCK_INDEX": "$BLOCK_INDEX",
        },
        "controls": [],
    },
    {
        "title": "Dispense with send: get 900 XCP",
        "transaction": "send",
        "source": "$ADDRESS_2",
        "params": {
            "destination": "$ADDRESS_8",
            "quantity": 6000,
            "asset": "BTC",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=DISPENSE",
                "result": [
                    {
                        "event": "DISPENSE",
                        "event_index": "$EVENT_INDEX_6",
                        "params": {
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "btc_amount": 6000,
                            "destination": "$ADDRESS_2",
                            "dispense_index": 0,
                            "dispense_quantity": 6000,
                            "dispenser_tx_hash": "$DISPENSER_XCP_TX_HASH",
                            "source": "$ADDRESS_8",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            }
        ],
    },
    {
        "title": "Dispense with send no_dispense: get 0 XCP",
        "transaction": "send",
        "source": "$ADDRESS_2",
        "params": {
            "destination": "$ADDRESS_1",
            "quantity": 3000,
            "asset": "BTC",
            "no_dispense": True,
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=DISPENSE",
                "result": [],
            }
        ],
    },
]
