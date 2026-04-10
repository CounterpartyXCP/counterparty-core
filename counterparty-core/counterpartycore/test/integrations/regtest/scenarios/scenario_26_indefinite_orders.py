SCENARIO = [
    {
        "title": "Place indefinite order (expiration=0)",
        "transaction": "order",
        "source": "$ADDRESS_2",
        "params": {
            "give_asset": "XCP",
            "give_quantity": 5000,
            "get_asset": "BTC",
            "get_quantity": 5000,
            "expiration": 0,
            "fee_required": 0,
        },
        "set_variables": {
            "INDEFINITE_ORDER_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=OPEN_ORDER,DEBIT",
                "result": [
                    {
                        "event": "OPEN_ORDER",
                        "event_index": "$EVENT_INDEX_4",
                        "params": {
                            "block_index": "$BLOCK_INDEX",
                            "expiration": 0,
                            "expire_index": None,
                            "fee_provided": 10000,
                            "fee_provided_remaining": 10000,
                            "fee_required": 0,
                            "fee_required_remaining": 0,
                            "get_asset": "BTC",
                            "get_quantity": 5000,
                            "get_remaining": 5000,
                            "give_asset": "XCP",
                            "give_quantity": 5000,
                            "give_remaining": 5000,
                            "source": "$ADDRESS_2",
                            "status": "open",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "action": "open order",
                            "address": "$ADDRESS_2",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "event": "$TX_HASH",
                            "quantity": 5000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            },
            {
                "url": "orders/$INDEFINITE_ORDER_HASH",
                "result": {
                    "status": "open",
                    "expiration": 0,
                    "expire_index": None,
                    "tx_hash": "$INDEFINITE_ORDER_HASH",
                },
            },
        ],
    },
    {
        "title": "Mine 50 blocks — indefinite order stays open",
        "transaction": "mine_blocks",
        "params": {
            "blocks": 50,
        },
        "controls": [
            {
                "url": "orders/$INDEFINITE_ORDER_HASH",
                "result": {
                    "status": "open",
                    "expiration": 0,
                    "expire_index": None,
                    "tx_hash": "$INDEFINITE_ORDER_HASH",
                },
            },
        ],
    },
    {
        "title": "Cancel the indefinite order",
        "transaction": "cancel",
        "source": "$ADDRESS_2",
        "params": {
            "offer_hash": "$INDEFINITE_ORDER_HASH",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=CANCEL_ORDER,ORDER_UPDATE,CREDIT",
                "result": [
                    {
                        "event": "CANCEL_ORDER",
                        "event_index": "$EVENT_INDEX_5",
                        "params": {
                            "block_index": "$BLOCK_INDEX",
                            "offer_hash": "$INDEFINITE_ORDER_HASH",
                            "source": "$ADDRESS_2",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_4",
                        "params": {
                            "address": "$ADDRESS_2",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "cancel order",
                            "event": "$INDEFINITE_ORDER_HASH",
                            "quantity": 5000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "ORDER_UPDATE",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "status": "cancelled",
                            "tx_hash": "$INDEFINITE_ORDER_HASH",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            },
            {
                "url": "orders/$INDEFINITE_ORDER_HASH",
                "result": {
                    "status": "cancelled",
                    "tx_hash": "$INDEFINITE_ORDER_HASH",
                },
            },
        ],
    },
]
