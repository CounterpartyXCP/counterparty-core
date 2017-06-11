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
    ['order', (ADDR[0], config.XCP, DP['quantity'], 'DIVISIBLE', DP['quantity'], 2000, 0), {'encoding': 'multisig'}],
    ['send', (ADDR[0], ADDR[1], 'DIVISIBLE', DP['quantity']), {'encoding': 'multisig'}, None],
    ['send', (ADDR[0], ADDR[1], config.XCP, DP['quantity']), {'encoding': 'multisig'}, None],
    ['order', (ADDR[0], config.XCP, DP['quantity'], 'DIVISIBLE', DP['quantity'], 2000, 0), {'encoding': 'multisig'}],
    ['order', (ADDR[0], config.XCP, DP['quantity'], config.BTC, round(DP['quantity'] / 100), 2000, DP['fee_required']), {'encoding': 'multisig'}],
    ['order', (ADDR[0], config.BTC, round(DP['quantity'] / 150), config.XCP, DP['quantity'], 2000, 0), {'encoding': 'multisig', 'fee_provided': DP['fee_provided']}],
    ['send', (ADDR[0], MULTISIGADDR[0], config.XCP, DP['quantity'] * 3), {'encoding': 'multisig'}, None],
    ['send', (ADDR[0], MULTISIGADDR[0], 'DIVISIBLE', DP['quantity'] * 10), {'encoding': 'multisig'}, None],
    ['send', (ADDR[0], ADDR[1], 'NODIVISIBLE', 5), {'encoding': 'multisig'}, None],
    ['send', (ADDR[0], MULTISIGADDR[0], 'NODIVISIBLE', 10), {'encoding': 'multisig'}, None],
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
    ['send', (ADDR[0], P2SH_ADDR[0], 'DIVISIBLE', DP['quantity']), {'encoding': 'multisig'}, None],
    ['broadcast', (P2SH_ADDR[0], 1388000002, 1, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'opreturn'}],
    ['bet', (P2SH_ADDR[0], P2SH_ADDR[0], 3, 1388000200, 10, 10, 0.0, 5040, 1000), {'encoding': 'opreturn'}],

    # locked with an issuance after lock
    ['issuance', (ADDR[6], None, 'LOCKEDPREV', 1000, True, 'Locked asset'), {'encoding': 'multisig'}],
    ['issuance', (ADDR[6], None, 'LOCKEDPREV', 0, True, 'LOCK'), {'encoding': 'multisig'}],
    ['issuance', (ADDR[6], None, 'LOCKEDPREV', 0, True, 'changed'), {'encoding': 'multisig'}],

    ['create_next_block', 480],

    # force 2 enhanced sends
    ['send', (ADDR[0], ADDR[1], config.XCP, DP['quantity'], 'hello', False, True), {'encoding': 'opreturn'}, {'enhanced_sends': True}],
    ['send', (ADDR[1], ADDR[0], config.XCP, DP['quantity'], 'fade0001', True, True), {'encoding': 'opreturn'}, {'enhanced_sends': True}],

    ['create_next_block', 485],

    ['broadcast', (ADDR[4], 1388000000, 1, DP['fee_multiplier'], 'Unit Test'), {'encoding': 'multisig'}],
    ['bet', (ADDR[4], ADDR[4], 1, 1388000001, 9, 9, 0.0, 5040, 100), {'encoding': 'multisig'}],

    # To test REQUIRE_MEMO
    ['broadcast', (ADDR[4], 1388000002, 1, 0.0, 'options 0'), {'encoding': 'multisig'}, {'options_require_memo': True}],

    ['broadcast', (ADDR[4], 1388000003, 1, 0.0, 'lock'), {'encoding': 'multisig'}],

    # To test REQUIRE_MEMO
    ['broadcast', (ADDR[6], 1388000004, 1, 0.0, 'options 1'), {'encoding': 'multisig'}, {'options_require_memo': True}],

    #['create_next_block', 490],

    ['order', (ADDR[0], config.XCP, DP['quantity'], config.BTC, round(DP['quantity'] / 125), 2000, DP['fee_required']), {'encoding': 'multisig'}],
    ['order', (ADDR[1], config.BTC, round(DP['quantity'] / 125), config.XCP, DP['quantity'], 2000, 0), {'encoding': 'multisig', 'fee_provided': DP['fee_provided']}],
    ['burn', (ADDR[2], DP['burn_quantity']), {'encoding': 'multisig'}],
    ['issuance', (ADDR[2], None, 'DIVIDEND', 100, True, 'Test dividend'), {'encoding': 'multisig'}],
    ['send', (ADDR[2], ADDR[3], 'DIVIDEND', 10), {'encoding': 'multisig'}, None],
    ['send', (ADDR[2], ADDR[3], config.XCP, 92945878046), {'encoding': 'multisig'}, None],

    ['issuance', (ADDR[0], None, 'PARENT', DP['quantity'] * 1, True, 'Parent asset'), {'encoding': 'opreturn'}],
    ['issuance', (ADDR[0], None, 'PARENT.already.issued', DP['quantity'] * 1, True, 'Child of parent'), {'encoding': 'opreturn'}],

    ['create_next_block', 500],
]

