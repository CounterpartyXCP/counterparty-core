import json

SCENARIO = [
    {
        "title": "Double send",
        "transaction": "multiple",
        "source": "",
        "params": {
            "json_txs": json.dumps(
                {
                    "transactions": [
                        {
                            "name": "send",
                            "params": {
                                "address": "$ADDRESS_1",
                                "destination": "$ADDRESS_2",
                                "asset": "XCP",
                                "quantity": 1,
                            },
                        },
                        {
                            "name": "send",
                            "params": {
                                "address": "$ADDRESS_1",
                                "destination": "$ADDRESS_2",
                                "asset": "MYASSETA",
                                "quantity": 1,
                            },
                        },
                    ],
                }
            ),
        },
        "controls": [
            {
                "url": "blocks/141/events?event_name=ENHANCED_SEND,DEBIT,CREDIT",
                "result": [
                    {
                        "event": "ENHANCED_SEND",
                        "event_index": 243,
                        "params": {
                            "asset": "MYASSETA",
                            "block_index": 141,
                            "destination": "$ADDRESS_2",
                            "memo": None,
                            "msg_index": 1,
                            "quantity": 1,
                            "source": "$ADDRESS_1",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": 28,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "CREDIT",
                        "event_index": 242,
                        "params": {
                            "address": "$ADDRESS_2",
                            "asset": "MYASSETA",
                            "block_index": 141,
                            "calling_function": "send",
                            "event": "$TX_HASH",
                            "quantity": 1,
                            "tx_index": 28,
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": 241,
                        "params": {
                            "action": "send",
                            "address": "$ADDRESS_1",
                            "asset": "MYASSETA",
                            "block_index": 141,
                            "event": "$TX_HASH",
                            "quantity": 1,
                            "tx_index": 28,
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "ENHANCED_SEND",
                        "event_index": 240,
                        "params": {
                            "asset": "XCP",
                            "block_index": 141,
                            "destination": "$ADDRESS_2",
                            "memo": None,
                            "msg_index": 0,
                            "quantity": 1,
                            "source": "$ADDRESS_1",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": 28,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "CREDIT",
                        "event_index": 239,
                        "params": {
                            "address": "$ADDRESS_2",
                            "asset": "XCP",
                            "block_index": 141,
                            "calling_function": "send",
                            "event": "$TX_HASH",
                            "quantity": 1,
                            "tx_index": 28,
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": 238,
                        "params": {
                            "action": "send",
                            "address": "$ADDRESS_1",
                            "asset": "XCP",
                            "block_index": 141,
                            "event": "$TX_HASH",
                            "quantity": 1,
                            "tx_index": 28,
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
