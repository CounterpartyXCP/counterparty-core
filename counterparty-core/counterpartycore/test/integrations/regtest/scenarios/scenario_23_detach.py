SCENARIO = [
    {
        "title": "Create asset DETACHA",
        "transaction": "issuance",
        "source": "$ADDRESS_10",
        "params": {
            "asset": "DETACHA",
            "quantity": 10 * 10**8,
            "exact_fee": 0,
        },
        "set_variables": {
            "CREATE_DETACHA_TX_HASH": "$TX_HASH",
            "CREATE_DETACHA_TX_INDEX": "$TX_INDEX",
        },
        "controls": [],
    },
    {
        "title": "Create asset DETACHB",
        "transaction": "issuance",
        "source": "$ADDRESS_10",
        "params": {
            "asset": "DETACHB",
            "quantity": 10 * 10**8,
            "exact_fee": 0,
        },
        "set_variables": {
            "CREATE_DETACHB_TX_HASH": "$TX_HASH",
            "CREATE_DETACHB_TX_INDEX": "$TX_INDEX",
        },
    },
    {
        "title": "Attach DETACHA asset to UTXO",
        "transaction": "attach",
        "source": "$ADDRESS_10",
        "no_confirmation": True,
        "params": {
            "asset": "DETACHA",
            "quantity": 1 * 10**8,
            "inputs_set": "$CREATE_DETACHB_TX_HASH:1",
            "utxo_value": 10000,
            "exact_fee": 0,
        },
        "set_variables": {
            "ATTACH_DETACHA_TX_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "addresses/mempool?event_name=ATTACH_TO_UTXO&addresses=$ADDRESS_10",
                "result": [
                    {
                        "event": "ATTACH_TO_UTXO",
                        "params": {
                            "asset": "DETACHA",
                            "block_index": 9999999,
                            "destination": "$ATTACH_DETACHA_TX_HASH:0",
                            "destination_address": "$ADDRESS_10",
                            "fee_paid": 0,
                            "msg_index": 0,
                            "quantity": 100000000,
                            "send_type": "attach",
                            "source": "$ADDRESS_10",
                            "status": "valid",
                            "tx_hash": "$ATTACH_DETACHA_TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$ATTACH_DETACHA_TX_HASH",
                    }
                ],
            }
        ],
    },
    {
        "title": "Attach DETACHB asset to UTXO",
        "transaction": "attach",
        "source": "$ADDRESS_10",
        "params": {
            "asset": "DETACHB",
            "quantity": 1 * 10**8,
            "inputs_set": "$ATTACH_DETACHA_TX_HASH:0",
            "exact_fee": 0,
            "validate": False,
            "utxo_value": 10000,
        },
        "set_variables": {
            "ATTACH_DETACHB_TX_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=ATTACH_TO_UTXO,UTXO_MOVE",
                "result": [
                    {
                        "event": "UTXO_MOVE",
                        "event_index": "$EVENT_INDEX_15",
                        "params": {
                            "asset": "DETACHA",
                            "block_index": "$BLOCK_INDEX",
                            "destination": "$TX_HASH:0",
                            "destination_address": "$ADDRESS_10",
                            "msg_index": 1,
                            "quantity": 100000000,
                            "send_type": "move",
                            "source": "$ATTACH_DETACHA_TX_HASH:0",
                            "source_address": "$ADDRESS_10",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "ATTACH_TO_UTXO",
                        "event_index": "$EVENT_INDEX_12",
                        "params": {
                            "asset": "DETACHB",
                            "block_index": "$BLOCK_INDEX",
                            "destination": "$TX_HASH:0",
                            "destination_address": "$ADDRESS_10",
                            "fee_paid": 0,
                            "msg_index": 0,
                            "quantity": 100000000,
                            "send_type": "attach",
                            "source": "$ADDRESS_10",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "ATTACH_TO_UTXO",
                        "event_index": "$EVENT_INDEX_7",
                        "params": {
                            "asset": "DETACHA",
                            "block_index": "$BLOCK_INDEX",
                            "destination": "$ATTACH_DETACHA_TX_HASH:0",
                            "destination_address": "$ADDRESS_10",
                            "fee_paid": 0,
                            "msg_index": 0,
                            "quantity": 100000000,
                            "send_type": "attach",
                            "source": "$ADDRESS_10",
                            "status": "valid",
                            "tx_hash": "$ATTACH_DETACHA_TX_HASH",
                            "tx_index": "$TX_INDEX - 1",
                        },
                        "tx_hash": "$ATTACH_DETACHA_TX_HASH",
                    },
                ],
            }
        ],
    },
    {
        "title": "Detach DETACHA and DETACHB from UTXO",
        "transaction": "detach",
        "source": "$ATTACH_DETACHB_TX_HASH:0",
        "params": {
            "exact_fee": 0,
            "inputs_source": "$ADDRESS_10",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=DETACH_FROM_UTXO",
                "result": [
                    {
                        "event": "DETACH_FROM_UTXO",
                        "event_index": "$EVENT_INDEX_8",
                        "params": {
                            "asset": "DETACHB",
                            "block_index": "$BLOCK_INDEX",
                            "destination": "$ADDRESS_10",
                            "fee_paid": 0,
                            "msg_index": 1,
                            "quantity": 100000000,
                            "send_type": "detach",
                            "source": "$ATTACH_DETACHB_TX_HASH:0",
                            "source_address": "$ADDRESS_10",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DETACH_FROM_UTXO",
                        "event_index": "$EVENT_INDEX_5",
                        "params": {
                            "asset": "DETACHA",
                            "block_index": "$BLOCK_INDEX",
                            "destination": "$ADDRESS_10",
                            "fee_paid": 0,
                            "msg_index": 0,
                            "quantity": 100000000,
                            "send_type": "detach",
                            "source": "$ATTACH_DETACHB_TX_HASH:0",
                            "source_address": "$ADDRESS_10",
                            "status": "valid",
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
        "title": "Attach DETACHA asset to UTXO",
        "transaction": "attach",
        "source": "$ADDRESS_10",
        "params": {
            "asset": "DETACHA",
            "quantity": 1 * 10**8,
            "utxo_value": 10000,
        },
        "set_variables": {
            "ATTACH2_DETACHA_TX_HASH": "$TX_HASH",
        },
        "controls": [],
    },
    {
        "title": "Move no confirmation",
        "transaction": "movetoutxo",
        "no_confirmation": True,
        "source": "$ATTACH2_DETACHA_TX_HASH:0",
        "params": {
            "destination": "$ADDRESS_9",
            "quantity": 1 * 10**8,
            "utxo_value": 10000,
        },
        "controls": [
            {
                "url": "mempool/events?event_name=UTXO_MOVE",
                "result": [
                    {
                        "event": "UTXO_MOVE",
                        "params": {
                            "asset": "DETACHA",
                            "block_index": 9999999,
                            "destination": "$TX_HASH:0",
                            "destination_address": "$ADDRESS_9",
                            "msg_index": 0,
                            "quantity": 100000000,
                            "send_type": "move",
                            "source": "$ATTACH2_DETACHA_TX_HASH:0",
                            "source_address": "$ADDRESS_10",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    }
                ],
            },
            {
                "url": "addresses/mempool?addresses=$ADDRESS_10&event_name=UTXO_MOVE",
                "result": [
                    {
                        "event": "UTXO_MOVE",
                        "params": {
                            "asset": "DETACHA",
                            "block_index": 9999999,
                            "destination": "$TX_HASH:0",
                            "destination_address": "$ADDRESS_9",
                            "msg_index": 0,
                            "quantity": 100000000,
                            "send_type": "move",
                            "source": "$ATTACH2_DETACHA_TX_HASH:0",
                            "source_address": "$ADDRESS_10",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    }
                ],
            },
            {
                "url": "addresses/mempool?addresses=$ADDRESS_9&event_name=UTXO_MOVE",
                "result": [
                    {
                        "event": "UTXO_MOVE",
                        "params": {
                            "asset": "DETACHA",
                            "block_index": 9999999,
                            "destination": "$TX_HASH:0",
                            "destination_address": "$ADDRESS_9",
                            "msg_index": 0,
                            "quantity": 100000000,
                            "send_type": "move",
                            "source": "$ATTACH2_DETACHA_TX_HASH:0",
                            "source_address": "$ADDRESS_10",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    }
                ],
            },
        ],
    },
]
