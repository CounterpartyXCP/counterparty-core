"""
This file defines the fixtures used for unit testing and integration testing scenarios. The fixtures are required to test the
full range of functionality. They are also used in integration testing, with additional scenarios to test different signing types.
The folder `test/fixtures/scenarios` contains the expected output (.json, .log and .sql) for each scenario. The integration suite
tests if the outputs of all scenarios are identical. It also tests the similarity between the output of a scenario and its base
scenario (for instance `simplesig` scenario is the base scenario for all mutlisig scenarios).

To add (or update) a transaction in a scenario, or add a scenario, just update `scenarios.py` and run `py.test --skiptestbook=all --savescenarios`
This command will generates new outputs for each scenario (.new.json, .new.sql and .new.log), if you are satisfied with the new output just rename them (remove the .new). 
You need to do this every time you update UNITTEST_FIXTURE.
"""

from .params import ADDR, MULTISIGADDR, DEFAULT_PARAMS as DP

UNITTEST_FIXTURE = [
    ['burn', (ADDR[0], DP['burn_quantity']), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'DIVISIBLE', DP['quantity'] * 1000, True, 'Divisible asset'), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'NODIVISIBLE', 1000, False, 'No divisible asset'), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'CALLABLE', 1000, True, 'Callable asset'), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'LOCKED', 1000, True, 'Locked asset'), {'encoding': 'multisig'}],
    ['issuance', (ADDR[0], None, 'LOCKED', 0, True, 'LOCK'), {'encoding': 'multisig'}],
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
    ['issuance', (ADDR[0], None, 'MAXI', 2**63 - 1, True, 'Maximum quantity'), {'encoding': 'multisig'}],
    ['create_next_block', 490],
    ['order', (ADDR[0], 'XCP', DP['quantity'], 'BTC', round(DP['quantity'] / 125), 2000, DP['fee_required']), {'encoding': 'multisig'}],
    ['order', (ADDR[1], 'BTC', round(DP['quantity'] / 125), 'XCP', DP['quantity'], 2000, 0), {'encoding': 'multisig', 'fee_provided': DP['fee_provided']}],
    ['broadcast', (ADDR[0], 1388000000, 1, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],
    ['broadcast', (ADDR[2], 1288000000, 1, 0.0, 'lock'), {'encoding': 'multisig'}],
    ['create_next_block', 500]
]

