SCENARIO = [
    {
        "title": "Open Sell XCP for BTC order",
        "transaction": "order",
        "source": "$ADDRESS_1",
        "params": {
            "give_asset": "XCP",
            "give_quantity": 1000,
            "get_asset": "BTC",
            "get_quantity": 1000,
            "expiration": 21,
            "fee_required": 0,
        },
        "set_variables": {
            "ORDER_1_HASH": "$TX_HASH",
            "ORDER_1_TX_INDEX": "$TX_INDEX",
            "ORDER_1_BLOCK_INDEX": "$BLOCK_INDEX",
            "ORDER_1_EXPIRATION_BLOCK_INDEX": "$BLOCK_INDEX + 21",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=OPEN_ORDER,DEBIT,CREDIT",
                "result": [
                    {
                        "event": "OPEN_ORDER",
                        "event_index": "$EVENT_INDEX_4",
                        "params": {
                            "block_index": "$BLOCK_INDEX",
                            "expiration": 21,
                            "expire_index": "$ORDER_1_EXPIRATION_BLOCK_INDEX",
                            "fee_provided": 10000,
                            "fee_provided_remaining": 10000,
                            "fee_required": 0,
                            "fee_required_remaining": 0,
                            "get_asset": "BTC",
                            "get_quantity": 1000,
                            "get_remaining": 1000,
                            "give_asset": "XCP",
                            "give_quantity": 1000,
                            "give_remaining": 1000,
                            "source": "$ADDRESS_1",
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
                            "address": "$ADDRESS_1",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "event": "$TX_HASH",
                            "quantity": 1000,
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
    {
        "title": "Open Buy XCP for BTC order",
        "transaction": "order",
        "source": "$ADDRESS_2",
        "params": {
            "give_asset": "BTC",
            "give_quantity": 1000,
            "get_asset": "XCP",
            "get_quantity": 1000,
            "expiration": 20,
            "fee_required": 0,
        },
        "set_variables": {
            "ORDER_2_HASH": "$TX_HASH",
            "ORDER_2_TX_INDEX": "$TX_INDEX",
            "ORDER_2_BLOCK_INDEX": "$BLOCK_INDEX",
            "ORDER_2_EXPIRATION_BLOCK_INDEX": "$BLOCK_INDEX + 20",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=OPEN_ORDER,ORDER_MATCH,ORDER_UPDATE,DEBIT,CREDIT",
                "result": [
                    {
                        "event": "ORDER_MATCH",
                        "event_index": "$EVENT_INDEX_6",
                        "params": {
                            "backward_asset": "BTC",
                            "backward_quantity": 1000,
                            "block_index": "$BLOCK_INDEX",
                            "fee_paid": 0,
                            "forward_asset": "XCP",
                            "forward_quantity": 1000,
                            "id": "$ORDER_1_HASH_$TX_HASH",
                            "match_expire_index": "$ORDER_2_EXPIRATION_BLOCK_INDEX",
                            "status": "pending",
                            "tx0_address": "$ADDRESS_1",
                            "tx0_block_index": "$ORDER_1_BLOCK_INDEX",
                            "tx0_expiration": 21,
                            "tx0_hash": "$ORDER_1_HASH",
                            "tx0_index": "$ORDER_1_TX_INDEX",
                            "tx1_address": "$ADDRESS_2",
                            "tx1_block_index": "$BLOCK_INDEX",
                            "tx1_expiration": 20,
                            "tx1_hash": "$TX_HASH",
                            "tx1_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "ORDER_UPDATE",
                        "event_index": "$EVENT_INDEX_5",
                        "params": {
                            "fee_provided_remaining": 10000,
                            "fee_required_remaining": 0,
                            "get_remaining": 0,
                            "give_remaining": 0,
                            "status": "open",
                            "tx_hash": "$TX_HASH",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "ORDER_UPDATE",
                        "event_index": "$EVENT_INDEX_4",
                        "params": {
                            "fee_provided_remaining": 10000,
                            "fee_required_remaining": 0,
                            "get_remaining": 0,
                            "give_remaining": 0,
                            "status": "open",
                            "tx_hash": "$ORDER_1_HASH",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "OPEN_ORDER",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "block_index": "$BLOCK_INDEX",
                            "expiration": 20,
                            "expire_index": "$ORDER_2_EXPIRATION_BLOCK_INDEX",
                            "fee_provided": 10000,
                            "fee_provided_remaining": 10000,
                            "fee_required": 0,
                            "fee_required_remaining": 0,
                            "get_asset": "XCP",
                            "get_quantity": 1000,
                            "get_remaining": 1000,
                            "give_asset": "BTC",
                            "give_quantity": 1000,
                            "give_remaining": 1000,
                            "source": "$ADDRESS_2",
                            "status": "open",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            },
            {
                "url": "order_matches?block_index=$BLOCK_INDEX",
                "result": [
                    {
                        "backward_asset": "BTC",
                        "backward_quantity": 1000,
                        "block_index": "$BLOCK_INDEX",
                        "fee_paid": 0,
                        "forward_asset": "XCP",
                        "forward_quantity": 1000,
                        "id": "$ORDER_1_HASH_$TX_HASH",
                        "match_expire_index": "$ORDER_2_EXPIRATION_BLOCK_INDEX",
                        "status": "pending",
                        "tx0_address": "$ADDRESS_1",
                        "tx0_block_index": "$ORDER_1_BLOCK_INDEX",
                        "tx0_expiration": 21,
                        "tx0_hash": "$ORDER_1_HASH",
                        "tx0_index": "$ORDER_1_TX_INDEX",
                        "tx1_address": "$ADDRESS_2",
                        "tx1_block_index": "$BLOCK_INDEX",
                        "tx1_expiration": 20,
                        "tx1_hash": "$TX_HASH",
                        "tx1_index": "$TX_INDEX",
                        "backward_price": 1.0,
                        "forward_price": 1.0,
                    }
                ],
            },
        ],
    },
    {
        "title": "mint empty block to trigger order expiration",
        "transaction": "mine_blocks",
        "params": {"blocks": 21},
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=ORDER_EXPIRATION,ORDER_UPDATE,CREDIT,ORDER_MATCH_EXPIRATION,ORDER_MATCH_UPDATE,DEBIT",
                "result": [
                    {
                        "event": "ORDER_EXPIRATION",
                        "event_index": "$EVENT_INDEX_10",
                        "params": {
                            "block_index": "$BLOCK_INDEX",
                            "order_hash": "$ORDER_2_HASH",
                            "source": "$ADDRESS_2",
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "ORDER_UPDATE",
                        "event_index": "$EVENT_INDEX_9",
                        "params": {"status": "expired", "tx_hash": "$ORDER_2_HASH"},
                        "tx_hash": None,
                    },
                    {
                        "event": "ORDER_EXPIRATION",
                        "event_index": "$EVENT_INDEX_8",
                        "params": {
                            "block_index": "$BLOCK_INDEX",
                            "order_hash": "$ORDER_1_HASH",
                            "source": "$ADDRESS_1",
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_7",
                        "params": {
                            "address": "$ADDRESS_1",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "cancel order",
                            "event": "$ORDER_1_HASH",
                            "quantity": 1000,
                            "tx_index": 0,
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "ORDER_UPDATE",
                        "event_index": "$EVENT_INDEX_6",
                        "params": {"status": "expired", "tx_hash": "$ORDER_1_HASH"},
                        "tx_hash": None,
                    },
                    {
                        "event": "ORDER_MATCH_EXPIRATION",
                        "event_index": "$EVENT_INDEX_5",
                        "params": {
                            "block_index": "$BLOCK_INDEX",
                            "order_match_id": "$ORDER_1_HASH_$ORDER_2_HASH",
                            "tx0_address": "$ADDRESS_1",
                            "tx1_address": "$ADDRESS_2",
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "ORDER_UPDATE",
                        "event_index": "$EVENT_INDEX_4",
                        "params": {
                            "fee_required_remaining": 0,
                            "get_remaining": 1000,
                            "give_remaining": 1000,
                            "status": "open",
                            "tx_hash": "$ORDER_2_HASH",
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "ORDER_UPDATE",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "fee_required_remaining": 0,
                            "get_remaining": 1000,
                            "give_remaining": 1000,
                            "status": "open",
                            "tx_hash": "$ORDER_1_HASH",
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "ORDER_MATCH_UPDATE",
                        "event_index": "$EVENT_INDEX_2",
                        "params": {
                            "id": "$ORDER_1_HASH_$ORDER_2_HASH",
                            "order_match_id": "$ORDER_1_HASH_$ORDER_2_HASH",
                            "status": "expired",
                        },
                        "tx_hash": None,
                    },
                ],
            }
        ],
    },
]
