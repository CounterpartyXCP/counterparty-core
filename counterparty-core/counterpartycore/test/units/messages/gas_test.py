import random

import pytest
from counterpartycore.lib.messages import gas


def test_get_transaction_count_for_last_period(ledger_db):
    # attach.ID, 310507
    assert gas.get_transaction_count_for_last_period(ledger_db, 101, 310507) == 0


def test_increment_counter(ledger_db, test_helpers):
    gas.increment_counter(ledger_db, 101, 310507)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "transaction_count",
                "values": {
                    "block_index": 310507,
                    "transaction_id": 101,
                    "count": 1,
                },
            }
        ],
    )


def test_get_average_transactions(ledger_db):
    # attach.ID, 310507
    assert gas.get_average_transactions(ledger_db, 101, 310507) == 0


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


def test_gas_counter(ledger_db):
    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, 800000) == 0

    # two transactions by block during 2016 blocks
    for i in range(2016):
        gas.increment_counter(ledger_db, TRANSACTION_ID, 800000 + i)
        gas.increment_counter(ledger_db, TRANSACTION_ID, 800000 + i)

    assert gas.get_transaction_count_for_last_period(ledger_db, TRANSACTION_ID, 802016) == 2016 * 2

    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, 802016) == 2

    # 2.5 transactions by block during 2016 blocks
    for i in range(1008):
        gas.increment_counter(ledger_db, TRANSACTION_ID, 800000 + i)

    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, 802016) == 2

    # 3 transactions by block during 2016 blocks
    for i in range(1008):
        gas.increment_counter(ledger_db, TRANSACTION_ID, 800000 + i)

    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, 802016) == 3


def test_gas_counter_2(ledger_db):
    assert gas.get_average_transactions(ledger_db, 101, 800000) == 0

    # two transactions by block during 3000 blocks
    for i in range(3000):
        gas.increment_counter(ledger_db, TRANSACTION_ID, 800000 + i)
        gas.increment_counter(ledger_db, TRANSACTION_ID, 800000 + i)

    for i in range(802016, 803001):
        assert gas.get_transaction_count_for_last_period(ledger_db, TRANSACTION_ID, i) == 2016 * 2
        assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, i) == 2

    # then 4 transactions by block during 1032 blocks
    for i in range(1008):
        gas.increment_counter(ledger_db, TRANSACTION_ID, 803000 + i)
        gas.increment_counter(ledger_db, TRANSACTION_ID, 803000 + i)
        gas.increment_counter(ledger_db, TRANSACTION_ID, 803000 + i)
        gas.increment_counter(ledger_db, TRANSACTION_ID, 803000 + i)

    assert (
        gas.get_transaction_count_for_last_period(ledger_db, TRANSACTION_ID, 804008)
        == 1008 * 2 + 1008 * 4
    )
    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, 804008) == 3

    # then no transaction during 1 block
    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, 804009) == 2

    # then no transaction during 1008 block
    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, 804008 + 1008) == 2
    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, 804008 + 1009) == 1
    # 4 tx by block during 504 blocks, then 0 tx during 1512 blocks (1512 + 504 = 2016)
    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, 804008 + 1512) == 1
    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, 804008 + 1513) == 0


def generate_gas_counter(ledger_db, block_index, average):
    for i in range(2016):
        for _ in range(average):
            gas.increment_counter(ledger_db, TRANSACTION_ID, block_index + i)
    block_index += 2016
    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, block_index) == average
    return block_index


def test_calculate_fee(ledger_db):
    assert gas.get_average_transactions(ledger_db, TRANSACTION_ID, 800000) == 0

    block_index = 3000000

    # test five random tx count per period between 2 and 40
    for _ in range(5):
        # for tx_count_per_period in range(2, 41):
        tx_count_per_period = random.randint(2, 40)  # noqa: S311
        block_index = generate_gas_counter(ledger_db, block_index, tx_count_per_period)
        fee = gas.get_transaction_fee(ledger_db, TRANSACTION_ID, block_index)
        print(f'"{tx_count_per_period}": {fee},')
        assert fee == FEE_BY_TX_COUNT_PER_PERIOD[str(tx_count_per_period)]


def test_calculate_fee_validation_errors():
    """Test calculate_fee raises errors for invalid inputs."""
    # Test negative x
    with pytest.raises(ValueError, match="All inputs must be non-negative"):
        gas.calculate_fee(x=-1, a=3, b=15, base_fee=100, k=1)

    # Test negative a
    with pytest.raises(ValueError, match="All inputs must be non-negative"):
        gas.calculate_fee(x=10, a=-3, b=15, base_fee=100, k=1)

    # Test negative b
    with pytest.raises(ValueError, match="All inputs must be non-negative"):
        gas.calculate_fee(x=10, a=3, b=-15, base_fee=100, k=1)

    # Test negative base_fee
    with pytest.raises(ValueError, match="All inputs must be non-negative"):
        gas.calculate_fee(x=10, a=3, b=15, base_fee=-100, k=1)

    # Test negative k
    with pytest.raises(ValueError, match="All inputs must be non-negative"):
        gas.calculate_fee(x=10, a=3, b=15, base_fee=100, k=-1)

    # Test b <= a (upper threshold must be greater than lower threshold)
    with pytest.raises(ValueError, match="Upper threshold must be greater than lower threshold"):
        gas.calculate_fee(x=10, a=15, b=10, base_fee=100, k=1)

    # Test b == a
    with pytest.raises(ValueError, match="Upper threshold must be greater than lower threshold"):
        gas.calculate_fee(x=10, a=10, b=10, base_fee=100, k=1)


