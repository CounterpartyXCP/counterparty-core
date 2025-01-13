import bitcoin as bitcoinlib

from counterpartycore.lib import exceptions, script

from ..params import ADDR, P2SH_ADDR

SCRIPT_VECTOR = {
    "script": {
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
                "error": (script.Base58Error, "invalid base58 string"),
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
                    script.MultiSigAddressError,
                    "Invalid PubKeyHashes. Multi-signature address must use PubKeyHashes, not public keys.",
                ),
            },
        ],
        "scriptpubkey_to_address": [
            # "OP_DUP OP_HASH160 4838d8b3588c4c7ba7c1d06f866e9b3739c63037 OP_EQUALVERIFY OP_CHECKSIG"
            {
                "in": (
                    bitcoinlib.core.CScript(
                        bitcoinlib.core.x("76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac")
                    ),
                ),
                "out": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            },
            # "OP_DUP OP_HASH160 8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec OP_EQUALVERIFY OP_CHECKSIG"
            {
                "in": (
                    bitcoinlib.core.CScript(
                        bitcoinlib.core.x("76a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac")
                    ),
                ),
                "out": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            },
            # "1 035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe35 02309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17 0319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977 3 OP_CHECKMULTISIG"
            {
                "in": (
                    bitcoinlib.core.CScript(
                        bitcoinlib.core.x(
                            "5121035ca51ea175f108a1c63588683dc4c43a7146c46799f864a300263c0813f5fe352102309a14a1a30202f2e76f46acdb2917752371ca42b97460f7928ade8ecb02ea17210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae"
                        )
                    ),
                ),
                "out": "1_mjH9amw2tJrsrw76PVvCkCQ18V4pZCVtm5_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_mvgph5nejRWUVvbzyq7TU9ENpJyV97ua37_3",
            },
            {
                "in": ("mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",),
                "error": (exceptions.DecodeError, "invalid script"),
            },
            {
                "in": (
                    [
                        "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
                        "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
                    ],
                ),
                "error": (exceptions.DecodeError, "invalid script"),
            },
            {
                "in": (
                    bitcoinlib.core.CScript(
                        bitcoinlib.core.x("6a53657466697665207361797320686921")
                    ),
                ),
                "error": (exceptions.DecodeError, "invalid script"),
            },
            {
                "comment": "p2pkh",
                "in": (
                    bitcoinlib.core.CScript(
                        bitcoinlib.core.x("76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac")
                    ),
                ),
                "out": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            },
            {
                "comment": "p2sh",
                "in": (
                    bitcoinlib.core.CScript(
                        bitcoinlib.core.x("a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e87")
                    ),
                ),
                "out": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
            },
        ],
        "get_asm": [{"in": (b"",), "error": (exceptions.DecodeError, "empty output")}],
        "base58_encode": [
            {
                "comment": "random bytes",
                "in": (b"\x82\xe3\x069\x16\x17I\x12S\x81\xeaQC\xa6J\xac",),
                "out": "HARXEpbq7gJQGcSVUtubYo",
            },
            {
                "in": (b"\x01\tfw`\x06\x95=UgC\x9e^9\xf8j\r';\xee",),
                "out": "qb3y62fmEEVTPySXPQ77WXok6H",
            },
        ],
        "base58_check_encode": [
            {
                "comment": "valid mainnet bitcoin address",
                "in": ("010966776006953d5567439e5e39f86a0d273bee", b"\x00"),
                "out": "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM",
            },
            {
                "comment": "valid mainnet bitcoin P2SH address",
                "in": ("010966776006953d5567439e5e39f86a0d273bee", b"\x05"),
                "out": "31nVrspaydBz8aMpxH9WkS2DuhgqS1fCuG",
                # TODO }, {
                #    'invalid mainnet bitcoin address: leading zero byte,
                #    'in': ('SOMETHING', b'\x00'),
                #    'error': (script.AddressError, 'encoded address does not decode properly')
            },
        ],
        "base58_check_decode": [
            {
                "comment": "valid mainnet bitcoin address",
                "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM", b"\x00"),
                "out": b"\x01\tfw`\x06\x95=UgC\x9e^9\xf8j\r';\xee",
            },
            {
                "comment": "valid mainnet bitcoin address that contains a padding byte",
                "in": ("13PGb7v3nmTDugLDStRJWXw6TzsNLUKJKC", b"\x00"),
                "out": b"\x1a&jGxV\xea\xd2\x9e\xcb\xe6\xaeQ\xad:,\x8dG<\xf4",
            },
            {
                "comment": "valid mainnet bitcoin P2SH address",
                "in": ("31nVrspaydBz8aMpxH9WkS2DuhgqS1fCuG", b"\x05"),
                "out": b"\x01\tfw`\x06\x95=UgC\x9e^9\xf8j\r';\xee",
            },
            {
                "comment": "valid mainnet bitcoin address that contains a padding byte, checked against incorrect version byte",
                "in": ("13PGb7v3nmTDugLDStRJWXw6TzsNLUKJKC", b"\x05"),
                "error": (script.VersionByteError, "incorrect version byte"),
            },
            {
                "comment": "valid mainnet bitcoin P2SH address, checked against incorrect version byte",
                "in": ("31nVrspaydBz8aMpxH9WkS2DuhgqS1fCuG", b"\x00"),
                "error": (script.VersionByteError, "incorrect version byte"),
            },
            {
                "comment": "wrong version byte",
                "in": ("26UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM", b"\x00"),
                "error": (script.Base58Error, "invalid base58 string"),
            },
            {
                "comment": "invalid mainnet bitcoin address: bad checksum",
                "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvN", b"\x00"),
                "error": (script.Base58Error, "invalid base58 string"),
            },
            {
                "comment": "valid testnet bitcoin address that we use in many tests",
                "in": (ADDR[0], b"\x6f"),
                "out": b"H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607",
            },
            {
                "comment": "invalid mainnet bitcoin address: invalid character",
                "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjv0", b"\x00"),
                "error": (script.Base58Error, "invalid base58 string"),
            },
        ],
        # base58_decode is the raw decoding, we use the test cases from base58_check_decode
        "base58_decode": [
            {
                "comment": "valid mainnet bitcoin address",
                "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM",),
                "out": b"\x00\x01\tfw`\x06\x95=UgC\x9e^9\xf8j\r';\xee\xd6\x19g\xf6",
            },
            {
                "comment": "valid mainnet bitcoin address that contains a padding byte",
                "in": ("13PGb7v3nmTDugLDStRJWXw6TzsNLUKJKC",),
                "out": b"\x00\x1a&jGxV\xea\xd2\x9e\xcb\xe6\xaeQ\xad:,\x8dG<\xf4\x07eG#",
            },
            {
                "comment": "wrong version byte",
                "in": ("26UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM",),
                "out": b"\x0c\x01\x86\xaa\xbd\xa1\xd2\xdaJ\xf2\xd4\xbb\xe5=N\xe2\x08\xa6\x8eo\xd6\x19g\xf6",
            },
            {
                "comment": "invalid mainnet bitcoin address: bad checksum",
                "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvN",),
                "out": b"\x00\x01\tfw`\x06\x95=UgC\x9e^9\xf8j\r';\xee\xd6\x19g\xf7",
            },
            {
                "comment": "valid testnet bitcoin address that we use in many tests",
                "in": (ADDR[0],),
                "out": b"oH8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607\x98!\xc4U",
            },
            {
                "comment": "invalid mainnet bitcoin address: invalid character",
                "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjv0",),
                "error": (script.Base58Error, "Not a valid Base58 character: ‘0’"),
            },
        ],
        # base58_check_decode_parts is the raw decoding and splitting, we use the test cases from base58_check_decode
        "base58_check_decode_parts": [
            {
                "comment": "valid mainnet bitcoin address",
                "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM",),
                "out": (b"\x00", b"\x01\tfw`\x06\x95=UgC\x9e^9\xf8j\r';\xee", b"\xd6\x19g\xf6"),
            },
            {
                "comment": "valid mainnet bitcoin address that contains a padding byte",
                "in": ("13PGb7v3nmTDugLDStRJWXw6TzsNLUKJKC",),
                "out": (
                    b"\x00",
                    b"\x1a&jGxV\xea\xd2\x9e\xcb\xe6\xaeQ\xad:,\x8dG<\xf4",
                    b"\x07eG#",
                ),
            },
            {
                "comment": "wrong version byte",
                "in": ("26UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM",),
                "out": (
                    b"\x0c",
                    b"\x01\x86\xaa\xbd\xa1\xd2\xdaJ\xf2\xd4\xbb\xe5=N\xe2\x08\xa6\x8eo",
                    b"\xd6\x19g\xf6",
                ),
            },
            {
                "comment": "invalid mainnet bitcoin address: bad checksum",
                "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvN",),
                "out": (b"\x00", b"\x01\tfw`\x06\x95=UgC\x9e^9\xf8j\r';\xee", b"\xd6\x19g\xf7"),
            },
            {
                "comment": "valid testnet bitcoin address that we use in many tests",
                "in": (ADDR[0],),
                "out": (
                    b"o",
                    b"H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607",
                    b"\x98!\xc4U",
                ),
            },
            {
                "comment": "invalid mainnet bitcoin address: invalid character",
                "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjv0",),
                "error": (script.Base58Error, "Not a valid Base58 character: ‘0’"),
            },
        ],
        "is_multisig": [
            {"comment": "mono-sig", "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM",), "out": False},
            {
                "comment": "multi-sig",
                "in": (
                    "1_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2",
                ),
                "out": True,
            },
        ],
        "is_fully_valid": [
            {
                "comment": "fully valid compressed public key",
                "in": (
                    b"\x03T\xdaT\x0f\xb2g;u\xe6\xc3\xc9\x94\xf8\n\xd0\xc8C\x16C\xba\xb2\x8c\xedx<\xd9@y\xbb\xe7$E",
                ),
                "out": True,
            },
            {
                "comment": "not fully valid compressed public key: last byte decremented; not on curve",
                "in": (
                    b"\x03T\xdaT\x0f\xb2g;u\xe6\xc3\xc9\x94\xf8\n\xd0\xc8C\x16C\xba\xb2\x8c\xedx<\xd9@y\xbb\xe7$D",
                ),
                "out": False,
            },
            {
                "comment": "invalid compressed public key: first byte not `\x02` or `\x03`",
                "in": (
                    b"\x01T\xdaT\x0f\xb2g;u\xe6\xc3\xc9\x94\xf8\n\xd0\xc8C\x16C\xba\xb2\x8c\xedx<\xd9@y\xbb\xe7$E",
                ),
                "out": False,
            },
        ],
        "make_canonical": [
            {
                "in": (
                    "1_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_2",
                ),  # TODO: Pubkeys out of order
                "out": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
            },
            {
                "in": (
                    "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                ),  # TODO: Pubkeys out of order
                "out": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
            },
            {
                "comment": "mono-sig",
                "in": ("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",),
                "out": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            },
            {"comment": "mono-sig P2SH", "in": (P2SH_ADDR[0],), "out": P2SH_ADDR[0]},
            {
                "in": (
                    "1_02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2",
                ),
                "error": (
                    script.MultiSigAddressError,
                    "Multi-signature address must use PubKeyHashes, not public keys.",
                ),
            },
        ],
        "test_array": [
            {
                "in": (
                    "1",
                    [
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    ],
                    2,
                ),
                "out": None,
            },
            {
                "in": (
                    "Q",
                    [
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    ],
                    2,
                ),
                "error": (script.MultiSigAddressError, "Signature values not integers."),
            },
            {
                "in": (
                    "1",
                    [
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    ],
                    None,
                ),
                "error": (script.MultiSigAddressError, "Signature values not integers."),
            },
            {
                "in": (
                    "0",
                    [
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    ],
                    2,
                ),
                "error": (script.MultiSigAddressError, "Invalid signatures_required."),
            },
            {
                "in": (
                    "4",
                    [
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    ],
                    2,
                ),
                "error": (script.MultiSigAddressError, "Invalid signatures_required."),
            },
            {
                "in": (
                    "1",
                    [
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    ],
                    1,
                ),
                "error": (script.MultiSigAddressError, "Invalid signatures_possible."),
            },
            {
                "in": (
                    "2",
                    [
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    ],
                    4,
                ),
                "error": (script.MultiSigAddressError, "Invalid signatures_possible."),
            },
            {
                "in": (
                    "1",
                    [
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_2",
                    ],
                    2,
                ),
                "error": (
                    script.MultiSigAddressError,
                    "Invalid characters in pubkeys/pubkeyhashes.",
                ),
            },
            {
                "in": (
                    "3",
                    [
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    ],
                    3,
                ),
                "error": (
                    script.InputError,
                    "Incorrect number of pubkeys/pubkeyhashes in multi-signature address.",
                ),
            },
        ],
        "construct_array": [
            {
                "in": (
                    "1",
                    [
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    ],
                    2,
                ),
                "out": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
            }
        ],
        "extract_array": [
            {
                "in": (
                    "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                ),
                "out": (
                    1,
                    [
                        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    ],
                    2,
                ),
            }
        ],
        "pubkeyhash_array": [
            {
                "in": (
                    "1_xxxxxxxxxxxWRONGxxxxxxxxxxxxxxxxxx_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                ),
                "error": (
                    script.MultiSigAddressError,
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
        "make_pubkeyhash": [
            {
                "comment": "mono-sig",
                "in": ("02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558",),
                "out": "mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6",
            },
            {
                "comment": "multi-sig, with pubkey in first position and pubkeyhash in second",
                "in": (
                    "1_02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2",
                ),
                "out": "1_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2",
            },
        ],
        "extract_pubkeys": [
            {"comment": "pubkeyhash", "in": ("mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6",), "out": []},
            {"comment": "p2sh", "in": (P2SH_ADDR[0],), "out": []},
            {
                "comment": "mono-sig",
                "in": ("02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558",),
                "out": ["02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558"],
            },
            {
                "comment": "multi-sig, with pubkey in first position and pubkeyhash in second",
                "in": (
                    "1_02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2",
                ),
                "out": ["02513522cbf07b0bd553b0d8f8414c476c9275334fd3edfa368386412e3a193558"],
            },
        ],
    },
}
