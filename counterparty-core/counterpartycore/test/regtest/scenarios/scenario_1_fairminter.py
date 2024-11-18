# soft cap reached.
SCENARIO = [
    {
        "title": "Create FAIRMINTA fairminter",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FAIRMINTA",
            "price": 1,
            "hard_cap": 100 * 10**8,
            "soft_cap": 10 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 3",
        },
        "set_variables": {
            "FAIRMINTA_TX_HASH": "$TX_HASH",
            "FAIRMINTA_BLOCK_INDEX": "$BLOCK_INDEX",
        },
        "controls": [
            {
                "url": "assets/FAIRMINTA/fairminters",
                "result": [
                    {
                        "tx_hash": "$TX_HASH",
                        "tx_index": "$TX_INDEX",
                        "block_index": "$BLOCK_INDEX",
                        "source": "$ADDRESS_1",
                        "asset": "FAIRMINTA",
                        "asset_parent": None,
                        "asset_longname": None,
                        "description": "",
                        "price": 1,
                        "quantity_by_price": 1,
                        "hard_cap": 100 * 10**8,
                        "burn_payment": False,
                        "max_mint_per_tx": 0,
                        "premint_quantity": 0,
                        "start_block": 0,
                        "end_block": 0,
                        "minted_asset_commission_int": 0,
                        "soft_cap": 10 * 10**8,
                        "soft_cap_deadline_block": "$BLOCK_INDEX + 2",
                        "lock_description": False,
                        "lock_quantity": False,
                        "divisible": True,
                        "pre_minted": False,
                        "status": "open",
                        "earned_quantity": None,
                        "commission": None,
                        "paid_quantity": None,
                        "confirmed": True,
                    }
                ],
            },
            {
                "url": "transactions/$TX_HASH/events",
                "result": [
                    {
                        "event_index": "$EVENT_INDEX_7",
                        "event": "TRANSACTION_PARSED",
                        "params": {
                            "supported": True,
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                        "block_index": "$BLOCK_INDEX",
                    },
                    {
                        "event_index": "$EVENT_INDEX_6",
                        "event": "DEBIT",
                        "params": {
                            "action": "fairminter fee",
                            "address": "$ADDRESS_1",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "event": "$TX_HASH",
                            "quantity": 50000000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                        "block_index": "$BLOCK_INDEX",
                    },
                    {
                        "event_index": "$EVENT_INDEX_5",
                        "event": "ASSET_ISSUANCE",
                        "params": {
                            "asset": "FAIRMINTA",
                            "asset_longname": None,
                            "asset_events": "open_fairminter",
                            "block_index": "$BLOCK_INDEX",
                            "call_date": 0,
                            "call_price": 0,
                            "callable": False,
                            "description": "",
                            "divisible": True,
                            "fair_minting": True,
                            "fee_paid": 50000000.0,
                            "issuer": "$ADDRESS_1",
                            "locked": False,
                            "quantity": 0,
                            "reset": False,
                            "source": "$ADDRESS_1",
                            "status": "valid",
                            "transfer": False,
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                        "block_index": "$BLOCK_INDEX",
                    },
                    {
                        "event_index": "$EVENT_INDEX_4",
                        "event": "ASSET_CREATION",
                        "params": {
                            "asset_id": "1046814266082",
                            "asset_longname": None,
                            "asset_name": "FAIRMINTA",
                            "block_index": "$BLOCK_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                        "block_index": "$BLOCK_INDEX",
                    },
                    {
                        "event_index": "$EVENT_INDEX_3",
                        "event": "NEW_FAIRMINTER",
                        "params": {
                            "asset": "FAIRMINTA",
                            "asset_longname": None,
                            "asset_parent": None,
                            "block_index": "$BLOCK_INDEX",
                            "burn_payment": False,
                            "description": "",
                            "divisible": True,
                            "end_block": 0,
                            "hard_cap": 100 * 10**8,
                            "lock_description": False,
                            "lock_quantity": False,
                            "max_mint_per_tx": 0,
                            "minted_asset_commission_int": 0,
                            "pre_minted": False,
                            "premint_quantity": 0,
                            "price": 1,
                            "quantity_by_price": 1,
                            "soft_cap": 10 * 10**8,
                            "soft_cap_deadline_block": "$BLOCK_INDEX + 2",
                            "source": "$ADDRESS_1",
                            "start_block": 0,
                            "status": "open",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                        "block_index": "$BLOCK_INDEX",
                    },
                    {
                        "event_index": "$EVENT_INDEX_2",
                        "event": "NEW_TRANSACTION",
                        "params": {
                            "block_hash": "$BLOCK_HASH",
                            "block_index": "$BLOCK_INDEX",
                            "block_time": "$BLOCK_TIME",
                            "btc_amount": 0,
                            "data": "5a464149524d494e54417c7c317c317c307c31303030303030303030307c307c307c307c313030303030303030307c3131357c307c307c307c307c317c",
                            "destination": "",
                            "fee": 10000,
                            "source": "$ADDRESS_1",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                            "utxos_info": " $TX_HASH:1 2 ",
                        },
                        "tx_hash": "$TX_HASH",
                        "block_index": "$BLOCK_INDEX",
                    },
                ],
            },
        ],
    },
    {
        "title": "mint FAIRMINTA with ADDRESS_2",
        "transaction": "fairmint",
        "source": "$ADDRESS_2",
        "params": {
            "asset": "FAIRMINTA",
            "quantity": 5 * 10**8,
        },
        "set_variables": {
            "FAIRMINTA_MINT_1_TX_HASH": "$TX_HASH",
            "FAIRMINTA_MINT_1_TX_INDEX": "$TX_INDEX",
        },
        "controls": [
            {
                "url": "transactions/$TX_HASH/events",
                "result": [
                    {
                        "block_index": "$BLOCK_INDEX",
                        "event": "TRANSACTION_PARSED",
                        "event_index": "$EVENT_INDEX_8",
                        "params": {
                            "supported": True,
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "block_index": "$BLOCK_INDEX",
                        "event": "ASSET_ISSUANCE",
                        "event_index": "$EVENT_INDEX_7",
                        "params": {
                            "asset": "FAIRMINTA",
                            "asset_longname": None,
                            "asset_events": "fairmint",
                            "block_index": "$BLOCK_INDEX",
                            "call_date": 0,
                            "call_price": 0.0,
                            "callable": False,
                            "description": "",
                            "description_locked": False,
                            "divisible": True,
                            "fair_minting": True,
                            "fee_paid": 0,
                            "issuer": "$ADDRESS_1",
                            "locked": False,
                            "msg_index": 0,
                            "quantity": 500000000,
                            "reset": False,
                            "source": "$ADDRESS_2",
                            "status": "valid",
                            "transfer": False,
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "block_index": "$BLOCK_INDEX",
                        "event": "NEW_FAIRMINT",
                        "event_index": "$EVENT_INDEX_6",
                        "params": {
                            "asset": "FAIRMINTA",
                            "block_index": "$BLOCK_INDEX",
                            "commission": 0,
                            "earn_quantity": 5 * 10**8,
                            "fairminter_tx_hash": "$FAIRMINTA_TX_HASH",
                            "paid_quantity": 5 * 10**8,
                            "source": "$ADDRESS_2",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "block_index": "$BLOCK_INDEX",
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_5",
                        "params": {
                            "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                            "asset": "FAIRMINTA",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "escrowed fairmint",
                            "event": "$TX_HASH",
                            "quantity": 5 * 10**8,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "block_index": "$BLOCK_INDEX",
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_4",
                        "params": {
                            "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "escrowed fairmint",
                            "event": "$TX_HASH",
                            "quantity": 5 * 10**8,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "block_index": "$BLOCK_INDEX",
                        "event": "DEBIT",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "action": "escrowed fairmint",
                            "address": "$ADDRESS_2",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "event": "$TX_HASH",
                            "quantity": 5 * 10**8,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "block_index": "$BLOCK_INDEX",
                        "event": "NEW_TRANSACTION",
                        "event_index": "$EVENT_INDEX_2",
                        "params": {
                            "block_hash": "$BLOCK_HASH",
                            "block_index": "$BLOCK_INDEX",
                            "block_time": "$BLOCK_TIME",
                            "btc_amount": 0,
                            "data": "5b464149524d494e54417c353030303030303030",
                            "destination": "",
                            "fee": 10000,
                            "source": "$ADDRESS_2",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                            "utxos_info": " $TX_HASH:1 2 ",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            }
        ],
    },
    {
        "title": "mint FAIRMINTA with ADDRESS_3",
        "transaction": "fairmint",
        "source": "$ADDRESS_3",
        "params": {
            "asset": "FAIRMINTA",
            "quantity": 5 * 10**8,
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=CREDIT,DEBIT,ASSET_ISSUANCE,NEW_FAIRMINT",
                "result": [
                    {
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_14",
                        "params": {
                            "address": "$ADDRESS_3",
                            "asset": "FAIRMINTA",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "unescrowed fairmint",
                            "event": "$TX_HASH",
                            "quantity": 500000000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_13",
                        "params": {
                            "address": "$ADDRESS_1",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "fairmint payment",
                            "event": "$TX_HASH",
                            "quantity": 500000000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_12",
                        "params": {
                            "address": "$ADDRESS_2",
                            "asset": "FAIRMINTA",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "unescrowed fairmint",
                            "event": "$FAIRMINTA_MINT_1_TX_HASH",
                            "quantity": 500000000,
                            "tx_index": "$FAIRMINTA_MINT_1_TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_11",
                        "params": {
                            "address": "$ADDRESS_1",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "fairmint payment",
                            "event": "$FAIRMINTA_MINT_1_TX_HASH",
                            "quantity": 500000000,
                            "tx_index": "$FAIRMINTA_MINT_1_TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "DEBIT",
                        "event_index": "$EVENT_INDEX_10",
                        "params": {
                            "action": "unescrowed fairmint payment",
                            "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "event": "$FAIRMINTA_TX_HASH",
                            "quantity": 1000000000,
                            "tx_index": 0,
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "DEBIT",
                        "event_index": "$EVENT_INDEX_9",
                        "params": {
                            "action": "unescrowed fairmint",
                            "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                            "asset": "FAIRMINTA",
                            "block_index": "$BLOCK_INDEX",
                            "event": "$FAIRMINTA_TX_HASH",
                            "quantity": 1000000000,
                            "tx_index": 0,
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": None,
                    },
                    {
                        "event": "ASSET_ISSUANCE",
                        "event_index": "$EVENT_INDEX_7",
                        "params": {
                            "asset": "FAIRMINTA",
                            "asset_longname": None,
                            "asset_events": "fairmint",
                            "block_index": "$BLOCK_INDEX",
                            "call_date": 0,
                            "call_price": 0.0,
                            "callable": False,
                            "description": "",
                            "description_locked": False,
                            "divisible": True,
                            "fair_minting": True,
                            "fee_paid": 0,
                            "issuer": "$ADDRESS_1",
                            "locked": False,
                            "msg_index": 0,
                            "quantity": 500000000,
                            "reset": False,
                            "source": "$ADDRESS_3",
                            "status": "valid",
                            "transfer": False,
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "NEW_FAIRMINT",
                        "event_index": "$EVENT_INDEX_6",
                        "params": {
                            "asset": "FAIRMINTA",
                            "block_index": "$BLOCK_INDEX",
                            "commission": 0,
                            "earn_quantity": 500000000,
                            "fairminter_tx_hash": "$FAIRMINTA_TX_HASH",
                            "paid_quantity": 500000000,
                            "source": "$ADDRESS_3",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_5",
                        "params": {
                            "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                            "asset": "FAIRMINTA",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "escrowed fairmint",
                            "event": "$TX_HASH",
                            "quantity": 500000000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_4",
                        "params": {
                            "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "escrowed fairmint",
                            "event": "$TX_HASH",
                            "quantity": 500000000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "action": "escrowed fairmint",
                            "address": "$ADDRESS_3",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "event": "$TX_HASH",
                            "quantity": 500000000,
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
        "title": "mint FAIRMINTA with ADDRESS_4",
        "transaction": "fairmint",
        "source": "$ADDRESS_4",
        "params": {
            "asset": "FAIRMINTA",
            "quantity": 90 * 10**8,
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=CREDIT,DEBIT,ASSET_ISSUANCE,NEW_FAIRMINT,FAIRMINTER_UPDATE",
                "result": [
                    {
                        "event": "ASSET_ISSUANCE",
                        "event_index": "$EVENT_INDEX_8",
                        "params": {
                            "asset": "FAIRMINTA",
                            "asset_longname": None,
                            "asset_events": "fairmint",
                            "block_index": "$BLOCK_INDEX",
                            "call_date": 0,
                            "call_price": 0.0,
                            "callable": False,
                            "description": "",
                            "description_locked": False,
                            "divisible": True,
                            "fair_minting": False,
                            "fee_paid": 0,
                            "issuer": "$ADDRESS_1",
                            "locked": False,
                            "msg_index": 0,
                            "quantity": 9000000000,
                            "reset": False,
                            "source": "$ADDRESS_4",
                            "status": "valid",
                            "transfer": False,
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "FAIRMINTER_UPDATE",
                        "event_index": "$EVENT_INDEX_7",
                        "params": {"status": "closed", "tx_hash": "$FAIRMINTA_TX_HASH"},
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "NEW_FAIRMINT",
                        "event_index": "$EVENT_INDEX_6",
                        "params": {
                            "asset": "FAIRMINTA",
                            "block_index": "$BLOCK_INDEX",
                            "commission": 0,
                            "earn_quantity": 9000000000,
                            "fairminter_tx_hash": "$FAIRMINTA_TX_HASH",
                            "paid_quantity": 9000000000,
                            "source": "$ADDRESS_4",
                            "status": "valid",
                            "tx_hash": "$TX_HASH",
                            "tx_index": "$TX_INDEX",
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_5",
                        "params": {
                            "address": "$ADDRESS_4",
                            "asset": "FAIRMINTA",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "fairmint",
                            "event": "$TX_HASH",
                            "quantity": 9000000000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "CREDIT",
                        "event_index": "$EVENT_INDEX_4",
                        "params": {
                            "address": "$ADDRESS_1",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "calling_function": "fairmint payment",
                            "event": "$TX_HASH",
                            "quantity": 9000000000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                    {
                        "event": "DEBIT",
                        "event_index": "$EVENT_INDEX_3",
                        "params": {
                            "action": "fairmint payment",
                            "address": "$ADDRESS_4",
                            "asset": "XCP",
                            "block_index": "$BLOCK_INDEX",
                            "event": "$TX_HASH",
                            "quantity": 9000000000,
                            "tx_index": "$TX_INDEX",
                            "utxo": None,
                            "utxo_address": None,
                        },
                        "tx_hash": "$TX_HASH",
                    },
                ],
            },
            {
                "url": "assets/FAIRMINTA",
                "result": {
                    "asset": "FAIRMINTA",
                    "asset_id": "1046814266082",
                    "asset_longname": None,
                    "confirmed": True,
                    "description": "",
                    "description_locked": False,
                    "divisible": True,
                    "first_issuance_block_index": "$FAIRMINTA_BLOCK_INDEX",
                    "issuer": "$ADDRESS_1",
                    "last_issuance_block_index": "$BLOCK_INDEX",
                    "locked": False,
                    "owner": "$ADDRESS_1",
                    "supply": 100 * 10**8,
                },
            },
        ],
    },
]
