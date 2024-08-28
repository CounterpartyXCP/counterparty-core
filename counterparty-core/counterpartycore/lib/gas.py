import math

from counterpartycore.lib import config, ledger, util


def increment_counter(db, transaction_id, block_index):
    cursor = db.cursor()
    difficulty_period = block_index // 2016
    current_count = cursor.execute(
        """
        SELECT count FROM transaction_count
        WHERE transaction_id = ? AND difficulty_period = ?
    """,
        (transaction_id, difficulty_period),
    ).fetchone()
    if current_count is None:
        new_count = 1
    else:
        new_count = current_count["count"] + 1

    bindings = {
        "block_index": block_index,
        "difficulty_period": difficulty_period,
        "transaction_id": transaction_id,
        "count": new_count,
    }
    ledger.insert_record(db, "transaction_count", bindings, "INCREMENT_TRANSACTION_COUNT")


def get_average_transaction_count(db, transaction_id, block_index):
    cursor = db.cursor()
    previous_difficulty_period = (block_index // 2016) - 1
    if previous_difficulty_period < 0:
        return 0
    transaction_count = cursor.execute(
        """
        SELECT count FROM transaction_count
        WHERE transaction_id = ? AND difficulty_period = ?
    """,
        (transaction_id, previous_difficulty_period),
    ).fetchone()
    # return average number of transactions per block
    return transaction_count // 2016


def get_transaction_fee(db, transaction_type, block_index):
    x = get_average_transaction_count(db, transaction_type)
    a = util.get_value_by_block_index("fee_lower_threshold", block_index)
    b = util.get_value_by_block_index("fee_upper_threshold", block_index)
    base_fee = util.get_value_by_block_index("base_fee", block_index)
    k = util.get_value_by_block_index("fee_sigmoid_k", block_index)
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
