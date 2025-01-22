"""
This is a collection of default transaction data used to test various components.
"""

UNIT = 100000000

"""This structure is used throughout the test suite to populate transactions with standardized and tested data."""

DEFAULT_PARAMS = {
    "quantity": UNIT,
    "small": round(UNIT / 2),
    "expiration": 10,
    "fee_required": 900000,
    "fee_provided": 1000000,
    "fee_multiplier": 0.05,
    "unspendable": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
    "burn_start": 310000,
    "burn_end": 4017708,
    "burn_quantity": int(0.62 * UNIT),
    "burn_verysmall_quantity": int(0.0001 * UNIT),
    "regular_dust_size": 5430,  # This was the default value used in a lot of tests historically
}


ADDRESSES = [
    [
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "4838d8b3588c4c7ba7c1d06f866e9b3739c63037",
        "cPdUqd5EbBWsjcG9xiL1hz8bEyGFiz4SW99maU9JgpL9TEcxUf3j",
        "0282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0",
    ],
    [
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec",
        "cQ897jnCVRrawNbw8hgmjMiRNHejwzg4KbzdMCzc91iaTif8ReqX",
        "0319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977",
    ],
    [
        "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
        "4e5638a01efbb2f292481797ae1dcfcdaeb98d00",
        "cRNnyC1h5qjv3tHkkt74Y5wowknM1BBDK5Ft2hj5SzfV3mgwPvC3",
        "0378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b",
    ],
    [
        "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
        "6c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a152",
        "cNNz8RhmTQufdmCKsCYjxPy43J6AxrH1wnAjutrxbeQs7Cy4C9q1",
        "037af2e06061b54cdfe3657bbc8496d69000b822e2db0c86ccbe376346a700b833",
    ],
    [
        "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM",
        "c1a6de504b9bc0d0d6987312b2e37564079791b7",
        "cPEo2oY8z3Fe9dDcFmzA7Wr1LjFh7iVQkCgBoXZEvQ8X6T2kfAHk",
        "02610f28a56e187f5cd133d7bfe107b159fa3b5129ba35e91fb915fe9a8efa43b4",
    ],
    [
        "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
        "9c8d1f5405451de6070bf1db86ab6accb495b625",
        "cNGEvSnRJ4wqdKWrni3fcX9wKTHXJt1gmoBUTrfqNrtKVZCnTUR2",
        "025bc8fb22d87eb72fb5e297803ab9aa3ace5bf38df4e23918b876fd3ea0cdd7b8",
    ],
    [
        "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
        "b390187ef2854422ac5e4a2eb6ffe92496bef523",
        "cQiFxpxU2twNfViTqv3Tp3nY6H6Wd2YnypKjJFCkuim8YY3iQo2B",
        "03c403a9364dcb223cc32df5a4afab6089e941590cecfd5ac823c4fcff46e8f6c5",
    ],
    ["mv4rnyY3Su5gjcDNzbMLKBQkBicCtHUtFB", "", "", ""],  # Empty address for testing purposes
    [
        "mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK",
        "",
        "cSrcqM6oaUxhYo48ejQJbtRYLeyAMe6p44Fdoc91KtpYHiBG9hWd",
        "033ae8ae93bca8a08043768879a623b05f352a64cd64e1b8de4291c4cc52778936",
    ],
]

DEFAULT_PARAMS["addresses"] = [a[0] for a in ADDRESSES]

DEFAULT_PARAMS["short_address_bytes"] = ["6f" + a[1] for a in ADDRESSES]

DEFAULT_PARAMS["p2ms_addresses"] = [
    f"1_{DEFAULT_PARAMS['addresses'][0]}_{DEFAULT_PARAMS['addresses'][1]}_2",
    f"1_{DEFAULT_PARAMS['addresses'][2]}_{DEFAULT_PARAMS['addresses'][1]}_2",
    f"1_{DEFAULT_PARAMS['addresses'][0]}_{DEFAULT_PARAMS['addresses'][2]}_2",
    f"2_{DEFAULT_PARAMS['addresses'][0]}_{DEFAULT_PARAMS['addresses'][1]}_2",
    f"2_{DEFAULT_PARAMS['addresses'][2]}_{DEFAULT_PARAMS['addresses'][1]}_2",
    f"1_{DEFAULT_PARAMS['addresses'][0]}_{DEFAULT_PARAMS['addresses'][2]}_{DEFAULT_PARAMS['addresses'][1]}_3",
    f"1_{DEFAULT_PARAMS['addresses'][0]}_{DEFAULT_PARAMS['addresses'][2]}_{DEFAULT_PARAMS['addresses'][3]}_3",
    f"2_{DEFAULT_PARAMS['addresses'][0]}_{DEFAULT_PARAMS['addresses'][2]}_{DEFAULT_PARAMS['addresses'][1]}_3",
    f"2_{DEFAULT_PARAMS['addresses'][0]}_{DEFAULT_PARAMS['addresses'][2]}_{DEFAULT_PARAMS['addresses'][3]}_3",
    f"3_{DEFAULT_PARAMS['addresses'][0]}_{DEFAULT_PARAMS['addresses'][2]}_{DEFAULT_PARAMS['addresses'][1]}_3",
    f"3_{DEFAULT_PARAMS['addresses'][0]}_{DEFAULT_PARAMS['addresses'][2]}_{DEFAULT_PARAMS['addresses'][3]}_3",
]

DEFAULT_PARAMS["p2sh_addresses"] = [
    "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",  # 2of2 mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns
    "2N6P6d3iypnnud4YJDfHZ6kc513N8ezWmPx",  # 2of3 mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH
]

DEFAULT_PARAMS["p2wpkh_address"] = ["bcrt1qfaw3f6ryl9jn4f5l0x7qdccxyl82snmwkrcfh9"]

DEFAULT_PARAMS["privkey"] = {addr: priv for (addr, pubkeyhash, priv, pub) in ADDRESSES}
DEFAULT_PARAMS["pubkey"] = {addr: pub for (addr, pubkeyhash, priv, pub) in ADDRESSES}
DEFAULT_PARAMS["pubkey"]["2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy"] = (
    "0282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0"
)
DEFAULT_PARAMS["pubkey"]["2N6P6d3iypnnud4YJDfHZ6kc513N8ezWmPx"] = (
    "0282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0"
)
DEFAULT_PARAMS["privkey"]["bcrt1qfaw3f6ryl9jn4f5l0x7qdccxyl82snmwkrcfh9"] = (
    "fff4e9f45244db7694296879d9ffbf03758104f0d614aac252a8d7b5eca3427d"
)
DEFAULT_PARAMS["pubkey"]["bcrt1qfaw3f6ryl9jn4f5l0x7qdccxyl82snmwkrcfh9"] = (
    "02653194070e7b2fb47eda68d0412341c5a88cddc7f7635929bb1d6996264fd4fd"
)
