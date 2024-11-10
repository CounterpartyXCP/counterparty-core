import random
import tempfile

import pytest

from counterpartycore.lib import gas
from counterpartycore.test.fixtures.params import ADDR, DP  # noqa: F401
from counterpartycore.test.util_test import CURR_DIR

FIXTURE_SQL_FILE = CURR_DIR + "/fixtures/scenarios/unittest_fixture.sql"
FIXTURE_DB = tempfile.gettempdir() + "/fixtures.unittest_fixture.db"

TRANSACTION_ID = 101

FEE_BY_TX_COUNT_PER_PERIOD = {
    "2": 0,
    "3": 0,
    "4": 669285,
    "5": 1798620,
    "6": 4742587,
    "7": 11920292,
    "8": 26894142,
    "9": 50000000,
    "10": 73105857,
    "11": 88079707,
    "12": 95257412,
    "13": 98201379,
    "14": 99330714,
    "15": 99752737,
    "16": 101000000,
    "17": 102828427,
    "18": 105196152,
    "19": 108000000,
    "20": 111180339,
    "21": 114696938,
    "22": 118520259,
    "23": 122627416,
    "24": 127000000,
    "25": 131622776,
    "26": 136482872,
    "27": 141569219,
    "28": 146872166,
    "29": 152383203,
    "30": 158094750,
    "31": 164000000,
    "32": 170092795,
    "33": 176367532,
    "34": 182819079,
    "35": 189442719,
    "36": 196234089,
    "37": 203189146,
    "38": 210304125,
    "39": 217575507,
    "40": 225000000,
}


@pytest.mark.usefixtures("server_db")
def test_gas_counter(server_db):
    assert gas.get_average_transactions(server_db, TRANSACTION_ID, 800000) == 0

    # two transactions by block during 2016 blocks
    for i in range(2016):
        gas.increment_counter(server_db, TRANSACTION_ID, 800000 + i)
        gas.increment_counter(server_db, TRANSACTION_ID, 800000 + i)

    assert gas.get_transaction_count_for_last_period(server_db, TRANSACTION_ID, 802016) == 2016 * 2

    assert gas.get_average_transactions(server_db, TRANSACTION_ID, 802016) == 2

    # 2.5 transactions by block during 2016 blocks
    for i in range(1008):
        gas.increment_counter(server_db, TRANSACTION_ID, 800000 + i)

    assert gas.get_average_transactions(server_db, TRANSACTION_ID, 802016) == 2

    # 3 transactions by block during 2016 blocks
    for i in range(1008):
        gas.increment_counter(server_db, TRANSACTION_ID, 800000 + i)

    assert gas.get_average_transactions(server_db, TRANSACTION_ID, 802016) == 3


@pytest.mark.usefixtures("server_db")
def test_gas_counter_2(server_db):
    assert gas.get_average_transactions(server_db, 101, 800000) == 0

    # two transactions by block during 3000 blocks
    for i in range(3000):
        gas.increment_counter(server_db, TRANSACTION_ID, 800000 + i)
        gas.increment_counter(server_db, TRANSACTION_ID, 800000 + i)

    for i in range(802016, 803001):
        assert gas.get_transaction_count_for_last_period(server_db, TRANSACTION_ID, i) == 2016 * 2
        assert gas.get_average_transactions(server_db, TRANSACTION_ID, i) == 2

    # then 4 transactions by block during 1032 blocks
    for i in range(1008):
        gas.increment_counter(server_db, TRANSACTION_ID, 803000 + i)
        gas.increment_counter(server_db, TRANSACTION_ID, 803000 + i)
        gas.increment_counter(server_db, TRANSACTION_ID, 803000 + i)
        gas.increment_counter(server_db, TRANSACTION_ID, 803000 + i)

    assert (
        gas.get_transaction_count_for_last_period(server_db, TRANSACTION_ID, 804008)
        == 1008 * 2 + 1008 * 4
    )
    assert gas.get_average_transactions(server_db, TRANSACTION_ID, 804008) == 3

    # then no transaction during 1 block
    assert gas.get_average_transactions(server_db, TRANSACTION_ID, 804009) == 2

    # then no transaction during 1008 block
    assert gas.get_average_transactions(server_db, TRANSACTION_ID, 804008 + 1008) == 2
    assert gas.get_average_transactions(server_db, TRANSACTION_ID, 804008 + 1009) == 1
    # 4 tx by block during 504 blocks, then 0 tx during 1512 blocks (1512 + 504 = 2016)
    assert gas.get_average_transactions(server_db, TRANSACTION_ID, 804008 + 1512) == 1
    assert gas.get_average_transactions(server_db, TRANSACTION_ID, 804008 + 1513) == 0


def generate_gas_counter(server_db, block_index, average):
    for i in range(2016):
        for _ in range(average):
            gas.increment_counter(server_db, TRANSACTION_ID, block_index + i)
    block_index += 2016
    assert gas.get_average_transactions(server_db, TRANSACTION_ID, block_index) == average
    return block_index


@pytest.mark.usefixtures("server_db")
def test_calculate_fee(server_db):
    assert gas.get_average_transactions(server_db, TRANSACTION_ID, 800000) == 0

    block_index = 3000000

    # test five random tx count per period between 2 and 40
    for _ in range(5):
        tx_count_per_period = random.randint(2, 40)  # noqa: S311
        block_index = generate_gas_counter(server_db, block_index, tx_count_per_period)
        fee = gas.get_transaction_fee(server_db, TRANSACTION_ID, block_index)
        print(f'"{tx_count_per_period}": {fee},')
        assert fee == FEE_BY_TX_COUNT_PER_PERIOD[str(tx_count_per_period)]