def test_get_transaction_fee_no_fee_params(ledger_db, monkeypatch):
    """Test get_transaction_fee returns 0 when fee_params is None."""
    # Monkeypatch protocol.get_value_by_block_index to return None
    monkeypatch.setattr(
        "counterpartycore.lib.messages.gas.protocol.get_value_by_block_index",
        lambda *args: None,
    )

    # Should return 0 when fee_params is None
    assert gas.get_transaction_fee(ledger_db, TRANSACTION_ID, 1000000) == 0


def test_get_transaction_fee_for_count(ledger_db, monkeypatch):
    block_index = 4000000
    # nothing counted: the first units are free (average <= fee_lower_threshold)
    assert gas.get_transaction_fee_for_count(ledger_db, TRANSACTION_ID, block_index, 0) == 0
    assert gas.get_transaction_fee_for_count(ledger_db, TRANSACTION_ID, block_index, 2016) == 0
    # each slice of 2016 units is priced at the average it brings the period to
    unit_fee_4 = FEE_BY_TX_COUNT_PER_PERIOD["4"]
    unit_fee_5 = FEE_BY_TX_COUNT_PER_PERIOD["5"]
    assert (
        gas.get_transaction_fee_for_count(ledger_db, TRANSACTION_ID, block_index, 2016 * 5)
        == 2016 * unit_fee_4
    )
    assert (
        gas.get_transaction_fee_for_count(ledger_db, TRANSACTION_ID, block_index, 2016 * 5 + 10)
        == 2016 * unit_fee_4 + 10 * unit_fee_5
    )
    # the units already counted in the block are priced first: splitting a bulk
    # purchase across the transactions of a block changes nothing
    gas.increment_counter(ledger_db, TRANSACTION_ID, block_index, count=2016 * 4)
    assert (
        gas.get_transaction_fee_for_count(ledger_db, TRANSACTION_ID, block_index, 2016)
        == 2016 * unit_fee_4
    )
    # and so are those of the last period: a single unit costs what
    # get_transaction_fee charges
    assert gas.get_transaction_fee_for_count(
        ledger_db, TRANSACTION_ID, block_index + 1, 1
    ) == gas.get_transaction_fee(ledger_db, TRANSACTION_ID, block_index + 1)
    # above `limit`, None
    assert (
        gas.get_transaction_fee_for_count(
            ledger_db, TRANSACTION_ID, block_index, 2016, limit=2016 * unit_fee_4 - 1
        )
        is None
    )
    assert gas.get_transaction_fee_for_count(ledger_db, TRANSACTION_ID, block_index, 2**70) is None
    # `ahead` units counted before `count`: the fee once the usage has grown
    # by that much (the units of the block are already counted)
    assert (
        gas.get_transaction_fee_for_count(ledger_db, TRANSACTION_ID, block_index, 2016, ahead=2016)
        == 2016 * unit_fee_5
    )

    def fee(count, ahead=0):
        return gas.get_transaction_fee_for_count(
            ledger_db, TRANSACTION_ID, block_index, count, ahead=ahead
        )

    assert fee(2016 * 5) == fee(2016 * 4) + fee(2016, ahead=2016 * 4)

    monkeypatch.setattr(
        "counterpartycore.lib.messages.gas.protocol.get_value_by_block_index",
        lambda *args: None,
    )
    assert gas.get_transaction_fee_for_count(ledger_db, TRANSACTION_ID, block_index, 2**70) == 0


def test_get_transaction_fee_for_count_bounded(ledger_db):
    """`min_unit_fee` and `max_unit_fee` (fairboosters, 130) bound the price of
    a unit: the curve is rescaled between them and capped at `max_unit_fee`."""
    min_fee, max_fee = 100000, 1000000

    def unit_fee(x):
        return gas.get_unit_fee(x, 10, 100, 1, 1, min_fee, max_fee)

    assert unit_fee(0) == unit_fee(10) == min_fee
    assert unit_fee(55) == min_fee + (max_fee - min_fee) // 2
    assert all(unit_fee(x) <= unit_fee(x + 1) for x in range(200))
    assert unit_fee(100) < max_fee
    assert unit_fee(101) == unit_fee(10**6) == max_fee

    block_index = 4000000
    assert gas.get_transaction_fee_for_count(ledger_db, 130, block_index, 2016) == 2016 * min_fee
    # past the cap every unit left pays `max_fee`, priced in one step however
    # many units there are
    count = 10**15
    expected = sum(2016 * unit_fee(x) for x in range(101)) + (count - 101 * 2016) * max_fee
    assert (
        gas.get_transaction_fee_for_count(ledger_db, 130, block_index, count, limit=2**80)
        == expected
    )
    assert gas.get_transaction_fee_for_count(ledger_db, 130, block_index, count) is None