PARSEBLOCKS_FIXTURE = UNITTEST_FIXTURE + [
    ['create_next_block', 501, False]  # parse_block=False so we can unittest blocks.parse_block
]

def generate_standard_scenario(address1, address2, order_matches):
    """Return a predefined set of transactions to test different types of signing."""
    return [
        ['burn', (address1, int(.62 * DP['quantity'])), {'encoding': 'multisig'}],
        ['send', (address1, address2, config.XCP, DP['small']), {'encoding': 'multisig'}, None],
        ['order', (address1, config.BTC, DP['small'], config.XCP, DP['small'] * 2, DP['expiration'], 0), {'encoding': 'multisig', 'fee_provided': DP['fee_provided']}],
        ['order', (address1, config.XCP, round(DP['small'] * 2.1), config.BTC, DP['small'], DP['expiration'], DP['fee_required']), {'encoding': 'multisig'}],
        ['btcpay', (address1, order_matches[0]), {'encoding': 'multisig'}],
        ['issuance', (address1, None, 'BBBB', DP['quantity'] * 10, True, ''), {'encoding': 'multisig'}],
        ['issuance', (address1, None, 'BBBC', round(DP['quantity'] / 1000), False, 'foobar'), {'encoding': 'multisig'}],
        ['send', (address1, address2, 'BBBB', round(DP['quantity'] / 25)), {'encoding': 'multisig'}, None],
        ['send', (address1, address2, 'BBBC', round(DP['quantity'] / 190000)), {'encoding': 'multisig'}, None],
        ['dividend', (address1, 600, 'BBBB', config.XCP), {'encoding': 'multisig'}],
        ['dividend', (address1, 800, 'BBBC', config.XCP), {'encoding': 'multisig'}],
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
        ['order', (address1, 'BBBB', DP['small'], config.XCP, DP['small'], DP['expiration'], 0), {'encoding': 'multisig'}],
        ['burn', (address1, (1 * DP['quantity']), True), {'encoding': 'multisig'}],  # Try to burn a whole 'nother BTC.
        ['send', (address1, address2, 'BBBC', 10000), {'encoding': 'multisig'}, None],
        ['create_next_block', 101]
    ]

standard_scenarios_params = {
    'simplesig': {
        'address1': ADDR[0],
        'address2': ADDR[1],
        'order_matches': [
            '507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379_178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424'
        ]
    },
    'multisig_1_of_2': {
        'address1': MULTISIGADDR[0],
        'address2': MULTISIGADDR[1],
        'order_matches': [
            '7a78df734fd910fcf9170d4af753c2ceda92974684b929ff595e6063ca5a2cf1_e75417825d1fe276bfb329960a3367c711dcb256aa2ed21da0f79a58120e2433'
        ]
    },
    'multisig_2_of_2': {
        'address1': MULTISIGADDR[3],
        'address2': MULTISIGADDR[4],
        'order_matches': [
            '82e2a0085961f5672c7bcf81a04abf78021d9b91c5f9e0d98421ce3cb083cd4e_371a06e55fbb3661941dc2300754556a09b6badc04aa182ee7d80842dd6cb9f1'
        ]
    },
    'multisig_1_of_3': {
        'address1': MULTISIGADDR[5],
        'address2': MULTISIGADDR[6],
        'order_matches': [
            'cb66a40be14321e489c3fa3455e62315e23f92244127f3f2c2f7eccb6d75b052_beaa1fddda140d119b4e5c94aa81f2e25e5550c18f3180c0f791ef6e7ad35754'
        ]
    },
    'multisig_2_of_3': {
        'address1': MULTISIGADDR[7],
        'address2': MULTISIGADDR[8],
        'order_matches': [
            '12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8_792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c'
        ]
    },
    'multisig_3_of_3': {
        'address1': MULTISIGADDR[9],
        'address2': MULTISIGADDR[10],
        'order_matches': [
            '53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71_cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16'
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
