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
            '49419de600dbee1e2d5e379eb4a37739ee3360d506522bbf728a632d06ece726c740728c908e01df094c434fb58b6426d8359220e404edf24c6f6fd41971f6b6'
        ],
        'rps_matches': [
            'b08a7a28d03a62821b5510e6cedf936ab09216a45ba0ef51f234c5a4ee2aaa9aca94f4122a83adf4d27ee4836542e07e1b236d1ef33493e44d79a3edef0c3362',
            '2389f5719e05dedd11d0c0988cc74ac40caa3b19f2392987575d0ad6cbd037f4b18c2963e52589f5b9ff1731542d27a502436f37b578d1f610dcbccc705ba6ae'
        ]
    },
    'multisig_2_of_2': {
        'address1': MULTISIGADDR[3],
        'address2': MULTISIGADDR[4],
        'order_matches': [
            '878c11df1a0dc35b8cb39e2c35bdc3c7e1102e40ec03b704938cfa0d6a06ab0625b19174b9ed4bc5d692125e0bc572b5a7c935938155be20d04e650f09feffb0'
        ],
        'rps_matches': [
            '06577f103706ef5b6b4afaf2918a63b86034f3082f53b3baab38c1d9e5e3501c490c5880ea56313edb2a7e5f8b313a2bffb4852918e8c737d93ca512fc4be417',
            'cb91b1e26844266bd3dfbd8952f160d05a57a79ee2a7577f093c643ce6353e38771874b62b13a8efcdfc502b68cced7b1466838558bcc644bbc74cf7c18561a9'
        ]
    },
    'multisig_1_of_3': {
        'address1': MULTISIGADDR[5],
        'address2': MULTISIGADDR[6],
        'order_matches': [
            '73656ed61e13f5862872d2391beb8489e5d47d4fbe2e70ac44dc804794d12eb56cfa7e71bab6adf4cb495097c32645d57d0a2976c950151d50a0444c1a853a4d'
        ],
        'rps_matches': [
            '0aeeb0b82a9f62fd7fb00780ee626f5b11f697cba60a8e38456ac52f3c5103dcd5bbe3d346fd180e78ce6ddecad87a4feb3ee0e0b7c7f30944a01156f36a0c12',
            '93a6926b8b6ee2d4c8bf277c0ee2c51aaaf3dcb358be87993d328b852def2dcef2d714440922691756a8354ef8e77ba22f2c0cc91234c2610af394cf336df857'
        ]
    },
    'multisig_2_of_3': {
        'address1': MULTISIGADDR[7],
        'address2': MULTISIGADDR[8],
        'order_matches': [
            'e9f8fbc1ee2d161867e77aec88ec2cb7b69f41513e51d6189c5aad5a0dd6245b50155ea68921273f308d37e1e7c0b57672cb6d9146ced587ce18098f639153cf'
        ],
        'rps_matches': [
            'cf8c7134a6010e812d6f1df93517f8c2ea065cdd88a6ee51f69c85d6f686d614199064bea45ef1113fe46acd8c5992c45659f38d89d17e7ad3e5d0c768eb7b29',
            'ff755f79e47e0417b67e53c8d80f2eba9ef63f18e7825d2eb1b82bae882917d8b22358c5f5be7211ac3aed63e2594c00571b5307c83b088fd76c365e2d3725a4'
        ]
    },
    'multisig_3_of_3': {
        'address1': MULTISIGADDR[9],
        'address2': MULTISIGADDR[10],
        'order_matches': [
            '7efc440fe53509475e7c526af5dafe8752ef2a792df9ce552b9eba33373051c77582fcb849797577c29cbe6b2afa5c62b01c62f131d40de93ae9f0181f51fdf8'
        ],
        'rps_matches': [
            'cd05950b910c40fe30676bc669977fe9948faaaed9228bb385dbdac35b994cb76c35187c7c49b178fe7279abd490530fcef7f018f96c1406fe9c56112f4e43a4',
            'c489007df2a197940874a3992a00a7bd1a6770059bc7697b38d7c1b8100c0091dade89f45a70fd82cb410d6dca48ca2affcb85eb83701b6be3f1939dd0eb5bdc'
        ]
    }
}

INTEGRATION_SCENARIOS = {
    'unittest_fixture': (UNITEST_FIXTURE, 'unittest_fixture')
}
for scenario_name in standard_scenarios_params:
    INTEGRATION_SCENARIOS[scenario_name] = (generate_standard_scenario(**standard_scenarios_params[scenario_name]), 'simplesig')
