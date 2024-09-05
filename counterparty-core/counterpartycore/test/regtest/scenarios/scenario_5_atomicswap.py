SCENARIO = [
    {
        "title": "Test Atomic Swap",
        "transaction": "atomic_swap",
        "params": {
            "seller": "$ADDRESS_6",
            "utxo": "$UTXO_MOVE_2_TX_HASH:0",  # 15.00000000 MYASSETA and 15.00000000 XCP
            "price": 100000,  # for 100000 satoshis
            "buyer": "$ADDRESS_8",
        },
        "controls": [
            {
                "url": "blocks/141/events?event_name=UTXO_MOVE,DEBIT,CREDIT",
                "result": [
                    {
                        "event": "UTXO_MOVE",
                        "event_index": 243,
                        "params": {
                            "asset": "XCP",
                            "block_index": 141,
                            "destination": "$TX_HASH:0",
                            "msg_index": 1,
                            "quantity": 1500000000,
                            "source": "$UTXO_MOVE_2_TX_HASH:0",
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
                            "address": None,
                            "asset": "XCP",
                            "block_index": 141,
                            "calling_function": "utxo move",
                            "event": "$TX_HASH",
                            "quantity": 1500000000,
                            "tx_index": 28,
                            "utxo": "$TX_HASH:0",
                            "utxo_address": "$ADDRESS_8",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": 241,
                        "params": {
                            "action": "utxo move",
                            "address": None,
                            "asset": "XCP",
                            "block_index": 141,
                            "event": "$TX_HASH",
                            "quantity": 1500000000,
                            "tx_index": 28,
                            "utxo": "$UTXO_MOVE_2_TX_HASH:0",
                            "utxo_address": "$ADDRESS_6",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "UTXO_MOVE",
                        "event_index": 240,
                        "params": {
                            "asset": "MYASSETA",
                            "block_index": 141,
                            "destination": "$TX_HASH:0",
                            "msg_index": 0,
                            "quantity": 1500000000,
                            "source": "$UTXO_MOVE_2_TX_HASH:0",
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
                            "address": None,
                            "asset": "MYASSETA",
                            "block_index": 141,
                            "calling_function": "utxo move",
                            "event": "$TX_HASH",
                            "quantity": 1500000000,
                            "tx_index": 28,
                            "utxo": "$TX_HASH:0",
                            "utxo_address": "$ADDRESS_8",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": 238,
                        "params": {
                            "action": "utxo move",
                            "address": None,
                            "asset": "MYASSETA",
                            "block_index": 141,
                            "event": "$TX_HASH",
                            "quantity": 1500000000,
                            "tx_index": 28,
                            "utxo": "$UTXO_MOVE_2_TX_HASH:0",
                            "utxo_address": "$ADDRESS_6",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            }
        ],
    }
]
