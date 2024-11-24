SCENARIO = [
    {
        "title": "Create Dispenser 1",
        "transaction": "dispenser",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "XCP",
            "give_quantity": 1,
            "escrow_quantity": 10000,
            "mainchainrate": 1,  # 1 BTC for 1 XCP
            "status": 0,
        },
        "set_variables": {
            "DISPENSER_1_TX_HASH": "$TX_HASH",
            "DISPENSER_1_TX_INDEX": "$TX_INDEX",
            "DISPENSER_1_BLOCK_INDEX": "$BLOCK_INDEX",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=OPEN_DISPENSER,DEBIT",
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
                            "origin": "$ADDRESS_1",
                            "satoshirate": 1,
                            "source": "$ADDRESS_1",
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
                            "address": "$ADDRESS_1",
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
            }
        ],
    },
    {
        "title": "Dispense 1: get 900 XCP",
        "transaction": "dispense",
        "source": "$ADDRESS_2",
        "params": {
            "dispenser": "$ADDRESS_1",
            "quantity": 6000,
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=NEW_TRANSACTION,NEW_TRANSACTION_OUTPUT,CREDIT,DISPENSER_UPDATE,DISPENSE",
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
                            "dispenser_tx_hash": "$DISPENSER_1_TX_HASH",
                            "source": "$ADDRESS_1",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DISPENSER_UPDATE",
                        "event_index": "$EVENT_INDEX_5",
                        "params": {
                            "asset": "XCP",
                            "dispense_count": 1,
                            "give_remaining": 4000,
                            "source": "$ADDRESS_1",
                            "status": 0,
                            "tx_hash": "$DISPENSER_1_TX_HASH",
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
                            "calling_function": "dispense",
                            "event": "$TX_HASH",
                            "quantity": 6000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "NEW_TRANSACTION_OUTPUT",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "block_index": "$BLOCK_INDEX",
                            "btc_amount": 6000,
                            "destination": "$ADDRESS_1",
                            "out_index": 0,
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "NEW_TRANSACTION",
                        "event_index": "$EVENT_INDEX_2",
                        "params": {
                            "block_hash": "$BLOCK_HASH",
                            "block_index": "$BLOCK_INDEX",
                            "block_time": "$BLOCK_TIME",
                            "btc_amount": 6000,
                            "data": "0d00",
                            "destination": "$ADDRESS_1",
                            "fee": 0,
                            "source": "$ADDRESS_2",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                            "utxos_info": " $TX_HASH:0 3 1",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            }
        ],
    },
    {
        "title": "Dispense 2: get no enough asset error",
        "transaction": "dispense",
        "source": "$ADDRESS_3",
        "params": {
            "dispenser": "$ADDRESS_1",
            "quantity": 4001,
        },
        "expected_error": ["dispenser for XCP doesn't have enough asset to give"],
    },
    {
        "title": "Dispense 3: no dispenser error",
        "transaction": "dispense",
        "source": "$ADDRESS_3",
        "params": {
            "dispenser": "$ADDRESS_2",
            "quantity": 50,
        },
        "expected_error": ["address doesn't have any open dispenser"],
    },
    {
        "title": "Dispense from the dispenser",
        "transaction": "dispense",
        "source": "$ADDRESS_1",
        "params": {
            "dispenser": "$ADDRESS_1",
            "quantity": 4000,
        },
        "expected_error": "source and destination must be different",
    },
    {
        "title": "Dispense 4: get 100 XCP",
        "transaction": "dispense",
        "source": "$ADDRESS_2",
        "params": {
            "dispenser": "$ADDRESS_1",
            "quantity": 4000,
        },
        "set_variables": {
            "DISPENSER_1_LAST_UPDATE_BLOCK_INDEX": "$BLOCK_INDEX",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=NEW_TRANSACTION,NEW_TRANSACTION_OUTPUT,CREDIT,DISPENSER_UPDATE,DISPENSE",
                "result": [
                    {
                        "event": "DISPENSE",
                        "event_index": "$EVENT_INDEX_6",
                        "params": {
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "btc_amount": 4000,
                            "destination": "$ADDRESS_2",
                            "dispense_index": 0,
                            "dispense_quantity": 4000,
                            "dispenser_tx_hash": "$DISPENSER_1_TX_HASH",
                            "source": "$ADDRESS_1",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DISPENSER_UPDATE",
                        "event_index": "$EVENT_INDEX_5",
                        "params": {
                            "asset": "XCP",
                            "dispense_count": 2,
                            "give_remaining": 0,
                            "source": "$ADDRESS_1",
                            "status": 10,
                            "tx_hash": "$DISPENSER_1_TX_HASH",
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
                            "calling_function": "dispense",
                            "event": "$TX_HASH",
                            "quantity": 4000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "NEW_TRANSACTION_OUTPUT",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "block_index": "$BLOCK_INDEX",
                            "btc_amount": 4000,
                            "destination": "$ADDRESS_1",
                            "out_index": 0,
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "NEW_TRANSACTION",
                        "event_index": "$EVENT_INDEX_2",
                        "params": {
                            "block_hash": "$BLOCK_HASH",
                            "block_index": "$BLOCK_INDEX",
                            "block_time": "$BLOCK_TIME",
                            "btc_amount": 4000,
                            "data": "0d00",
                            "destination": "$ADDRESS_1",
                            "fee": 0,
                            "source": "$ADDRESS_2",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                            "utxos_info": " $TX_HASH:0 3 1",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            }
        ],
    },
    {
        "title": "Dispense 5: dispenser is closed and empy errors",
        "transaction": "dispense",
        "source": "$ADDRESS_3",
        "params": {
            "dispenser": "$ADDRESS_1",
            "quantity": 4001,
        },
        "expected_error": ["dispenser for XCP is not open", "dispenser for XCP is empty"],
    },
    {
        "title": "Create Dispenser 2: dispenser must be created by source",
        "transaction": "dispenser",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "XCP",
            "give_quantity": 1,
            "escrow_quantity": 10000,
            "mainchainrate": 1,  # 1 BTC for 1 XCP
            "status": 0,
            "open_address": "$ADDRESS_5",
        },
        "expected_error": ["dispenser must be created by source"],
    },
]
