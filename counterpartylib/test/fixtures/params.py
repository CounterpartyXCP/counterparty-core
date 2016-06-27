"""
This is a collection of default transaction data used to test various components.
"""

UNIT = 100000000

"""This structure is used throughout the test suite to populate transactions with standardized and tested data."""
DEFAULT_PARAMS = {
    'addresses': [
        ['mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc', '4838d8b3588c4c7ba7c1d06f866e9b3739c63037', 'cPdUqd5EbBWsjcG9xiL1hz8bEyGFiz4SW99maU9JgpL9TEcxUf3j', '0282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0'],
        ['mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', '8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec', 'cQ897jnCVRrawNbw8hgmjMiRNHejwzg4KbzdMCzc91iaTif8ReqX', '0319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977'],
        ['mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH', '4e5638a01efbb2f292481797ae1dcfcdaeb98d00', 'cRNnyC1h5qjv3tHkkt74Y5wowknM1BBDK5Ft2hj5SzfV3mgwPvC3', '0378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b'],
        ['mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj', '6c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a152', 'cNNz8RhmTQufdmCKsCYjxPy43J6AxrH1wnAjutrxbeQs7Cy4C9q1', '037af2e06061b54cdfe3657bbc8496d69000b822e2db0c86ccbe376346a700b833'],
        ['myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM', 'c1a6de504b9bc0d0d6987312b2e37564079791b7', 'cPEo2oY8z3Fe9dDcFmzA7Wr1LjFh7iVQkCgBoXZEvQ8X6T2kfAHk', '02610f28a56e187f5cd133d7bfe107b159fa3b5129ba35e91fb915fe9a8efa43b4'],
        ['munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b', '9c8d1f5405451de6070bf1db86ab6accb495b625', 'cNGEvSnRJ4wqdKWrni3fcX9wKTHXJt1gmoBUTrfqNrtKVZCnTUR2', '025bc8fb22d87eb72fb5e297803ab9aa3ace5bf38df4e23918b876fd3ea0cdd7b8'],
        ['mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42', 'b390187ef2854422ac5e4a2eb6ffe92496bef523', 'cQiFxpxU2twNfViTqv3Tp3nY6H6Wd2YnypKjJFCkuim8YY3iQo2B', '03c403a9364dcb223cc32df5a4afab6089e941590cecfd5ac823c4fcff46e8f6c5']
    ],
    'quantity': UNIT,
    'small': round(UNIT / 2),
    'expiration': 10,
    'fee_required': 900000,
    'fee_provided': 1000000,
    'fee_multiplier': .05,
    'unspendable': 'mvCounterpartyXXXXXXXXXXXXXXW24Hef',
    'burn_start': 310000,
    'burn_end': 4017708,
    'burn_quantity': int(.62 * UNIT),
    'default_block_index': 310000 + 501,
    'default_block_hash': '2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8'
}
DEFAULT_PARAMS['privkey'] = {addr: priv for (addr, pubkeyhash, priv, pub) in DEFAULT_PARAMS['addresses']}
DEFAULT_PARAMS['pubkey'] = {addr: pub for (addr, pubkeyhash, priv, pub) in DEFAULT_PARAMS['addresses']}
ADDR = [a[0] for a in DEFAULT_PARAMS['addresses']]
DP = DEFAULT_PARAMS
MULTISIGADDR = [
    '1_{}_{}_2'.format(ADDR[0], ADDR[1]),
    '1_{}_{}_2'.format(ADDR[2], ADDR[1]),
    '1_{}_{}_2'.format(ADDR[0], ADDR[2]),

    '2_{}_{}_2'.format(ADDR[0], ADDR[1]),
    '2_{}_{}_2'.format(ADDR[2], ADDR[1]),

    '1_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[1]),
    '1_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[3]),

    '2_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[1]),
    '2_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[3]),

    '3_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[1]),
    '3_{}_{}_{}_3'.format(ADDR[0], ADDR[2], ADDR[3])
]

import binascii
import bitcoin as bitcoinlib

# bitcoinlib.SelectParams('testnet')
# addr0 = DEFAULT_PARAMS['addresses'][0]
# pubkey0 = binascii.unhexlify(addr0[3])
# for addr in DEFAULT_PARAMS['addresses'][1:]:
#     pubkey1 = binascii.unhexlify(addr[3])
#
#     redeemScript = bitcoinlib.core.CScript([bitcoinlib.core.script.OP_2, pubkey0, pubkey1, bitcoinlib.core.script.OP_2, bitcoinlib.core.script.OP_CHECKMULTISIG])
#     scriptPubKey = redeemScript.to_p2sh_scriptPubKey()
#     p2sh_address = bitcoinlib.wallet.CBitcoinAddress.from_scriptPubKey(scriptPubKey)
#
#     print('''"%s",  # 2of2 %s %s''' % (p2sh_address, addr0[0], addr[0]))
#     print(binascii.hexlify(scriptPubKey))

P2SH_ADDR = [
    "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",  # 2of2 mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns
    "2NErxwfmefM47yQ7Mk4y7WCqmvNfW2bhzic",  # 2of2 mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH
    "2MxHK9KY4zhTPoupLCyXgPJoN2GtCsFr7gK",  # 2of2 mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj
    "2MuWaw3xAczwSL6DKY77kEP7JgAWiQdqFSy",  # 2of2 mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM
    "2MtBCufaZs6NDoDfLfR5MGG3KtDzUG2Pmy8",  # 2of2 mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b
    "2N3ACzPYimgijjPWhowmwPWzzY7XtvqbtRq",  # 2of2 mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42
]
