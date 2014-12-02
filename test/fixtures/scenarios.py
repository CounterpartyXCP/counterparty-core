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
            'ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a'
        ],
        'rps_matches': [
            '7d2c0534f479c13d7e00ce9338e435be62bd8b9d13f781230da9cf7c0215e4b94ef4ac1d6a4c5f31a33425b0bd290f8a4ef26af380083b5874a4f3e6516c8fdc',
            '40575c4cf1ee21282459c8c824be1cb2e28df26c6c83b9c85d431fc694f8257d432f37fd7f18bdeece846f019649fcb632c65acdef437e88d817304d29a8ede4'
        ]
    },
    'multisig_1_of_2': {
        'address1': MULTISIGADDR[0],
        'address2': MULTISIGADDR[1],
        'order_matches': [
            '2593e61dff78d2397647bfa9c14c7b17b23b2bb1b446bde8dd23f537b56870dfdda95fb9e4ccadc9e511622585ff74889c8f76dd572f9b40bb5af1242b1e6f30'
        ],
        'rps_matches': [
            '7a08c17d9dd9e4796662f541701efe691b48684cb0f0c384a7f5bb542dea26656f01d2eb3703f4542954feb08433efa4e91a9ae55d95302eb262772d24739364',
            '71da68e9b75cbb99814fe92b9412d145461bd3edbe8d117bdf72eea40feecf4792d92ee63d3e4eb1e51a3672eae30aee6a81672f88da24cc5a18376b88e5af00'
        ]
    },
    'multisig_2_of_2': {
        'address1': MULTISIGADDR[3],
        'address2': MULTISIGADDR[4],
        'order_matches': [
            '21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643'
        ],
        'rps_matches': [
            'ec51d2115074f7c190057ed016a3cf0a88d778daa3336c2e333ca9136c7de4239fd41ab99bb1d38e2503288b55ee0e34245d2af4c12babceb222c3d854daa2f3',
            'c16a90462b02a2cbc36fe7f6c2a646797e975e2acbef1e2ea2a3d31ed0d08a8e752e0181ee100e92c4cad221a3110a292ce8673016d86ae60f050f64a192b134'
        ]
    },
    'multisig_1_of_3': {
        'address1': MULTISIGADDR[5],
        'address2': MULTISIGADDR[6],
        'order_matches': [
            'e1c19fef00aa067d54fcd72239999d499470c41f878807bb67e681a03ee615179bc459c9d72bcc916e391d7d393cabb21fb3edb9369837452babc6f0e0c9d83d'
        ],
        'rps_matches': [
            '6fc562b56b9126620d9bae5fa314b50710dcc56cd66e3526665b90ddb608a1b0174b542cb976b9ab11290aa35509774e39846a096605c783c8f5163c8156bf49',
            '448a55b6dcfe60bc7d3b3af156d783e084d035e81bcac810185943de4e78e8c8324aab8528a27eb4c22fce5b7c94a7cd352dae783cf971ffeb4574485bfae1da'
        ]
    },
    'multisig_2_of_3': {
        'address1': MULTISIGADDR[7],
        'address2': MULTISIGADDR[8],
        'order_matches': [
            'b898ed7f73ba34981adde222bf27498f66f352254817b0f4d07156a62b387e86bc36229a30165dd3d5f927646292fa4b1b024c50ed3490ce578946020f4f29ed'
        ],
        'rps_matches': [
            '6525c809f91a8b27811a6666d0c0b3be50b45e98d45d9b129a0742ac7f7d212f37d6d98de1ef78401344ff7ebd4d82cc29394d5447feff21f13332a805df4d94',
            '8dd0a5f27bcb77b5b3f9de3ab2bdb826d6d068e18d0d84e70d72ab24f96537bece5b732f98efdc6dd02355f406b521801b1cbe75739f5137217f9deed2419b85'
        ]
    },
    'multisig_3_of_3': {
        'address1': MULTISIGADDR[9],
        'address2': MULTISIGADDR[10],
        'order_matches': [
            '17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b89e7f3ea3c4c7bb01ac12d4b4eb8583e8d5351f7d03cf2221c194d324c3ce345'
        ],
        'rps_matches': [
            '4518e2a1dd95e57c406a3d3c4de23c1bf4bb47d32c00997a77f1b287be4794b8f4db04b005842971934da73fb379ace5c8649e77614a1a610544dd6d1a23622c',
            '6201956b04ed01203fa7b204e1481268e4ac96910a504b4efad382357c6bf18fd04c381ebded6c49c4e5a0f0b1746d61fb4dcd45c8dc280b29f7a0afa7a7eedc'
        ]
    }
}

INTEGRATION_SCENARIOS = {
    'unittest_fixture': (UNITEST_FIXTURE, 'unittest_fixture')
}
for scenario_name in standard_scenarios_params:
    INTEGRATION_SCENARIOS[scenario_name] = (generate_standard_scenario(**standard_scenarios_params[scenario_name]), 'simplesig')
