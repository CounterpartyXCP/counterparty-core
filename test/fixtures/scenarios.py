from .params import ADDR, MULTISIGADDR, DEFAULT_PARAMS as DP

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
    ['send', (ADDR[0], MULTISIGADDR[0], 'XCP', DP['quantity'] * 3), {'encoding': 'multisig'}],
    ['send', (ADDR[0], MULTISIGADDR[0], 'DIVISIBLE', DP['quantity'] * 10), {'encoding': 'multisig'}],
    ['send', (ADDR[0], ADDR[1], 'NODIVISIBLE', 5), {'encoding': 'multisig'}],
    ['send', (ADDR[0], MULTISIGADDR[0], 'NODIVISIBLE', 10), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'MAXI', 2**63 - 1, True, False, None, None, 'Maximum quantity'), {'encoding': 'multisig'}],
    ['create_next_block', 490],
    ['order', (ADDR[0], 'XCP', DP['quantity'], 'BTC', round(DP['quantity'] / 125), 2000, DP['fee_required']), {'encoding': 'multisig'}],
    ['order', (ADDR[1], 'BTC', round(DP['quantity'] / 125), 'XCP', DP['quantity'], 2000, 0), {'encoding': 'multisig', 'fee_provided': DP['fee_provided']}],
    ['create_next_block', 500]
]

