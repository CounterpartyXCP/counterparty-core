#! /usr/bin/python3

#TODO: transform this file to json
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
DEFAULT_PARAMS['privkey'] = {ad: pr for (ad, pr) in DEFAULT_PARAMS['addresses']}
ADDR = [a[0] for a in DEFAULT_PARAMS['addresses']]
DP = DEFAULT_PARAMS

UNITEST_FIXTURE = [
    ['burn', (ADDR[0], DP['burn_quantity']), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'DIVISIBLE', DP['quantity'] * 1000, True, False, None, None, 'Divisible asset'), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'NODIVISIBLE', 1000, False, False, None, None, 'No divisible asset'), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'CALLABLE', 1000, True, True, 1409400251, DP['quantity'], 'Callable asset'), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'LOCKED', 1000, True, False, None, None, 'Locked asset'), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'LOCKED', 0, True, False, None, None, 'LOCK'), {'encoding': 'multisig'}],
    ['order', (ADDR[0], 'XCP', DP['quantity'], 'DIVISIBLE', DP['quantity'], 2000, 0), {'encoding': 'multisig'}],
    ['send', (ADDR[0], ADDR[1], 'DIVISIBLE', DP['quantity']), {'encoding': 'multisig'}],
    ['send', (ADDR[0], ADDR[1], 'XCP', DP['quantity']), {'encoding': 'multisig'}],
    ['order', (ADDR[0], 'XCP', DP['quantity'], 'DIVISIBLE', DP['quantity'], 2000, 0), {'encoding': 'multisig'}],
    ['order', (ADDR[0], 'XCP', DP['quantity'], 'BTC', round(DP['quantity'] / 100), 2000, DP['fee_required']), {'encoding': 'multisig'}],
    ['order', (ADDR[0], 'BTC', round(DP['quantity'] / 150), 'XCP', DP['quantity'], 2000, 0), {'encoding': 'multisig', 'fee_provided': DP['fee_provided']}],
    ['create_next_block', 490],
    ['order', (ADDR[0], 'XCP', DP['quantity'], 'BTC', round(DP['quantity'] / 125), 2000, DP['fee_required']), {'encoding': 'multisig'}],
    ['order', (ADDR[1], 'BTC', round(DP['quantity'] / 125), 'XCP', DP['quantity'], 2000, 0), {'encoding': 'multisig', 'fee_provided': DP['fee_provided']}],
    ['create_next_block', 500]
]

