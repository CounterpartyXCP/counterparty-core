import math

from counterpartycore.lib import config, database, ledger, util


def initialise(db):
    cursor = db.cursor()
    # transaction_count
    cursor.execute(
        """CREATE TABLE IF NOT EXISTS transaction_count(
            block_index INTEGER,
            transaction_id INTEGER,
            count INTEGER)
        """
    )
    database.create_indexes(
        cursor,
        "transaction_count",
        [
            ["block_index", "transaction_id"],
        ],
    )


def get_transaction_count_for_last_period(db, transaction_id, block_index):
    cursor = db.cursor()
    count = cursor.execute(
        """
        SELECT count FROM transaction_count
        WHERE transaction_id = ? AND block_index >= ? - 2016
        ORDER BY rowid DESC
        LIMIT 1
    """,
        (transaction_id, block_index),
    ).fetchone()
    if count is None:
        return 0
    return count["count"]


def increment_counter(db, transaction_id, block_index):
    current_count = get_transaction_count_for_last_period(db, transaction_id, block_index)
    new_count = current_count + 1

    bindings = {
        "block_index": block_index,
        "transaction_id": transaction_id,
        "count": new_count,
    }
    ledger.insert_record(db, "transaction_count", bindings, "INCREMENT_TRANSACTION_COUNT")


def get_average_transactions(db, transaction_id, block_index):
    if block_index < 2016:
        return 0
    transaction_count = get_transaction_count_for_last_period(db, transaction_id, block_index)
    # return average number of transactions for the last 2016 blocks
    return transaction_count // 2016


def get_transaction_fee(db, transaction_id, block_index):
    x = get_average_transactions(db, transaction_id, block_index)
    fee_params = util.get_value_by_block_index("fee_parameters", block_index)

    a = fee_params[str(transaction_id)]["fee_lower_threshold"]
    b = fee_params[str(transaction_id)]["fee_upper_threshold"]
    base_fee = fee_params[str(transaction_id)]["base_fee"]
    k = fee_params[str(transaction_id)]["fee_sigmoid_k"]

    fee = calculate_fee(x, a, b, base_fee, k)
    return int(fee * config.UNIT)


def calculate_fee(x, a, b, base_fee, k):
    """
    Calculate the fee based on the number of transactions per block,
    ensuring continuity at the transition point.

    Parameters:
    x (float): Number of transactions per period
    a (float): Lower threshold (fee is zero below this)
    b (float): Upper threshold (transition point to exponential growth)
    base_fee (float): Base fee amount
    k (float): Sigmoid steepness factor

    Returns:
    float: Calculated fee
    """

    def sigmoid(t):
        return 1 / (1 + math.exp(-k * (t - 0.5)))

    if x <= a:
        return 0
    elif x <= b:
        return base_fee * sigmoid((x - a) / (b - a))
    else:
        # Calculate sigmoid value and derivative at x = b
        sigmoid_at_b = sigmoid(1)
        sigmoid_derivative_at_b = k * sigmoid_at_b * (1 - sigmoid_at_b)

        # Calculate parameters for the exponential part
        m = sigmoid_derivative_at_b * (b - a) / base_fee
        c = math.log(m)

        # Exponential function that matches sigmoid at x = b
        return base_fee * sigmoid_at_b * math.exp(c * ((x - b) / (b - a)))
