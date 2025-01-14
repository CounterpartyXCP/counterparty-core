import binascii

from counterpartycore.lib import config, exceptions

from ..params import P2SH_ADDR

ADDRESS_VECTOR = {
    "messages.utils.address": {
        "is_pubkeyhash": [
            {
                "comment": "valid bitcoin address",
                "in": ("mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6",),
                "out": True,
            },
            {
                "comment": "valid P2SH bitcoin address, but is_pubkeyhash specifically checks for valid P2PKH address",
                "in": (P2SH_ADDR[0],),
                "out": False,
            },
            {
                "comment": "invalid checksum",
                "in": ("mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP7",),
                "out": False,
            },
            {
                "comment": "invalid version byte",
                "in": ("LnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6",),
                "out": False,
            },
        ],
        "pubkeyhash_array": [
            {
                "in": (
                    "1_xxxxxxxxxxxWRONGxxxxxxxxxxxxxxxxxx_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                ),
                "error": (
                    exceptions.MultiSigAddressError,
                    "Invalid PubKeyHashes. Multi-signature address must use PubKeyHashes, not public keys.",
                ),
            },
            {
                "in": (
                    "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                ),
                "out": [
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                ],
            },
        ],
        "validate": [
            {
                "comment": "valid bitcoin address",
                "in": ("mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6",),
                "out": None,
            },
            {"comment": "valid bitcoin P2SH address", "in": (P2SH_ADDR[0],), "out": None},
            {
                "comment": "invalid bitcoin address: bad checksum",
                "in": ("mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP7",),
                "error": (exceptions.Base58Error, "invalid base58 string"),
            },
            {
                "comment": "valid multi-sig",
                "in": (
                    "1_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2",
                ),
                "out": None,
            },
            {
                "comment": "invalid multi-sig with P2SH addres",
                "in": ("1_" + P2SH_ADDR[0] + "_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2",),
                "error": (
                    exceptions.MultiSigAddressError,
                    "Invalid PubKeyHashes. Multi-signature address must use PubKeyHashes, not public keys.",
                ),
            },
        ],
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
