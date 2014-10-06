UNIT = 100000000

DEFAULT_PARAMS = {
    'addresses': [
        ['mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'cPdUqd5EbBWsjcG9xiL1hz8bEyGFiz4SW99maU9JgpL9TEcxUf3j'],
        ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'cQ897jnCVRrawNbw8hgmjMiRNHejwzg4KbzdMCzc91iaTif8ReqX'],
        ['mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH', 'cRNnyC1h5qjv3tHkkt74Y5wowknM1BBDK5Ft2hj5SzfV3mgwPvC3']
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
    'burn_start': 154908,
    'burn_end': 4017708,
    'burn_quantity': int(.62 * UNIT)
}
DEFAULT_PARAMS['privkey'] = {addr: priv for (addr, priv) in DEFAULT_PARAMS['addresses']}
ADDR = [a[0] for a in DEFAULT_PARAMS['addresses']]
DP = DEFAULT_PARAMS
MULTISIGADDR = [
    '1_{}_{}_2'.format(ADDR[0], ADDR[1]),
    '1_{}_{}_2'.format(ADDR[2], ADDR[1]),
    '1_{}_{}_2'.format(ADDR[0], ADDR[2])
]