UNITTEST_VECTOR = {
    'burn': {
        'validate': [{
            'in': (ADDR[0], DP['unspendable'], DP['burn_quantity'], DP['burn_start']),
            'out': ([])
        }, {
            'in': (ADDR[0], DP['unspendable'], 1.1 * DP['burn_quantity'], DP['burn_start']),
            'out': (['quantity must be in satoshis'])
        }, {
            'in': (ADDR[0], ADDR[1], DP['burn_quantity'], DP['burn_start']),
            'out': (['wrong destination address'])
        }, {
            'in': (ADDR[0], DP['unspendable'], -1 * DP['burn_quantity'], DP['burn_start']),
            'out': (['negative quantity'])
        }, {
            'in': (ADDR[0], DP['unspendable'], DP['burn_quantity'], DP['burn_start'] - 2),
            'out': (['too early'])
        }, {
            'in': (ADDR[0], DP['unspendable'], DP['burn_quantity'], DP['burn_end'] + 1),
            'out': (['too late'])
        }, {
            'in': (ADDR[0], ADDR[1], 1.1 * DP['burn_quantity'], DP['burn_start'] - 2),
            'out': (['wrong destination address', 'quantity must be in satoshis'])
        }, {
            'in': (ADDR[0], ADDR[1], DP['burn_quantity'], DP['burn_start'] - 2),
            'out': (['wrong destination address', 'too early'])
        }],
        'compose': [{
            'in': (ADDR[1], DP['burn_quantity']),
            'out': ('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 62000000)], None)
        }, {
            'in': (ADDR[0], DP['burn_quantity']),
            'error': ('BurnError', '1 BTC may be burned per address')
        }],
        'parse': [{
            'in': ({'block_index': 155409, 'destination': 'mvCounterpartyXXXXXXXXXXXXXXW24Hef', 'fee': 10000, 'block_time': 1554090000000, 'supported': 1, 'btc_amount': 62000000, 'data': b'', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_index': 502, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'burns', 'values': {'tx_index': 502, 'earned': 92995979341, 'burned': 62000000, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'status': 'valid', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 155409}},
                {'table': 'credits', 'values': {'block_index': 155409, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'asset': 'XCP', 'calling_function': 'burn', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 92995979341}}
            ]
        }]
    },
    'send': {
        'validate': [{
            'in': (ADDR[0], ADDR[1], 'XCP', DP['quantity']),
            'out': ([])
        }, {
            'in': (ADDR[0], ADDR[1], 'BTC', DP['quantity']),
            'out': (['cannot send bitcoins'])
        }, {
            'in': (ADDR[0], ADDR[1], 'XCP', DP['quantity'] / 3),
            'out': (['quantity must be in satoshis'])
        }, {
            'in': (ADDR[0], ADDR[1], 'XCP', -1 * DP['quantity']),
            'out': (['negative quantity'])
        }],
        'compose': [{
            'in': (ADDR[0], ADDR[1], 'XCP', DP['small']),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80')
        }, {
            'in': (ADDR[0], ADDR[1], 'XCP', DP['quantity'] * 10000000),
            'error': ('SendError', 'insufficient funds')
        }, {
            'in': (ADDR[0], ADDR[1], 'XCP', DP['quantity'] / 3),
            'error': ('SendError', 'quantity must be an int (in satoshi)')
        }],
        'parse': [{
            'in': ({'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'supported': 1, 'block_index': 155409, 'fee': 10000, 'block_time': 1554090000000, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': 7800, 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00', 'tx_index': 502, 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'},),
            'records': [
                {'table': 'sends', 'values': {'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': 155409, 'status': 'valid', 'asset': 'XCP', 'quantity': 100000000, 'tx_index': 502, 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'}},
                {'table': 'credits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 155409, 'calling_function': 'send', 'asset': 'XCP', 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'quantity': 100000000}},
                {'table': 'debits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 155409, 'asset': 'XCP', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'action': 'send', 'quantity': 100000000}}
            ]
        }, {
            'in': ({'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': 7800, 'block_index': 155409, 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x0b\xeb\xc2\x00', 'block_time': 1554090000000, 'fee': 10000, 'source': 'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH', 'tx_index': 502, 'supported': 1},),
            'records': [
                {'table': 'sends', 'values': {'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 200000000, 'block_index': 155409, 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'asset': 'XCP', 'source': 'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH', 'tx_index': 502, 'status': 'invalid: insufficient funds'}}
            ]
        }, {
            'in': ({'block_index': 155409, 'btc_amount': 7800, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_time': 1554090000000, 'fee': 10000, 'tx_index': 502, 'data': b'\x00\x00\x00\x00\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x01\xf4', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'supported': 1},),
            'records': [
                {'table': 'sends', 'values': {'block_index': 155409, 'quantity': 500, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx_index': 502, 'asset': 'NODIVISIBLE', 'status': 'valid', 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'}},
                {'table': 'credits', 'values': {'block_index': 155409, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'calling_function': 'send', 'quantity': 500, 'asset': 'NODIVISIBLE'}},
                {'table': 'debits', 'values': {'block_index': 155409, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'action': 'send', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 500, 'asset': 'NODIVISIBLE'}}
            ]
        }]
    },
    'issuance': {
        'validate': [{
            'in': (ADDR[0], None, 'ASSET', 1000, True, False, None, None, '', 1),
            'out': (0, 0.0, [], 50000000)
        }, {
            'in': (ADDR[0], None, 'BTC', 1000, True, False, None, None, '', 1),
            'out': (0, 0.0, ['cannot issue BTC or XCP'], 50000000)
        },{
            'in': (ADDR[0], None, 'XCP', 1000, True, False, None, None, '', 1),
            'out': (0, 0.0, ['cannot issue BTC or XCP'], 50000000)
        },{
            'in': (ADDR[0], None, 'NOSATOSHI', 1000.5, True, False, None, None, '', 1),
            'out': (0, 0.0, ['quantity must be in satoshis'], 0)
        },{
            'in': (ADDR[0], None, 'INVALIDCALLDATE', 1000, True, True, 10000.5, DP['quantity'], '', 1),
            'out': (10000.5, 100000000.0, ['call_date must be epoch integer'], 0)
        },{
            'in': (ADDR[0], None, 'INVALIDCALLPRICE', 1000, True, True, 1409401723, 'price', '', 1),
            'out': (1409401723, 'price', ['call_price must be a float'], 0)
        },{
            'in': (ADDR[0], None, 'NEGATIVEVALUES', -1000, True, True, -1409401723, -DP['quantity'], '', 1),
            'out': (-1409401723, -100000000.0, ['negative quantity', 'negative call price', 'negative call date'], 50000000)
        },{
            'in': (ADDR[2], None, 'DIVISIBLE', 1000, True, False, None, None, 'Divisible asset', 1),
            'out': (0, 0.0, ['issued by another address', 'insufficient funds'], 50000000)
        },{
            'in': (ADDR[0], None, 'DIVISIBLE', 1000, False, True, 1409401723, DP['quantity'], 'Divisible asset', 1),
            'out': (1409401723, 100000000.0, ['cannot change divisibility', 'cannot change callability'], 50000000)
        },{
            'in': (ADDR[0], None, 'CALLABLE', 1000, True, True, 1409400251, DP['quantity'] / 2, 'Callable asset', 1),
            'out': (1409400251, 50000000.0, ['cannot reduce call price'], 50000000)
        },{
            'in': (ADDR[0], None, 'LOCKED', 1000, True, False, None, None, 'Locked asset', 1),
            'out': (0, 0.0, ['locked asset and non‐zero quantity'], 50000000)
        },{
            'in': (ADDR[0], None, 'BSSET', 1000, True, False, None, None, 'LOCK', 1),
            'out': (0, 0.0, ['cannot lock a non‐existent asset'], 50000000)
        },{
            'in': (ADDR[0], ADDR[1], 'BSSET', 1000, True, False, None, None, '', 1),
            'out': (0, 0.0, ['cannot transfer a non‐existent asset', 'cannot issue and transfer simultaneously'], 50000000)
        },{
            'in': (ADDR[2], None, 'BSSET', 1000, True, False, None, None, '', 1),
            'out': (0, 0.0, ['insufficient funds'], 50000000)
        },{
            'in': (ADDR[0], None, 'BSSET', 2**63, True, False, None, None, '', 1),
            'out': (0, 0.0, ['total quantity overflow'], 50000000)
        },{
            'in': (ADDR[0], ADDR[1], 'DIVISIBLE', 1000, True, False, None, None, 'Divisible asset', 1),
            'out': (0, 0.0, ['cannot issue and transfer simultaneously'], 50000000)
        }],
        'compose': [{
            'in': (ADDR[0], None, 'ASSET', 1000, True, False, None, None, ''),
            'error': ('AssetNameError', 'starts with ‘A’')
        }, {
            'in': (ADDR[0], None, 'BSSET1', 1000, True, False, None, None, ''),
            'error': ('AssetNameError', "('invalid character:', '1')")
        }, {
            'in': (ADDR[0], None, 'SET', 1000, True, False, None, None, ''),
            'error': ('AssetNameError', 'too short')
        }, {
            'in': (ADDR[0], None, 'BSSET', 1000, True, False, None, None, ''),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'TESTXXXX\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (ADDR[0], ADDR[1], 'DIVISIBLE', 0, True, False, None, None, ''),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'TESTXXXX\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        }],
        'parse': [{
            'in': ({'supported': 1, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'data': b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\xbaOs\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00', 'btc_amount': None, 'destination': None, 'block_time': 1554090000000, 'block_index': 155409, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'fee': 10000, 'tx_index': 502, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'issuances', 'values': {'locked': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'call_price': 0.0, 'description': '', 'divisible': 1, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'asset': 'BASSET', 'issuer': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'call_date': 0, 'callable': 0, 'status': 'valid', 'tx_index': 502, 'fee_paid': 50000000, 'block_index': 155409, 'transfer': 0, 'quantity': 1000}},
                {'table': 'credits', 'values': {'calling_function': 'issuance', 'block_index': 155409, 'asset': 'BASSET', 'quantity': 1000, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d'}},
                {'table': 'debits', 'values': {'block_index': 155409, 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'quantity': 50000000, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'action': 'issuance fee'}}
            ]
        }, {
            'in': ({'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_time': 1554090000000, 'btc_amount': 7800, 'supported': 1, 'tx_index': 502, 'block_index': 155409, 'data': b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'fee': 10000, 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'},),
            'records': [
                {'table': 'issuances', 'values': {'locked': 0, 'call_date': 0, 'block_index': 155409, 'description': '', 'quantity': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'DIVISIBLE', 'callable': 0, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'fee_paid': 50000000, 'issuer': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_index': 502, 'transfer': 1, 'call_price': 0.0, 'divisible': 1, 'status': 'valid'}}
            ]
        }, {
            'in': ({'tx_index': 502, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'data': b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04LOCK', 'block_time': 1554090000000, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'fee': 10000, 'destination': None, 'supported': 1, 'block_index': 155409, 'btc_amount': None},),
            'records': [
                {'table': 'issuances', 'values': {'tx_index': 502, 'quantity': 0, 'block_index': 155409, 'callable': 0, 'status': 'valid', 'locked': 1, 'description': 'Divisible asset', 'divisible': 1, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'transfer': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'call_price': 0.0, 'issuer': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'call_date': 0, 'fee_paid': 50000000, 'asset': 'DIVISIBLE'}}
            ]
        }]
    },
    'order': {
        'validate': [{
            'in': (ADDR[0], 'DIVISIBLE', DP['quantity'], 'XCP', DP['quantity'], 2000, 0, 1),
            'out': ([])
        }, {
            'in': (ADDR[0], 'BTC', DP['quantity'], 'BTC', DP['quantity'], 2000, 0, 1),
            'out': (['cannot trade BTC for itself'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', DP['quantity'] / 3, 'XCP', DP['quantity'], 2000, 0, 1),
            'out': (['give_quantity must be in satoshis'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', DP['quantity'], 'XCP', DP['quantity'] / 3, 2000, 0, 1),
            'out': (['get_quantity must be in satoshis'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', DP['quantity'], 'XCP', DP['quantity'], 1.5, 0, 1),
            'out': (['expiration must be expressed as an integer block delta'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', -DP['quantity'], 'XCP', -DP['quantity'], -2000, -10000, 1),
            'out': (['non‐positive give quantity', 'non‐positive get quantity', 'negative fee_required', 'negative expiration'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', 0, 'XCP', DP['quantity'], 2000, 0, 1),
            'out': (['non‐positive give quantity', 'zero give or zero get'])
        },{
            'in': (ADDR[0], 'NOASSETA', DP['quantity'], 'NOASSETB', DP['quantity'], 2000, 0, 1),
            'out': (['no such asset to give (NOASSETA)', 'no such asset to get (NOASSETB)'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', 2**63 + 10, 'XCP', DP['quantity'], 4 * 2016 + 10, 0, 1),
            'out': (['expiration overflow', 'integer overflow'])
        }],
        'compose': [{
            'in': (ADDR[0], 'BTC', DP['small'], 'XCP', DP['small'] * 2, DP['expiration'], 0),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'TESTXXXX\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (ADDR[0], 'XCP', round(DP['small'] * 2.1), 'BTC', DP['small'], DP['expiration'], DP['fee_required']),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'TESTXXXX\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0')
        }],
        'parse': [{
            'in': ({'destination': None, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'block_time': 1554090000000, 'block_index': 155409, 'tx_index': 502, 'data': b'\x00\x00\x00\n\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'fee': 10000, 'btc_amount': None, 'supported': 1, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'orders', 'values': {'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'fee_required_remaining': 0, 'block_index': 155409, 'status': 'filled', 'get_quantity': 100000000, 'fee_provided_remaining': 10000, 'get_asset': 'XCP', 'give_remaining': 0, 'fee_provided': 10000, 'expiration': 2000, 'get_remaining': 0, 'tx_index': 502, 'give_asset': 'DIVISIBLE', 'expire_index': 157409, 'give_quantity': 100000000, 'fee_required': 0}},
                {'table': 'order_matches', 'values': {'status': 'completed', 'tx0_index': 7, 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'forward_quantity': 100000000, 'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'backward_asset': 'DIVISIBLE', 'tx0_hash': 'ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879', 'tx0_expiration': 2000, 'id': 'ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx1_expiration': 2000, 'tx1_block_index': 155409, 'forward_asset': 'XCP', 'fee_paid': 0, 'match_expire_index': 155429, 'tx0_block_index': 154914, 'backward_quantity': 100000000, 'tx1_index': 502, 'block_index': 155409}},
                {'table': 'credits', 'values': {'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'calling_function': 'filled', 'block_index': 155409, 'quantity': 0, 'asset': 'XCP', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d'}},
                {'table': 'debits', 'values': {'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 155409, 'quantity': 100000000, 'asset': 'DIVISIBLE', 'action': 'open order'}},
                {'table': 'credits', 'values': {'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'calling_function': 'order match', 'block_index': 155409, 'quantity': 100000000, 'asset': 'XCP', 'event': 'ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d'}},
                {'table': 'credits', 'values': {'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'calling_function': 'order match', 'block_index': 155409, 'quantity': 100000000, 'asset': 'DIVISIBLE', 'event': 'ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d'}}
            ]
        }, {
            'in': ({'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': None, 'tx_index': 502, 'supported': 1, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'fee': 10000, 'block_time': 1554090000000, 'block_index': 155409, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0fB@\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'destination': None},),
            'records': [
                {'table': 'orders', 'values': {'give_quantity': 1000000, 'status': 'open', 'get_remaining': 0, 'tx_index': 502, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'give_remaining': 0, 'block_index': 155409, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'fee_required': 0, 'fee_provided': 10000, 'give_asset': 'BTC', 'get_asset': 'XCP', 'fee_provided_remaining': 1000, 'expiration': 2000, 'expire_index': 157409, 'fee_required_remaining': 0, 'get_quantity': 100000000}},
                {'table': 'order_matches', 'values': {'status': 'pending', 'match_expire_index': 155429, 'forward_quantity': 100000000, 'tx1_block_index': 155409, 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx0_expiration': 2000, 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 155409, 'tx1_index': 502, 'tx0_index': 11, 'backward_asset': 'BTC', 'backward_quantity': 1000000, 'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'forward_asset': 'XCP', 'tx0_block_index': 154918, 'id': 'e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx0_hash': 'e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6', 'fee_paid': 9000, 'tx1_expiration': 2000}}
            ]
        }, {
            'in': ({'fee': 10000, 'block_time': 1554090000000, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'destination': None, 'supported': 1, 'tx_index': 502, 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\n,+\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': None, 'block_index': 155409},),
            'records': [
                {'table': 'orders', 'values': {'fee_required_remaining': 0, 'expire_index': 157409, 'status': 'open', 'expiration': 2000, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'get_remaining': 0, 'give_remaining': 0, 'get_quantity': 666667, 'fee_required': 0, 'fee_provided_remaining': 10000, 'fee_provided': 10000, 'block_index': 155409, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'give_quantity': 100000000, 'tx_index': 502, 'give_asset': 'XCP', 'get_asset': 'BTC'}},
                {'table': 'order_matches', 'values': {'tx0_expiration': 2000, 'tx1_index': 502, 'backward_asset': 'XCP', 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx1_expiration': 2000, 'forward_asset': 'BTC', 'forward_quantity': 666667, 'fee_paid': 0, 'tx0_hash': 'ef6cbd2161eaea7943ce8693b9824d23d1793ffb1c0fca05b600d3899b44c977', 'tx1_block_index': 155409, 'id': 'ef6cbd2161eaea7943ce8693b9824d23d1793ffb1c0fca05b600d3899b44c977db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx0_block_index': 154919, 'backward_quantity': 100000000, 'match_expire_index': 155429, 'tx0_index': 12, 'status': 'pending', 'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'block_index': 155409, 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d'}},
                {'table': 'debits', 'values': {'action': 'open order', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'block_index': 155409, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'quantity': 100000000}}
            ]
        }, {
            'in': ({'block_time': 1554090000000, 'destination': None, 'btc_amount': None, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x1e\x84\x80\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'supported': 1, 'fee': 10000, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_index': 502, 'block_index': 155409, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'orders', 'values': {'fee_provided_remaining': 10000, 'get_asset': 'BTC', 'give_remaining': 100000000, 'get_remaining': 2000000, 'get_quantity': 2000000, 'give_asset': 'XCP', 'block_index': 155409, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'expiration': 2000, 'expire_index': 157409, 'tx_index': 502, 'status': 'open', 'give_quantity': 100000000, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'fee_required_remaining': 0, 'fee_provided': 10000, 'fee_required': 0}},
                {'table': 'debits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'quantity': 100000000, 'action': 'open order', 'asset': 'XCP', 'block_index': 155409}}
            ]
        }, {
            'in': ({'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07\xa1 \x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'tx_index': 502, 'destination': None, 'block_index': 155409, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'btc_amount': None, 'block_time': 1554090000000, 'supported': 1, 'fee': 1000000, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'},),
            'records': [
                {'table': 'orders', 'values': {'block_index': 155409, 'fee_required_remaining': 0, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'give_remaining': 500000, 'expiration': 2000, 'give_quantity': 500000, 'get_asset': 'XCP', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'fee_provided_remaining': 1000000, 'tx_index': 502, 'fee_required': 0, 'give_asset': 'BTC', 'expire_index': 157409, 'get_remaining': 100000000, 'fee_provided': 1000000, 'get_quantity': 100000000, 'status': 'open'}}
            ]
        }, {
            'in': ({'btc_amount': None, 'block_time': 1554090000000, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx_index': 502, 'supported': 1, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'destination': None, 'block_index': 155409, 'data': b'\x00\x00\x00\n\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x01\xf4\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'fee': 10000},),
            'records': [
                {'table': 'orders', 'values': {'fee_required_remaining': 0, 'fee_provided_remaining': 10000, 'block_index': 155409, 'give_remaining': 500, 'status': 'open', 'fee_required': 0, 'fee_provided': 10000, 'expiration': 2000, 'give_quantity': 500, 'get_asset': 'XCP', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx_index': 502, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'get_remaining': 100000000, 'get_quantity': 100000000, 'give_asset': 'NODIVISIBLE', 'expire_index': 157409}},
                {'table': 'debits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': 155409, 'quantity': 500, 'action': 'open order', 'asset': 'NODIVISIBLE'}}
            ]
        }]
    },
    'bitcoin': {
        'transaction': [{
            'comment': 'burn',
            'in': (('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 62000000)], None), {'encoding': 'multisig'}),
            'out': '0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac70ae4302000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000'            
        }, {
            'comment': 'send',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0211c54455354585858580000000000000000000000010000000002faf0800000000052ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'issuance',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'TESTXXXX\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0212054455354585858580000001400000000000bfce300000000000003e80100000052ae781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02107000000000000000000000000000000000000000000000000000000000000000052ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'issuance',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'TESTXXXX\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff04781e0000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02120544553545858585800000014000000a25be34b6600000000000000000100000052ae781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02107000000000000000000000000000000000000000000000000000000000000000052ae9cdce90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'order',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'TESTXXXX\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig','fee_provided': DP['fee_provided']}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0212054455354585858580000000a00000000000000000000000002faf0800000000052ae781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02116000000010000000005f5e100000a00000000000000000000000000000000000052aee4dfda0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'order',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'TESTXXXX\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0212054455354585858580000000a00000000000000010000000006422c400000000052ae781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02116000000000000000002faf080000a00000000000dbba00000000000000000000052ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }]
    },
    'util': {
        'api': [{
            'in': ('create_burn', {'source': ADDR[1], 'quantity': DP['burn_quantity']}),
            'out': '0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac70ae4302000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000'            
        }, {
            'in': ('create_send', {'source': ADDR[0], 'destination': ADDR[1], 'asset': 'XCP', 'quantity': DP['quantity']}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0211c54455354585858580000000000000000000000010000000005f5e1000000000052ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'           
        }, {
            'in': ('create_issuance', {'source': ADDR[0], 'transfer_destination': None, 'asset': 'BSSET', 'quantity': 1000, 'divisible': True, 'callable': False, 'call_date':  None, 'call_price': None, 'description': ''}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0212054455354585858580000001400000000000bfce300000000000003e80100000052ae781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02107000000000000000000000000000000000000000000000000000000000000000052ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'           
        }, {
            'in': ('create_issuance', {'source': ADDR[0], 'transfer_destination': ADDR[1], 'asset': 'DIVISIBLE', 'quantity': 0, 'divisible': True, 'callable': False, 'call_date': None, 'call_price': None, 'description': ''}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff04781e0000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02120544553545858585800000014000000a25be34b6600000000000000000100000052ae781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02107000000000000000000000000000000000000000000000000000000000000000052ae9cdce90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'           
        }, {
            'in': ('create_order', {'source': ADDR[0], 'give_asset': 'BTC', 'give_quantity': DP['small'], 'get_asset': 'XCP', 'get_quantity': DP['small'] * 2, 'expiration': DP['expiration'], 'fee_required': 0, 'fee_provided': DP['fee_provided']}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0212054455354585858580000000a00000000000000000000000002faf0800000000052ae781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02116000000010000000005f5e100000a00000000000000000000000000000000000052aee4dfda0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_order', {'source': ADDR[0], 'give_asset': 'XCP', 'give_quantity': round(DP['small'] * 2.1), 'get_asset': 'BTC', 'get_quantity': DP['small'], 'expiration': DP['expiration'], 'fee_required': DP['fee_required']}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0212054455354585858580000000a00000000000000010000000006422c400000000052ae781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02116000000000000000002faf080000a00000000000dbba00000000000000000000052ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }]
    }
}

SCENARIO_1 = [
    ['burn', (ADDR[0], int(.62 * DP['quantity'])), {'encoding': 'multisig'}],
    ['send', (ADDR[0], ADDR[1], 'XCP', DP['small']), {'encoding': 'multisig'}],
    ['order', (ADDR[0], 'BTC', DP['small'], 'XCP', DP['small'] * 2, DP['expiration'], 0), {'encoding': 'multisig', 'fee_provided': DP['fee_provided']}],
    ['order', (ADDR[0], 'XCP', round(DP['small'] * 2.1), 'BTC', DP['small'], DP['expiration'], DP['fee_required']), {'encoding': 'multisig'}],
    ['btcpay', (ADDR[0], '084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71'), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'BBBB', DP['quantity'] * 10, True, False, 0, 0.0, ''), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'BBBC', round(DP['quantity'] / 1000), False, True, 17, 0.015, 'foobar'), {'encoding': 'multisig'}],
    ['send', (ADDR[0], ADDR[1], 'BBBB', round(DP['quantity'] / 25)), {'encoding': 'multisig'}],
    ['send', (ADDR[0], ADDR[1], 'BBBC', round(DP['quantity'] / 190000)), {'encoding': 'multisig'}],
    ['dividend', (ADDR[0], 600, 'BBBB', 'XCP'), {'encoding': 'multisig'}],
    ['dividend', (ADDR[0], 800, 'BBBC', 'XCP'), {'encoding': 'multisig'}],
    ['broadcast', (ADDR[0], 1388000000, 100, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],
    ['bet', (ADDR[0], ADDR[0], 0, 1388000100, DP['small'], round(DP['small'] / 2), 0.0, 15120, DP['expiration']), {'encoding': 'multisig'}],
    ['bet', (ADDR[0], ADDR[0], 1, 1388000100, round(DP['small'] / 2), round(DP['small'] * .83), 0.0, 15120, DP['expiration']), {'encoding': 'multisig'}],
    ['bet', (ADDR[0], ADDR[0], 0, 1388000100, DP['small'] * 3, DP['small'] * 7, 0.0, 5040, DP['expiration']), {'encoding': 'multisig'}],
    ['bet', (ADDR[0], ADDR[0], 1, 1388000100, DP['small'] * 7, DP['small'] * 3, 0.0, 5040, DP['expiration']), {'encoding': 'multisig'}],
    ['bet', (ADDR[0], ADDR[0], 2, 1388000200, DP['small'] * 15, DP['small'] * 13, 1, 5040, DP['expiration']), {'encoding': 'multisig'}],
    ['bet', (ADDR[0], ADDR[0], 3, 1388000200, DP['small'] * 13, DP['small'] * 15, 1, 5040, DP['expiration']), {'encoding': 'multisig'}],
    ['broadcast', (ADDR[0], 1388000050, round(100 - (.415/3) - .00001, 5), DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],
    ['broadcast', (ADDR[0], 1388000101, 100.343, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],
    ['broadcast', (ADDR[0], 1388000201, 2, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],
    ['order', (ADDR[0], 'BBBB', DP['small'], 'XCP', DP['small'], DP['expiration'], 0), {'encoding': 'multisig'}],
    ['burn', (ADDR[0], (1 * DP['quantity']), True), {'encoding': 'multisig'}],  # Try to burn a whole 'nother BTC.
    ['send', (ADDR[0], ADDR[1], 'BBBC', 10000), {'encoding': 'multisig'}],
    ['callback', (ADDR[0], .3, 'BBBC'), {'encoding': 'multisig'}],
    ['rps', (ADDR[0], 5, 11021663, DP['move_random_hash'], 100), {'encoding': 'multisig'}],
    ['rps', (ADDR[1], 5, 11021663, '6e8bf66cbd6636aca1802459b730a99548624e48e243b840e0b34a12bede17ec', 100), {'encoding': 'multisig'}],
    ['rpsresolve', (ADDR[0], 3, DP['rps_random'], '58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd'), {'encoding': 'multisig'}],
    ['rpsresolve', (ADDR[1], 5, 'fa765e80203cba24a298e4458f63ff6b', '58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd'), {'encoding': 'multisig'}],
    ['rps', (ADDR[0], 5, 11021663, DP['move_random_hash'], 10), {'encoding': 'multisig'}],
    ['create_next_block', 46],
    ['rps', (ADDR[0], 5, 11021664, DP['move_random_hash'], 10), {'encoding': 'multisig'}],
    ['rps', (ADDR[1], 5, 11021664, DP['move_random_hash'], 10), {'encoding': 'multisig'}],
    ['create_next_block', 73],
    ['rps', (ADDR[0], 5, 11021665, DP['move_random_hash'], 10), {'encoding': 'multisig'}],
    ['rps', (ADDR[1], 5, 11021665, DP['move_random_hash'], 10), {'encoding': 'multisig'}],
    ['rpsresolve', (ADDR[0], 3, DP['rps_random'], '86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb17772dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa'), {'encoding': 'multisig'}],
    ['create_next_block', 101]
]

INTEGRATION_SCENARIOS = {
    'unittest_fixture': UNITEST_FIXTURE,
    'scenario_1': SCENARIO_1
}

