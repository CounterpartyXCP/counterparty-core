SCENARIO = [
    # ═══════════════════════════════════════════════════════════════════
    # TEST 1: Fairmint pool success
    # hard_cap=10, pool=4, mintable=6, soft_cap=6
    # lot_price=1, quantity_by_price=1 (1 sat per base unit)
    # ADDRESS_1 mints twice: 3 + 3 tokens (6 XCP total)
    # Total: 6 XCP raised, pool gets 4*10^8 tokens + 6*10^8 XCP
    # ═══════════════════════════════════════════════════════════════════
    {
        "title": "Create FAIRPOOL fairminter with pool_quantity",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FAIRPOOL",
            "lot_price": 1,
            "hard_cap": 10 * 10**8,
            "soft_cap": 6 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 4 * 10**8,
            "lock_quantity": True,
        },
        "set_variables": {
            "FAIRMINTER_POOL_HASH": "$TX_HASH",
            "FAIRMINTER_POOL_TX_INDEX": "$TX_INDEX",
            "POOL_DEADLINE_BLOCK_INDEX": "$BLOCK_INDEX + 2",
        },
    },
    {
        "title": "Mint 3 FAIRPOOL tokens (first mint)",
        "transaction": "fairmint",
        "source": "$ADDRESS_1",
        "params": {"asset": "FAIRPOOL", "quantity": 3 * 10**8},
    },
    {
        "title": "Mint 3 FAIRPOOL tokens (second mint)",
        "transaction": "fairmint",
        "source": "$ADDRESS_1",
        "params": {"asset": "FAIRPOOL", "quantity": 3 * 10**8},
    },
    {
        "title": "Mine to soft cap deadline - pool should be created",
        "transaction": "mine_blocks",
        "params": {"blocks": 3},
        "controls": [
            {
                "url": "pools/FAIRPOOL/XCP",
                "result": {
                    "asset_a": "FAIRPOOL",
                    "asset_b": "XCP",
                    "block_index": "$POOL_DEADLINE_BLOCK_INDEX",
                    "lp_asset": "A95428960030839430",
                    "reserve_a": 400000000,
                    "reserve_b": 600000000,
                    "source": "$ADDRESS_1",
                    "tx_hash": "$FAIRMINTER_POOL_HASH",
                    "tx_index": "$FAIRMINTER_POOL_TX_INDEX",
                },
            },
        ],
    },
    # ═══════════════════════════════════════════════════════════════════
    # TEST 2: Fairmint pool failure (soft_cap not met -> refund)
    # ═══════════════════════════════════════════════════════════════════
    {
        "title": "Create FAIRFAIL fairminter with pool_quantity",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FAIRFAIL",
            "lot_price": 1,
            "hard_cap": 10 * 10**8,
            "soft_cap": 6 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 4 * 10**8,
            "lock_quantity": True,
        },
    },
    {
        "title": "Mint only 2 FAIRFAIL tokens (not enough for soft cap)",
        "transaction": "fairmint",
        "source": "$ADDRESS_1",
        "params": {"asset": "FAIRFAIL", "quantity": 2 * 10**8},
    },
    {
        "title": "Mine to soft cap deadline - should refund, no pool",
        "transaction": "mine_blocks",
        "params": {"blocks": 4},
        "controls": [
            {
                "url": "pools/FAIRFAIL/XCP/deposits",
                "result": [],
            },
        ],
    },
    # ═══════════════════════════════════════════════════════════════════
    # Negative compose tests
    # ═══════════════════════════════════════════════════════════════════
    {
        "title": "Try burn_payment + pool (should be rejected)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FPOOLBURN",
            "lot_price": 1,
            "hard_cap": 10 * 10**8,
            "soft_cap": 6 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 4 * 10**8,
            "burn_payment": True,
        },
        "expected_error": ["pool_quantity is incompatible with burn_payment"],
    },
    {
        "title": "Try free fairminter + pool (should be rejected)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FPOOLFREE",
            "max_mint_per_tx": 10 * 10**8,
            "hard_cap": 10 * 10**8,
            "soft_cap": 6 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 4 * 10**8,
        },
        "expected_error": ["pool_quantity requires price > 0"],
    },
    {
        "title": "Try soft_cap != mintable with pool (should be rejected)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FPOOLBAD",
            "lot_price": 1,
            "hard_cap": 10 * 10**8,
            "soft_cap": 3 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 4 * 10**8,
        },
        "expected_error": [
            "soft_cap must equal mintable supply (hard_cap - existing_supply - premint_quantity - pool_quantity) when pool_quantity > 0"
        ],
    },
]
