SCENARIO = [
    # ── First Deposit: Create XCP/DIVISIBLE Pool ────────────────────────────
    {
        "title": "Create AMM pool with first deposit",
        "transaction": "pooldeposit",
        "source": "$ADDRESS_1",
        "params": {
            "asset_a": "XCP",
            "asset_b": "DIVISIBLE",
            "quantity_a": 100000000,  # 1.0 XCP
            "quantity_b": 100000000,  # 1.0 DIVISIBLE
        },
        "set_variables": {
            "POOL_DEPOSIT_1_HASH": "$TX_HASH",
            "POOL_DEPOSIT_1_BLOCK": "$BLOCK_INDEX",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=OPEN_POOL,NEW_POOL_DEPOSIT,DEBIT,CREDIT,ASSET_CREATION,ASSET_ISSUANCE",
                "result": None,  # populated after first run
            },
        ],
    },
    # ── Verify pool exists via API ──────────────────────────────────────────
    {
        "title": "Get pool info",
        "transaction": None,
        "controls": [
            {
                "url": "pools/DIVISIBLE/XCP",
                "result": None,  # populated after first run
            },
        ],
    },
    # ── Order that matches against pool ─────────────────────────────────────
    {
        "title": "Place order that fills against pool",
        "transaction": "order",
        "source": "$ADDRESS_2",
        "params": {
            "give_asset": "XCP",
            "give_quantity": 10000000,   # 0.1 XCP
            "get_asset": "DIVISIBLE",
            "get_quantity": 9000000,     # min 0.09 DIVISIBLE (allows ~10% slippage)
            "expiration": 21,
            "fee_required": 0,
        },
        "set_variables": {
            "POOL_ORDER_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "orders/$TX_HASH/pool_matches",
                "result": None,  # populated after first run
            },
        ],
    },
    # ── Second LP deposits ──────────────────────────────────────────────────
    {
        "title": "Second LP deposits to existing pool",
        "transaction": "pooldeposit",
        "source": "$ADDRESS_3",
        "params": {
            "asset_a": "XCP",
            "asset_b": "DIVISIBLE",
            "quantity_a": 50000000,   # 0.5 XCP
            "quantity_b": 50000000,   # ratio must match
        },
        "set_variables": {
            "POOL_DEPOSIT_2_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=NEW_POOL_DEPOSIT",
                "result": None,
            },
        ],
    },
    # ── Withdrawal ──────────────────────────────────────────────────────────
    {
        "title": "First LP withdraws half their position",
        "transaction": "poolwithdraw",
        "source": "$ADDRESS_1",
        "params": {
            "asset_a": "XCP",
            "asset_b": "DIVISIBLE",
            "quantity": 25000000,  # half of their LP tokens
        },
        "set_variables": {
            "POOL_WITHDRAW_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "blocks/$BLOCK_INDEX/events?event_name=NEW_POOL_WITHDRAWAL,ASSET_DESTRUCTION",
                "result": None,
            },
        ],
    },
    # ── Verify LP positions ─────────────────────────────────────────────────
    {
        "title": "Check LP positions for ADDRESS_1",
        "transaction": None,
        "controls": [
            {
                "url": "addresses/$ADDRESS_1/pools",
                "result": None,
            },
        ],
    },
    # ── Invalid deposit: BTC pair ───────────────────────────────────────────
    {
        "title": "Reject deposit with BTC pair",
        "transaction": "pooldeposit",
        "source": "$ADDRESS_1",
        "params": {
            "asset_a": "BTC",
            "asset_b": "XCP",
            "quantity_a": 100000000,
            "quantity_b": 100000000,
        },
        "expected_error": "BTC pairs are not supported",
    },
    # ── Invalid deposit: indivisible asset ──────────────────────────────────
    {
        "title": "Reject deposit with indivisible asset",
        "transaction": "pooldeposit",
        "source": "$ADDRESS_1",
        "params": {
            "asset_a": "XCP",
            "asset_b": "NODIVISIBLE",
            "quantity_a": 100000000,
            "quantity_b": 100,
        },
        "expected_error": "not divisible",
    },
]
