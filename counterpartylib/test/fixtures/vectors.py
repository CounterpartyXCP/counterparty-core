"""
This structure holds the unit test vectors. They are used to generate test cases in conftest.py.
The results are computed using check_outputs in util_test.py.
The function supports three types of output checks:
- Return values - 'out'
- Errors raised - 'error'
- Database changes - 'records'
- PRAGMA changes - 'pragma'
"""

from .params import ADDR, MULTISIGADDR, DEFAULT_PARAMS as DP

from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import script
from counterpartylib.lib.messages.scriptlib import processblock
from counterpartylib.lib.messages.scriptlib.processblock import ContractError
from counterpartylib.lib.api import APIError
from counterpartylib.lib.util import (DebitError, CreditError, QuantityError)
from fractions import Fraction

UNITTEST_VECTOR = {
    'bet': {
        'validate': [{
            'in': (ADDR[1], ADDR[0], 0, 1488000100, DP['small'], DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': ([], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 0, 1488000100, 2**32, DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': ([], 15120)
        },  {
            'in': (ADDR[0], ADDR[1], 3, 1388001000, DP['small'], DP['small'], 0.0, 5040, DP['expiration'], DP['default_block']),
            'out': (['feed doesn’t exist'], 5040)
        },  {
            'in': (ADDR[1], ADDR[0], -1, 1488000100, DP['small'], DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['unknown bet type'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 2, 1488000100, DP['small'], DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['leverage used with Equal or NotEqual'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 3, 1488000100, DP['small'], DP['small'], 0.0, 5000, DP['expiration'], DP['default_block']),
            'out': (['leverage used with Equal or NotEqual', 'leverage level too low'], 5000)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, DP['small'], DP['small'], 0.0, 15120, DP['expiration'], 312350),
            'out': (['CFDs temporarily disabled'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, 1.1 * DP['small'], DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['wager_quantity must be in satoshis'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, DP['small'], 1.1 * DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['counterwager_quantity must be in satoshis'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, DP['small'], DP['small'], 0.0, 15120, 1.1 * DP['expiration'], DP['default_block']),
            'out': (['expiration must be expressed as an integer block delta'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, -1 * DP['small'], DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['non‐positive wager'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, DP['small'], -1 * DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['non‐positive counterwager'], 15120)
        },  {
            'in': (ADDR[1], ADDR[2], 1, 1488000100, DP['small'], DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['feed is locked'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 1, -1488000100, DP['small'], DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': ( ['deadline in that feed’s past', 'negative deadline'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, DP['small'], DP['small'], 0.0, 15120, -1 * DP['expiration'], DP['default_block']),
            'out': (['negative expiration'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, DP['small'], DP['small'], 1.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['CFDs have no target value'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 2, 1488000100, DP['small'], DP['small'], -1.0, 5040, DP['expiration'], DP['default_block']),
            'out': (['negative target value'], 5040)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, DP['small'], DP['small'], 0.0, 15120, 8095, DP['default_block']),
            'out': (['expiration overflow'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, 2**63, DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['integer overflow'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, DP['small'], 2**63, 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['integer overflow'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 2**63, 1488000100, DP['small'], DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['unknown bet type', 'integer overflow'], 15120)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 1488000100, DP['small'], DP['small'], 0.0, 2**63, DP['expiration'], DP['default_block']),
            'out': (['integer overflow'], 2**63)
        },  {
            'in': (ADDR[1], ADDR[0], 1, 2**63, DP['small'], DP['small'], 0.0, 15120, DP['expiration'], DP['default_block']),
            'out': (['integer overflow'], 15120)
        }],
        'compose': [{
            'in': (ADDR[1], ADDR[0], 0, 1488000100, 2**32, DP['small'], 0.0, 15120, DP['expiration']),
            'error': (exceptions.ComposeError, 'insufficient funds')
        },  {
            'in': (ADDR[1], ADDR[0], 0, 1488000100, DP['small'], DP['small'], 0.0, 15120, DP['expiration']),
            'out': (ADDR[1], [(ADDR[0], None)], b'\x00\x00\x00(\x00\x00X\xb1\x14d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n')
        }],
        'parse': [{
            'in': ({'block_hash': '46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58', 'block_time': 310501000, 'data': b'\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'block_index': 310501, 'supported': 1, 'btc_amount': 5430, 'tx_index': 502, 'tx_hash': 'a0ed83b170344b996bdd71799dd774ab10f5410f8572079a292f681d36ebc42c', 'fee': 10000, 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'},),
            'out': None
        },  {
            'in': ({'fee': 10000, 'tx_hash': '72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f', 'data': b'\x00\x00\x00(\x00\x00X\xb1\x14\x00\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x13\xb0\x00\x00\x00\n', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': 310501, 'btc_amount': 5430, 'tx_index': 502, 'supported': 1, 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_time': 310501000, 'block_hash': '46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58'},),
            'records': [
                {'table': 'bets', 'values': {'expire_index': 310511, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'wager_quantity': 100000000, 'feed_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'leverage': 5040, 'fee_fraction_int': 5000000, 'deadline': 1488000000, 'counterwager_quantity': 0, 'bet_type': 0, 'wager_remaining': 100000000, 'status': 'invalid: non‐positive counterwager', 'expiration': 10, 'tx_index': 502, 'tx_hash': '72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f', 'block_index': 310501, 'target_value': 0.0, 'counterwager_remaining': 0}}
            ]
        },  {
            'in': ({'supported': 1, 'data': b'\x00\x00\x00(\x00\x02R\xbb3\xc8\x00\x00\x00\x00\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x13\xb0\x00\x00\x03\xe8', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'btc_amount': 5430, 'block_index': 310501, 'block_hash': '46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58', 'tx_index': 502, 'tx_hash': '30b9ca8488a931dffa1d8d3ac8f1c51360a29cedb7c703840becc8a95f81188c', 'block_time': 310501000, 'fee': 10000},),
            'records': [
                {'table': 'bets', 'values': {'wager_quantity': 10, 'counterwager_quantity': 10, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'target_value': 0.0, 'expiration': 1000, 'leverage': 5040, 'tx_hash': '30b9ca8488a931dffa1d8d3ac8f1c51360a29cedb7c703840becc8a95f81188c', 'counterwager_remaining': 0, 'wager_remaining': 0, 'expire_index': 311501, 'bet_type': 2, 'fee_fraction_int': 5000000, 'block_index': 310501, 'tx_index': 502, 'deadline': 1388000200, 'feed_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'status': 'filled'}},
                {'table': 'bets', 'values': {'wager_quantity': 10, 'counterwager_quantity': 10, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'target_value': 0.0, 'expiration': 1000, 'leverage': 5040, 'tx_hash': 'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a', 'counterwager_remaining': 0, 'wager_remaining': 0, 'expire_index': 311101, 'bet_type': 3, 'fee_fraction_int': 5000000, 'block_index': 310101, 'tx_index': 102, 'deadline': 1388000200, 'feed_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'status': 'filled'}}
            ]
        }],
        'get_fee_fraction': [{
            'in': (ADDR[1],),
            'out': (0)
        },  {
            'in': (ADDR[0],),
            'out': (0.05)
        },  {
            'in': (ADDR[2],),
            'out': (0)
        }],
        # TODO: Test match by calling parse. Add all skipping modes
        'match': [{
            'in': ({'tx_index': 99999999},),
            'out': None
        },  {
            'in': ({'block_hash': '46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58', 'block_time': 310501000, 'data': b'\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'block_index': 310501, 'supported': 1, 'btc_amount': 5430, 'tx_index': 502, 'tx_hash': 'a0ed83b170344b996bdd71799dd774ab10f5410f8572079a292f681d36ebc42c', 'fee': 10000, 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'},),
            'out': None
        }],
        # Testing expiration of normal bets is impossible - either the bet is expired automatically with expiry < 310500 or
        # with expire > 310500 insert fails with FOREIGN KEY error on block_index (which doesn't exist). With expiry 310500 nothing happens.
        # Testing bet_match expirations is impossible too, since if you add a bet_match with 'pending' status to the fixtures, it raises a ConsensusError in blocks.parse_block.
        # 'expire': [{
        #     'in': (DP['default_block'] - 1, 5388000200,),
        #     'records': [
        #         {'table': 'bet_match_expirations', 'values': {'bet_match_id': '94c900515ecf53680e98d51216c520ccb6b91a72d5aff7f62665d6328d4db832_ee5ea2ce1a423157bbb1edbabcadf2dc3adcd328d17c52c44f63dbda835f9125', 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'block_index':  DP['default_block'] - 1}}
        #     ]
        # }],
        'cancel_bet': [{
            'in': ({'counterwager_quantity': 10, 'wager_remaining': 10, 'target_value': 0.0, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'feed_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'counterwager_remaining': 10, 'tx_index': 102, 'block_index': 310101, 'deadline': 1388000200, 'bet_type': 3, 'expiration': 1000, 'expire_index': 311101, 'tx_hash': 'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a', 'leverage': 5040, 'wager_quantity': 10, 'fee_fraction_int': 5000000, 'status': 'open'}, 'filled', DP['default_block']),
            'records': [
                {'table': 'bets', 'values': {'counterwager_quantity': 10, 'wager_remaining': 10, 'target_value': 0.0, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'feed_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'counterwager_remaining': 10, 'tx_index': 102, 'block_index': 310101, 'deadline': 1388000200, 'bet_type': 3, 'expiration': 1000, 'expire_index': 311101, 'tx_hash': 'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a', 'leverage': 5040, 'wager_quantity': 10, 'fee_fraction_int': 5000000, 'status': 'filled'}}
            ]
        }],
        'cancel_bet_match': [{
            'in': ({'tx0_block_index': 310019, 'backward_quantity': 9, 'initial_value': 1, 'tx1_expiration': 100, 'id': 'be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd_90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5', 'feed_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'status': 'settled', 'leverage': 5040, 'target_value': 0.0, 'fee_fraction_int': 5000000, 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'deadline': 1388000001, 'tx1_bet_type': 0, 'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx0_index': 20, 'tx1_hash': '90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5', 'tx0_hash': 'be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd', 'block_index': 310020, 'forward_quantity': 9, 'match_expire_index': 310119, 'tx1_block_index': 310020, 'tx0_expiration': 100, 'tx1_index': 21, 'tx0_bet_type': 1}, 'filled', DP['default_block']),
            'records': [
                {'table': 'bet_matches', 'values': {'tx0_block_index': 310019, 'backward_quantity': 9, 'initial_value': 1, 'tx1_expiration': 100, 'id': 'be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd_90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5', 'feed_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'status': 'filled', 'leverage': 5040, 'target_value': 0.0, 'fee_fraction_int': 5000000, 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'deadline': 1388000001, 'tx1_bet_type': 0, 'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx0_index': 20, 'tx1_hash': '90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5', 'tx0_hash': 'be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd', 'block_index': 310020, 'forward_quantity': 9, 'match_expire_index': 310119, 'tx1_block_index': 310020, 'tx0_expiration': 100, 'tx1_index': 21, 'tx0_bet_type': 1}}
            ]
        }],
    },
    'blocks': {
        'parse_tx': [{
            'in': ({'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc-mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj', 'supported': 1, 'block_index': DP['default_block'], 'fee': 10000, 'block_time': 155409000, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': 7800, 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00', 'tx_index': 502, 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'},),
            'out': None
        },  {
            'in': ({'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'supported': 1, 'block_index': DP['default_block'], 'fee': 10000, 'block_time': 155409000, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': 7800, 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00', 'tx_index': 502, 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns-mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj'},),
            'out': None
        }],
        'parse_block': [{
            'in': (DP['default_block'] - 1, 1420914478),
            'out': ('bc2a2e09a881d5e382904ee20025c7b0c50006a445ac4635d4282234212429a1', '7a345ce55acea2b33aeefd37dcc20bbf8dd6cd98b6b0a4f0697c001f854af85a', '73581237adaf4842a9fba69241f2989588427488b3833ed371bc8ca239187b63', '73581237adaf4842a9fba69241f2989588427488b3833ed371bc8ca239187b63')
        }],
        'get_next_tx_index': [{
            'in': (),
            'out': 498
        }],
        'last_db_index': [{
            'in': (),
            'out': 310500
        }],
        'get_tx_info': [{
            'in': (b'0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000',),
            'out': ('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 5430, 10000, b'\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n')
        }],
        'get_tx_info1': [{
            'in': (b'0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0636150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac36150000000000001976a9147da51ea175f108a1c63588683dc4c43a7146c46788ac36150000000000001976a9147da51ea175f108a1c6358868173e34e8ca75a06788ac36150000000000001976a9147da51ea175f108a1c637729895c4c468ca75a06788ac36150000000000001976a9147fa51ea175f108a1c63588682ed4c468ca7fa06788ace24ff505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000', DP['default_block']),
            'out': ('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 5430, 10000,  b'\x00\x00\x00(\x00\x00R\xbb3d\x00TESTXXXX\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00TESTXXXX\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00TESTXXXX\x00\x00\x00;\x10\x00\x00\x00\n\x9b\xb3Q\x92(6\xc8\x86\x81i\x87\xe1\x0b\x03\xb8_8v\x8b')
        }],
        'get_tx_info2': [{
            'in': (b'0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e000000000000695121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae4286f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000',),
            'out': ('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 5430, 10000, b'\x00\x00\x00(\x00\x00R\xbb3d\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00;\x10\x00\x00\x00\n')
        }],
    },
    'cancel': {
        'compose': [{
            'in': (ADDR[1], 'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a'),
            'out': ('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [], b'\x00\x00\x00F\xba\x0e\xf1\xdf\xbb\xc8}\xf9N\x1d\x19\x8b\x0e\x9e<\x060\x17\x10\xd4\xaa\xb3\xd8Q\x16\xcb\xc8\x19\x99TdJ')
        },  {
            'in': (ADDR[1], 'foobar'),
            'error': (exceptions.ComposeError, "['no open offer with that hash']")
        },  {
            'in': ('foobar', 'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a'),
            'error': (exceptions.ComposeError, "['incorrect source address']")
        },  {
            'in': (ADDR[1], '90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5'),
            'error': (exceptions.ComposeError, "['offer not open']")
        }],
        'parse': [{
            'in': ({'block_index': 310501, 'btc_amount': 0, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'data': b'\x00\x00\x00F\xba\x0e\xf1\xdf\xbb\xc8}\xf9N\x1d\x19\x8b\x0e\x9e<\x060\x17\x10\xd4\xaa\xb3\xd8Q\x16\xcb\xc8\x19\x99TdJ', 'block_hash': '46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58', 'tx_index': 502, 'fee': 10000, 'block_time': 310501000, 'tx_hash': 'fb645106e276bfa1abd587f4a251b26f491a2a9ae61ca46a669794109728b122', 'destination': '', 'supported': 1},),
            'out': None
        },  {
            'in': ({'block_index': 310501, 'btc_amount': 0, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'data': b'\x00\x00\x00F\xba\x0e\xf1\xdf\xbb\xc8}\xf9N\x1d\x19\x8b\x0e\x9e<\x060\x17\x10\xd4\xaa\xb3\xd8Q\x16\xcb\xc8\x19\x99TdJ', 'block_hash': '46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58', 'tx_index': 502, 'fee': 10000, 'block_time': 310501000, 'tx_hash': 'fb645106e276bfa1abd587f4a251b26f491a2a9ae61ca46a669794109728b122', 'destination': '', 'supported': 1},),
            'records': [
                {'table': 'cancels', 'values': {'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'block_index': 310501, 'offer_hash': 'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a', 'tx_index': 502, 'tx_hash': 'fb645106e276bfa1abd587f4a251b26f491a2a9ae61ca46a669794109728b122', 'status': 'valid'}},
                {'table': 'bets', 'values': {'counterwager_quantity': 10, 'wager_remaining': 10, 'target_value': 0.0, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'feed_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'counterwager_remaining': 10, 'tx_index': 102, 'block_index': 310101, 'deadline': 1388000200, 'bet_type': 3, 'expiration': 1000, 'expire_index': 311101, 'tx_hash': 'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a', 'leverage': 5040, 'wager_quantity': 10, 'fee_fraction_int': 5000000, 'status': 'cancelled'}}
           ]
        }],
    },
    'broadcast': {
        'validate': [{
            'in': (ADDR[0], 1588000000, 1, DP['fee_multiplier'], 'Unit Test', DP['default_block']),
            'out': ([])
        },  {
            'in': (ADDR[2], 1588000000, 1, DP['fee_multiplier'], 'Unit Test', DP['default_block']),
            'out': (['locked feed'])
        },  {
            'in': (ADDR[0], 1588000000, 1, 4294967296, 'Unit Test', DP['default_block']),
            'out': (['fee fraction greater than 42.94967295'])
        },  {
            'in': (ADDR[0], -1388000000, 1, DP['fee_multiplier'], 'Unit Test', DP['default_block']),
            'out': (['negative timestamp', 'feed timestamps not monotonically increasing'])
        },  {
            'in': (None, 1588000000, 1, DP['fee_multiplier'], 'Unit Test', DP['default_block']),
            'out': (['null source address'])
        }],
        'compose': [{
            'in': (ADDR[0], 1588000000, 1, DP['fee_multiplier'], 'Unit Test'),
            'out': (ADDR[0], [], b'\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00LK@\tUnit Test')
        },  {
            'in': (ADDR[0], 1588000000, 1, DP['fee_multiplier'], 'Over 52 characters test test test test test test test test'),
            'out': (ADDR[0], [], b'\x00\x00\x00\x1e^\xa6\xf5\x00?\xf0\x00\x00\x00\x00\x00\x00\x00LK@Over 52 characters test test test test test test test test')
        }],
        'parse': [{
            'in': ({'destination': '', 'block_index': 310501, 'supported': 1, 'data': b'\x00\x00\x00\x1eR\xbb3dA\x87\xd7\x84\x00\x00\x00\x00\x00\x00\x00\x00\x06BARFOO', 'fee': 10000, 'block_hash': '46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58', 'tx_index': 502, 'btc_amount': 0, 'block_time': 310501000, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_hash': 'dd48da950fd7d000224b79ebe3495fa594ca6d6698f16c4e2dc93b4f116006ea'},),
            'out': None
        },  {
            'in': ({'destination': '', 'block_index': 310501, 'supported': 1, 'data': b'\x00\x00\x00\x1eR\xbb3dA\x87\xd7\x84\x00\x00\x00\x00\x00\x00\x00\x00\x06BARFOO', 'fee': 10000, 'block_hash': '46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58', 'tx_index': 502, 'btc_amount': 0, 'block_time': 310501000, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_hash': 'dd48da950fd7d000224b79ebe3495fa594ca6d6698f16c4e2dc93b4f116006ea'},),
            'records': [
                {'table': 'broadcasts', 'values': {'text': 'BARFOO', 'block_index': 310501, 'fee_fraction_int': 0, 'status': 'valid', 'locked': 0, 'timestamp': 1388000100, 'tx_index': 502, 'value': 50000000.0, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_hash': 'dd48da950fd7d000224b79ebe3495fa594ca6d6698f16c4e2dc93b4f116006ea'}},
            ]
        },  {
            'in': ({'fee': 10000, 'btc_amount': 0, 'supported': 1, 'block_hash': '46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58', 'tx_index': 502, 'block_time': 310501000, 'destination': '', 'block_index': 310501, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_hash': 'c9e8db96d520b0611218504801e74796ae4f476578512d21d3f99367ab8e356f', 'data': b'\x00\x00\x00\x1eR\xbb4,\xc0\x00\x00\x00\x00\x00\x00\x00\x00LK@\tUnit Test'},),
            'records': [
                {'table': 'broadcasts', 'values':  {'text': 'Unit Test', 'value': -2.0, 'tx_index': 502, 'timestamp': 1388000300, 'fee_fraction_int': 5000000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'locked': 0, 'block_index': 310501, 'status': 'valid', 'tx_hash': 'c9e8db96d520b0611218504801e74796ae4f476578512d21d3f99367ab8e356f'}},
                {'table': 'bets', 'values': {'target_value': 0.0, 'tx_index': 102, 'status': 'dropped', 'fee_fraction_int': 5000000, 'expiration': 1000, 'feed_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'expire_index': 311101, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'deadline': 1388000200, 'counterwager_quantity': 10, 'tx_hash': 'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a', 'bet_type': 3, 'block_index': 310101, 'leverage': 5040, 'wager_quantity': 10, 'counterwager_remaining': 10, 'wager_remaining': 10}}
            ]
        },  {
            'in': ({'btc_amount': 0, 'block_hash': '46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'destination': '', 'block_index': 310501, 'fee': 10000, 'supported': 1, 'block_time': 310501000, 'tx_hash': '6b4a62b80f35b0e66df4591c8a445d453d995609e2df12afe93e742bea10dd86', 'tx_index': 502, 'data': b'\x00\x00\x00\x1eR\xbb3dA\x87\xd7\x84\x00\x00\x00\x00\x00\x00\x00\x00\x04LOCK'},),
            'records': [
                {'table': 'broadcasts', 'values': {'status': 'valid', 'fee_fraction_int': None, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'block_index': 310501, 'timestamp': 0, 'text': None, 'locked': 1, 'value': None, 'tx_hash': '6b4a62b80f35b0e66df4591c8a445d453d995609e2df12afe93e742bea10dd86', 'tx_index': 502}}
        ]
        }],
    },
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
            'error': (exceptions.ComposeError, '1 BTC may be burned per address')
        }, {
            'in': (MULTISIGADDR[0], int(DP['quantity'] / 2)),
            'out': ('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 50000000)], None)
        }],
        'parse': [{
            'in': ({'block_index': DP['default_block'], 'destination': 'mvCounterpartyXXXXXXXXXXXXXXW24Hef', 'fee': 10000, 'block_time': 155409000, 'supported': 1, 'btc_amount': 62000000, 'data': b'', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_index': 502, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'burns', 'values': {'tx_index': 502, 'earned': 92995811159, 'burned': 62000000, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'status': 'valid', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': DP['default_block']}},
                {'table': 'credits', 'values': {'block_index': DP['default_block'], 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'asset': 'XCP', 'calling_function': 'burn', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 92995811159}}
            ]
        }, {
            'in': ({'supported': 1, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'btc_amount': 50000000, 'block_index': DP['default_block'], 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'fee': 10000, 'data': b'', 'block_time': 155409000, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'tx_index': 502, 'destination': 'mvCounterpartyXXXXXXXXXXXXXXW24Hef'},),
            'records': [
                {'table': 'burns', 'values': {'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': DP['default_block'], 'burned': 50000000, 'status': 'valid', 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'earned': 74996621902, 'tx_index': 502}},
                {'table': 'credits', 'values': {'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'block_index': DP['default_block'], 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'calling_function': 'burn', 'quantity': 74996621902}}
            ]
        }],
    },
    'destroy': {
        'validate': [{
            'in': (ADDR[0], None, 'XCP', 1),
            'out': None
        },  {
            'in': (ADDR[0], None, 'foobar', 1),
            'error': (exceptions.ValidateError, 'asset invalid')
        },  {
            'in': (ADDR[0], ADDR[1], 'XCP', 1),
            'error': (exceptions.ValidateError, 'destination exists')
        },  {
            'in': (ADDR[0], None, 'BTC', 1),
            'error': (exceptions.ValidateError, 'cannot destroy BTC')
        },  {
            'in': (ADDR[0], None, 'XCP', 1.1),
            'error': (exceptions.ValidateError, 'quantity not integer')
        },  {
            'in': (ADDR[0], None, 'XCP', 2**63),
            'error': (exceptions.ValidateError, 'quantity too large')
        },  {
            'in': (ADDR[0], None, 'XCP', -1),
            'error': (exceptions.ValidateError, 'quantity negative')
        },  {
            'in': (ADDR[0], None, 'XCP', 2**62),
            'error': (exceptions.BalanceError, 'balance insufficient')
        }],
        'pack': [{
            'in': ('XCP', 1, bytes(9999999)),
            'out': b'\x00\x00\x00n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00'
        }],
        'unpack': [{
            'in': (b'\x00\x00\x00n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00',),
            'error': (exceptions.UnpackError, 'could not unpack')
        }],
        'compose': [{
            'in': (ADDR[0], 'XCP', 1, bytes(9999999)),
            'out': (ADDR[0], [],  b'\x00\x00\x00n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00')
        }],
    },
    'execute': {
        'compose': [{
            'in': (ADDR[0], 'faf080', 10, 10, 10, 'faf080'),
            'out': (ADDR[0], [], b'\x00\x00\x00e\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\n\xfa\xf0\x80')
        },  {
            'in': (ADDR[0], 'faf080', 10, -10, 10, 'faf080'),
            'error': (ContractError, 'negative startgas')
        },  {
            'in': (ADDR[0], 'faf080', -10, 10, 10, 'faf080'),
            'error': (ContractError, 'negative gasprice')
        }],
    },
    'send': {
        'validate': [{
            'in': (ADDR[0], ADDR[1], 'XCP', DP['quantity'], 1),
            'out': ([])
        }, {
            'in': (ADDR[0], ADDR[1], 'BTC', DP['quantity'], 1),
            'out': (['cannot send bitcoins'])
        }, {
            'in': (ADDR[0], ADDR[1], 'XCP', DP['quantity'] / 3, 1),
            'out': (['quantity must be in satoshis'])
        }, {
            'in': (ADDR[0], ADDR[1], 'XCP', -1 * DP['quantity'], 1),
            'out': (['negative quantity'])
        }, {
            'in': (ADDR[0], MULTISIGADDR[0], 'XCP', DP['quantity'], 1),
            'out': ([])
        }, {
            'in': (ADDR[0], ADDR[1], 'MAXI', 2**63 - 1, 1),
            'out': ([])
        }, {
            'in': (ADDR[0], ADDR[1], 'MAXI', 2**63 + 1, 1),
            'out': ([])
        }],
        'compose': [{
            'in': (ADDR[0], ADDR[1], 'XCP', DP['small']),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80')
        }, {
            'in': (ADDR[0], ADDR[1], 'XCP', DP['quantity'] * 10000000),
            'error': (exceptions.ComposeError, 'insufficient funds')
        }, {
            'in': (ADDR[0], ADDR[1], 'XCP', DP['quantity'] / 3),
            'error': (exceptions.ComposeError, 'quantity must be an int (in satoshi)')
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
            'error': (exceptions.ComposeError, 'insufficient funds')
        }, {
            'in': (ADDR[0], ADDR[1], 'BTC', DP['quantity']),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 100000000)], None)
        }],
        'parse': [{
            'in': ({'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'supported': 1, 'block_index': DP['default_block'], 'fee': 10000, 'block_time': 155409000, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': 7800, 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00', 'tx_index': 502, 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'},),
            'records': [
                {'table': 'sends', 'values': {'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': DP['default_block'], 'status': 'valid', 'asset': 'XCP', 'quantity': 100000000, 'tx_index': 502, 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'}},
                {'table': 'credits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': DP['default_block'], 'calling_function': 'send', 'asset': 'XCP', 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'quantity': 100000000}},
                {'table': 'debits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': DP['default_block'], 'asset': 'XCP', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'action': 'send', 'quantity': 100000000}}
            ]
        }, {
            'in': ({'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': 7800, 'block_index': DP['default_block'], 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x0b\xeb\xc2\x00', 'block_time': 155409000, 'fee': 10000, 'source': 'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH', 'tx_index': 502, 'supported': 1},),
            'records': [
                {'table': 'sends', 'values': {'status': 'valid', 'quantity': 0, 'asset': 'XCP', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 310501, 'tx_index': 502, 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'source': 'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'}}
            ]
        }, {
            'in':({'tx_index': 502, 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00X\xb1\x14\x00', 'source': 'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH', 'block_time': 310501000, 'block_hash': '46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58', 'tx_hash': '736ecc18f9f41b3ccf67dded1252969e4929404d6ad657b2039b937a7785cf3e', 'supported': 1, 'destination': 'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj', 'btc_amount': 5430, 'block_index': 310501, 'fee': 10000},),
            'records': [
                {'table': 'sends', 'values': {'asset': 'XCP', 'status': 'valid', 'source': 'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH', 'destination': 'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj', 'tx_index': 502, 'tx_hash': '736ecc18f9f41b3ccf67dded1252969e4929404d6ad657b2039b937a7785cf3e', 'block_index': 310501, 'quantity': 0}}
            ]
        }, {
            'in': ({'block_index': DP['default_block'], 'btc_amount': 7800, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_time': 155409000, 'fee': 10000, 'tx_index': 502, 'data': b'\x00\x00\x00\x00\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x01\xf4', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'supported': 1},),
            'records': [
                {'table': 'sends', 'values': {'block_index': DP['default_block'], 'quantity': 500, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx_index': 502, 'asset': 'NODIVISIBLE', 'status': 'valid', 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'}},
                {'table': 'credits', 'values': {'block_index': DP['default_block'], 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'calling_function': 'send', 'quantity': 500, 'asset': 'NODIVISIBLE'}},
                {'table': 'debits', 'values': {'block_index': DP['default_block'], 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'action': 'send', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 500, 'asset': 'NODIVISIBLE'}}
            ]
        }, {
            'in': ({'btc_amount': 7800, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'fee': 10000, 'tx_index': 502, 'destination': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'supported': 1, 'block_time': 155409000, 'block_index': DP['default_block']},),
            'records': [
                {'table': 'sends', 'values': {'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'destination': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'asset': 'XCP', 'quantity': 100000000, 'tx_index': 502, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'status': 'valid', 'block_index': DP['default_block']}},
                {'table': 'credits', 'values': {'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'quantity': 100000000, 'asset': 'XCP', 'block_index': DP['default_block'], 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'calling_function': 'send'}},
                {'table': 'debits', 'values': {'action': 'send', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'quantity': 100000000, 'asset': 'XCP', 'block_index': DP['default_block'], 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d'}}
            ]
        }, {
            'in': ({'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00', 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'supported': 1, 'block_time': 155409000, 'fee': 10000, 'tx_index': 502, 'btc_amount': 7800, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'block_index': DP['default_block'], 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'},),
            'records': [
                {'table': 'sends', 'values': {'quantity': 100000000, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'status': 'valid', 'destination': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'asset': 'XCP', 'tx_index': 502, 'block_index': DP['default_block']}},
                {'table': 'credits', 'values': {'quantity': 100000000, 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'calling_function': 'send', 'asset': 'XCP', 'block_index': DP['default_block'], 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'}},
                {'table': 'debits', 'values': {'quantity': 100000000, 'action': 'send', 'asset': 'XCP', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': DP['default_block'], 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'}}
            ]
        }, {
            'in': ({'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'destination': '1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'supported': 1, 'block_time': 155409000, 'fee': 10000, 'block_index': DP['default_block'], 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'btc_amount': 7800, 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00', 'tx_index': 502, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'sends', 'values': {'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'destination': '1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'asset': 'XCP', 'status': 'valid', 'block_index': DP['default_block'], 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 100000000, 'tx_index': 502}},
                {'table': 'credits', 'values': {'asset': 'XCP', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 100000000, 'address': '1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'block_index': DP['default_block'], 'calling_function': 'send'}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'action': 'send', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 100000000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'block_index': DP['default_block']}}
            ]
        }, {
            'in': ({'block_index': DP['default_block'], 'block_time': 155409000, 'fee': 10000, 'tx_index': 502, 'tx_hash': '8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0', 'btc_amount': 7800, 'data': b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'supported': 1, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'sends', 'values': {'block_index': DP['default_block'], 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_hash': '8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0', 'quantity': 9223372036854775807, 'asset': 'MAXI', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'status': 'valid', 'tx_index': 502}},
                {'table': 'credits', 'values': {'block_index': DP['default_block'], 'asset': 'MAXI', 'quantity': 9223372036854775807, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'calling_function': 'send', 'event': '8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0'}},
                {'table': 'debits', 'values': {'block_index': DP['default_block'], 'action': 'send', 'asset': 'MAXI', 'quantity': 9223372036854775807, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'event': '8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0'}}
            ]
        }]
    },
    'issuance': {
        'validate': [{
            'in': (ADDR[0], None, 'ASSET', 1000, True, False, None, None, '', DP['default_block']),
            'out': (0, 0.0, [], 50000000, '', True, False)
        }, {
            'in': (ADDR[2], None, 'DIVIDEND', 1000, False, False, None, None, '', DP['default_block']),
            'out': (0, 0.0, ['cannot change divisibility'], 0, '', False, True)
        }, {
            'in': (ADDR[2], None, 'DIVIDEND', 1000, True, True, None, None, '', DP['default_block']),
            'out': (0, 0.0, ['cannot change callability'], 0, '', True, True)
        }, {
            'in': (ADDR[0], None, 'BTC', 1000, True, False, None, None, '', DP['default_block']),
            'out': (0, 0.0, ['cannot issue BTC or XCP'], 50000000, '', True, False)
        }, {
            'in': (ADDR[0], None, 'XCP', 1000, True, False, None, None, '', DP['default_block']),
            'out': (0, 0.0, ['cannot issue BTC or XCP'], 50000000, '', True, False)
        }, {
            'in': (ADDR[0], None, 'NOSATOSHI', 1000.5, True, False, None, None, '', DP['default_block']),
            'out': (0, 0.0, ['quantity must be in satoshis'], 0, '', True, None)
        }, {
            'in': (ADDR[0], None, 'CALLPRICEFLOAT', 1000, True, False, None, 100.0, '', DP['default_block']),
            'out': (0, 0.0, [], 0, '', True, False)
        }, {
            'in': (ADDR[0], None, 'CALLPRICEINT', 1000, True, False, None, 100, '', DP['default_block']),
            'out': (0, 0.0, [], 50000000, '', True, False)
        }, {
            'in': (ADDR[0], None, 'CALLPRICESTR', 1000, True, False, None, 'abc', '', DP['default_block']),
            'out': (0, 'abc', ['call_price must be a float'], 0, '', True, None)
        }, {
            'in': (ADDR[0], None, 'CALLDATEINT', 1000, True, False, 1409401723, None, '', DP['default_block']),
            'out': (0, 0.0, [], 50000000, '', True, False)
        }, {
            'in': (ADDR[0], None, 'CALLDATEFLOAT', 1000, True, False, 0.9 * 1409401723, None, '', DP['default_block']),
            'out': (1268461550.7, 0.0, ['call_date must be epoch integer'], 0, '', True, None)
        }, {
            'in': (ADDR[0], None, 'CALLDATESTR', 1000, True, False, 'abc', None, '', DP['default_block']),
            'out': ('abc', 0.0, ['call_date must be epoch integer'], 0, '', True, None)
        }, {
            'in': (ADDR[0], None, 'NEGVALUES', -1000, True, True, -1409401723, -DP['quantity'], '', DP['default_block']),
            'out': (-1409401723, -100000000.0, ['negative quantity', 'negative call price', 'negative call date'], 50000000, '', True, False)
        }, {
            'in': (ADDR[2], None, 'DIVISIBLE', 1000, True, False, None, None, 'Divisible asset', DP['default_block']),
            'out': (0, 0.0, ['issued by another address'], 0, 'Divisible asset', True, True)
        }, {
            'in': (ADDR[0], None, 'LOCKED', 1000, True, False, None, None, 'Locked asset', DP['default_block']),
            'out': (0, 0.0, ['locked asset and non‐zero quantity'], 0, 'Locked asset', True, True)
        }, {
            'in': (ADDR[0], None, 'BSSET', 1000, True, False, None, None, 'LOCK', DP['default_block']),
            'out': (0, 0.0, ['cannot lock a non‐existent asset'], 50000000, 'LOCK', True, False)
        }, {
            'in': (ADDR[0], ADDR[1], 'BSSET', 1000, True, False, None, None, '', DP['default_block']),
            'out': (0, 0.0, ['cannot transfer a non‐existent asset', 'cannot issue and transfer simultaneously'], 50000000, '', True, False)
        }, {
            'in': (ADDR[2], None, 'BSSET', 1000, True, False, None, None, '', DP['default_block']),
            'out': (0, 0.0, ['insufficient funds'], 50000000, '', True, False)
        }, {
            'in': (ADDR[0], None, 'BSSET', 2**63, True, False, None, None, '', DP['default_block']),
            'out': (0, 0.0, ['total quantity overflow'], 50000000, '', True, False)
        }, {
            'in': (ADDR[0], ADDR[1], 'DIVISIBLE', 1000, True, False, None, None, 'Divisible asset', DP['default_block']),
            'out': (0, 0.0, ['cannot issue and transfer simultaneously'], 0, 'Divisible asset', True, True)
        }, {
            'in': (ADDR[0], None, 'MAXIMUM', 2**63-1, True, False, None, None, 'Maximum quantity', DP['default_block']),
            'out': (0, 0.0, [], 50000000, 'Maximum quantity', True, False)
        }, {
            'in': (ADDR[0], None, 'DIVISIBLE', 2**63-1, True, False, None, None, 'Maximum quantity', DP['default_block']),
            'out': (0, 0.0, ['total quantity overflow'], 0, 'Maximum quantity', True, True)
        }],
        'compose': [{
            'in': (ADDR[0], None, 'ASSET', 1000, True, ''),
            'error': (exceptions.AssetNameError, 'non‐numeric asset name starts with ‘A’')
        }, {
            'in': (ADDR[0], None, 'BSSET1', 1000, True, ''),
            'error': (exceptions.AssetNameError, "('invalid character:', '1')")
        }, {
            'in': (ADDR[0], None, 'SET', 1000, True, ''),
            'error': (exceptions.AssetNameError, 'too short')
        }, {
            'in': (ADDR[0], None, 'BSSET', 1000, True, ''),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (ADDR[0], None, 'BSSET', 1000, True, 'description much much much longer than 42 letters'),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00description much much much longer than 42 letters')
        }, {
            'in': (ADDR[0], ADDR[1], 'DIVISIBLE', 0, True, ''),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (MULTISIGADDR[0], None, 'BSSET', 1000, True, ''),
            'out': ('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (ADDR[0], MULTISIGADDR[0], 'DIVISIBLE', 0, True, ''),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (ADDR[0], None, 'MAXIMUM', 2**63-1, True, 'Maximum quantity'),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\xdd\x96\xd2t\x7f\xff\xff\xff\xff\xff\xff\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10Maximum quantity')
        }, {
            'in': (ADDR[0], None, 'A{}'.format(2**64 - 1), 1000, None, None),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\x14\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        }, {
            'in': (ADDR[0], None, 'A{}'.format(2**64), 1000, True, ''),
            'error': (exceptions.AssetNameError, 'numeric asset name not in range')
        }, {
            'in': (ADDR[0], None, 'A{}'.format(26**12), 1000, True, ''),
            'error': (exceptions.AssetNameError, 'numeric asset name not in range')
        }],
        'parse': [{
            'in': ({'supported': 1, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'data': b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\xbaOs\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00', 'btc_amount': None, 'destination': None, 'block_time': 155409000, 'block_index': DP['default_block'], 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'fee': 10000, 'tx_index': 502, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'issuances', 'values': {'locked': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'description': '', 'divisible': 1, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'asset': 'BASSET', 'issuer': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'status': 'valid', 'tx_index': 502, 'fee_paid': 50000000, 'block_index': DP['default_block'], 'transfer': 0, 'quantity': 1000}},
                {'table': 'credits', 'values': {'calling_function': 'issuance', 'block_index': DP['default_block'], 'asset': 'BASSET', 'quantity': 1000, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d'}},
                {'table': 'debits', 'values': {'block_index': DP['default_block'], 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'quantity': 50000000, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'action': 'issuance fee'}}
            ]
        }, {
            'in': ({'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_time': 155409000, 'btc_amount': 7800, 'supported': 1, 'tx_index': 502, 'block_index': DP['default_block'], 'data': b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'fee': 10000, 'destination': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'},),
            'records': [
                {'table': 'issuances', 'values': {'locked': 0, 'block_index': DP['default_block'], 'description': '', 'quantity': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'DIVISIBLE', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'fee_paid': 0, 'issuer': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_index': 502, 'transfer': 1, 'divisible': 1, 'status': 'valid'}}
            ]
        }, {
            'in': ({'tx_index': 502, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'data': b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04LOCK', 'block_time': 155409000, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'fee': 10000, 'destination': None, 'supported': 1, 'block_index': DP['default_block'], 'btc_amount': None},),
            'records': [
                {'table': 'issuances', 'values': {'tx_index': 502, 'quantity': 0, 'block_index': DP['default_block'], 'status': 'valid', 'locked': 1, 'description': 'Divisible asset', 'divisible': 1, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'transfer': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'issuer': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'fee_paid': 0, 'asset': 'DIVISIBLE'}}
            ]
        }, {
            'in': ({'data': b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00', 'supported': 1, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': DP['default_block'], 'destination': '', 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'btc_amount': 0, 'tx_index': 502, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'block_time': 155409000, 'fee': 10000},),
            'records': [
                {'table': 'issuances', 'values': {'issuer': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'asset': 'BSSET', 'description': '', 'block_index': DP['default_block'], 'transfer': 0, 'quantity': 1000, 'status': 'valid', 'divisible': 1, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'locked': 0, 'tx_index': 502, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'fee_paid': 50000000}},
                {'table': 'credits', 'values': {'quantity': 1000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'asset': 'BSSET', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'calling_function': 'issuance', 'block_index': DP['default_block']}},
                {'table': 'debits', 'values': {'quantity': 50000000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'asset': 'XCP', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'action': 'issuance fee', 'block_index': DP['default_block']}}
            ]
        }, {
            'in': ({'fee': 10000, 'block_time': 155409000, 'data': b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00', 'block_index': DP['default_block'], 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'btc_amount': 7800, 'tx_index': 502, 'destination': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'supported': 1, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'},),
            'records': [
                {'table': 'issuances', 'values': {'fee_paid': 0, 'divisible': 1, 'block_index': DP['default_block'], 'tx_index': 502, 'description': '', 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'transfer': 1, 'issuer': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'locked': 0, 'asset': 'DIVISIBLE', 'status': 'valid', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'quantity': 0}},
                {'table': 'debits', 'values': {'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'action': 'issuance fee', 'block_index': DP['default_block'], 'quantity': 0}}
            ]
        }, {
            'in': ({'data': b'\x00\x00\x00\x14\x00\x00\x00\x00\xdd\x96\xd2t\x7f\xff\xff\xff\xff\xff\xff\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10Maximum quantity', 'block_time': 155409000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'block_index': DP['default_block'], 'btc_amount': 0, 'fee': 10000, 'supported': 1, 'tx_index': 502, 'destination': '', 'tx_hash': '71da4fac29d6442ef3ff13f291860f512a888161ae9e574f313562851912aace'},),
            'records': [
                {'table': 'issuances', 'values': {'issuer': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'transfer': 0, 'divisible': 1, 'description': 'Maximum quantity', 'asset': 'MAXIMUM', 'tx_index': 502, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': DP['default_block'], 'quantity': 9223372036854775807, 'status': 'valid', 'tx_hash': '71da4fac29d6442ef3ff13f291860f512a888161ae9e574f313562851912aace', 'fee_paid': 50000000, 'locked': 0}},
                {'table': 'credits', 'values': {'asset': 'MAXIMUM', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': DP['default_block'], 'quantity': 9223372036854775807, 'event': '71da4fac29d6442ef3ff13f291860f512a888161ae9e574f313562851912aace', 'calling_function': 'issuance'}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': DP['default_block'], 'action': 'issuance fee', 'quantity': 50000000, 'event': '71da4fac29d6442ef3ff13f291860f512a888161ae9e574f313562851912aace'}}
            ]
        }, {
            'in': ({'data': b'\x00\x00\x00\x14\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00', 'tx_index': 502, 'tx_hash': '4188c1f7aaae56ce3097ef256cdbcb644dd43c84e237b4add4f24fd4848cb2c7', 'destination': '', 'fee': 10000, 'btc_amount': 0, 'block_time': 2815010000000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'supported': 1, 'block_index': DP['default_block'], 'block_hash': '8e80b430efbe3e1b7cc13d7ec51c1e47a16b0fa23d6dd3c939fb6c4d4cfa311e1f25072500f5f9872373b54c72424b3557fccd68915d00c0afb6523702e11b6a'},),
            'records': [
                {'table': 'issuances', 'values': {'transfer': 0, 'tx_hash': '4188c1f7aaae56ce3097ef256cdbcb644dd43c84e237b4add4f24fd4848cb2c7', 'divisible': 1, 'status': 'valid', 'asset': 'A18446744073709551615', 'description': '', 'tx_index': 502, 'issuer': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'fee_paid': 0, 'locked': 0, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': DP['default_block'], 'quantity': 1000}},
                {'table': 'credits', 'values': {'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'asset': 'A18446744073709551615', 'event': '4188c1f7aaae56ce3097ef256cdbcb644dd43c84e237b4add4f24fd4848cb2c7', 'block_index': DP['default_block'], 'quantity': 1000, 'calling_function': 'issuance'}},
                {'table': 'debits', 'values': {'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'action': 'issuance fee', 'asset': 'XCP', 'event': '4188c1f7aaae56ce3097ef256cdbcb644dd43c84e237b4add4f24fd4848cb2c7', 'block_index': DP['default_block'], 'quantity': 0}}
            ]
        }]
    },
    'dividend': {
        'validate': [{
            'in': (ADDR[0], DP['quantity'] * 1000, 'DIVISIBLE', 'XCP', DP['default_block']),
            'out': (1100000000000, [{'address_quantity': 100000000, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'dividend_quantity': 100000000000}, {'address_quantity': 1000000000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'dividend_quantity': 1000000000000}], ['insufficient funds (XCP)'], 0)
        }, {
            'in': (ADDR[0], DP['quantity'] * -1000, 'DIVISIBLE', 'XCP', DP['default_block']),
            'out': (-1100000000000, [{'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'dividend_quantity': -100000000000, 'address_quantity': 100000000}, {'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'dividend_quantity': -1000000000000, 'address_quantity': 1000000000}], ['non‐positive quantity per unit'], 0)
        }, {
            'in': (ADDR[0], DP['quantity'], 'BTC', 'XCP', DP['default_block']),
            'out': (None, None, ['cannot pay dividends to holders of BTC', 'no such asset, BTC.'], 0)
        }, {
            'in': (ADDR[0], DP['quantity'], 'XCP', 'XCP', DP['default_block']),
            'out': (None, None, ['cannot pay dividends to holders of XCP', 'no such asset, XCP.'], 0)
        }, {
            'in': (ADDR[0], DP['quantity'], 'NOASSET', 'XCP', DP['default_block']),
            'out': (None, None, ['no such asset, NOASSET.'], 0)
        }, {
            'in': (ADDR[0], 0, 'DIVISIBLE', 'XCP', DP['default_block']),
            'out': (0,  [{'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'dividend_quantity': 0, 'address_quantity': 100000000}, {'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'dividend_quantity': 0, 'address_quantity': 1000000000}], ['non‐positive quantity per unit', 'zero dividend'], 0)
        }, {
            'in': (ADDR[1], DP['quantity'], 'DIVISIBLE', 'XCP', DP['default_block']),
            'out': (99900000000, [{'dividend_quantity': 98900000000, 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'address_quantity': 98900000000}, {'dividend_quantity': 1000000000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'address_quantity': 1000000000}], ['only issuer can pay dividends', 'insufficient funds (XCP)'], 0)
        }, {
            'in': (ADDR[0], DP['quantity'], 'DIVISIBLE', 'NOASSET', DP['default_block']),
            'out': (None, None, ['no such dividend asset, NOASSET.'], 0)
        }, {
            'in': (ADDR[0], 8359090909, 'DIVISIBLE', 'XCP', DP['default_block']),
            'out': (91949999999, [{'address_quantity': 100000000, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'dividend_quantity': 8359090909}, {'address_quantity': 1000000000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'dividend_quantity': 83590909090}], ['insufficient funds (XCP)'], 40000)
        }, {
            'in': (ADDR[2], 100000000, 'DIVIDEND', 'DIVIDEND', DP['default_block']),
            'out': (10, [{'address_quantity': 10, 'address': 'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj', 'dividend_quantity': 10}], ['insufficient funds (XCP)'], 20000)
        }],
        'compose': [{
            'in': (ADDR[0], DP['quantity'], 'DIVISIBLE', 'XCP'),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x002\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01')
        }, {
            'in': (ADDR[0], 1, 'NODIVISIBLE', 'XCP'),
            'out': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x002\x00\x00\x00\x00\x00\x00\x00\x01\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x00\x01')
        }],
        'parse': [{
            'in': ({'tx_hash': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'supported': 1, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'data': b'\x00\x00\x002\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01', 'tx_index': 502, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'block_index': DP['default_block'], 'btc_amount': 0, 'fee': 10000, 'destination': '', 'block_time': 155409000},),
            'records': [
                {'table': 'dividends', 'values': {'tx_hash': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'fee_paid': 40000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_index': 502, 'block_index': DP['default_block'], 'dividend_asset': 'XCP', 'status': 'valid', 'quantity_per_unit': 100000000, 'asset': 'DIVISIBLE'}},
                {'table': 'credits', 'values': {'calling_function': 'dividend', 'asset': 'XCP', 'block_index': DP['default_block'], 'quantity': 100000000, 'event': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'}},
                {'table': 'credits', 'values': {'calling_function': 'dividend', 'asset': 'XCP', 'block_index': DP['default_block'], 'quantity': 1000000000, 'event': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'action': 'dividend', 'block_index': DP['default_block'], 'quantity': 1100000000, 'event': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'action': 'dividend fee', 'block_index': DP['default_block'], 'quantity': 40000, 'event': '450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'}}
            ]
        }, {
            'in': ({'tx_index': 502, 'btc_amount': 0, 'block_time': 155409000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_hash': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'fee': 10000, 'block_index': DP['default_block'], 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'supported': 1, 'destination': '', 'data': b'\x00\x00\x002\x00\x00\x00\x00\x00\x00\x00\x01\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x00\x01'},),
            'records': [
                {'table': 'dividends', 'values': {'tx_index': 502, 'asset': 'NODIVISIBLE', 'fee_paid': 40000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx_hash': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'dividend_asset': 'XCP', 'block_index': DP['default_block'], 'quantity_per_unit': 1, 'status': 'valid'}},
                {'table': 'credits', 'values': {'asset': 'XCP', 'event': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'calling_function': 'dividend', 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'quantity': 5, 'block_index': DP['default_block']}},
                {'table': 'credits', 'values': {'asset': 'XCP', 'event': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'calling_function': 'dividend', 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'quantity': 10, 'block_index': DP['default_block']}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'event': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'quantity': 15, 'block_index': DP['default_block'], 'action': 'dividend'}},
                {'table': 'debits', 'values': {'asset': 'XCP', 'event': '5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'quantity': 40000, 'block_index': DP['default_block'], 'action': 'dividend fee'}}
            ]
        }]
    },
    'order': {
        'validate': [{
            'in': (ADDR[0], 'DIVISIBLE', DP['quantity'], 'XCP', DP['quantity'], 2000, 0, DP['default_block']),
            'out': ([])
        }, {
            'in': (ADDR[0], 'DIVISIBLE', DP['quantity'], 'XCP', DP['quantity'], 2000, 0.5, DP['default_block']),
            'out': (['fee_required must be in satoshis'])
        }, {
            'in': (ADDR[0], 'BTC', DP['quantity'], 'BTC', DP['quantity'], 2000, 0, DP['default_block']),
            'out': (['cannot trade BTC for itself'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', DP['quantity'] / 3, 'XCP', DP['quantity'], 2000, 0, DP['default_block']),
            'out': (['give_quantity must be in satoshis'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', DP['quantity'], 'XCP', DP['quantity'] / 3, 2000, 0, DP['default_block']),
            'out': (['get_quantity must be in satoshis'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', DP['quantity'], 'XCP', DP['quantity'], 1.5, 0, DP['default_block']),
            'out': (['expiration must be expressed as an integer block delta'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', -DP['quantity'], 'XCP', -DP['quantity'], -2000, -10000, DP['default_block']),
            'out': (['non‐positive give quantity', 'non‐positive get quantity', 'negative fee_required', 'negative expiration'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', 0, 'XCP', DP['quantity'], 2000, 0, DP['default_block']),
            'out': (['non‐positive give quantity', 'zero give or zero get'])
        },{
            'in': (ADDR[0], 'NOASSETA', DP['quantity'], 'NOASSETB', DP['quantity'], 2000, 0, DP['default_block']),
            'out': (['no such asset to give (NOASSETA)', 'no such asset to get (NOASSETB)'])
        },{
            'in': (ADDR[0], 'DIVISIBLE', 2**63 + 10, 'XCP', DP['quantity'], 4 * 2016 + 10, 0, DP['default_block']),
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
            'error': (exceptions.ComposeError, 'insufficient funds')
        }],
        'parse': [{
            'in': ({'destination': None, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'block_time': 155409000, 'block_index': DP['default_block'], 'tx_index': 502, 'data': b'\x00\x00\x00\n\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'fee': 10000, 'btc_amount': None, 'supported': 1, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'orders', 'values': {'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'fee_required_remaining': 0, 'block_index': DP['default_block'], 'status': 'filled', 'get_quantity': 100000000, 'fee_provided_remaining': 10000, 'get_asset': 'XCP', 'give_remaining': 0, 'fee_provided': 10000, 'expiration': 2000, 'get_remaining': 0, 'tx_index': 502, 'give_asset': 'DIVISIBLE', 'expire_index': DP['default_block'] + 2000, 'give_quantity': 100000000, 'fee_required': 0}},
                {'table': 'order_matches', 'values': {'status': 'completed', 'tx0_index': 7, 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'forward_quantity': 100000000, 'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'backward_asset': 'DIVISIBLE', 'tx0_hash': '074fa38a84a81c0ed7957484ebe73836104d3068f66b189e05a7cf0b95c737f3', 'tx0_expiration': 2000, 'id': '074fa38a84a81c0ed7957484ebe73836104d3068f66b189e05a7cf0b95c737f3_db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx1_expiration': 2000, 'tx1_block_index': DP['default_block'], 'forward_asset': 'XCP', 'fee_paid': 0, 'match_expire_index': DP['default_block'] + 20, 'tx0_block_index': DP['default_block'] - 495, 'backward_quantity': 100000000, 'tx1_index': 502, 'block_index': DP['default_block']}},
                {'table': 'credits', 'values': {'event': '074fa38a84a81c0ed7957484ebe73836104d3068f66b189e05a7cf0b95c737f3_db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'block_index': DP['default_block'], 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'quantity': 100000000, 'calling_function': 'order match'}},
                {'table': 'debits', 'values': {'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': DP['default_block'], 'quantity': 100000000, 'asset': 'DIVISIBLE', 'action': 'open order'}},
                {'table': 'credits', 'values': {'event': '074fa38a84a81c0ed7957484ebe73836104d3068f66b189e05a7cf0b95c737f3_db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'DIVISIBLE', 'block_index': DP['default_block'], 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'quantity': 100000000, 'calling_function': 'order match'}},
                {'table': 'credits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'block_index': DP['default_block'], 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'quantity': 0, 'calling_function': 'filled'}},
                {'table': 'credits', 'values': {'event': '074fa38a84a81c0ed7957484ebe73836104d3068f66b189e05a7cf0b95c737f3', 'asset': 'DIVISIBLE', 'block_index': DP['default_block'], 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'quantity': 0, 'calling_function': 'filled'}}
            ]
        }, {
            'in': ({'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': None, 'tx_index': 502, 'supported': 1, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'fee': 10000, 'block_time': 155409000, 'block_index': DP['default_block'], 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0fB@\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'destination': None},),
            'records': [
                {'table': 'orders', 'values': {'give_quantity': 1000000, 'status': 'open', 'get_remaining': 0, 'tx_index': 502, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'give_remaining': 0, 'block_index': DP['default_block'], 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'fee_required': 0, 'fee_provided': 10000, 'give_asset': 'BTC', 'get_asset': 'XCP', 'fee_provided_remaining': 1000, 'expiration': 2000, 'expire_index': DP['default_block'] + 2000, 'fee_required_remaining': 0, 'get_quantity': 100000000}},
                {'table': 'order_matches', 'values': {'forward_asset': 'XCP', 'id': 'b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d_db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'forward_quantity': 100000000, 'match_expire_index': DP['default_block'] + 20, 'tx1_block_index': DP['default_block'], 'backward_quantity': 1000000, 'block_index': DP['default_block'], 'fee_paid': 9000, 'tx1_index': 502, 'tx1_expiration': 2000, 'tx0_hash': 'b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d', 'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx0_index': 11, 'tx0_block_index': DP['default_block'] - 491, 'backward_asset': 'BTC', 'tx0_expiration': 2000, 'status': 'pending'}}
            ]
        }, {
            'in': ({'fee': 10000, 'block_time': 155409000, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'destination': None, 'supported': 1, 'tx_index': 502, 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\n,+\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': None, 'block_index': DP['default_block']},),
            'records': [
                {'table': 'orders', 'values': {'give_remaining': 140, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'fee_required': 0, 'tx_index': 502, 'expire_index': 312501, 'status': 'open', 'fee_required_remaining': 0, 'fee_provided': 10000, 'get_remaining': 0, 'get_asset': 'BTC', 'give_quantity': 99999990, 'block_index': 310501, 'give_asset': 'XCP', 'fee_provided_remaining': 10000, 'expiration': 2000, 'get_quantity': 666666}},
                {'table': 'order_matches', 'values': {'tx1_address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx0_index': 12, 'tx0_expiration': 2000, 'block_index': 310501, 'backward_asset': 'XCP', 'tx1_index': 502, 'fee_paid': 0, 'forward_asset': 'BTC', 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx1_block_index': 310501, 'id': '8a63e7a516d36c17ac32999222ac282ab94fb9c5ea30637cd06660b3139510f6_db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'backward_quantity': 99999850, 'forward_quantity': 666666, 'tx0_hash': '8a63e7a516d36c17ac32999222ac282ab94fb9c5ea30637cd06660b3139510f6', 'tx1_expiration': 2000, 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'status': 'pending', 'match_expire_index': 310521, 'tx0_block_index': 310011}},
                {'table': 'debits', 'values': {'action': 'open order', 'quantity': 99999990, 'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 310501, 'asset': 'XCP', 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'}}
            ]
        }, {
            'in': ({'block_time': 155409000, 'destination': None, 'btc_amount': None, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x1e\x84\x80\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'supported': 1, 'fee': 10000, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_index': 502, 'block_index': DP['default_block'], 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'},),
            'records': [
                {'table': 'orders', 'values': {'give_quantity': 99999990, 'get_asset': 'BTC', 'give_asset': 'XCP', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'expire_index': 312501, 'expiration': 2000, 'tx_index': 502, 'fee_required_remaining': 0, 'give_remaining': 99999990, 'get_remaining': 1999999, 'fee_provided': 10000, 'fee_provided_remaining': 10000, 'status': 'open', 'fee_required': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_index': 310501, 'get_quantity': 1999999}},
                {'table': 'debits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'action': 'open order', 'asset': 'XCP', 'block_index': 310501, 'quantity': 99999990, 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'}}
           ]
        }, {
            'in': ({'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07\xa1 \x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'tx_index': 502, 'destination': None, 'block_index': DP['default_block'], 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'btc_amount': None, 'block_time': 155409000, 'supported': 1, 'fee': 1000000, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'},),
            'records': [
                {'table': 'orders', 'values': {'block_index': DP['default_block'], 'fee_required_remaining': 0, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'give_remaining': 500000, 'expiration': 2000, 'give_quantity': 500000, 'get_asset': 'XCP', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'fee_provided_remaining': 1000000, 'tx_index': 502, 'fee_required': 0, 'give_asset': 'BTC', 'expire_index': DP['default_block'] + 2000, 'get_remaining': 100000000, 'fee_provided': 1000000, 'get_quantity': 100000000, 'status': 'open'}}
            ]
        }, {
            'in': ({'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'btc_amount': None, 'tx_index': 502, 'supported': 1, 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'fee': 10000, 'block_time': 155409000, 'block_index': DP['default_block'], 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00 foo\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'destination': None},),
            'records': [
                {'table': 'orders', 'values': {'get_asset': '0', 'tx_index': 502, 'fee_required': 0, 'status': 'invalid: could not unpack', 'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'fee_required_remaining': 0, 'give_remaining': 0, 'fee_provided_remaining': 10000, 'fee_provided': 10000, 'expire_index': 310501, 'get_quantity': 0, 'expiration': 0, 'give_asset': '0', 'block_index': 310501, 'get_remaining': 0, 'give_quantity': 0}},
            ]
        }, {
            'in': ({'btc_amount': None, 'block_time': 155409000, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx_index': 502, 'supported': 1, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'destination': None, 'block_index': DP['default_block'], 'data': b'\x00\x00\x00\n\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x01\xf4\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x07\xd0\x00\x00\x00\x00\x00\x00\x00\x00', 'fee': 10000},),
            'records': [
                {'table': 'orders', 'values': {'fee_required_remaining': 0, 'fee_provided_remaining': 10000, 'block_index': DP['default_block'], 'give_remaining': 500, 'status': 'open', 'fee_required': 0, 'fee_provided': 10000, 'expiration': 2000, 'give_quantity': 500, 'get_asset': 'XCP', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx_index': 502, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'get_remaining': 100000000, 'get_quantity': 100000000, 'give_asset': 'NODIVISIBLE', 'expire_index': DP['default_block'] + 2000}},
                {'table': 'debits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': DP['default_block'], 'quantity': 500, 'action': 'open order', 'asset': 'NODIVISIBLE'}}
            ]
        }, {
            'in': ({'block_index': DP['default_block'], 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'destination': '', 'fee': 10000, 'tx_index': 502, 'supported': 1, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'block_time': 155409000, 'btc_amount': 0},),
            'records': [
                {'table': 'orders', 'values': {'block_index': DP['default_block'], 'expiration': 10, 'expire_index': DP['default_block'] + 10, 'fee_required_remaining': 0, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'fee_provided': 10000, 'status': 'open', 'give_asset': 'BTC', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'get_remaining': 0, 'give_remaining': 49000000, 'tx_index': 502, 'get_asset': 'XCP', 'fee_provided_remaining': 1000, 'fee_required': 0, 'give_quantity': 50000000, 'get_quantity': 100000000}},
                {'table': 'order_matches', 'values': {'backward_quantity': 1000000, 'tx0_hash': 'b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d', 'tx1_block_index': DP['default_block'], 'match_expire_index': DP['default_block'] + 20, 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx0_block_index': DP['default_block'] - 491, 'status': 'pending', 'block_index': DP['default_block'], 'tx1_address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'forward_quantity': 100000000, 'tx1_index': 502, 'fee_paid': 9000, 'id': 'b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d_db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'forward_asset': 'XCP', 'tx0_expiration': 2000, 'tx1_expiration': 10, 'backward_asset': 'BTC', 'tx0_index': 11, 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d'}}
            ]
        }, {
            'in': ({'block_index': DP['default_block'], 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'destination': '', 'fee': 10000, 'tx_index': 502, 'supported': 1, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'block_time': 155409000, 'btc_amount': 0},),
            'records': [
                {'table': 'orders', 'values': {'block_index': DP['default_block'], 'expiration': 10, 'expire_index': DP['default_block'] + 10, 'fee_required_remaining': 0, 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'fee_provided': 10000, 'status': 'open', 'give_asset': 'BTC', 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'get_remaining': 0, 'give_remaining': 49000000, 'tx_index': 502, 'get_asset': 'XCP', 'fee_provided_remaining': 1000, 'fee_required': 0, 'give_quantity': 50000000, 'get_quantity': 100000000}},
                {'table': 'order_matches', 'values': {'backward_quantity': 1000000, 'tx0_hash': 'b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d', 'tx1_block_index': DP['default_block'], 'match_expire_index': DP['default_block'] + 20, 'tx0_address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'tx0_block_index': DP['default_block'] - 491, 'status': 'pending', 'block_index': DP['default_block'], 'tx1_address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'forward_quantity': 100000000, 'tx1_index': 502, 'fee_paid': 9000, 'id': 'b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d_db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'forward_asset': 'XCP', 'tx0_expiration': 2000, 'tx1_expiration': 10, 'backward_asset': 'BTC', 'tx0_index': 11, 'tx1_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d'}}
            ]
        }, {
            'in': ({'fee': 10000, 'btc_amount': 0, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx_index': 502, 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'supported': 1, 'block_time': 155409000, 'block_index': DP['default_block'], 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0', 'destination': ''},),
            'records': [
                {'table': 'orders', 'values': {'get_asset': 'BTC', 'give_asset': 'XCP', 'fee_required': 900000, 'block_index': DP['default_block'], 'expire_index': DP['default_block'] + 10, 'give_remaining': 105000000, 'fee_provided_remaining': 10000, 'tx_hash': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'tx_index': 502, 'expiration': 10, 'status': 'open', 'source': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'give_quantity': 105000000, 'get_quantity': 50000000, 'fee_provided': 10000, 'fee_required_remaining': 900000, 'get_remaining': 50000000}},
                {'table': 'debits', 'values': {'event': 'db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d', 'asset': 'XCP', 'quantity': 105000000, 'address': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 'block_index': DP['default_block'], 'action': 'open order'}}
            ]
        }, {
            'in': ({'btc_amount': 0, 'fee': 10000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'destination': '', 'tx_hash': '0ec7da68a67e165693afd6c97566f8f509d302bceec8d1be0100335718a40fe5', 'tx_index': 502, 'data': b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0', 'block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8', 'supported': 1, 'block_time': 155409000, 'block_index': DP['default_block']},),
            'records': [
                {'table': 'orders', 'values': {'fee_provided_remaining': 10000, 'source': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'block_index': DP['default_block'], 'tx_index': 502, 'fee_required': 900000, 'give_asset': 'MAXI', 'status': 'open', 'get_remaining': 100000000, 'give_quantity': 9223372036854775807, 'give_remaining': 9223372036854775807, 'expiration': 10, 'get_asset': 'XCP', 'tx_hash': '0ec7da68a67e165693afd6c97566f8f509d302bceec8d1be0100335718a40fe5', 'expire_index': DP['default_block'] + 10, 'fee_provided': 10000, 'get_quantity': 100000000, 'fee_required_remaining': 900000}},
                {'table': 'debits', 'values': {'quantity': 9223372036854775807, 'asset': 'MAXI', 'action': 'open order', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'event': '0ec7da68a67e165693afd6c97566f8f509d302bceec8d1be0100335718a40fe5', 'block_index': DP['default_block']}}
            ]
        }],
        'expire': [{
            'in': (310500,),
            'out': None
        }]
    },
    'transaction': {
        'var_int': [{
            'in': (252,),
            'out': b'\xfc'
        }, {
            'in': (65535,),
            'out': b'\xfd\xff\xff'
        }, {
            'in': (4294967295,),
            'out': b'\xfe\xff\xff\xff\xff'
        }, {
            'in': (4294967296,),
            'out': b'\xff\x00\x00\x00\x00\x01\x00\x00\x00'
        }],
        'op_push': [{
            'in': (75,),
            'out': b'K'
        }, {
            'in': (255,),
            'out': b'L\xff'
        }, {
            'in': (65535,),
            'out': b'M\xff\xff'
        }, {
            'in': (65536,),
            'out': b'N\x00\x00\x01\x00'
        }],
        'get_multisig_script': [{
            'in': ('1_0282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0_0319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977_2',),
            'out': b'Q!\x02\x82\xb8\x86\xc0\x87\xeb7\xdc\x81\x82\xf1K\xa6\xcc>\x94\x85\xeda\x8b\x95\x80MD\xae\xcc\x17\xc3\x00\xb5\x85\xb0!\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9wR\xae'
        }],
        'get_monosig_script': [{
            'in': (ADDR[1],),
            'out': b'v\xa9\x14\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec\x88\xac'
        }],
        'make_fully_valid': [{
            'in': (b'T\xdaT\x0f\xb2f;u\xe6\xc3\xcca\x19\n\xd0\xc2C\x16C\xba\xb2\x8c\xedx<\xd9@y\xbb\xe7$',),
            'out': b'\x02T\xdaT\x0f\xb2f;u\xe6\xc3\xcca\x19\n\xd0\xc2C\x16C\xba\xb2\x8c\xedx<\xd9@y\xbb\xe7$G'
        }],
        'serialise': [{
            'in': ('multisig', [{'confirmations': 74, 'amount': 1.9990914, 'vout': 0, 'account': '', 'scriptPubKey': '76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac', 'txid': 'ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1', 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'txhex': '0100000002eff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b000000006c493046022100ec6fa8316a4f5cfd69816e31011022acce0933bd3b01248caa8b49e60de1b98a022100987ba974b2a4f9976a8d61d94009cb7f7986a827dc5730e999de1fb748d2046c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffeff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b010000006a47304402201f8fb2d62df22592cb8d37c68ab26563dbb8e270f7f8409ac0f6d7b24ddb5c940220314e5c767fd12b20116528c028eab2bfbad30eb963bd849993410049cf14a83d01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffff02145fea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000346a32544553540000000a00000000000000010000000005f5e1000000000000000000000000000bebc2000032000000000000271000000000'}], [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 5430)], ([b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80'], 7800), ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 199885910), b'\x02\x82\xb8\x86\xc0\x87\xeb7\xdc\x81\x82\xf1K\xa6\xcc>\x94\x85\xeda\x8b\x95\x80MD\xae\xcc\x17\xc3\x00\xb5\x85\xb0'),
            'out': b'\x01\x00\x00\x00\x01\xc1\xd8\xc0u\x93l4\x95\xf6\xd6S\xc5\x0fs\xd9\x87\xf7TH\xd9zu\x02I\xb1\xeb\x83\xbe\xe7\x1b$\xae\x00\x00\x00\x00\x19v\xa9\x14H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607\x88\xac\xff\xff\xff\xff\x036\x15\x00\x00\x00\x00\x00\x00\x19v\xa9\x14\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec\x88\xacx\x1e\x00\x00\x00\x00\x00\x00iQ!\x02bA[\xf0J\xf84B==\xd7\xad\xa4\xdcrz\x03\x08eu\x9f\x9f\xbaZ\xeex\xc9\xeaq\xe5\x87\x98!\x02T\xdaT\x0f\xb2f;u\xe6\xc3\xcca\x19\n\xd0\xc2C\x16C\xba\xb2\x8c\xedx<\xd9@y\xbb\xe7$G!\x02\x82\xb8\x86\xc0\x87\xeb7\xdc\x81\x82\xf1K\xa6\xcc>\x94\x85\xeda\x8b\x95\x80MD\xae\xcc\x17\xc3\x00\xb5\x85\xb0S\xaeV\x04\xea\x0b\x00\x00\x00\x00\x19v\xa9\x14H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607\x88\xac\x00\x00\x00\x00'
        },  {
            'in': ('multisig', [{'txid': 'e43c357b78baf473fd21cbc1481ac450746b60cf1d2702ce3a73a8811811e3eb', 'txhex': '0100000001980b1a29634f263b00e5301519c153edd65c9149445c9dfdf175b07782388a84000000006a4730440220438f0878ec34cbb676ad8d8badcf81d93a7748a7b85c5841c5bed024b0ad287602203bd635a7d15ccabe235da9cf5086e9a2611242b0e894bd2f9f66a1d4de3fff3d01210276e73c0c0b5af814085f9a9bec7421bc97bc84c4f5bbdf4f6973bd04e16765e7ffffffff0100e1f505000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000', 'amount': 1.0, 'vout': 0, 'scriptPubKey': '76a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac', 'address': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'confirmations': 2}], [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 62000000)], None, ('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 37990000), None),
            'out': b'\x01\x00\x00\x00\x01\xeb\xe3\x11\x18\x81\xa8s:\xce\x02\'\x1d\xcf`ktP\xc4\x1aH\xc1\xcb!\xfds\xf4\xbax{5<\xe4\x00\x00\x00\x00\x19v\xa9\x14\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec\x88\xac\xff\xff\xff\xff\x02\x80\x0b\xb2\x03\x00\x00\x00\x00\x19v\xa9\x14\xa1\x1bf\xa6{?\xf6\x96q\xc8\xf8"T\t\x9f\xaf7K\x80\x0e\x88\xacp\xaeC\x02\x00\x00\x00\x00\x19v\xa9\x14\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec\x88\xac\x00\x00\x00\x00'
        }],
        'get_dust_return_pubkey': [{
            'in': (ADDR[1], None, 'multisig'),
            'out': None
        },  {
            'in': (ADDR[1], [],'multisig'),
            'out': b'\x03\x19\xf6\xe0{\x0b\x8duaV9K\x9d\xcf;\x01\x1f\xe9\xac\x19\xf2p\x0b\xd6\xb6\x9aj\x17\x83\xdb\xb8\xb9w'
        }],
        'construct': [{
            'in': (('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 62000000)], None), {'encoding': 'multisig', 'exact_fee': 1.0}),
            'error': (exceptions.TransactionError, 'Exact fees must be in satoshis.')
        }, {
            'in': (('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 62000000)], None), {'encoding': 'multisig', 'fee_provided': 1.0}),
            'error': (exceptions.TransactionError, 'Fee provided must be in satoshis.')
        }, {
            'in': (('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 5429)], None), {'encoding': 'singlesig'}),
            'error': (exceptions.TransactionError, 'Destination output is dust.')
        }, {
            'in': (('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', 7799)], None), {'encoding': 'multisig'}),
            'error': (exceptions.TransactionError, 'Destination output is dust.')
        }, {
            'in': (('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 62000000)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80'), {'encoding': 'foobar'}),
            'error': (exceptions.TransactionError, 'Unknown encoding‐scheme.')
        }, {
            'in': (('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 62000000)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80\x02\xfa\xf0\x80\x02\xfa\xf0\x80\x02\xfa\xf0\x80\x02\xfa\xf0\x80\x02\xfa\xf0\x80\x02\xfa\xf0\x80\x02\xfa\xf0'), {'encoding': 'opreturn'}),
            'error': (exceptions.TransactionError, 'One `OP_RETURN` output per transaction.')
        }, {
            'in': (('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 2**30)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80'), {'encoding': 'multisig'}),
            'error': (exceptions.BalanceError,  'Insufficient BTC at address mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns. (Need approximately 10.73759624 BTC.) To spend unconfirmed coins, use the flag `--unconfirmed`. (Unconfirmed coins cannot be spent from multi‐sig addresses.)')
        }, {
            'comment': 'burn',
            'in': (('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 62000000)], None), {'encoding': 'multisig'}),
            'out': '0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac70ae4302000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000'
        }, {
            'comment': 'multisig burn',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [('mvCounterpartyXXXXXXXXXXXXXXW24Hef', 50000000)], None), {'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff0280f0fa02000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac70c9fa02000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'comment': 'send',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000006951210262415bf04af834423d3dd7ada4dc727a030865759f9fba5aee78c9ea71e58798210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae5604ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'send dest multisig',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae781e0000000000006951210362415bf04af834423d3dd7ada4dc727a030865759f9fba5aee7fc6fbf1e5875a210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'send dest multisig exact_fee',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00'), {'encoding': 'multisig', 'exact_fee': 1}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae781e0000000000006951210362415bf04af834423d3dd7ada4dc727a030865759f9fba5aee7fc6fbf1e5875a210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae2322ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'send dest opreturn',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00'), {'encoding': 'opreturn'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000000000001e6a1c2a504df746f83442653dd7ada4dc727a030865749e9fba5aeb8fd21a8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'send dest pubkeyhash',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00'), {'encoding': 'pubkeyhash'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff04781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae36150000000000001976a9146d415bf04af834423d3dd7ada4dc727a0308657588ac36150000000000001976a9146f415bf04af834423d3cd7ada4dc778fe208657588ac20efe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'send dest 1-of-1',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_1', None)], b'\x00\x00\x00\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'error': (script.MultiSigAddressError, 'Invalid signatures_possible.')
        }, {
            'comment': 'send source multisig',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00'), {'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e0000000000006951210334caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108892102bc14528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b57d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4286f505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'comment': 'send source and dest multisig',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [('1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00'), {'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff03781e0000000000004751210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977210378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b52ae781e0000000000006951210334caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108892102bc14528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b57d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae007df505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'comment': 'maximum quantity send',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000006951210362415bf04af834423d3dd7ada4dc727a0308664fa0e045a51185cce50ee58717210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae5604ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'issuance',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210359415bf04af834423d3dd7adb0dc727a03086e897d9fba5aee7a331919e4871d210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'issuance',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', None)], b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000006951210259415bf04af834423d3dd7adb0dc727aa153863ef89fba5aee7a331af1e4873a210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae5604ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'multisig issuance',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e000000000000695121030fcaf7ca87f0fd78a01d9a0d7c221e55beef3cde388be72d254826b32a6008cb2102bc14528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b57d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae789bf505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'comment': 'maximum quantity issuance',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\x14\x00\x00\x00\x00\xdd\x96\xd2t\x7f\xff\xff\xff\xff\xff\xff\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10Maximum quantity'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210249415bf04af834423d3dd7adb0dc727a03d5f3a7eae045a51185cce50ee4877e210354da540fb2663b75f68ead197067a5af636736dbdcf8840c45d94079bbe724cb210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'transfer asset to multisig',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', None)], b'\x00\x00\x00\x14\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae781e0000000000006951210259415bf04af834423d3dd7adb0dc727aa153863ef89fba5aee7a331af1e4873a210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'order',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig','fee_provided': DP['fee_provided']}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210348415bf04af834423d3dd7adaedc727a030865759e9fba5aee78c9ea71e5870f210354da540fb2673b75e6c3c994f80ad0c8431643bab28ced783cd94079bbe72445210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae5cfeda0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'multisig order',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig','fee_provided': DP['fee_provided']}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e000000000000695121021ecaf7ca87f0fd78a01d9a0d62221e55beef3722db8be72d254adc40426108d02103bc14528340c37d005aa9e764ded8c038ffa94625307a450077125d580099b53b210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4880e605000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'comment': 'multisig order',
            'in': (('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x06B,@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xfa\xf0\x80\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0'), {'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e000000000000695121031ecaf7ca87f0fd78a01d9a0d62221e55beef3722da8be72d254e649c8261083d2102bc14528340c27d005aa9e06bcf58c038ffa946253077fea077125d580099b5bb210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae789bf505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'comment': 'maximum quantity order',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\n\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\n\x00\x00\x00\x00\x00\r\xbb\xa0'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210248415bf04af834423d3dd7adaedc727a0308664fa0e045a51185cce50ee58759210354da540fb2673b75e6c3c994f80ad0c8431643bab28156d83cd94079bbe72452210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'dividend',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x002\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e000000000000695121035a415bf04af834423d3dd7ad96dc727a030d90949e9fba5a4c21d05197e58735210254da540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe7246f210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'dividend',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x002\x00\x00\x00\x00\x00\x00\x00\x01\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x00\x01'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e000000000000695121025a415bf04af834423d3dd7ad96dc727a030865759f9fbc9036a64c1197e587c8210254da540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe7246f210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'comment': 'free issuance',
            'in': (('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', [], b'\x00\x00\x00\x14\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x03\xe8\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'), {'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210259415bf04af834423d3dd7adb0238d85fcf79a8a619fba5aee7a331919e487e8210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }],
    },
    'api': {
        'get_rows': [{
            'in': ('balances', None, 'AND', None, None, None, None, None, 1000, 0, True),
            'out': None
        }, {
            'in': ('balances', None, 'barfoo', None, None, None, None, None, 1000, 0, True),
            'error': (APIError, 'Invalid filter operator (OR, AND)')
        }, {
            'in': (None, None, 'AND', None, None, None, None, None, 1000, 0, True),
            'error': (APIError, 'Unknown table')
        }, {
            'in': ('balances', None, 'AND', None, 'barfoo', None, None, None, 1000, 0, True),
            'error': (APIError, 'Invalid order direction (ASC, DESC)')
        }, {
            'in': ('balances', None, 'AND', None, None, None, None, None, 1000.0, 0, True),
            'error': (APIError, 'Invalid limit')
        }, {
            'in': ('balances', None, 'AND', None, None, None, None, None, 1001, 0, True),
            'error': (APIError, 'Limit should be lower or equal to 1000')
        }, {
            'in': ('balances', None, 'AND', None, None, None, None, None, 1000, 0.0, True),
            'error': (APIError, 'Invalid offset')
        }, {
            'in': ('balances', None, 'AND', '*', None, None, None, None, 1000, 0, True),
            'error': (APIError, 'Invalid order_by, must be a field name')
        }, {
            'in': ('balances', [0], 'AND', None, None, None, None, None, 1000, 0, True),
            'error': (APIError, 'Unknown filter type')
        }, {
            'in': ('balances', {'field': 'bar', 'op': '='}, 'AND', None, None, None, None, None, 1000, 0, True),
            'error': (APIError, "A specified filter is missing the 'value' field")
        }, {
            'in': ('balances', {'field': 'bar', 'op': '=', 'value': {}}, 'AND', None, None, None, None, None, 1000, 0, True),
            'error': (APIError, "Invalid value for the field 'bar'")
        }, {
            'in': ('balances', {'field': 'bar', 'op': '=', 'value': [0,2]}, 'AND', None, None, None, None, None, 1000, 0, True),
            'error': (APIError, "Invalid value for the field 'bar'")
        }, {
            'in': ('balances', {'field': 'bar', 'op': 'AND', 'value': 0}, 'AND', None, None, None, None, None, 1000, 0, True),
            'error': (APIError, "Invalid operator for the field 'bar'")
        }, {
            'in': ('balances', {'field': 'bar', 'op': '=', 'value': 0, 'case_sensitive': 0}, 'AND', None, None, None, None, None, 1000, 0, True),
            'error': (APIError, "case_sensitive must be a boolean")
        }],
    },
    'script': {
        'validate': [{
            'comment': 'valid bitcoin address',
            'in': ('mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6',),
            'out': None
        }, {
            'comment': 'invalid bitcoin address: bad checksum',
            'in': ('mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP7',),
            'error': (script.Base58ChecksumError, 'Checksum mismatch: 0x00285aa2 ≠ 0x00285aa1')
        }, {
            'comment': 'valid multi‐sig',
            'in': ('1_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2',),
            'out': None
        }],
        'scriptpubkey_to_address': [{
            'in': (['mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH', 'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'],),
            'out': None
        }],
        'get_asm': [{
            'in': ([],),
            'error': (exceptions.DecodeError, 'empty output')
        }],
        'base58_encode': [{
            'comment': 'random bytes',
            'in': (b'\x82\xe3\x069\x16\x17I\x12S\x81\xeaQC\xa6J\xac',),
            'out': 'HARXEpbq7gJQGcSVUtubYo'
        }, {
            'in': (b"\x01\tfw`\x06\x95=UgC\x9e^9\xf8j\r';\xee",),
            'out': 'qb3y62fmEEVTPySXPQ77WXok6H'
        }],
        'base58_check_encode': [{
            'comment': 'valid mainnet bitcoin address',
            'in': ('010966776006953d5567439e5e39f86a0d273bee', b'\x00'),
            'out': '16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM'
        # TODO }, {
        #    'invalid mainnet bitcoin address: leading zero byte,
        #    'in': ('SOMETHING', b'\x00'),
        #    'error': (script.AddressError, 'encoded address does not decode properly')
        }],
        'base58_check_decode': [{
            'comment': 'valid mainnet bitcoin address',
            'in': ('16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM', b'\x00'),
            'out': b"\x01\tfw`\x06\x95=UgC\x9e^9\xf8j\r';\xee"
        }, {
            'comment': 'wrong version byte',
            'in': ('26UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM', b'\x00'),
            'error': (script.VersionByteError, 'incorrect version byte')
        }, {
            'comment': 'invalid mainnet bitcoin address: bad checksum',
            'in': ('16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvN', b'\x00'),
            'error': (script.Base58ChecksumError, 'Checksum mismatch: 0xd61967f7 ≠ 0xd61967f6')
        }, {
            'in': (ADDR[0], b'\x6f'),                                                               # TODO: What is this?
            'out': b'H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607'
        }, {
            'comment': 'invalid mainnet bitcoin address: invalid character',
            'in': ('16UwLL9Risc3QfPqBUvKofHmBQ7wMtjv0', b'\x00'),
            'error': (script.Base58Error, "Not a valid Base58 character: ‘0’")
        }],
        'is_multisig': [{
            'comment': 'mono‐sig',
            'in': ('16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM',),
            'out': False
        }, {
            'comment': 'multi‐sig',
            'in': ('1_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2',),
            'out': True
        }],
        'is_fully_valid': [{
            'comment': 'fully valid compressed public key',
            'in': (b'\x03T\xdaT\x0f\xb2g;u\xe6\xc3\xc9\x94\xf8\n\xd0\xc8C\x16C\xba\xb2\x8c\xedx<\xd9@y\xbb\xe7$E',),
            'out': True
        }, {
            'comment': 'not fully valid compressed public key: last byte decremented; not on curve',
            'in': (b'\x03T\xdaT\x0f\xb2g;u\xe6\xc3\xc9\x94\xf8\n\xd0\xc8C\x16C\xba\xb2\x8c\xedx<\xd9@y\xbb\xe7$D',),
            'out': False
        }, {
            'comment': 'invalid compressed public key: first byte not `\x02` or `\x03`',
            'in': (b'\x01T\xdaT\x0f\xb2g;u\xe6\xc3\xc9\x94\xf8\n\xd0\xc8C\x16C\xba\xb2\x8c\xedx<\xd9@y\xbb\xe7$E',),
            'out': False
        }],
        'make_canonical': [{
            'in': ('1_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_2',),                   # TODO: Pubkeys out of order
            'out': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'
        }, {
            'in': ('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',),                   # TODO: Pubkeys out of order
            'out': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'
        }, {
            'comment': 'mono‐sig',
            'in': ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',),
            'out': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'
        }, {
            'in': ('1_02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2',),
            'error': (script.MultiSigAddressError, 'Multi‐signature address must use PubKeyHashes, not public keys.')
        }],

        'test_array': [{
            'in': ('1', ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'], 2),
            'out': None
        }, {
            'in': ('Q', ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'], 2),
            'error': (script.MultiSigAddressError, 'Signature values not integers.')
        }, {
            'in': ('1', ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'], None),
            'error': (script.MultiSigAddressError, 'Signature values not integers.')
        }, {
            'in': ('0', ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'], 2),
            'error': (script.MultiSigAddressError, 'Invalid signatures_required.')
        }, {
            'in': ('4', ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'], 2),
            'error': (script.MultiSigAddressError, 'Invalid signatures_required.')
        }, {
            'in': ('1', ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'], 1),
            'error': (script.MultiSigAddressError, 'Invalid signatures_possible.')
        }, {
            'in': ('2', ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'], 4),
            'error': (script.MultiSigAddressError, 'Invalid signatures_possible.')
        }, {
            'in': ('1', ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_2'], 2),
            'error': (script.MultiSigAddressError, 'Invalid characters in pubkeys/pubkeyhashes.')
        },  {
            'in': ('3', ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'], 3),
            'error': (script.InputError, 'Incorrect number of pubkeys/pubkeyhashes in multi‐signature address.')
        }],
        'construct_array': [{
            'in': ('1', ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'], 2),
            'out': '1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'
        }],
        'extract_array': [{
            'in': ('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',),
            'out': (1, ['mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'], 2)
        }],
        'pubkeyhash_array': [{
            'in': ('1_xxxxxxxxxxxWRONGxxxxxxxxxxxxxxxxxx_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',),
            'error': (script.MultiSigAddressError, 'Invalid PubKeyHashes. Multi‐signature address must use PubKeyHashes, not public keys.')
        }, {
            'in': ('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',),
            'out': ['mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns']
        }],
        'is_pubkeyhash': [{
            'comment': 'valid bitcoin address',
            'in': ('mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6',),
            'out': True
        }, {
            'comment': 'invalid checksum',
            'in': ('mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP7',),
            'out': False
        }, {
            'comment': 'invalid version byte',
            'in': ('LnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6',),
            'out': False
        }],
        'make_pubkeyhash': [{
            'comment': 'mono‐sig',
            'in': ('02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558',),
            'out': 'mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6'
        }, {
            'comment': 'multi‐sig, with pubkey in first position and pubkeyhash in second',
            'in': ('1_02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2',),
            'out': '1_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2'
        }],
        'extract_pubkeys': [{
            'comment': 'pubkeyhash',
            'in': ('mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6',),
            'out': []
        }, {
            'comment': 'mono‐sig',
            'in': ('02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558',),
            'out': ['02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558']
        }, {
            'comment': 'multi‐sig, with pubkey in first position and pubkeyhash in second',
            'in': ('1_02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2',),
            'out': ['02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558']
        }]
    },
    'util': {
        'api': [{
            'in': ('create_burn', {'source': ADDR[1], 'quantity': DP['burn_quantity'], 'encoding': 'multisig'}),
            'out': '0100000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce4000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88acffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac70ae4302000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000'
        }, {
            'in': ('create_send', {'source': ADDR[0], 'destination': ADDR[1], 'asset': 'XCP', 'quantity': DP['small'], 'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000006951210262415bf04af834423d3dd7ada4dc727a030865759f9fba5aee78c9ea71e58798210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae5604ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_issuance', {'source': ADDR[0], 'transfer_destination': None, 'asset': 'BSSET', 'quantity': 1000, 'divisible': True, 'description': '', 'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210359415bf04af834423d3dd7adb0dc727a03086e897d9fba5aee7a331919e4871d210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_issuance', {'source': ADDR[0], 'transfer_destination': ADDR[1], 'asset': 'DIVISIBLE', 'quantity': 0, 'divisible': True, 'description': '', 'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac781e0000000000006951210259415bf04af834423d3dd7adb0dc727aa153863ef89fba5aee7a331af1e4873a210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae5604ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_order', {'source': ADDR[0], 'give_asset': 'BTC', 'give_quantity': DP['small'], 'get_asset': 'XCP', 'get_quantity': DP['small'] * 2, 'expiration': DP['expiration'], 'fee_required': 0, 'fee_provided': DP['fee_provided'], 'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210348415bf04af834423d3dd7adaedc727a030865759e9fba5aee78c9ea71e5870f210354da540fb2673b75e6c3c994f80ad0c8431643bab28ced783cd94079bbe72445210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae5cfeda0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_order', {'source': ADDR[0], 'give_asset': 'XCP', 'give_quantity': round(DP['small'] * 2.1), 'get_asset': 'BTC', 'get_quantity': DP['small'], 'expiration': DP['expiration'], 'fee_required': DP['fee_required'], 'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210248415bf04af834423d3dd7adaedc727a030865759f9fba5aee7c7136b1e58715210354da540fb2663b75e6c3ce9be98ad0c8431643bab28156d83cd94079bbe72460210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_burn', {'source': MULTISIGADDR[0], 'quantity': int(DP['quantity'] / 2), 'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff0280f0fa02000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac70c9fa02000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'in': ('create_send', {'source': ADDR[0], 'destination': MULTISIGADDR[0], 'asset': 'XCP', 'quantity': DP['quantity'], 'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae781e0000000000006951210362415bf04af834423d3dd7ada4dc727a030865759f9fba5aee7fc6fbf1e5875a210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_send', {'source': MULTISIGADDR[0], 'destination': ADDR[0], 'asset': 'XCP', 'quantity': DP['quantity'], 'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff0336150000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac781e0000000000006951210334caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108892102bc14528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b57d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4286f505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'in': ('create_send', {'source': MULTISIGADDR[0], 'destination': MULTISIGADDR[1], 'asset': 'XCP', 'quantity': DP['quantity'], 'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff03781e0000000000004751210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977210378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b52ae781e0000000000006951210334caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108892102bc14528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b57d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae007df505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'in': ('create_issuance', {'source': MULTISIGADDR[0], 'transfer_destination': None, 'asset': 'BSSET', 'quantity': 1000, 'divisible': True, 'description': '', 'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e000000000000695121030fcaf7ca87f0fd78a01d9a0d7c221e55beef3cde388be72d254826b32a6008cb2102bc14528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b57d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae789bf505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'in': ('create_issuance', {'source': ADDR[0], 'transfer_destination': MULTISIGADDR[0], 'asset': 'DIVISIBLE', 'quantity': 0, 'divisible': True, 'description': '', 'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff03781e0000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae781e0000000000006951210259415bf04af834423d3dd7adb0dc727aa153863ef89fba5aee7a331af1e4873a210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae14fbe90b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_issuance', {'source': ADDR[0], 'asset': 'A{}'.format(2**64 - 1), 'quantity': 1000, 'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e0000000000006951210259415bf04af834423d3dd7adb0238d85fcf79a8a619fba5aee7a331919e487e8210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_order', {'source': MULTISIGADDR[0], 'give_asset': 'BTC', 'give_quantity': DP['small'], 'get_asset': 'XCP', 'get_quantity': DP['small'] * 2, 'expiration': DP['expiration'], 'fee_required': 0, 'fee_provided': DP['fee_provided'], 'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e000000000000695121021ecaf7ca87f0fd78a01d9a0d62221e55beef3722db8be72d254adc40426108d02103bc14528340c37d005aa9e764ded8c038ffa94625307a450077125d580099b53b210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4880e605000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'in': ('create_order', {'source': MULTISIGADDR[0], 'give_asset': 'XCP', 'give_quantity': round(DP['small'] * 2.1), 'get_asset': 'BTC', 'get_quantity': DP['small'], 'expiration': DP['expiration'], 'fee_required': DP['fee_required'], 'encoding': 'multisig'}),
            'out': '0100000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aeffffffff02781e000000000000695121031ecaf7ca87f0fd78a01d9a0d62221e55beef3722da8be72d254e649c8261083d2102bc14528340c27d005aa9e06bcf58c038ffa946253077fea077125d580099b5bb210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae789bf505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000'
        }, {
            'in': ('create_dividend', {'source': ADDR[0], 'quantity_per_unit': DP['quantity'], 'asset': 'DIVISIBLE', 'dividend_asset': 'XCP', 'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e000000000000695121035a415bf04af834423d3dd7ad96dc727a030d90949e9fba5a4c21d05197e58735210254da540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe7246f210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }, {
            'in': ('create_dividend', {'source': ADDR[0], 'quantity_per_unit': 1, 'asset': 'NODIVISIBLE', 'dividend_asset': 'XCP', 'encoding': 'multisig'}),
            'out': '0100000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788acffffffff02781e000000000000695121025a415bf04af834423d3dd7ad96dc727a030865759f9fbc9036a64c1197e587c8210254da540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe7246f210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae8c19ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000'
        }],
        'generate_asset_id': [{
            'in': ('BTC', DP['default_block']),
            'out': 0
        },  {
            'in': ('XCP', DP['default_block']),
            'out': 1
        },  {
            'in': ('BCD', 308000),
            'error': (exceptions.AssetNameError, 'too short')
        }, {
            'in': ('ABCD', 308000),
            'error': (exceptions.AssetNameError, 'non‐numeric asset name starts with ‘A’')
        }, {
            'in': ('A{}'.format(26**12), 308000),
            'error': (exceptions.AssetNameError, 'numeric asset name not in range')
        }, {
            'in': ('A{}'.format(2**64), 308000),
            'error': (exceptions.AssetNameError, 'numeric asset name not in range')
        }, {
            'in': ('A{}'.format(26**12 + 1), 308000),
            'out': 26**12 + 1
        }, {
            'in': ('A{}'.format(2**64 - 1), 308000),
            'out': 2**64 - 1
        }, {
            'in': ('LONGASSETNAMES', 308000),
            'error': (exceptions.AssetNameError, 'long asset names must be numeric')
        }, {
            'in': ('BCDE_F', 308000),
            'error': (exceptions.AssetNameError, "('invalid character:', '_')")
        }, {
            'in': ('BAAA', 308000),
            'out': 26**3
        }, {
            'in': ('ZZZZZZZZZZZZ', 308000),
            'out': 26**12 - 1
        }],
        'generate_asset_name': [{
            'in': (0, DP['default_block']),
            'out': 'BTC'
        },  {
            'in': (1, DP['default_block']),
            'out': 'XCP'
        },  {
            'in': (26**12 - 1, 308000),
            'out': 'ZZZZZZZZZZZZ'
        }, {
            'in': (26**3, 308000),
            'out': 'BAAA'
        }, {
            'in': (2**64 - 1, 308000),
            'out': 'A{}'.format(2**64 - 1)
        }, {
            'in': (26**12 + 1, 308000),
            'out': 'A{}'.format(26**12 + 1)
        }, {
            'in': (26**3 - 1, 308000),
            'error': (exceptions.AssetIDError, 'too low')
        }, {
            'in': (2**64, 308000),
            'error': (exceptions.AssetIDError, 'too high')
        }],
        'price': [{
            'in': (1, 10),
            'out': Fraction(1, 10)
        }],
        'dhash_string': [{
            'in': ('foobar',),
            'out': '3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda1'
        }],
        'hexlify': [{
            'in': (b'\x00\x00\x00\x14\x00\x00\x00\x00\x00\x0b\xfc\xe3',),
            'out': '0000001400000000000bfce3'
        }],
        'last_message': [{
            'in': (),
            'out': {'command': 'insert', 'block_index': 310496, 'message_index': 79, 'category': 'sends', 'timestamp': 0, 'bindings': '{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef", "tx_index": 497}'}
        }],
        'get_asset_id': [{
            'in': ('XCP', DP['default_block']),
            'out': 1
        },  {
            'in': ('BTC', DP['default_block']),
            'out': 0
        },  {
            'in': ('foobar', DP['default_block']),
            'error': (exceptions.AssetError, 'No such asset: foobar')
        }],
        'debit': [{
            'in': (ADDR[0], 'XCP', 1),
            'out': None
        },  {
            'in': (ADDR[0], 'BTC', DP['quantity']),
            'error': (DebitError, 'Cannot debit bitcoins.')
        },  {
            'in': (ADDR[0], 'BTC', -1 * DP['quantity']),
            'error': (DebitError, 'Negative quantity.')
        },  {
            'in': (ADDR[0], 'BTC', 1.1 * DP['quantity']),
            'error': (DebitError, 'Quantity must be an integer.')
        },  {
            'in': (ADDR[0], 'XCP', 2**40),
            'error': (DebitError, 'Insufficient funds.')
        }],
        'credit': [{
            'in': (ADDR[0], 'XCP', 1),
            'out': None
        },  {
            'in': (ADDR[0], 'BTC', DP['quantity']),
            'error': (CreditError, 'Cannot debit bitcoins.')
        },  {
            'in': (ADDR[0], 'BTC', -1 * DP['quantity']),
            'error': (CreditError, 'Negative quantity.')
        },  {
            'in': (ADDR[0], 'BTC', 1.1 * DP['quantity']),
            'error': (CreditError, 'Quantity must be an integer.')
        }],
        'is_divisible': [{
            'in': ('XCP',),
            'out': True
        },  {
            'in': ('BTC',),
            'out': True
        },  {
            'in': ('DIVISIBLE',),
            'out': True
        },  {
            'in': ('NODIVISIBLE',),
            'out': False
        },  {
            'in': ('foobar',),
            'error': (exceptions.AssetError, 'No such asset: foobar')
        }],
        'value_in': [{
            'in': (1.1, 'leverage',),
            'out': 1
        },  {
            'in': (1/10, 'fraction',),
            'out': 0.1
        },  {
            'in': (1, 'NODIVISIBLE',),
            'out': 1
        },  {
            'in': (1.111111111111, 'DIVISIBLE',),
            'error': (QuantityError, 'Divisible assets have only eight decimal places of precision.')
        },  {
            'in': (1.1, 'NODIVISIBLE',),
            'error': (QuantityError, 'Fractional quantities of indivisible assets.')
        }],
        'value_out': [{
            'in': (1.1, 'leverage',),
            'out': '1.1'
        },  {
            'in': (1/10, 'fraction',),
            'out': '10.0%'
        },  {
            'in': (1, 'NODIVISIBLE',),
            'out': 1
        },  {
            'in': (1.1, 'NODIVISIBLE',),
            'error': (QuantityError, 'Fractional quantities of indivisible assets.')
        }],
        'xcp_created': [{
            'in': (),
            'out': 185995878046
        }],
        'xcp_destroyed': [{
            'in': (),
            'out': 300000000
        }],
        'xcp_supply': [{
            'in': (),
            'out': 185695878046
        }],
        'creations': [{
            'in': (),
            'out': {'CALLABLE': 1000, 'DIVIDEND': 100, 'DIVISIBLE': 100000000000, 'LOCKED': 1000, 'MAXI': 9223372036854775807, 'NODIVISIBLE': 1000, 'XCP': 185995878046}
        }],
        'destructions': [{
            'in': (),
            'out': {'XCP': 300000000}
        }],
        'asset_supply': [{
            'in': ('XCP',),
            'out': 185695878046
        }],
        'supplies': [{
            'in': (),
            'out':  {'CALLABLE': 1000, 'DIVIDEND': 100, 'DIVISIBLE': 100000000000, 'LOCKED': 1000, 'MAXI': 9223372036854775807, 'NODIVISIBLE': 1000, 'XCP': 185695878046}
        }],
        'get_balance': [{
            'in': (ADDR[0], 'XCP'),
            'out': 91950000000
        },  {
            'in': (ADDR[0], 'foobar'),
            'out': 0
        }],
        'get_asset_name': [{
            'in': (1, DP['default_block']),
            'out': 'XCP'
        },  {
            'in': (0, DP['default_block']),
            'out': 'BTC'
        },  {
            'in': (453, DP['default_block']),
            'out': 0
        }],
        'enabled': [{
            'in': ('numeric_asset_names',),
            'out': True
        },  {
            'in': ('foobar',),
            'error': (KeyError, "'foobar'")
        }],
        'date_passed': [{
            'comment': 'date in the past, mock function overrides this one and always returns `False` in the test suite',
            'in': ('1020720007',),
            'out': False
        },  {
            'comment': 'date far in the future, mock function overrides this one and always returns `False` in the test suite',
            'in': ('5520720007',),
            'out': False
        }],
    },
    'database': {
        'version': [{
            'in': (),
            'out': (config.VERSION_MAJOR, config.VERSION_MINOR)
        }],
        'update_version': [{
            'in': (),
            'records': [
                {'table': 'pragma', 'field':'user_version', 'value': (config.VERSION_MAJOR * 1000) + config.VERSION_MINOR}
            ]
        }]
    }
}
