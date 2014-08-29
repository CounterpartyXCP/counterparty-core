#! /usr/bin/python3

#TODO: transform this file to json
UNIT = 100000000

DEFAULT_PARAMS = {
    'address_1': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 
    'address_2': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',
    'address_1_privkey': 'cPdUqd5EbBWsjcG9xiL1hz8bEyGFiz4SW99maU9JgpL9TEcxUf3j', 
    'address_2_privkey': 'cQ897jnCVRrawNbw8hgmjMiRNHejwzg4KbzdMCzc91iaTif8ReqX',
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
DP = DEFAULT_PARAMS

UNITTEST_VECTOR = {
    'burn': {
        'validate': [{
            'in': (DP['address_1'], DP['unspendable'], DP['burn_quantity'], DP['burn_start']),
            'out': ([])
        }, {
            'in': (DP['address_1'], DP['unspendable'], 1.1 * DP['burn_quantity'], DP['burn_start']),
            'out': (['quantity must be in satoshis'])
        }, {
            'in': (DP['address_1'], DP['address_2'], DP['burn_quantity'], DP['burn_start']),
            'out': (['wrong destination address'])
        }, {
            'in': (DP['address_1'], DP['unspendable'], -1 * DP['burn_quantity'], DP['burn_start']),
            'out': (['negative quantity'])
        }, {
            'in': (DP['address_1'], DP['unspendable'], DP['burn_quantity'], DP['burn_start'] - 2),
            'out': (['too early'])
        }, {
            'in': (DP['address_1'], DP['unspendable'], DP['burn_quantity'], DP['burn_end'] + 1),
            'out': (['too late'])
        }, {
            'in': (DP['address_1'], DP['address_2'], 1.1 * DP['burn_quantity'], DP['burn_start'] - 2),
            'out': (['wrong destination address', 'quantity must be in satoshis'])
        }, {
            'in': (DP['address_1'], DP['address_2'], DP['burn_quantity'], DP['burn_start'] - 2),
            'out': (['wrong destination address', 'too early'])
        }],
        'compose': [{
            'in': (DP['address_2'], DP['burn_quantity']),
            'out': ('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 62000000)], None)
        }, {
            'in': (DP['address_1'], DP['burn_quantity']),
            'error': ('BurnError', '1 BTC may be burned per address')
        }],
        'parse': [{
            'in': ({'btc_amount': 62000000, 'data': b'', 'block_time': 1549100000000, 'block_index': 154910, 'tx_index': 2, 'supported': 1, 'fee': 10000, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'destination': 'mvCounterpartyXXXXXXXXXXXXXXW24Hef', 'block_hash': '80d40ca10e5ea63a2ad8303c70819f369afbbd5716faf875fa4eb8ac2799ee0f9b2e5e204849d8ebca34537bdef7620fe81db66fc8195e193ee778fa43d68cdb', 'tx_hash': 'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986'},),
            'records': [
                {'table': 'burns', 'values': {'tx_index': 2, 'tx_hash': 'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986', 'burned': 62000000, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'earned': 92999983949, 'status': 'valid', 'block_index': 154910}},
                {'table': 'credits', 'values': {'asset': 'XCP', 'event': 'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986', 'block_index': 154910, 'quantity': 92999983949, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'calling_function': None}}
            ]
        }]
    },
    'send': {
        'compose': [{
            'in': (DP['address_1'], DP['address_2'], 'XCP', DP['small']),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'TESTXXXX\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80')
        }, {
            'in': (DP['address_1'], DP['address_2'], 'XCP', DP['quantity'] * 10000000),
            'error': ('SendError', 'insufficient funds')
        }]
    },
    'order': {
        'compose': [{
            'in': (DP['address_1'], 'BTC', DP['small'], 'XCP', DP['small'] * 2, DP['expiration'], 0),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'TESTXXXX\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (DP['address_1'], 'XCP', round(DP['small'] * 2.1), 'BTC', DP['small'], DP['expiration'], DP['fee_required']),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'TESTXXXX\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0')
        }]
    }
}

