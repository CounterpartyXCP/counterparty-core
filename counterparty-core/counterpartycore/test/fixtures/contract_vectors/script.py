from counterpartycore.lib import exceptions

from ..params import ADDR

SCRIPT_VECTOR = {
    "utils.multisig": {
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
                "error": (exceptions.MultiSigAddressError, "Signature values not integers."),
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
                "error": (exceptions.MultiSigAddressError, "Signature values not integers."),
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
                "error": (exceptions.MultiSigAddressError, "Invalid signatures_required."),
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
                "error": (exceptions.MultiSigAddressError, "Invalid signatures_required."),
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
                "error": (exceptions.MultiSigAddressError, "Invalid signatures_possible."),
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
                "error": (exceptions.MultiSigAddressError, "Invalid signatures_possible."),
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
                    exceptions.MultiSigAddressError,
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
                    exceptions.InputError,
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
    },
    "utils.base58": {
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
                #    'error': (exceptions.AddressError, 'encoded address does not decode properly')
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
                "error": (exceptions.VersionByteError, "incorrect version byte"),
            },
            {
                "comment": "valid mainnet bitcoin P2SH address, checked against incorrect version byte",
                "in": ("31nVrspaydBz8aMpxH9WkS2DuhgqS1fCuG", b"\x00"),
                "error": (exceptions.VersionByteError, "incorrect version byte"),
            },
            {
                "comment": "wrong version byte",
                "in": ("26UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM", b"\x00"),
                "error": (exceptions.Base58Error, "invalid base58 string"),
            },
            {
                "comment": "invalid mainnet bitcoin address: bad checksum",
                "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvN", b"\x00"),
                "error": (exceptions.Base58Error, "invalid base58 string"),
            },
            {
                "comment": "valid testnet bitcoin address that we use in many tests",
                "in": (ADDR[0], b"\x6f"),
                "out": b"H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607",
            },
            {
                "comment": "invalid mainnet bitcoin address: invalid character",
                "in": ("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjv0", b"\x00"),
                "error": (exceptions.Base58Error, "invalid base58 string"),
            },
        ],
    },
}
