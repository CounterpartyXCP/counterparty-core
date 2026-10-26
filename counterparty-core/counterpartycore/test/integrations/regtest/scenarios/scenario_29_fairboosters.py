# Fairboosters: boosters of trading cards sold for XCP, drawn in the block that
# follows each purchase. The draws depend on the regtest block hashes, so the
# scenario only asserts outcomes that every draw gives: the first booster takes
# the whole two-card deck, and once it is exhausted the only card left is the
# unlimited one. Card asset names are deterministic
# (`assetnames.gen_random_asset_name(<longname>)`).
FIRE_DRAGON_HASH = "c9e1bef304e1c4e33a68dc241d8aa7b0f378de0fc3ea250a09a805dda1a06673"
WATER_ELF_HASH = "ab51d98fabede21b89e12870c51f73670e143fc809c10df462ea69aa6f38760f"
EARTH_GOLEM_HASH = "870e9d3c1ed1520995db7d2fcc150969c90d7535916a433569b0f00e546b3183"


def card_asset(asset, longname, owner, description):
    return {
        "asset": asset,
        "asset_id": asset[1:],
        "asset_longname": longname,
        "issuer": owner,
        "owner": owner,
        "divisible": False,
        "locked": True,
        "supply": 1,
        "description": description,
        "description_locked": True,
        "first_issuance_block_index": "$BLOCK_INDEX",
        "last_issuance_block_index": "$BLOCK_INDEX",
        "mime_type": "text/plain",
    }


