"""
This file defines the fixtures used for unit testing and integration testing scenarios. The fixtures are required to test the
full range of functionality. They are also used in integration testing, with additional scenarios to test different signing types.
The folder `test/fixtures/scenarios` contains the expected output (.json, .log and .sql) for each scenario. The integration suite
tests if the outputs of all scenarios are identical. It also tests the similarity between the output of a scenario and its base
scenario (for instance `simplesig` scenario is the base scenario for all mutlisig scenarios).

To add (or update) a transaction in a scenario, or add a scenario, just update `scenarios.py` and run `py.test --skiptestbook=all --savescenarios`
This command will generates new outputs for each scenario (.new.json, .new.sql and .new.log), if you are satisfied with the new output just rename them (remove the .new). 
You need to do this every time you update UNITTEST_FIXTURE.

```
mv counterpartylib/test/fixtures/scenarios/unittest_fixture.new.json counterpartylib/test/fixtures/scenarios/unittest_fixture.json
mv counterpartylib/test/fixtures/scenarios/unittest_fixture.new.sql counterpartylib/test/fixtures/scenarios/unittest_fixture.sql
mv counterpartylib/test/fixtures/scenarios/unittest_fixture.new.log counterpartylib/test/fixtures/scenarios/unittest_fixture.log
```

Before every entry in UNITTEST_FIXTURE is executed a block is inserted first, so each of them has a +1 block_index.
The `create_next_block` that appears a few times bumps the height to a fixed number to keep things easier to test against.
When you add more fixtures, add before 310490, that won't affect any of other vector (for a while).

Some functions' output depends on scenarios staying the same (for instance, function returning the last message).
Here's a list of unit tests that will fail and need to be updated:
- blocks.get_next_tx_index
- blocks.parse_block
- util.last_message
- util.get_balance
"""

from .params import ADDR, MULTISIGADDR, P2SH_ADDR, DEFAULT_PARAMS as DP

UNITTEST_FIXTURE = [
    ['burn', (ADDR[0], DP['burn_quantity']), {'encoding': 'multisig'}],  # 310000
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
    ['broadcast', (ADDR[0], 1388000000, 1, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],
    ['broadcast', (ADDR[2], 1288000000, 1, 0.0, 'lock'), {'encoding': 'multisig'}],
    ['bet', (ADDR[0], ADDR[0], 1, 1388000001, 9, 9, 0.0, 5040, 100), {'encoding': 'multisig'}],
    ['bet', (ADDR[1], ADDR[0], 0, 1388000001, 9, 9, 0.0, 5040, 100), {'encoding': 'multisig'}],
    ['create_next_block', 100],  # 310100
    ['bet', (ADDR[1], ADDR[0], 3, 1388000200, 10, 10, 0.0, 5040, 1000), {'encoding': 'multisig'}],
    ['broadcast', (ADDR[0], 1388000002, 1, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],

    ['burn', (ADDR[4], DP['burn_quantity']), {'encoding': 'multisig'}],
    ['burn', (ADDR[5], DP['burn_quantity']), {'encoding': 'multisig'}],
    ['burn', (ADDR[6], DP['burn_quantity']), {'encoding': 'multisig'}],

    ['burn', (P2SH_ADDR[0], int(DP['burn_quantity'] / 2)), {'encoding': 'opreturn'}],
    ['issuance', (P2SH_ADDR[0], None, 'PAYTOSCRIPT', 1000, False, 'PSH issued asset'), {'encoding': 'multisig', 'dust_return_pubkey': False}],
    ['send', (ADDR[0], P2SH_ADDR[0], 'DIVISIBLE', DP['quantity']), {'encoding': 'multisig'}],
    ['broadcast', (P2SH_ADDR[0], 1388000002, 1, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'opreturn'}],
    ['bet', (P2SH_ADDR[0], P2SH_ADDR[0], 3, 1388000200, 10, 10, 0.0, 5040, 1000), {'encoding': 'opreturn'}],
    ['create_next_block', 490],  # 310490

    ['order', (ADDR[0], 'XCP', DP['quantity'], 'BTC', round(DP['quantity'] / 125), 2000, DP['fee_required']), {'encoding': 'multisig'}],
    ['order', (ADDR[1], 'BTC', round(DP['quantity'] / 125), 'XCP', DP['quantity'], 2000, 0), {'encoding': 'multisig', 'fee_provided': DP['fee_provided']}],
    ['burn', (ADDR[2], DP['burn_quantity']), {'encoding': 'multisig'}],
    ['issuance', (ADDR[2], None, 'DIVIDEND', 100, True, 'Test dividend'), {'encoding': 'multisig'}],
    ['send', (ADDR[2], ADDR[3], 'DIVIDEND', 10), {'encoding': 'multisig'}],
    ['send', (ADDR[2], ADDR[3], 'XCP', 92945878046), {'encoding': 'multisig'}],

    ['create_next_block', 500],
]

PARSEBLOCKS_FIXTURE = UNITTEST_FIXTURE + [
    ['create_next_block', 501, False]  # parse_block=False so we can unittest blocks.parse_block
]

def generate_standard_scenario(address1, address2, order_matches):
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
        ['create_next_block', 101]
    ]

standard_scenarios_params = {
    'simplesig' : {
        'address1': ADDR[0],
        'address2': ADDR[1],
        'order_matches': [
            'ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a'
        ]
    },
    'multisig_1_of_2': {
        'address1': MULTISIGADDR[0],
        'address2': MULTISIGADDR[1],
        'order_matches': [
            '2593e61dff78d2397647bfa9c14c7b17b23b2bb1b446bde8dd23f537b56870df_dda95fb9e4ccadc9e511622585ff74889c8f76dd572f9b40bb5af1242b1e6f30'
        ]
    },
    'multisig_2_of_2': {
        'address1': MULTISIGADDR[3],
        'address2': MULTISIGADDR[4],
        'order_matches': [
            '21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7_dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643'
        ]
    },
    'multisig_1_of_3': {
        'address1': MULTISIGADDR[5],
        'address2': MULTISIGADDR[6],
        'order_matches': [
            'e1c19fef00aa067d54fcd72239999d499470c41f878807bb67e681a03ee61517_9bc459c9d72bcc916e391d7d393cabb21fb3edb9369837452babc6f0e0c9d83d'
        ]
    },
    'multisig_2_of_3': {
        'address1': MULTISIGADDR[7],
        'address2': MULTISIGADDR[8],
        'order_matches': [
            'b898ed7f73ba34981adde222bf27498f66f352254817b0f4d07156a62b387e86_bc36229a30165dd3d5f927646292fa4b1b024c50ed3490ce578946020f4f29ed'
        ]
    },
    'multisig_3_of_3': {
        'address1': MULTISIGADDR[9],
        'address2': MULTISIGADDR[10],
        'order_matches': [
            '17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b_89e7f3ea3c4c7bb01ac12d4b4eb8583e8d5351f7d03cf2221c194d324c3ce345'
        ]
    }
}

INTEGRATION_SCENARIOS = {
    'unittest_fixture': (UNITTEST_FIXTURE, 'unittest_fixture'),
    'parseblock_unittest_fixture': (PARSEBLOCKS_FIXTURE, 'parseblock_unittest_fixture')
}
# Generate special tests for simplesig, multisig2 and multisig3 using standard scenario.
for scenario_name in standard_scenarios_params:
    INTEGRATION_SCENARIOS[scenario_name] = (generate_standard_scenario(**standard_scenarios_params[scenario_name]), 'simplesig')