def generate_standard_scenario(address1, address2, order_matches, rps_matches):
    return [
        ['burn', (address1, int(.62 * DP['quantity'])), {'encoding': 'multisig'}],
        ['send', (address1, address2, 'XCP', DP['small']), {'encoding': 'multisig'}],
        ['order', (address1, 'BTC', DP['small'], 'XCP', DP['small'] * 2, DP['expiration'], 0), {'encoding': 'multisig', 'fee_provided': DP['fee_provided']}],
        ['order', (address1, 'XCP', round(DP['small'] * 2.1), 'BTC', DP['small'], DP['expiration'], DP['fee_required']), {'encoding': 'multisig'}],
        ['btcpay', (address1, order_matches[0]), {'encoding': 'multisig'}],
        ['issuance', (address1, None, 'BBBB', DP['quantity'] * 10, True, False, 0, 0.0, ''), {'encoding': 'multisig'}],
        ['issuance', (address1, None, 'BBBC', round(DP['quantity'] / 1000), False, True, 17, 0.015, 'foobar'), {'encoding': 'multisig'}],
        ['send', (address1, address2, 'BBBB', round(DP['quantity'] / 25)), {'encoding': 'multisig'}],
        ['send', (address1, address2, 'BBBC', round(DP['quantity'] / 190000)), {'encoding': 'multisig'}],
        ['dividend', (address1, 600, 'BBBB', 'XCP'), {'encoding': 'multisig'}],
        ['dividend', (address1, 800, 'BBBC', 'XCP'), {'encoding': 'multisig'}],
        ['broadcast', (address1, 1388000000, 100, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],
        ['bet', (address1, address1, 0, 1388000100, DP['small'], round(DP['small'] / 2), 0.0, 15120, DP['expiration']), {'encoding': 'multisig'}],
        ['bet', (address1, address1, 1, 1388000100, round(DP['small'] / 2), round(DP['small'] * .83), 0.0, 15120, DP['expiration']), {'encoding': 'multisig'}],
        ['bet', (address1, address1, 0, 1388000100, DP['small'] * 3, DP['small'] * 7, 0.0, 5040, DP['expiration']), {'encoding': 'multisig'}],
        ['bet', (address1, address1, 1, 1388000100, DP['small'] * 7, DP['small'] * 3, 0.0, 5040, DP['expiration']), {'encoding': 'multisig'}],
        ['bet', (address1, address1, 2, 1388000200, DP['small'] * 15, DP['small'] * 13, 1, 5040, DP['expiration']), {'encoding': 'multisig'}],
        ['bet', (address1, address1, 3, 1388000200, DP['small'] * 13, DP['small'] * 15, 1, 5040, DP['expiration']), {'encoding': 'multisig'}],
        ['broadcast', (address1, 1388000050, round(100 - (.415/3) - .00001, 5), DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],
        ['broadcast', (address1, 1388000101, 100.343, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],
        ['broadcast', (address1, 1388000201, 2, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],
        ['order', (address1, 'BBBB', DP['small'], 'XCP', DP['small'], DP['expiration'], 0), {'encoding': 'multisig'}],
        ['burn', (address1, (1 * DP['quantity']), True), {'encoding': 'multisig'}],  # Try to burn a whole 'nother BTC.
        ['send', (address1, address2, 'BBBC', 10000), {'encoding': 'multisig'}],
        ['callback', (address1, .3, 'BBBC'), {'encoding': 'multisig'}],
        ['rps', (address1, 5, 11021663, DP['move_random_hash'], 100), {'encoding': 'multisig'}],
        ['rps', (address2, 5, 11021663, '6e8bf66cbd6636aca1802459b730a99548624e48e243b840e0b34a12bede17ec', 100), {'encoding': 'multisig'}],
        ['rpsresolve', (address1, 3, DP['rps_random'], rps_matches[0]), {'encoding': 'multisig'}],
        ['rpsresolve', (address2, 5, 'fa765e80203cba24a298e4458f63ff6b', rps_matches[0]), {'encoding': 'multisig'}],
        ['rps', (address1, 5, 11021663, DP['move_random_hash'], 10), {'encoding': 'multisig'}],
        ['create_next_block', 46],
        ['rps', (address1, 5, 11021664, DP['move_random_hash'], 10), {'encoding': 'multisig'}],
        ['rps', (address2, 5, 11021664, DP['move_random_hash'], 10), {'encoding': 'multisig'}],
        ['create_next_block', 73],
        ['rps', (address1, 5, 11021665, DP['move_random_hash'], 10), {'encoding': 'multisig'}],
        ['rps', (address2, 5, 11021665, DP['move_random_hash'], 10), {'encoding': 'multisig'}],
        ['rpsresolve', (address1, 3, DP['rps_random'], rps_matches[1]), {'encoding': 'multisig'}],
        ['create_next_block', 101]
    ]

standard_scenarios_params = {
    'simplesig' : {
        'address1': ADDR[0],
        'address2': ADDR[1], 
        'order_matches': [
            'b7a20fda89961cb1f3632fae11960769eb215b67092ab93911de977459c5b04cd646f64fb17ee3dc83700fae7d1155d2e2a7de1f634dd7dbd57fe7246f13f140'
        ], 
        'rps_matches': [
            'a54b7aea0e6875394b5ab938ab15a3b81f01303eedc7b726602357480e90cc90af5c2e5c41e84fbf96a7d03a5ae740552c4611786dc112826c75f147f1cd13eb',
            '2501cd2ee7e1c5f407e970b75a05ccbee4be74e605781de5dd3a6838a165f7bf72fe4a5e983752587b92edbb5da26c67c7f2968d2dde2e0f930acfce1ab9b669'
        ]
    }, 
    'multisig_1_of_2': {
        'address1': MULTISIGADDR[0],
        'address2': MULTISIGADDR[1],
        'order_matches': [
            '3f995494228c67860250b3ab0decf77e9467fed9dc15dbd278ddf3f9aef0acd2a667e44ce48fcd05a74130bd8cf564486a3017b8afb24fa369249d77f21bd253'
        ], 
        'rps_matches': [
            '08dd31a576fc835a651c7ce8818bf80a3c16b973ec5055ae5f6b1c75567c9e33dcc4b9ea7e9b98d2c9376c7a3240b7019de79bd0074039d652d27781b6a13011',
            '640f166066e9396abc163df5826a5184631fbccb470ce0724ef3349ed452fb62ce4d806a2f6266051585fc979e3a89f4c7b6a18ea0b41f51bfb26336137c4f26'
        ]
    }, 
    'multisig_2_of_2': {
        'address1': MULTISIGADDR[3],
        'address2': MULTISIGADDR[4],
        'order_matches': [
            '75799f04ade223ea1cc29121fa1cb7ca550da1cee549a87439994202d0d2585aa59a47b4b1cc072b8dfbcca228a00d700ccf0a66171aa50553e1ac32bbdd231d'
        ], 
        'rps_matches': [
            '3b5d38ad9a5470b642b4281483180a2368f2bc32f82e842fcec508d5f9341afe2b9193f719d4aaa4234a04a7a8e52a7584bd9e69dac2ea0dbd32b5eac8801aad',
            '31c71e187fc92b453d3d7cf6bbb4dde8755c40ef0cc08b2781b41b26f4e67d4f7a96ab193c6236d79834e90625cefc3cabcebb9d889663e3e137d6e546055ec5'
        ]
    }, 
    'multisig_1_of_3': {
        'address1': MULTISIGADDR[5],
        'address2': MULTISIGADDR[6],
        'order_matches': [
            'f744c1d46e9da6abb4768c8b44ee63a44b5513f86eabbbd4784bc6c961d566e508fe83094e172ee642271aac7b75980974d6b9f7ec614dbb380323892a4f1a46'
        ], 
        'rps_matches': [
            '35947f8727ab7834eab73084906d49dbd1ca50464efd17f602b3b942d6bbb34c7c9c7932b4c7410f0a7d4a5e8906ead88628b6ef25adc7a8f0e944764fb2bb3e',
            '1514d02df03b5126de43e78d7cc2f879d0688fbfea67eb64cfbda0add0aa412e539801eca19ca1c68f479b6ec9db353445481f921ec8cde51f4c042c3f41923a'
        ]
    }, 
    'multisig_2_of_3': {
        'address1': MULTISIGADDR[7],
        'address2': MULTISIGADDR[8],
        'order_matches': [
            'c27012f72d283a3e8dbfe1f4a65c2b0cc52f8387544f1a7b15b82eacb374b40e02197e98a43ac5d531f16fd72c7e9e7a3f448fc4bc0a4de4bf210b5124da8dd5'
        ], 
        'rps_matches': [
            '6220983855032fbd448a9cc20cddee130917f5f6ff5da67c6072a23635ce6dbe5a2766d9238954d214b185b75afb248f568f85bfa4df6a9409dc683f99e57370',
            '9feb47e813a167025c4d4ac9527a0a1067dd1774db20b16ae4732a39525b72ddb473bef4fad6f9fce39ed5be529539fbed0c41c3f6451018e70455875b6fa93b'
        ]
    }, 
    'multisig_3_of_3': {
        'address1': MULTISIGADDR[9],
        'address2': MULTISIGADDR[10],
        'order_matches': [
            '791e7db77ec2e974dc7912af2f09bb5b00bdebee1fc0905ce5ce953128d13f638250f7b366140c67814c2063661c86267d7e9c744f5b87f2d73990e033e7c7f6'
        ], 
        'rps_matches': [
            'ab5efc8615faa7f9a4af81b4418fbd6dbd6a395804b2cd3b83eb49968b35480b2b35d8308052dbf05b804bc5ec0eec0e8c1e4fe4d75efde745a7733493e295b9',
            '68d8328f0d3fbdc45ac14d7982622964e9d6b99ad0be065ff6d8ed3fbeaa9a567edcdabe2c175888d827a2a9c514b5e62589255d5fbc171aa6092a954fa2c95a'
        ]
    }
}

INTEGRATION_SCENARIOS = {
    'unittest_fixture': (UNITEST_FIXTURE, 'unittest_fixture')
}
for scenario_name in standard_scenarios_params:
    INTEGRATION_SCENARIOS[scenario_name] = (generate_standard_scenario(**standard_scenarios_params[scenario_name]), 'simplesig')
