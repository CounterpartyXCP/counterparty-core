import binascii

from counterpartycore.lib import config

ADDRESS_VECTOR = {
    "address": {
        "pack": [
            {
                "config_context": {"ADDRESSVERSION": config.ADDRESSVERSION_MAINNET},
                "in": ("1AAAA1111xxxxxxxxxxxxxxxxxxy43CZ9j",),
                "out": binascii.unhexlify("006474849fc9ac0f5bd6b49fe144d14db7d32e2445"),
            },
            {
                "config_context": {"ADDRESSVERSION": config.ADDRESSVERSION_MAINNET},
                "in": ("1AAAA2222xxxxxxxxxxxxxxxxxxy4pQ3tU",),
                "out": binascii.unhexlify("00647484b055e2101927e50aba74957ba134d501d7"),
            },
            {
                "config_context": {"P2SH_ADDRESSVERSION": config.P2SH_ADDRESSVERSION_MAINNET},
                "in": ("3AAAA1111xxxxxxxxxxxxxxxxxxy3SsDsZ",),
                "out": binascii.unhexlify("055ce31be63403fa7b19f2614272547c15c8df86b9"),
            },
            {
                "config_context": {"P2SH_ADDRESSVERSION": config.P2SH_ADDRESSVERSION_TESTNET},
                "in": ("2MtAV7xpAzU69E8GxRF2Vd2xt79kDnif6F5",),
                "out": binascii.unhexlify("C40A12AD889AECC8F6213BFD6BD47911CAB1C30E5F"),
            },
            {
                "in": ("BADBASE58III",),
                "error": (
                    Exception,
                    "The address BADBASE58III is not a valid bitcoin address (testnet)",
                ),
            },
        ],
        "unpack": [
            {
                "in": (binascii.unhexlify("006474849fc9ac0f5bd6b49fe144d14db7d32e2445"),),
                "out": "1AAAA1111xxxxxxxxxxxxxxxxxxy43CZ9j",
            },
            {
                "in": (binascii.unhexlify("00647484b055e2101927e50aba74957ba134d501d7"),),
                "out": "1AAAA2222xxxxxxxxxxxxxxxxxxy4pQ3tU",
            },
            {
                "in": (binascii.unhexlify("055ce31be63403fa7b19f2614272547c15c8df86b9"),),
                "out": "3AAAA1111xxxxxxxxxxxxxxxxxxy3SsDsZ",
            },
            {
                "in": (binascii.unhexlify("C40A12AD889AECC8F6213BFD6BD47911CAB1C30E5F"),),
                "out": "2MtAV7xpAzU69E8GxRF2Vd2xt79kDnif6F5",
            },
        ],
    },
}
