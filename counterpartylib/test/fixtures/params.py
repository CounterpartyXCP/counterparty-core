"""
This is a collection of default transaction data used to test various components.
"""

UNIT = 100000000

"""This structure is used throughout the test suite to populate transactions with standardized and tested data."""
DEFAULT_PARAMS = {
    'addresses': [
        ['mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'cPdUqd5EbBWsjcG9xiL1hz8bEyGFiz4SW99maU9JgpL9TEcxUf3j', '0282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0'],
        ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'cQ897jnCVRrawNbw8hgmjMiRNHejwzg4KbzdMCzc91iaTif8ReqX', '0319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977'],
        ['mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH', 'cRNnyC1h5qjv3tHkkt74Y5wowknM1BBDK5Ft2hj5SzfV3mgwPvC3', '0378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b'],
        ['mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj', 'cNNz8RhmTQufdmCKsCYjxPy43J6AxrH1wnAjutrxbeQs7Cy4C9q1', '037af2e06061b54cdfe3657bbc8496d69000b822e2db0c86ccbe376346a700b833']
    ],
    'quantity': UNIT,
    'small': round(UNIT / 2),
    'expiration': 10,
    'fee_required': 900000,
    'fee_provided': 1000000,
    'fee_multiplier': .05,
    'move_random_hash': '6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d',
    'rps_random': '7a4488d61ed8f2e9fa2874113fccb8b1',
    'unspendable': 'mvCounterpartyXXXXXXXXXXXXXXW24Hef',
    'burn_start': 310000,
    'burn_end': 4017708,
    'burn_quantity': int(.62 * UNIT),
    'default_block': 310000 + 501   # Should be called `block_index`.
}
DEFAULT_PARAMS['privkey'] = {addr: priv for (addr, priv, pub) in DEFAULT_PARAMS['addresses']}
DEFAULT_PARAMS['pubkey'] = {addr: pub for (addr, priv, pub) in DEFAULT_PARAMS['addresses']}
ADDR = [a[0] for a in DEFAULT_PARAMS['addresses']]
DP = DEFAULT_PARAMS
MULTISIGADDR = [
    '1_{}_{}_2'.format(ADDR[0], ADDR[1]),
    '1_{}_{}_2'.format(ADDR[2], ADDR[1]),
    '1_{}_{}_2'.format(ADDR[0], ADDR[2]),

    '2_{}_{}_2'.format(ADDR[0], ADDR[1]),
    '2_{}_{}_2'.format(ADDR[2], ADDR[1]),

    '1_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[1]),
    '1_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[3]),

    '2_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[1]),
    '2_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[3]),

    '3_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[1]),
    '3_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[3])
]