SCENARIO = [
    {
        "title": "Create the BOOSTERTEST fairbooster",
        "transaction": "fairbooster",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "BOOSTERTEST",
            "description": "Booster test",
            "image_url": "https://example.com/boostertest.png",
            "price": 1000,
            "max_boosters": 3,
            "cards_per_booster": 2,
            "cards_base_url": "https://example.com/boostertest/",
            "cards_image_extension": ".png",
            "cards": f"1:Fire Dragon:{FIRE_DRAGON_HASH}:3:1, 2:Water Elf:{WATER_ELF_HASH}:1:1",
        },
        "set_variables": {
            "BOOSTERTEST_TX_HASH": "$TX_HASH",
            "BOOSTERTEST_TX_INDEX": "$TX_INDEX",
            "BOOSTERTEST_BLOCK_INDEX": "$BLOCK_INDEX",
        },
        "controls": [
            {
                "url": "fairboosters/BOOSTERTEST",
                "result": {
                    "tx_index": "$TX_INDEX",
                    "tx_hash": "$TX_HASH",
                    "block_index": "$BLOCK_INDEX",
                    "source": "$ADDRESS_1",
                    "asset": "BOOSTERTEST",
                    "description": "Booster test",
                    "image_url": "https://example.com/boostertest.png",
                    "price": 1000,
                    "max_boosters": 3,
                    "cards_per_booster": 2,
                    "cards_base_url": "https://example.com/boostertest/",
                    "cards_image_extension": "png",
                    "card_count": 2,
                    "boosters_sold": 0,
                    "cards_sold": 0,
                    "paid_capacity": 6,
                    # 0.5 XCP for the named asset, and 0.001 XCP for each of
                    # its 6 cards while few cards are sold
                    "fee_paid": 50600000,
                    "status": "open",
                },
            },
            {
                "url": "fairboosters/BOOSTERTEST/cards",
                "result": [
                    {
                        "tx_index": "$TX_INDEX",
                        "tx_hash": "$TX_HASH",
                        "block_index": "$BLOCK_INDEX",
                        "fairbooster": "BOOSTERTEST",
                        "card_id": 1,
                        "name": "Fire Dragon",
                        "image_hash": FIRE_DRAGON_HASH,
                        "weight": 3,
                        "max_supply": 1,
                        "drawn": 0,
                    },
                    {
                        "tx_index": "$TX_INDEX",
                        "tx_hash": "$TX_HASH",
                        "block_index": "$BLOCK_INDEX",
                        "fairbooster": "BOOSTERTEST",
                        "card_id": 2,
                        "name": "Water Elf",
                        "image_hash": WATER_ELF_HASH,
                        "weight": 1,
                        "max_supply": 1,
                        "drawn": 0,
                    },
                ],
            },
            {
                "url": "assets/BOOSTERTEST",
                "result": {
                    "asset": "BOOSTERTEST",
                    "asset_id": "220254223677247",
                    "asset_longname": None,
                    "issuer": "$ADDRESS_1",
                    "owner": "$ADDRESS_1",
                    "divisible": False,
                    "locked": True,
                    "supply": 1,
                    "description": "Booster test",
                    "description_locked": False,
                    "first_issuance_block_index": "$BLOCK_INDEX",
                    "last_issuance_block_index": "$BLOCK_INDEX",
                    "mime_type": "text/plain",
                },
            },
        ],
    },
    {
        "title": "A fairbooster name must be free",
        "transaction": "fairbooster",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "BOOSTERTEST",
            "price": 1,
            "max_boosters": 1,
            "cards_per_booster": 1,
            "cards_base_url": "https://example.com/",
            "cards_image_extension": "png",
            "cards": f"1:Card:{FIRE_DRAGON_HASH}:1:0",
        },
        "expected_error": ["asset `BOOSTERTEST` already exists"],
    },
    {
        "title": "The subassets of a fairbooster are reserved for its cards",
        "transaction": "issuance",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "BOOSTERTEST.1.Fire_Dragon.1",
            "quantity": 1,
            "divisible": False,
        },
        "expected_error": ["subassets of a fairbooster are reserved for its cards"],
    },
    {
        "title": "A purchase states the highest price it pays",
        "transaction": "buybooster",
        "source": "$ADDRESS_2",
        "params": {
            "asset": "BOOSTERTEST",
            "max_price": 999,
        },
        "expected_error": ["the price of a booster (1000) is above `max_price` (999)"],
    },
    {
        "title": "Buy a BOOSTERTEST booster (drawn in the next block)",
        "transaction": "buybooster",
        "source": "$ADDRESS_2",
        "params": {
            "asset": "BOOSTERTEST",
            "max_price": 1000,
            "cards_per_booster": 2,
            "card_count": 2,
        },
        "set_variables": {
            "BOOSTER_1_TX_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "boosters/$TX_HASH",
                "result": {
                    "tx_index": "$TX_INDEX",
                    "tx_hash": "$TX_HASH",
                    "block_index": "$BLOCK_INDEX",
                    "source": "$ADDRESS_2",
                    "fairbooster": "BOOSTERTEST",
                    "paid_quantity": 1000,
                    "card_count": 2,
                    "status": "valid",
                },
            },
            {
                "url": "boosters/$TX_HASH/draws",
                "result": [],
            },
        ],
    },
    {
        "title": "The pending booster reserves the whole deck",
        "transaction": "buybooster",
        "source": "$ADDRESS_2",
        "params": {
            "asset": "BOOSTERTEST",
        },
        "expected_error": ["not enough cards left to fill a booster"],
    },
    {
        "title": "Draw the first booster",
        "transaction": "mine_blocks",
        "params": {"blocks": 1},
        "controls": [
            {
                "url": "assets/BOOSTERTEST.1.Fire_Dragon.1",
                "result": card_asset(
                    "A95428957292183076",
                    "BOOSTERTEST.1.Fire_Dragon.1",
                    "$ADDRESS_2",
                    "https://example.com/boostertest/1.png",
                ),
            },
            {
                "url": "assets/BOOSTERTEST.2.Water_Elf.1",
                "result": card_asset(
                    "A95428960593949307",
                    "BOOSTERTEST.2.Water_Elf.1",
                    "$ADDRESS_2",
                    "https://example.com/boostertest/2.png",
                ),
            },
            {
                "url": "addresses/$ADDRESS_2/balances/A95428957292183076",
                "result": [
                    {
                        "address": "$ADDRESS_2",
                        "asset": "A95428957292183076",
                        "asset_longname": "BOOSTERTEST.1.Fire_Dragon.1",
                        "quantity": 1,
                        "utxo": None,
                        "utxo_address": None,
                    }
                ],
            },
        ],
    },
    {
        "title": "Only new cards can be added to a fairbooster",
        "transaction": "updatefairbooster",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "BOOSTERTEST",
            "cards": f"3:Earth Golem:{WATER_ELF_HASH}:1:0",
        },
        "expected_error": ["card 3: duplicate image_hash"],
    },
    {
        "title": "Add an unlimited card and raise the price and the number of boosters",
        "transaction": "updatefairbooster",
        "source": "$ADDRESS_1",
        "params": {
            "asset": "BOOSTERTEST",
            "price": 2000,
            "max_boosters": 4,
            "cards": f"3:Earth Golem:{EARTH_GOLEM_HASH}:1:0",
        },
        "controls": [
            {
                "url": "fairboosters/BOOSTERTEST",
                "result": {
                    "tx_index": "$BOOSTERTEST_TX_INDEX",
                    "tx_hash": "$BOOSTERTEST_TX_HASH",
                    "block_index": "$BLOCK_INDEX",
                    "source": "$ADDRESS_1",
                    "asset": "BOOSTERTEST",
                    "description": "Booster test",
                    "image_url": "https://example.com/boostertest.png",
                    "price": 2000,
                    "max_boosters": 4,
                    "cards_per_booster": 2,
                    "cards_base_url": "https://example.com/boostertest/",
                    "cards_image_extension": "png",
                    "card_count": 3,
                    "boosters_sold": 1,
                    "cards_sold": 2,
                    "paid_capacity": 8,
                    # and 0.001 XCP for each of the 2 cards added to the capacity
                    "fee_paid": 50800000,
                    "status": "open",
                },
            },
            {
                "url": "fairboosters/BOOSTERTEST/updates",
                "result": [
                    {
                        "tx_index": "$TX_INDEX",
                        "tx_hash": "$TX_HASH",
                        "block_index": "$BLOCK_INDEX",
                        "source": "$ADDRESS_1",
                        "fairbooster": "BOOSTERTEST",
                        "description": None,
                        "image_url": None,
                        "price": 2000,
                        "max_boosters": 4,
                        "cards_per_booster": None,
                        "cards_base_url": None,
                        "cards_image_extension": None,
                        "cards_added": 1,
                        "fee_paid": 200000,
                        "status": "valid",
                    }
                ],
            },
        ],
    },
    {
        "title": "Buy a second booster: only the unlimited card is left",
        "transaction": "buybooster",
        "source": "$ADDRESS_2",
        "params": {
            "asset": "BOOSTERTEST",
        },
        "set_variables": {
            "BOOSTER_2_TX_HASH": "$TX_HASH",
        },
        "controls": [
            {
                "url": "fairboosters/BOOSTERTEST",
                "result": {
                    "tx_index": "$BOOSTERTEST_TX_INDEX",
                    "tx_hash": "$BOOSTERTEST_TX_HASH",
                    "block_index": "$BLOCK_INDEX",
                    "source": "$ADDRESS_1",
                    "asset": "BOOSTERTEST",
                    "description": "Booster test",
                    "image_url": "https://example.com/boostertest.png",
                    "price": 2000,
                    "max_boosters": 4,
                    "cards_per_booster": 2,
                    "cards_base_url": "https://example.com/boostertest/",
                    "cards_image_extension": "png",
                    "card_count": 3,
                    "boosters_sold": 2,
                    "cards_sold": 4,
                    "paid_capacity": 8,
                    "fee_paid": 50800000,
                    "status": "open",
                },
            },
        ],
    },
    {
        "title": "Draw the second booster",
        "transaction": "mine_blocks",
        "params": {"blocks": 1},
        "controls": [
            {
                "url": "assets/BOOSTERTEST.3.Earth_Golem.1",
                "result": card_asset(
                    "A95428959805503794",
                    "BOOSTERTEST.3.Earth_Golem.1",
                    "$ADDRESS_2",
                    "https://example.com/boostertest/3.png",
                ),
            },
            {
                "url": "assets/BOOSTERTEST.3.Earth_Golem.2",
                "result": card_asset(
                    "A95428958542012704",
                    "BOOSTERTEST.3.Earth_Golem.2",
                    "$ADDRESS_2",
                    "https://example.com/boostertest/3.png",
                ),
            },
        ],
    },
]
