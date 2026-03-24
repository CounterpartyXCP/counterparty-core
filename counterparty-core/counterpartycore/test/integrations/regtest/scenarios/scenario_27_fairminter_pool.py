# Fairminter with pool_quantity.
#
# Test 1 (FAIRPOOLA): soft cap NOT reached -> fairminter closed, XCP refunded, tokens destroyed
# Test 2 (FAIRPOOLB): soft cap reached -> tokens distributed, pool created with pool_quantity + XCP
#
# Config: hard_cap=100, pool_quantity=40, soft_cap=60, price=1 sat per unit (= 1 XCP/token)
# Mintable=60 tokens. Pool gets 60 XCP + 40 tokens -> opens at 1.5 XCP/token.

SCENARIO = [
    # ─── Test 1: Soft cap failure ──────────────────────────────────────
    {
        "title": "Create FAIRPOOLA fairminter with pool_quantity (will fail soft cap)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FAIRPOOLA",
            "lot_price": 1,
            "hard_cap": 100 * 10**8,
            "soft_cap": 60 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 4",
            "pool_quantity": 40 * 10**8,
            "lock_pool_liquidity": True,
            "lock_quantity": True,
        },
        "set_variables": {
            "FAIRPOOLA_TX_HASH": "$TX_HASH",
        },
    },
    {
        "title": "Mint FAIRPOOLA with ADDRESS_2 (10 tokens = 10 XCP, not enough for soft cap)",
        "transaction": "fairmint",
        "source": "$ADDRESS_2",
        "params": {
            "asset": "FAIRPOOLA",
            "quantity": 10 * 10**8,
        },
    },
    {
        "title": "Soft cap deadline: FAIRPOOLA fails (10 < 60), all destroyed and refunded",
        "transaction": "mine_blocks",
        "params": {"blocks": 3},
    },
    # ─── Test 2: Soft cap success + pool creation ──────────────────────
    {
        "title": "Create FAIRPOOLB fairminter with pool_quantity (will succeed)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FAIRPOOLB",
            "lot_price": 1,
            "hard_cap": 100 * 10**8,
            "soft_cap": 60 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 40 * 10**8,
            "lock_pool_liquidity": True,
            "lock_quantity": True,
        },
        "set_variables": {
            "FAIRPOOLB_TX_HASH": "$TX_HASH",
        },
    },
    {
        "title": "Mint FAIRPOOLB with ADDRESS_2 (30 tokens = 30 XCP)",
        "transaction": "fairmint",
        "source": "$ADDRESS_2",
        "params": {
            "asset": "FAIRPOOLB",
            "quantity": 30 * 10**8,
        },
    },
    {
        "title": "Mint FAIRPOOLB with ADDRESS_3 (30 tokens = 30 XCP)",
        "transaction": "fairmint",
        "source": "$ADDRESS_3",
        "params": {
            "asset": "FAIRPOOLB",
            "quantity": 30 * 10**8,
        },
    },
    {
        # Soft cap reached (60 >= 60). At deadline:
        # - 30 FAIRPOOLB tokens credited to ADDRESS_2
        # - 30 FAIRPOOLB tokens credited to ADDRESS_3
        # - Pool created: 40 FAIRPOOLB tokens + 60 XCP
        # - LP tokens credited to UNSPENDABLE (locked)
        "title": "Soft cap deadline: FAIRPOOLB succeeds, pool created",
        "transaction": "mine_blocks",
        "params": {"blocks": 3},
    },
]
