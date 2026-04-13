# LOCAL ONLY - not registered in scenarios_test.py
# Edge case exploration for fairminter pool feature.
# To run: temporarily set SCENARIOS = scenario_27_fairminter_pool_explore.SCENARIO
#
# Tests:
# 1. FPOOL01: soft_cap = mintable (all-or-nothing) - the clean XCP-69 case
# 2. FPOOL02: soft_cap < mintable - what happens to post-deadline minting XCP?
# 3. FPOOL03: premint + pool - both coexist
# 4. FPOOL04: commission + pool - commission from each mint
# 5. FPOOL05: tiny pool_quantity (1 token) - extreme ratio
# 6. FPOOL06: pool_quantity almost = mintable - extreme other direction
# 7. FPOOL07: try burn_payment + pool (should be rejected)
# 8. FPOOL08: try pool on free fairminter (should be rejected)
# 9. FPOOL09: try creating pool manually while fairmint active (should be rejected)

SCENARIO = [
    # ═══════════════════════════════════════════════════════════════════
    # TEST 1: All-or-nothing (soft_cap = mintable)
    # hard_cap=100, pool=40, mintable=60, soft_cap=60
    # Expected: 60 XCP raised, pool opens at 60/40 = 1.5x mint
    # ═══════════════════════════════════════════════════════════════════
    {
        "title": "T1: Create FPOOL01 (all-or-nothing, soft_cap=mintable)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FPOOL01",
            "lot_price": 1,
            "hard_cap": 100 * 10**8,
            "soft_cap": 60 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 40 * 10**8,

            "lock_quantity": True,
        },
    },
    {
        "title": "T1: Mint 30 tokens with ADDRESS_2",
        "transaction": "fairmint",
        "source": "$ADDRESS_2",
        "params": {"asset": "FPOOL01", "quantity": 30 * 10**8},
    },
    {
        "title": "T1: Mint 30 tokens with ADDRESS_3",
        "transaction": "fairmint",
        "source": "$ADDRESS_3",
        "params": {"asset": "FPOOL01", "quantity": 30 * 10**8},
    },
    {
        "title": "T1: Soft cap deadline - should create pool",
        "transaction": "mine_blocks",
        "params": {"blocks": 3},
    },
    # ═══════════════════════════════════════════════════════════════════
    # TEST 2: Partial fill (soft_cap < mintable)
    # hard_cap=100, pool=20, mintable=80, soft_cap=40
    # If 40 tokens minted during soft cap: pool gets 40 XCP + 20 tokens
    # If more minted after deadline: that XCP goes to issuer
    # ═══════════════════════════════════════════════════════════════════
    {
        "title": "T2: Create FPOOL02 (soft_cap < mintable)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FPOOL02",
            "lot_price": 1,
            "hard_cap": 100 * 10**8,
            "soft_cap": 40 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 20 * 10**8,

        },
    },
    {
        "title": "T2: Mint 40 tokens with ADDRESS_2 (hits soft cap)",
        "transaction": "fairmint",
        "source": "$ADDRESS_2",
        "params": {"asset": "FPOOL02", "quantity": 40 * 10**8},
    },
    {
        "title": "T2: Soft cap deadline - pool created with 40 XCP + 20 tokens",
        "transaction": "mine_blocks",
        "params": {"blocks": 4},
    },
    # After deadline, try minting more - XCP should go to issuer
    {
        "title": "T2: Post-deadline mint 20 tokens with ADDRESS_3 (XCP to issuer?)",
        "transaction": "fairmint",
        "source": "$ADDRESS_3",
        "params": {"asset": "FPOOL02", "quantity": 20 * 10**8},
    },
    # ═══════════════════════════════════════════════════════════════════
    # TEST 3: Premint + pool
    # hard_cap=100, premint=10, pool=30, mintable=60, soft_cap=60
    # Issuer gets 10 premint, pool gets 30 tokens + 60 XCP
    # ═══════════════════════════════════════════════════════════════════
    {
        "title": "T3: Create FPOOL03 (premint=10 + pool=30)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FPOOL03",
            "lot_price": 1,
            "hard_cap": 100 * 10**8,
            "premint_quantity": 10 * 10**8,
            "soft_cap": 60 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 30 * 10**8,

        },
    },
    {
        "title": "T3: Mint 60 tokens with ADDRESS_2",
        "transaction": "fairmint",
        "source": "$ADDRESS_2",
        "params": {"asset": "FPOOL03", "quantity": 60 * 10**8},
    },
    {
        "title": "T3: Soft cap deadline - premint to issuer, pool created, LP to issuer",
        "transaction": "mine_blocks",
        "params": {"blocks": 4},
    },
    # ═══════════════════════════════════════════════════════════════════
    # TEST 4: Commission + pool
    # hard_cap=100, pool=30, mintable=70, soft_cap=70, commission=10%
    # Each minter loses 10% to issuer commission
    # Pool still gets all XCP + pool_quantity tokens
    # ═══════════════════════════════════════════════════════════════════
    {
        "title": "T4: Create FPOOL04 (10% commission + pool)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FPOOL04",
            "lot_price": 1,
            "hard_cap": 100 * 10**8,
            "soft_cap": 70 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 30 * 10**8,
            "minted_asset_commission": 0.1,

        },
    },
    {
        "title": "T4: Mint 70 tokens with ADDRESS_2 (gets 63, issuer gets 7 commission)",
        "transaction": "fairmint",
        "source": "$ADDRESS_2",
        "params": {"asset": "FPOOL04", "quantity": 70 * 10**8},
    },
    {
        "title": "T4: Soft cap deadline - pool created, commission to issuer",
        "transaction": "mine_blocks",
        "params": {"blocks": 4},
    },
    # ═══════════════════════════════════════════════════════════════════
    # TEST 5: Extreme ratio - tiny pool
    # hard_cap=100, pool=1, mintable=99, soft_cap=99
    # Pool: 1 token + 99 XCP → 99x premium
    # ═══════════════════════════════════════════════════════════════════
    {
        "title": "T5: Create FPOOL05 (tiny pool=1, 99x premium)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FPOOL05",
            "lot_price": 1,
            "hard_cap": 100 * 10**8,
            "soft_cap": 99 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 1 * 10**8,

        },
    },
    {
        "title": "T5: Mint 99 tokens with ADDRESS_2",
        "transaction": "fairmint",
        "source": "$ADDRESS_2",
        "params": {"asset": "FPOOL05", "quantity": 99 * 10**8},
    },
    {
        "title": "T5: Soft cap deadline - pool at 99x premium",
        "transaction": "mine_blocks",
        "params": {"blocks": 4},
    },
    # ═══════════════════════════════════════════════════════════════════
    # TEST 6: Negative - burn_payment + pool (should fail at compose)
    # ═══════════════════════════════════════════════════════════════════
    {
        "title": "T6: Try burn_payment + pool (should be rejected)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FPOOL06",
            "lot_price": 1,
            "hard_cap": 100 * 10**8,
            "soft_cap": 60 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 40 * 10**8,
            "burn_payment": True,
        },
        "expected_error": ["pool_quantity is incompatible with burn_payment"],
    },
    # ═══════════════════════════════════════════════════════════════════
    # TEST 7: Negative - free fairminter + pool (should fail)
    # ═══════════════════════════════════════════════════════════════════
    {
        "title": "T7: Try free fairminter + pool (should be rejected)",
        "transaction": "fairminter",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "FPOOL07",
            "max_mint_per_tx": 10 * 10**8,
            "hard_cap": 100 * 10**8,
            "soft_cap": 60 * 10**8,
            "soft_cap_deadline_block": "$CURRENT_BLOCK + 5",
            "pool_quantity": 40 * 10**8,
        },
        "expected_error": ["pool_quantity requires price > 0"],
    },
]
