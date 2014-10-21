from .params import ADDR, MULTISIGADDR, DEFAULT_PARAMS as DP

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
        }, {
            'in': (MULTISIGADDR[0], DP['unspendable'], DP['burn_quantity'], DP['burn_start']),
            'out': ([])
        }],
        'compose': [{
            'in': (ADDR[1], DP['burn_quantity']),
            'out': ('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 62000000)], None)
        }, {
            'in': (ADDR[0], DP['burn_quantity']),
            'error': ('BurnError', '1 BTC may be burned per address')
        }, {
            'in': (MULTISIGADDR[0], int(DP['quantity'] / 2)),
            'out': ('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 50000000)], None)
        }],
        'parse': [{
            'in': ({'block_index': 155409, 'destination': 'mvCounterpartyXXXXXXXXXXXXXXW24Hef', 'fee': 10000, 'block_time': 1554090000000, 'supported': 1, 'btc_amount': 62000000, 'data': b'', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_index': 502, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'burns', 'values': {'tx_index': 502, 'earned': 92995979341, 'burned': 62000000, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'status': 'valid', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 155409}},
                {'table': 'credits', 'values': {'block_index': 155409, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'asset': 'XCP', 'calling_function': 'burn', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 92995979341}}
            ]
        }, {
            'in': ({'supported': 1, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'btc_amount': 50000000, 'block_index': 155409, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'fee': 10000, 'data': b'', 'block_time': 1554090000000, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'tx_index': 502, 'destination': 'mvCounterpartyXXXXXXXXXXXXXXW24Hef'},),
            'records': [
                {'table': 'burns', 'values': {'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 155409, 'burned': 50000000, 'status': 'valid', 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'earned': 74996757533, 'tx_index': 502}},
                {'table': 'credits', 'values': {'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'block_index': 155409, 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'calling_function': 'burn', 'quantity': 74996757533}}
            ]
        }],
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
        }, {
            'in': (ADDR[0], MULTISIGADDR[0], 'XCP', DP['quantity']),
            'out': ([])
        }, {
            'in': (ADDR[0], ADDR[1], 'MAXI', 2**63 - 1),
            'out': ([])
        }, {
            'in': (ADDR[0], ADDR[1], 'MAXI', 2**63 + 1),
            'out': ([])
        }],
        'compose': [{
            'in': (ADDR[0], ADDR[1], 'XCP', DP['small']),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80')
        }, {
            'in': (ADDR[0], ADDR[1], 'XCP', DP['quantity'] * 10000000),
            'error': ('SendError', 'insufficient funds')
        }, {
            'in': (ADDR[0], ADDR[1], 'XCP', DP['quantity'] / 3),
            'error': ('SendError', 'quantity must be an int (in satoshi)')
        }, {
            'in': (ADDR[0], MULTISIGADDR[0], 'XCP', DP['quantity']),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00')
        }, {
            'in': (MULTISIGADDR[0], ADDR[0], 'XCP', DP['quantity']),
            'out': ('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00')
        }, {
            'in': (MULTISIGADDR[0], MULTISIGADDR[1], 'XCP', DP['quantity']),
            'out': ('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [('1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00')
        }, {
            'in': (ADDR[0], ADDR[1], 'MAXI', 2**63 - 1),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff')
        }, {
            'in': (ADDR[0], ADDR[1], 'MAXI', 2**63 + 1),
            'error': ('SendError', 'insufficient funds')
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
        }, {
            'in': ({'btc_amount': 7800, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'fee': 10000, 'tx_index': 502, 'destination': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'supported': 1, 'block_time': 1554090000000, 'block_index': 155409},),
            'records': [
                {'table': 'sends', 'values': {'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'destination': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'asset': 'XCP', 'quantity': 100000000, 'tx_index': 502, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'status': 'valid', 'block_index': 155409}},
                {'table': 'credits', 'values': {'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'quantity': 100000000, 'asset': 'XCP', 'block_index': 155409, 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'calling_function': 'send'}},
                {'table': 'debits', 'values': {'action': 'send', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'quantity': 100000000, 'asset': 'XCP', 'block_index': 155409, 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d'}}
            ]
        }, {
            'in': ({'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00', 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'supported': 1, 'block_time': 1554090000000, 'fee': 10000, 'tx_index': 502, 'btc_amount': 7800, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'block_index': 155409, 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'},),
            'records': [
                {'table': 'sends', 'values': {'quantity': 100000000, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'status': 'valid', 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'asset': 'XCP', 'tx_index': 502, 'block_index': 155409}},
                {'table': 'credits', 'values': {'quantity': 100000000, 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'calling_function': 'send', 'asset': 'XCP', 'block_index': 155409, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'}},
                {'table': 'debits', 'values': {'quantity': 100000000, 'action': 'send', 'asset': 'XCP', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 155409, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'}}
            ]
        }, {
            'in': ({'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'destination': '1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'supported': 1, 'block_time': 1554090000000, 'fee': 10000, 'block_index': 155409, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'btc_amount': 7800, 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00', 'tx_index': 502, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'sends', 'values': {'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'destination': '1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'asset': 'XCP', 'status': 'valid', 'block_index': 155409, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 100000000, 'tx_index': 502}},
                {'table': 'credits', 'values': {'asset': 'XCP', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 100000000, 'address': '1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'block_index': 155409, 'calling_function': 'send'}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'action': 'send', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 100000000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'block_index': 155409}}
            ]
        }, {
            'in': ({'block_index': 155409, 'block_time': 1554090000000, 'fee': 10000, 'tx_index': 502, 'tx_hash': '8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0', 'btc_amount': 7800, 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'supported': 1, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'sends', 'values': {'block_index': 155409, 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_hash': '8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0', 'quantity': 9223372036854775807, 'asset': 'MAXI', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'status': 'valid', 'tx_index': 502}},
                {'table': 'credits', 'values': {'block_index': 155409, 'asset': 'MAXI', 'quantity': 9223372036854775807, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'calling_function': 'send', 'event': '8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0'}},
                {'table': 'debits', 'values': {'block_index': 155409, 'action': 'send', 'asset': 'MAXI', 'quantity': 9223372036854775807, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'event': '8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0'}}
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
        }, {
            'in': (ADDR[0], None, 'XCP', 1000, True, False, None, None, '', 1),
            'out': (0, 0.0, ['cannot issue BTC or XCP'], 50000000)
        }, {
            'in': (ADDR[0], None, 'NOSATOSHI', 1000.5, True, False, None, None, '', 1),
            'out': (0, 0.0, ['quantity must be in satoshis'], 0)
        }, {
            'in': (ADDR[0], None, 'INVALIDCALLDATE', 1000, True, True, 10000.5, DP['quantity'], '', 1),
            'out': (10000.5, 100000000.0, ['call_date must be epoch integer'], 0)
        }, {
            'in': (ADDR[0], None, 'INVALIDCALLPRICE', 1000, True, True, 1409401723, 'price', '', 1),
            'out': (1409401723, 'price', ['call_price must be a float'], 0)
        }, {
            'in': (ADDR[0], None, 'NEGATIVEVALUES', -1000, True, True, -1409401723, -DP['quantity'], '', 1),
            'out': (-1409401723, -100000000.0, ['negative quantity', 'negative call price', 'negative call date'], 50000000)
        }, {
            'in': (ADDR[2], None, 'DIVISIBLE', 1000, True, False, None, None, 'Divisible asset', 1),
            'out': (0, 0.0, ['issued by another address'], 0)
        }, {
            'in': (ADDR[0], None, 'DIVISIBLE', 1000, False, True, 1409401723, DP['quantity'], 'Divisible asset', 1),
            'out': (1409401723, 100000000.0, ['cannot change divisibility', 'cannot change callability'], 0)
        }, {
            'in': (ADDR[0], None, 'CALLABLE', 1000, True, True, 1409400251, DP['quantity'] / 2, 'Callable asset', 1),
            'out': (1409400251, 50000000.0, ['cannot reduce call price'], 0)
        }, {
            'in': (ADDR[0], None, 'LOCKED', 1000, True, False, None, None, 'Locked asset', 1),
            'out': (0, 0.0, ['locked asset and non‐zero quantity'], 0)
        }, {
            'in': (ADDR[0], None, 'BSSET', 1000, True, False, None, None, 'LOCK', 1),
            'out': (0, 0.0, ['cannot lock a non‐existent asset'], 50000000)
        }, {
            'in': (ADDR[0], ADDR[1], 'BSSET', 1000, True, False, None, None, '', 1),
            'out': (0, 0.0, ['cannot transfer a non‐existent asset', 'cannot issue and transfer simultaneously'], 50000000)
        }, {
            'in': (ADDR[2], None, 'BSSET', 1000, True, False, None, None, '', 1),
            'out': (0, 0.0, ['insufficient funds'], 50000000)
        }, {
            'in': (ADDR[0], None, 'BSSET', 2**63, True, False, None, None, '', 1),
            'out': (0, 0.0, ['total quantity overflow'], 50000000)
        }, {
            'in': (ADDR[0], ADDR[1], 'DIVISIBLE', 1000, True, False, None, None, 'Divisible asset', 1),
            'out': (0, 0.0, ['cannot issue and transfer simultaneously'], 0)
        }, {
            'in': (ADDR[0], None, 'MAXIMUM', 2**63-1, True, False, None, None, 'Maximum quantity', 1),
            'out': (0, 0.0, [], 50000000)
        }, {
            'in': (ADDR[0], None, 'DIVISIBLE', 2**63-1, True, False, None, None, 'Maximum quantity', 1),
            'out': (0, 0.0, ['total quantity overflow'], 0)
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
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (ADDR[0], ADDR[1], 'DIVISIBLE', 0, True, False, None, None, ''),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (MULTISIGADDR[0], None, 'BSSET', 1000, True, False, None, None, ''),
            'out': ('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (ADDR[0], MULTISIGADDR[0], 'DIVISIBLE', 0, True, False, None, None, ''),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (ADDR[0], None, 'MAXIMUM', 2**63-1, True, False, None, None, 'Maximum quantity'),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\xdd\x96\xd2t\x7f\xff\xff\xff\xff\xff\xff\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10Maximum quantity')
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
                {'table': 'issuances', 'values': {'locked': 0, 'call_date': 0, 'block_index': 155409, 'description': '', 'quantity': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'DIVISIBLE', 'callable': 0, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'fee_paid': 0, 'issuer': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_index': 502, 'transfer': 1, 'call_price': 0.0, 'divisible': 1, 'status': 'valid'}}
            ]
        }, {
            'in': ({'tx_index': 502, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'data': b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04LOCK', 'block_time': 1554090000000, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'fee': 10000, 'destination': None, 'supported': 1, 'block_index': 155409, 'btc_amount': None},),
            'records': [
                {'table': 'issuances', 'values': {'tx_index': 502, 'quantity': 0, 'block_index': 155409, 'callable': 0, 'status': 'valid', 'locked': 1, 'description': 'Divisible asset', 'divisible': 1, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'transfer': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'call_price': 0.0, 'issuer': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'call_date': 0, 'fee_paid': 0, 'asset': 'DIVISIBLE'}}
            ]
        }, {
            'in': ({'data': b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00', 'supported': 1, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 155409, 'destination': '', 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'btc_amount': 0, 'tx_index': 502, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'block_time': 1554090000000, 'fee': 10000},),
            'records': [
                {'table': 'issuances', 'values': {'issuer': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'asset': 'BSSET', 'call_date': 0, 'call_price': 0.0, 'description': '', 'block_index': 155409, 'transfer': 0, 'quantity': 1000, 'status': 'valid', 'divisible': 1, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'locked': 0, 'tx_index': 502, 'callable': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'fee_paid': 50000000}},
                {'table': 'credits', 'values': {'quantity': 1000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'asset': 'BSSET', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'calling_function': 'issuance', 'block_index': 155409}},
                {'table': 'debits', 'values': {'quantity': 50000000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'asset': 'XCP', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'action': 'issuance fee', 'block_index': 155409}}
            ]
        }, {
            'in': ({'fee': 10000, 'block_time': 1554090000000, 'data': b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00', 'block_index': 155409, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'btc_amount': 7800, 'tx_index': 502, 'destination': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'supported': 1, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'},),
            'records': [
                {'table': 'issuances', 'values': {'call_date': 0, 'call_price': 0.0, 'fee_paid': 0, 'divisible': 1, 'block_index': 155409, 'tx_index': 502, 'description': '', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'transfer': 1, 'issuer': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'locked': 0, 'asset': 'DIVISIBLE', 'callable': 0, 'status': 'valid', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 0}},
                {'table': 'debits', 'values': {'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'action': 'issuance fee', 'block_index': 155409, 'quantity': 0}}
            ]
        }, {
            'in': ({'data': b'\x00\x00\x00\x14\x00\x00\x00\x00\xdd\x96\xd2t\x7f\xff\xff\xff\xff\xff\xff\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10Maximum quantity', 'block_time': 1554090000000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'block_index': 155409, 'btc_amount': 0, 'fee': 10000, 'supported': 1, 'tx_index': 502, 'destination': '', 'tx_hash': '71da4fac29d6442ef3ff13f291860f512a888161ae9e574f313562851912aace'},),
            'records': [
                {'table': 'issuances', 'values': {'issuer': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'call_price': 0.0, 'transfer': 0, 'call_date': 0, 'divisible': 1, 'description': 'Maximum quantity', 'asset': 'MAXIMUM', 'tx_index': 502, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': 155409, 'quantity': 9223372036854775807, 'status': 'valid', 'callable': 0, 'tx_hash': '71da4fac29d6442ef3ff13f291860f512a888161ae9e574f313562851912aace', 'fee_paid': 50000000, 'locked': 0}},
                {'table': 'credits', 'values': {'asset': 'MAXIMUM', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': 155409, 'quantity': 9223372036854775807, 'event': '71da4fac29d6442ef3ff13f291860f512a888161ae9e574f313562851912aace', 'calling_function': 'issuance'}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': 155409, 'action': 'issuance fee', 'quantity': 50000000, 'event': '71da4fac29d6442ef3ff13f291860f512a888161ae9e574f313562851912aace'}}
            ]
        }]
    },
    'dividend': {
        'validate': [{
            'in': (ADDR[0], DP['quantity'] * 1000, 'DIVISIBLE', 'XCP', 155409),
            'out': (1100000000000, [{'address_quantity': 100000000, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'dividend_quantity': 100000000000}, {'address_quantity': 1000000000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'dividend_quantity': 1000000000000}], ['insufficient funds (XCP)'], 0)
        }, { 
            'in': (ADDR[0], DP['quantity'], 'BTC', 'XCP', 155409),
            'out': (None, None, ['cannot pay dividends to holders of BTC', 'no such asset, BTC.'], 0)
        }, { 
            'in': (ADDR[0], DP['quantity'], 'XCP', 'XCP', 155409),
            'out': (None, None, ['cannot pay dividends to holders of XCP', 'no such asset, XCP.'], 0)
        }, { 
            'in': (ADDR[0], DP['quantity'], 'NOASSET', 'XCP', 155409),
            'out': (None, None, ['no such asset, NOASSET.'], 0)
        }, { 
            'in': (ADDR[1], DP['quantity'], 'DIVISIBLE', 'XCP', 155409),
            'out': (99900000000, [{'dividend_quantity': 98900000000, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'address_quantity': 98900000000}, {'dividend_quantity': 1000000000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'address_quantity': 1000000000}], ['only issuer can pay dividends', 'insufficient funds (XCP)'], 0)
        }, { 
            'in': (ADDR[0], DP['quantity'], 'DIVISIBLE', 'NOASSET', 155409),
            'out': (None, None, ['no such dividend asset, NOASSET.'], 0)
        }],
        'compose': [{
            'in': (ADDR[0], DP['quantity'], 'DIVISIBLE', 'XCP'),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x002\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01')
        }, {
            'in': (ADDR[0], 1, 'NODIVISIBLE', 'XCP'),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x002\x00\x00\x00\x00\x00\x00\x00\x01\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x00\x01')
        }],
        'parse': [{
            'in': ({'tx_hash': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'supported': 1, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'data': b'\x00\x00\x002\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01', 'tx_index': 502, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'block_index': 155409, 'btc_amount': 0, 'fee': 10000, 'destination': '', 'block_time': 1554090000000},),
            'records': [
                {'table': 'dividends', 'values': {'tx_hash': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'fee_paid': 40000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_index': 502, 'block_index': 155409, 'dividend_asset': 'XCP', 'status': 'valid', 'quantity_per_unit': 100000000, 'asset': 'DIVISIBLE'}},
                {'table': 'credits', 'values': {'calling_function': 'dividend', 'asset': 'XCP', 'block_index': 155409, 'quantity': 100000000, 'event': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'}},
                {'table': 'credits', 'values': {'calling_function': 'dividend', 'asset': 'XCP', 'block_index': 155409, 'quantity': 1000000000, 'event': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'action': 'dividend', 'block_index': 155409, 'quantity': 1100000000, 'event': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'action': 'dividend fee', 'block_index': 155409, 'quantity': 40000, 'event': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'}}
            ]
        }, {
            'in': ({'tx_index': 502, 'btc_amount': 0, 'block_time': 1554090000000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_hash': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'fee': 10000, 'block_index': 155409, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'supported': 1, 'destination': '', 'data': b'\x00\x00\x002\x00\x00\x00\x00\x00\x00\x00\x01\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x00\x01'},),
            'records': [
                {'table': 'dividends', 'values': {'tx_index': 502, 'asset': 'NODIVISIBLE', 'fee_paid': 40000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_hash': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'dividend_asset': 'XCP', 'block_index': 155409, 'quantity_per_unit': 1, 'status': 'valid'}},
                {'table': 'credits', 'values': {'asset': 'XCP', 'event': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'calling_function': 'dividend', 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'quantity': 5, 'block_index': 155409}},
                {'table': 'credits', 'values': {'asset': 'XCP', 'event': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'calling_function': 'dividend', 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'quantity': 10, 'block_index': 155409}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'event': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'quantity': 15, 'block_index': 155409, 'action': 'dividend'}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'event': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'quantity': 40000, 'block_index': 155409, 'action': 'dividend fee'}}
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
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (ADDR[0], 'XCP', round(DP['small'] * 2.1), 'BTC', DP['small'], DP['expiration'], DP['fee_required']),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0')
        }, {
            'in': (MULTISIGADDR[0], 'BTC', DP['small'], 'XCP', DP['small'] * 2, DP['expiration'], 0),
            'out': ('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (MULTISIGADDR[0], 'XCP', round(DP['small'] * 2.1), 'BTC', DP['small'], DP['expiration'], DP['fee_required']),
            'out': ('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0')
        }, {
            'in': (ADDR[0], 'MAXI', 2**63 - 1, 'XCP', DP['quantity'], DP['expiration'], DP['fee_required']),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0')
        }, {
            'in': (ADDR[0], 'MAXI', 2**63 + 1, 'XCP', DP['quantity'], DP['expiration'], DP['fee_required']),
            'error': ('OrderError', 'insufficient funds')
        }],
        'parse': [{
            'in': ({'destination': None, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'block_time': 1554090000000, 'block_index': 155409, 'tx_index': 502, 'data': b'\x00\x00\x00\n\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'fee': 10000, 'btc_amount': None, 'supported': 1, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'orders', 'values': {'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'fee_required_remaining': 0, 'block_index': 155409, 'status': 'filled', 'get_quantity': 100000000, 'fee_provided_remaining': 10000, 'get_asset': 'XCP', 'give_remaining': 0, 'fee_provided': 10000, 'expiration': 2000, 'get_remaining': 0, 'tx_index': 502, 'give_asset': 'DIVISIBLE', 'expire_index': 157409, 'give_quantity': 100000000, 'fee_required': 0}},
                {'table': 'order_matches', 'values': {'status': 'completed', 'tx0_index': 7, 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'forward_quantity': 100000000, 'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'backward_asset': 'DIVISIBLE', 'tx0_hash': 'a2fa5c33c3a28b41b63fd1c695d9c215b514bdf9138768003785a025ae4523e4', 'tx0_expiration': 2000, 'id': 'a2fa5c33c3a28b41b63fd1c695d9c215b514bdf9138768003785a025ae4523e4db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx1_expiration': 2000, 'tx1_block_index': 155409, 'forward_asset': 'XCP', 'fee_paid': 0, 'match_expire_index': 155429, 'tx0_block_index': 154914, 'backward_quantity': 100000000, 'tx1_index': 502, 'block_index': 155409}},
                {'table': 'credits', 'values': {'event': 'a2fa5c33c3a28b41b63fd1c695d9c215b514bdf9138768003785a025ae4523e4db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'block_index': 155409, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'quantity': 100000000, 'calling_function': 'order match'}},
                {'table': 'debits', 'values': {'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 155409, 'quantity': 100000000, 'asset': 'DIVISIBLE', 'action': 'open order'}},
                {'table': 'credits', 'values': {'event': 'a2fa5c33c3a28b41b63fd1c695d9c215b514bdf9138768003785a025ae4523e4db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'DIVISIBLE', 'block_index': 155409, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'quantity': 100000000, 'calling_function': 'order match'}},
                {'table': 'credits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'block_index': 155409, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'quantity': 0, 'calling_function': 'filled'}},
                {'table': 'credits', 'values': {'event': 'a2fa5c33c3a28b41b63fd1c695d9c215b514bdf9138768003785a025ae4523e4', 'asset': 'DIVISIBLE', 'block_index': 155409, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'quantity': 0, 'calling_function': 'filled'}}
            ]
        }, {
            'in': ({'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': None, 'tx_index': 502, 'supported': 1, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'fee': 10000, 'block_time': 1554090000000, 'block_index': 155409, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0fB@\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'destination': None},),
            'records': [
                {'table': 'orders', 'values': {'give_quantity': 1000000, 'status': 'open', 'get_remaining': 0, 'tx_index': 502, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'give_remaining': 0, 'block_index': 155409, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'fee_required': 0, 'fee_provided': 10000, 'give_asset': 'BTC', 'get_asset': 'XCP', 'fee_provided_remaining': 1000, 'expiration': 2000, 'expire_index': 157409, 'fee_required_remaining': 0, 'get_quantity': 100000000}},
                {'table': 'order_matches', 'values': {'forward_asset': 'XCP', 'id': '319a5a996bb1ee56ee024dc658aaafeb0d29c3c2a4b0d38e780319082366f0a8db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'forward_quantity': 100000000, 'match_expire_index': 155429, 'tx1_block_index': 155409, 'backward_quantity': 1000000, 'block_index': 155409, 'fee_paid': 9000, 'tx1_index': 502, 'tx1_expiration': 2000, 'tx0_hash': '319a5a996bb1ee56ee024dc658aaafeb0d29c3c2a4b0d38e780319082366f0a8', 'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx0_index': 11, 'tx0_block_index': 154918, 'backward_asset': 'BTC', 'tx0_expiration': 2000, 'status': 'pending'}}
            ]
        }, {
            'in': ({'fee': 10000, 'block_time': 1554090000000, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'destination': None, 'supported': 1, 'tx_index': 502, 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\n,+\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': None, 'block_index': 155409},),
            'records': [
                {'table': 'orders', 'values': {'fee_required_remaining': 0, 'expire_index': 157409, 'status': 'open', 'expiration': 2000, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'get_remaining': 0, 'give_remaining': 0, 'get_quantity': 666667, 'fee_required': 0, 'fee_provided_remaining': 10000, 'fee_provided': 10000, 'block_index': 155409, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'give_quantity': 100000000, 'tx_index': 502, 'give_asset': 'XCP', 'get_asset': 'BTC'}},
                {'table': 'order_matches', 'values': {'forward_asset': 'BTC', 'id': 'de1e76e8172a0a3811d6c0d8be4a289547bb94b63b01ab7a175fc33ec8ddb43fdb6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'forward_quantity': 666667, 'match_expire_index': 155429, 'tx1_block_index': 155409, 'backward_quantity': 100000000, 'block_index': 155409, 'fee_paid': 0, 'tx1_index': 502, 'tx1_expiration': 2000, 'tx0_hash': 'de1e76e8172a0a3811d6c0d8be4a289547bb94b63b01ab7a175fc33ec8ddb43f', 'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx0_index': 12, 'tx0_block_index': 154919, 'backward_asset': 'XCP', 'tx0_expiration': 2000, 'status': 'pending'}},
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
        }, {
            'in': ({'block_index': 155409, 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'destination': '', 'fee': 10000, 'tx_index': 502, 'supported': 1, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'block_time': 1554090000000, 'btc_amount': 0},),
            'records': [
                {'table': 'orders', 'values': {'block_index': 155409, 'expiration': 10, 'expire_index': 155419, 'fee_required_remaining': 0, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'fee_provided': 10000, 'status': 'open', 'give_asset': 'BTC', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'get_remaining': 0, 'give_remaining': 49000000, 'tx_index': 502, 'get_asset': 'XCP', 'fee_provided_remaining': 1000, 'fee_required': 0, 'give_quantity': 50000000, 'get_quantity': 100000000}},
                {'table': 'order_matches', 'values': {'backward_quantity': 1000000, 'tx0_hash': '319a5a996bb1ee56ee024dc658aaafeb0d29c3c2a4b0d38e780319082366f0a8', 'tx1_block_index': 155409, 'match_expire_index': 155429, 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx0_block_index': 154918, 'status': 'pending', 'block_index': 155409, 'tx1_address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'forward_quantity': 100000000, 'tx1_index': 502, 'fee_paid': 9000, 'id': '319a5a996bb1ee56ee024dc658aaafeb0d29c3c2a4b0d38e780319082366f0a8db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'forward_asset': 'XCP', 'tx0_expiration': 2000, 'tx1_expiration': 10, 'backward_asset': 'BTC', 'tx0_index': 11, 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d'}}
            ]
        }, {
            'in': ({'fee': 10000, 'btc_amount': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx_index': 502, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'supported': 1, 'block_time': 1554090000000, 'block_index': 155409, 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0', 'destination': ''},),
            'records': [
                {'table': 'orders', 'values': {'get_asset': 'BTC', 'give_asset': 'XCP', 'fee_required': 900000, 'block_index': 155409, 'expire_index': 155419, 'give_remaining': 105000000, 'fee_provided_remaining': 10000, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx_index': 502, 'expiration': 10, 'status': 'open', 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'give_quantity': 105000000, 'get_quantity': 50000000, 'fee_provided': 10000, 'fee_required_remaining': 900000, 'get_remaining': 50000000}},
                {'table': 'debits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'quantity': 105000000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'block_index': 155409, 'action': 'open order'}}
            ]
        }, {
            'in': ({'btc_amount': 0, 'fee': 10000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'destination': '', 'tx_hash': '0ec7da68a67e165693afd6c97566f8f509d302bceec8d1be0100335718a40fe5', 'tx_index': 502, 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'supported': 1, 'block_time': 1554090000000, 'block_index': 155409},),
            'records': [
                {'table': 'orders', 'values': {'fee_provided_remaining': 10000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': 155409, 'tx_index': 502, 'fee_required': 900000, 'give_asset': 'MAXI', 'status': 'open', 'get_remaining': 100000000, 'give_quantity': 9223372036854775807, 'give_remaining': 9223372036854775807, 'expiration': 10, 'get_asset': 'XCP', 'tx_hash': '0ec7da68a67e165693afd6c97566f8f509d302bceec8d1be0100335718a40fe5', 'expire_index': 155419, 'fee_provided': 10000, 'get_quantity': 100000000, 'fee_required_remaining': 900000}},
                {'table': 'debits', 'values': {'quantity': 9223372036854775807, 'asset': 'MAXI', 'action': 'open order', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'event': '0ec7da68a67e165693afd6c97566f8f509d302bceec8d1be0100335718a40fe5', 'block_index': 155409}}
            ]
        }]
    },
    'bitcoin': {
        'transaction': [{
            'comment': 'burn',
            'in': (('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 62000000)], None), {'encoding': 'multisig'}),
            'out': '0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac70ae4302000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000'            
        }, {
            'comment': 'multisig burn',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 50000000)], None), {'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff0280f0fa02000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac70c9fa02000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'send',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02162415bf04af834423d3dd7ada4dc727a030865759f9fba5aee78c9ea71e58754da21540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'send dest multisig',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02162415bf04af834423d3dd7ada4dc727a030865759f9fba5aee7fc6fbf1e58754da21540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'send source multisig',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00'), {'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff03781e0000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02134caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108bc1421528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b5c8255d0e53ae007df505000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'send source and dest multisig',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [('1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00'), {'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff03781e0000000000004751210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977210378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b52ae781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02134caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108bc1421528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b5c8255d0e53ae007df505000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'maximum quantity send',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02162415bf04af834423d3dd7ada4dc727a0308664fa0e045a51185cce50ee58754da21540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'issuance',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02159415bf04af834423d3dd7adb0dc727a03086e897d9fba5aee7a331919e48754da21540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'issuance',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02159415bf04af834423d3dd7adb0dc727aa153863ef89fba5aee7a331af1e48754da21540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'multisig issuance',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210fcaf7ca87f0fd78a01d9a0d7c221e55beef3cde388be72d254826b32a6008bc1421528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b5c8255d0e53ae789bf505000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'maximum quantity issuance',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\xdd\x96\xd2t\x7f\xff\xff\xff\xff\xff\xff\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10Maximum quantity'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02149415bf04af834423d3dd7adb0dc727a03d5f3a7eae045a51185cce50ee48754da21540fb2663b75f68ead197067a5af636736dbdcf8840c45d94079bbe724e88ec81d53ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'transfer asset to multisig',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02159415bf04af834423d3dd7adb0dc727aa153863ef89fba5aee7a331af1e48754da21540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'order',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig','fee_provided': DP['fee_provided']}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02148415bf04af834423d3dd7adaedc727a030865759e9fba5aee78c9ea71e58754da21540fb2673b75e6c3c994f80ad0c8431643bab28ced783cd94079bbe724e88ec81d53ae5cfeda0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'multisig order',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig','fee_provided': DP['fee_provided']}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0211ecaf7ca87f0fd78a01d9a0d62221e55beef3722db8be72d254adc40426108bc1421528340c37d005aa9e764ded8c038ffa94625307a450077125d580099b5c8255d0e53ae4880e605000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'multisig order',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0'), {'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0211ecaf7ca87f0fd78a01d9a0d62221e55beef3722da8be72d254e649c826108bc1421528340c27d005aa9e06bcf58c038ffa946253077fea077125d580099b5c8255d0e53ae789bf505000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'maximum quantity order',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02148415bf04af834423d3dd7adaedc727a0308664fa0e045a51185cce50ee58754da21540fb2673b75e6c3c994f80ad0c8431643bab28156d83cd94079bbe724e88ec81d53ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'dividend',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x002\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0215a415bf04af834423d3dd7ad96dc727a030d90949e9fba5a4c21d05197e58754da21540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'dividend',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x002\x00\x00\x00\x00\x00\x00\x00\x01\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x00\x01'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0215a415bf04af834423d3dd7ad96dc727a030865759f9fbc9036a64c1197e58754da21540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }],
        'base58_check_decode': [{
            'in': ('16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM', b'\x00'),
            'out': '010966776006953d5567439e5e39f86a0d273bee'
        }, {
            'in': (ADDR[0], b'\x6f'),
            'out': '4838d8b3588c4c7ba7c1d06f866e9b3739c63037'
        }]
    },
    'util': {
        'api': [{
            'in': ('create_burn', {'source': ADDR[1], 'quantity': DP['burn_quantity']}),
            'out': '0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac70ae4302000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000'            
        }, {
            'in': ('create_send', {'source': ADDR[0], 'destination': ADDR[1], 'asset': 'XCP', 'quantity': DP['small']}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02162415bf04af834423d3dd7ada4dc727a030865759f9fba5aee78c9ea71e58754da21540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'           
        }, {
            'in': ('create_issuance', {'source': ADDR[0], 'transfer_destination': None, 'asset': 'BSSET', 'quantity': 1000, 'divisible': True, 'callable': False, 'call_date':  None, 'call_price': None, 'description': ''}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02159415bf04af834423d3dd7adb0dc727a03086e897d9fba5aee7a331919e48754da21540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'           
        }, {
            'in': ('create_issuance', {'source': ADDR[0], 'transfer_destination': ADDR[1], 'asset': 'DIVISIBLE', 'quantity': 0, 'divisible': True, 'callable': False, 'call_date': None, 'call_price': None, 'description': ''}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02159415bf04af834423d3dd7adb0dc727aa153863ef89fba5aee7a331af1e48754da21540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'           
        }, {
            'in': ('create_order', {'source': ADDR[0], 'give_asset': 'BTC', 'give_quantity': DP['small'], 'get_asset': 'XCP', 'get_quantity': DP['small'] * 2, 'expiration': DP['expiration'], 'fee_required': 0, 'fee_provided': DP['fee_provided']}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02148415bf04af834423d3dd7adaedc727a030865759e9fba5aee78c9ea71e58754da21540fb2673b75e6c3c994f80ad0c8431643bab28ced783cd94079bbe724e88ec81d53ae5cfeda0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_order', {'source': ADDR[0], 'give_asset': 'XCP', 'give_quantity': round(DP['small'] * 2.1), 'get_asset': 'BTC', 'get_quantity': DP['small'], 'expiration': DP['expiration'], 'fee_required': DP['fee_required']}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02148415bf04af834423d3dd7adaedc727a030865759f9fba5aee7c7136b1e58754da21540fb2663b75e6c3ce9be98ad0c8431643bab28156d83cd94079bbe724e88ec81d53ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_burn', {'source': MULTISIGADDR[0], 'quantity': int(DP['quantity'] / 2)}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff0280f0fa02000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac70c9fa02000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_send', {'source': ADDR[0], 'destination': MULTISIGADDR[0], 'asset': 'XCP', 'quantity': DP['quantity']}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02162415bf04af834423d3dd7ada4dc727a030865759f9fba5aee7fc6fbf1e58754da21540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_send', {'source': MULTISIGADDR[0], 'destination': ADDR[0], 'asset': 'XCP', 'quantity': DP['quantity']}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff03781e0000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02134caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108bc1421528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b5c8255d0e53ae007df505000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_send', {'source': MULTISIGADDR[0], 'destination': MULTISIGADDR[1], 'asset': 'XCP', 'quantity': DP['quantity']}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff03781e0000000000004751210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977210378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b52ae781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02134caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108bc1421528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b5c8255d0e53ae007df505000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_issuance', {'source': MULTISIGADDR[0], 'transfer_destination': None, 'asset': 'BSSET', 'quantity': 1000, 'divisible': True, 'callable': False, 'call_date': None, 'call_price': None, 'description': ''}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210fcaf7ca87f0fd78a01d9a0d7c221e55beef3cde388be72d254826b32a6008bc1421528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b5c8255d0e53ae789bf505000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_issuance', {'source': ADDR[0], 'transfer_destination': MULTISIGADDR[0], 'asset': 'DIVISIBLE', 'quantity': 0, 'divisible': True, 'callable': False, 'call_date': None, 'call_price': None, 'description': ''}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b02159415bf04af834423d3dd7adb0dc727aa153863ef89fba5aee7a331af1e48754da21540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_order', {'source': MULTISIGADDR[0], 'give_asset': 'BTC', 'give_quantity': DP['small'], 'get_asset': 'XCP', 'get_quantity': DP['small'] * 2, 'expiration': DP['expiration'], 'fee_required': 0, 'fee_provided': DP['fee_provided']}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0211ecaf7ca87f0fd78a01d9a0d62221e55beef3722db8be72d254adc40426108bc1421528340c37d005aa9e764ded8c038ffa94625307a450077125d580099b5c8255d0e53ae4880e605000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_order', {'source': MULTISIGADDR[0], 'give_asset': 'XCP', 'give_quantity': round(DP['small'] * 2.1), 'get_asset': 'BTC', 'get_quantity': DP['small'], 'expiration': DP['expiration'], 'fee_required': DP['fee_required']}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0211ecaf7ca87f0fd78a01d9a0d62221e55beef3722da8be72d254e649c826108bc1421528340c27d005aa9e06bcf58c038ffa946253077fea077125d580099b5c8255d0e53ae789bf505000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_dividend', {'source': ADDR[0], 'quantity_per_unit': DP['quantity'], 'asset': 'DIVISIBLE', 'dividend_asset': 'XCP'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0215a415bf04af834423d3dd7ad96dc727a030d90949e9fba5a4c21d05197e58754da21540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_dividend', {'source': ADDR[0], 'quantity_per_unit': 1, 'asset': 'NODIVISIBLE', 'dividend_asset': 'XCP'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0215a415bf04af834423d3dd7ad96dc727a030865759f9fbc9036a64c1197e58754da21540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe724e88ec81d53ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }] 
    }
}