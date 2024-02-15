import time

from counterpartylib.lib import config
from counterpartylib.lib.script import (
    base58_check_encode,
    base58_check_decode, 
    base58_check_decode_py,
    base58_check_encode_py
)


def test_pycoin_rs():

    vector = [
       ("4264cfd7eb65f8cbbdba98bd9815d5461fad8d7e", config.P2SH_ADDRESSVERSION_TESTNET, "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy"),
       ("641327ad1b3abc18cb6f1650a225f49a47764c22", config.ADDRESSVERSION_TESTNET, "mpe6p9ah9a6yoK57Xd2GEn8D9EonbLLkWJ"),
       ("415354746bc11e9ef91efa85da59f0ad1df61a9d", config.ADDRESSVERSION_MAINNET, "16xQkLFxYZcGtzyGbHD7tmnaeHavD21Kw5"),
       ("edf98b439f45eb4e3239122488cab2773296499d", config.P2SH_ADDRESSVERSION_MAINNET, "3PPK1dRAerbVZRfkh9BhA1Zxq9HrG4rRwN"),
    ]

    for (decoded, version, encoded) in vector:
        by_python = base58_check_encode_py(decoded, version)
        by_rust = base58_check_encode(decoded, version)
        assert by_rust == by_python

        by_python = base58_check_decode_py(encoded, version)
        by_rust = base58_check_decode(encoded, version)
        assert by_rust == by_python

    start_time = time.time()
    for i in range(100000):
        for (decoded, version, encoded) in vector:
            base58_check_encode(decoded, version)
            base58_check_decode(encoded, version)
    rust_duration = time.time() - start_time
    print("rust duration for 400K encodes and 400K decodes: ", rust_duration)

    start_time = time.time()
    for i in range(100000):
        for (decoded, version, encoded) in vector:
            base58_check_encode_py(decoded, version)
            base58_check_decode_py(encoded, version)
    python_duration = time.time() - start_time
    print("python duration for 400K encodes and 400K decodes: ", python_duration)

    assert rust_duration < python_duration