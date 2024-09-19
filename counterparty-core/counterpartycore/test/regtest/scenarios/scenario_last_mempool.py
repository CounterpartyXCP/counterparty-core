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
                            "block_index": "$BLOCK_INDEX",
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
            {
                "url": "transactions/$TX_HASH/info",
                "result": {
                    "btc_amount": 0,
                    "data": "$TX_DATA",
                    "decoded_tx": {
                        "coinbase": False,
                        "lock_time": 0,
                        "segwit": True,
                        "tx_hash": "$TX_HASH",
                        "tx_id": "$TX_HASH",
                        "version": 2,
                        "vin": [
                            {
                                "coinbase": False,
                                "hash": "$DESTROY_1_TX_HASH",
                                "n": 1,
                                "script_sig": "",
                                "sequence": 4294967295,
                            }
                        ],
                        "vout": [
                            {
                                "script_pub_key": "6a2e547ea24ed06a615893c16ff8e59a84444825e1af612ae2be0a26b09d39295552fef91497fd4146e8613d6be321c7",
                                "value": 0,
                            },
                            {
                                "script_pub_key": "0014dde33a51e649066e7add6dcf0963892c4fe5d653",
                                "value": 4999955000,
                            },
                        ],
                        "vtxinwit": [
                            "304402206145e076eabf0de3e5b4edfea8be33c9b22f47d258d7d4c5682b3d0f6e3c648e022037f3e5451f4257e4ecfaa7c34016e00e5fb73cacb81eff875017d24a62b0a5bc01",
                            "0355f42b0e4c7b6e73addef75deab673b9727225a3d529511ef28f5df36472826c",
                        ],
                    },
                    "destination": None,
                    "fee": 10000,
                    "source": "$ADDRESS_4",
                    "unpacked_data": {
                        "message_data": {
                            "address": "$ADDRESS_3",
                            "asset": "XCP",
                            "memo": None,
                            "quantity": 10000,
                        },
                        "message_type": "enhanced_send",
                        "message_type_id": 2,
                    },
                },
            },
        ],
    },
]