def generate_standard_scenario(address1, address2, order_matches, rps_matches):
    """Return a predefined set of transactions to test different types of signing."""
    return [
        ['burn', (address1, int(.62 * DP['quantity'])), {'encoding': 'multisig'}],
        ['send', (address1, address2, 'XCP', DP['small']), {'encoding': 'multisig'}],
        ['order', (address1, 'BTC', DP['small'], 'XCP', DP['small'] * 2, DP['expiration'], 0), {'encoding': 'multisig', 'fee_provided': DP['fee_provided']}],
        ['order', (address1, 'XCP', round(DP['small'] * 2.1), 'BTC', DP['small'], DP['expiration'], DP['fee_required']), {'encoding': 'multisig'}],
        ['btcpay', (address1, order_matches[0]), {'encoding': 'multisig'}],
        ['issuance', (address1, None, 'BBBB', DP['quantity'] * 10, True, ''), {'encoding': 'multisig'}],
        ['issuance', (address1, None, 'BBBC', round(DP['quantity'] / 1000), False, 'foobar'), {'encoding': 'multisig'}],
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
            'ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a'
        ],
        'rps_matches': [
            '635a5afd4efab8ed4c70d2601dc5e7dbe9ea6b8d252e4eec4e642a8e0ba10b3f_ffffe0e5b05c7bb14d8d95f454e9769cfa03e1663551e2ac0077268a2a3c88f6',
            '40575c4cf1ee21282459c8c824be1cb2e28df26c6c83b9c85d431fc694f8257d_432f37fd7f18bdeece846f019649fcb632c65acdef437e88d817304d29a8ede4'
        ]
    },
    'multisig_1_of_2': {
        'address1': MULTISIGADDR[0],
        'address2': MULTISIGADDR[1],
        'order_matches': [
            '2593e61dff78d2397647bfa9c14c7b17b23b2bb1b446bde8dd23f537b56870df_dda95fb9e4ccadc9e511622585ff74889c8f76dd572f9b40bb5af1242b1e6f30'
        ],
        'rps_matches': [
            'fa7429664990690ac78274dca111dcb53ed3bd8ee0f3f728305a34db0b89d483_e744b41a49191f82166ec2e6f32c56a16b9c9c6ed91b9e7d5da97caf95d26df9',
            '71da68e9b75cbb99814fe92b9412d145461bd3edbe8d117bdf72eea40feecf47_92d92ee63d3e4eb1e51a3672eae30aee6a81672f88da24cc5a18376b88e5af00'
        ]
    },
    'multisig_2_of_2': {
        'address1': MULTISIGADDR[3],
        'address2': MULTISIGADDR[4],
        'order_matches': [
            '21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7_dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643'
        ],
        'rps_matches': [
            '2964df351f57ff2cc3bf820b9e412eb46d4a6c5dbc74e2ecf44a9f5a800efe15_d6b0c1ba482c7c2ae802e1230c248e0b22fd37cf050215c7c2e33f293e3d7b41',
            'c16a90462b02a2cbc36fe7f6c2a646797e975e2acbef1e2ea2a3d31ed0d08a8e_752e0181ee100e92c4cad221a3110a292ce8673016d86ae60f050f64a192b134'
        ]
    },
    'multisig_1_of_3': {
        'address1': MULTISIGADDR[5],
        'address2': MULTISIGADDR[6],
        'order_matches': [
            'e1c19fef00aa067d54fcd72239999d499470c41f878807bb67e681a03ee61517_9bc459c9d72bcc916e391d7d393cabb21fb3edb9369837452babc6f0e0c9d83d'
        ],
        'rps_matches': [
            'a630d19099224b43f91b5acea6cb869a7f6ce4ec0251b9328a4f704583d5ddfa_b9b251f5408be36ee5b0986e156aedb2253e41bfca654569d5bb7269a6585b1d',
            '448a55b6dcfe60bc7d3b3af156d783e084d035e81bcac810185943de4e78e8c8_324aab8528a27eb4c22fce5b7c94a7cd352dae783cf971ffeb4574485bfae1da'
        ]
    },
    'multisig_2_of_3': {
        'address1': MULTISIGADDR[7],
        'address2': MULTISIGADDR[8],
        'order_matches': [
            'b898ed7f73ba34981adde222bf27498f66f352254817b0f4d07156a62b387e86_bc36229a30165dd3d5f927646292fa4b1b024c50ed3490ce578946020f4f29ed'
        ],
        'rps_matches': [
            '03985f244743b2c4067608cf3e3540f921aa84f9a915c1cfb662fef681af8357_faf4abea3f7c5303a1c4622ce5ff80994f9523eb1cace08914eaa91a4c7a31df',
            '8dd0a5f27bcb77b5b3f9de3ab2bdb826d6d068e18d0d84e70d72ab24f96537be_ce5b732f98efdc6dd02355f406b521801b1cbe75739f5137217f9deed2419b85'
        ]
    },
    'multisig_3_of_3': {
        'address1': MULTISIGADDR[9],
        'address2': MULTISIGADDR[10],
        'order_matches': [
            '17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b_89e7f3ea3c4c7bb01ac12d4b4eb8583e8d5351f7d03cf2221c194d324c3ce345'
        ],
        'rps_matches': [
            'd98546f0bd5e60cbec32f303453d9a6eaf55c7d45c65535ca8bd67fe2ee5afdb_5f4e33b3e7312187c0c40b3b4eba522910859f0ce1e64c3d61fa0d52e71af970',
            '6201956b04ed01203fa7b204e1481268e4ac96910a504b4efad382357c6bf18f_d04c381ebded6c49c4e5a0f0b1746d61fb4dcd45c8dc280b29f7a0afa7a7eedc'
        ]
    }
}

INTEGRATION_SCENARIOS = {
    'unittest_fixture': (UNITTEST_FIXTURE, 'unittest_fixture')
}
# Generate special tests for simplesig, multisig2 and multisig3 using standard scenario.
for scenario_name in standard_scenarios_params:
    INTEGRATION_SCENARIOS[scenario_name] = (generate_standard_scenario(**standard_scenarios_params[scenario_name]), 'simplesig')
