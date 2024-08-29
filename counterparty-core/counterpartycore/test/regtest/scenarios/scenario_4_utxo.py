SCENARIO = [
    {
        "title": "Create asset MYASSETA",
        "transaction": "issuance",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "MYASSETA",
            "quantity": 1000 * 10**8,
            "divisible": True,
            "description": "My super asset A",
        },
        "controls": [
            {
                "url": "blocks/134/events?event_name=CREDIT,ASSET_ISSUANCE,ASSET_CREATION,DEBIT",
                "result": [
                    {
                        "event": "CREDIT",
                        "event_index": 186,
                        "params": {
                            "address": "$ADDRESS_1",
                            "asset": "MYASSETA",
                            "block_index": 134,
                            "calling_function": "issuance",
                            "event": "$TX_HASH",
                            "quantity": 100000000000,
                            "tx_index": 21,
                            "utxo": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "ASSET_ISSUANCE",
                        "event_index": 185,
                        "params": {
                            "asset": "MYASSETA",
                            "asset_longname": None,
                            "block_index": 134,
                            "call_date": 0,
                            "call_price": 0.0,
                            "callable": False,
                            "description": "My super asset A",
                            "description_locked": False,
                            "divisible": True,
                            "fee_paid": 50000000,
                            "issuer": "$ADDRESS_1",
                            "locked": False,
                            "quantity": 100000000000,
                            "reset": False,
                            "source": "$ADDRESS_1",
                            "status": "valid",
                            "transfer": False,
                            "tx_hash": "$TX_HASH",
                            "tx_index": 21,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "ASSET_CREATION",
                        "event_index": 184,
                        "params": {
                            "asset_id": "103804245870",
                            "asset_longname": None,
                            "asset_name": "MYASSETA",
                            "block_index": 134,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": 183,
                        "params": {
                            "action": "issuance fee",
                            "address": "$ADDRESS_1",
                            "asset": "XCP",
                            "block_index": 134,
                            "event": "$TX_HASH",
                            "quantity": 50000000,
                            "tx_index": 21,
                            "utxo": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            }
        ],
    },
    {
        "title": "Attach asset to UTXO",
        "transaction": "attach",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "MYASSETA",
            "quantity": 10 * 10**8,
            "destination": "$FAIRMINTB_WITH_ADDRESS_3_TX_HASH:1",
        },
        "controls": [
            {
                "url": "blocks/135/events?event_name=ATTACH_TO_UTXO,INCREMENT_TRANSACTION_COUNT,CREDIT,DEBIT",
                "result": [
                    {
                        "event": "ATTACH_TO_UTXO",
                        "event_index": 194,
                        "params": {
                            "asset": "MYASSETA",
                            "block_index": 135,
                            "destination": "$FAIRMINTB_WITH_ADDRESS_3_TX_HASH:1",
                            "fee_paid": 0,
                            "quantity": 1000000000,
                            "source": "$ADDRESS_1",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": 22,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "INCREMENT_TRANSACTION_COUNT",
                        "event_index": 193,
                        "params": {
                            "block_index": 135,
                            "count": 1,
                            "difficulty_period": 0,
                            "transaction_id": 100,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "CREDIT",
                        "event_index": 192,
                        "params": {
                            "address": None,
                            "asset": "MYASSETA",
                            "block_index": 135,
                            "calling_function": "attach to utxo",
                            "event": "$TX_HASH",
                            "quantity": 1000000000,
                            "tx_index": 22,
                            "utxo": "$FAIRMINTB_WITH_ADDRESS_3_TX_HASH:1",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": 191,
                        "params": {
                            "action": "attach to utxo",
                            "address": "$ADDRESS_1",
                            "asset": "MYASSETA",
                            "block_index": 135,
                            "event": "$TX_HASH",
                            "quantity": 1000000000,
                            "tx_index": 22,
                            "utxo": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            }
        ],
    },
    {
        "title": "Move assets from UTXO to UTXO",
        "transaction": "movetoutxo",
        "source": "$FAIRMINTB_WITH_ADDRESS_3_TX_HASH:1",
        "params": {
            "destination": "$ADDRESS_4",
        },
        "controls": [
            {
                "url": "blocks/136/events?event_name=UTXO_MOVE,CREDIT,DEBIT,NEW_TRANSACTION",
                "result": [
                    {
                        "event": "UTXO_MOVE",
                        "event_index": 201,
                        "params": {
                            "asset": "MYASSETA",
                            "block_index": 136,
                            "destination": "$TX_HASH:0",
                            "msg_index": 0,
                            "quantity": 1000000000,
                            "source": "$FAIRMINTB_WITH_ADDRESS_3_TX_HASH:1",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": 23,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "CREDIT",
                        "event_index": 200,
                        "params": {
                            "address": None,
                            "asset": "MYASSETA",
                            "block_index": 136,
                            "calling_function": "utxo move",
                            "event": "$TX_HASH",
                            "quantity": 1000000000,
                            "tx_index": 23,
                            "utxo": "$TX_HASH:0",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": 199,
                        "params": {
                            "action": "utxo move",
                            "address": None,
                            "asset": "MYASSETA",
                            "block_index": 136,
                            "event": "$TX_HASH",
                            "quantity": 1000000000,
                            "tx_index": 23,
                            "utxo": "$FAIRMINTB_WITH_ADDRESS_3_TX_HASH:1",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "NEW_TRANSACTION",
                        "event_index": 198,
                        "params": {
                            "block_hash": "$BLOCK_HASH",
                            "block_index": 136,
                            "block_time": "$BLOCK_TIME",
                            "btc_amount": None,
                            "data": None,
                            "destination": None,
                            "fee": None,
                            "source": "",
                            "tx_hash": "$TX_HASH",
                            "tx_index": 23,
                            "utxos_info": "$FAIRMINTB_WITH_ADDRESS_3_TX_HASH:1 $TX_HASH:0",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            }
        ],
    },
]
