import functools
import logging
import math
from decimal import Decimal as D

from counterpartycore.lib import config, ledger
from counterpartycore.lib.parser import protocol

logger = logging.getLogger(config.LOGGER_NAME)

PERIOD_DURATION = 2016  # blocks, around 2 weeks


def pay_fee(db, tx, fee_payer, fee, action, destroy=True):
    """Debit an XCP usage fee and, unless `destroy` is False, record its destruction."""
    ledger.events.debit(
        db,
        fee_payer,
        config.XCP,
        fee,
        tx["tx_index"],
        action=action,
        event=tx["tx_hash"],
    )
    if not destroy:
        return
    destroy_bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        # tx["source"], not fee_payer: the bindings attach and utxo have always used.
        "source": tx["source"],
        "asset": config.XCP,
        "quantity": fee,
        "tag": action,
        "status": "valid",
    }
    ledger.events.insert_record(db, "destructions", destroy_bindings, "ASSET_DESTRUCTION")


def get_transaction_count_by_block(db, transaction_id, block_index):
    cursor = db.cursor()
    sql = """
    SELECT count FROM transaction_count
    WHERE transaction_id = ? AND block_index == ?
    ORDER BY rowid DESC
    LIMIT 1
    """  # noqa S608
    binding = (transaction_id, block_index)
    count = cursor.execute(sql, binding).fetchone()
    if count is None:
        return 0
    return count["count"]


def increment_counter(db, transaction_id, block_index, count=1):
    current_count = get_transaction_count_by_block(db, transaction_id, block_index)
    new_count = current_count + count

    bindings = {
        "block_index": block_index,
        "transaction_id": transaction_id,
        "count": new_count,
    }
    ledger.events.insert_record(db, "transaction_count", bindings, "INCREMENT_TRANSACTION_COUNT")


def get_transaction_count_for_last_period(db, transaction_id, block_index):
    if block_index < PERIOD_DURATION:
        return 0

    cursor = db.cursor()
    sql = """
        SELECT SUM(count) as total_count FROM (
            SELECT MAX(rowid) as rowid, block_index, count
            FROM transaction_count
            WHERE transaction_id = ?
            AND block_index >= ? AND block_index < ?
            GROUP BY block_index
        )
    """
    bindings = (transaction_id, block_index - PERIOD_DURATION, block_index)
    transaction_count = cursor.execute(sql, bindings).fetchone()
    if transaction_count is None:
        return 0
    return transaction_count["total_count"] or 0


def get_average_transactions(db, transaction_id, block_index):
    transaction_count = get_transaction_count_for_last_period(db, transaction_id, block_index)
    if transaction_count == 0:
        return 0
    # return average number of transactions for the last PERIOD_DURATION blocks
    return transaction_count // PERIOD_DURATION


def get_transaction_fee(db, transaction_id, block_index):
    x = get_average_transactions(db, transaction_id, block_index)
    fee_params = protocol.get_value_by_block_index("fee_parameters", block_index)

    if fee_params is None:
        return 0

    a = int(fee_params[str(transaction_id)]["fee_lower_threshold"])
    b = int(fee_params[str(transaction_id)]["fee_upper_threshold"])
    base_fee = int(fee_params[str(transaction_id)]["base_fee"])
    k = int(fee_params[str(transaction_id)]["fee_sigmoid_k"])

    fee = calculate_fee(x, a, b, base_fee, k)
    return int(fee * config.UNIT)


@functools.lru_cache(maxsize=4096)
def get_unit_fee(x, a, b, base_fee, k, min_fee=0, max_fee=None):
    """`get_transaction_fee` for an average of `x` transactions per block.
    With `max_fee`, the curve is bounded: rescaled to rise from `min_fee`
    (below `a`) to `max_fee` (at `base_fee`, around `b`) and capped there,
    both in satoshis."""
    fee = calculate_fee(x, a, b, base_fee, k)
    if max_fee is None:
        return int(fee * config.UNIT)
    share = min(D(fee) / D(base_fee), D(1))
    return min_fee + int((max_fee - min_fee) * share)


def get_transaction_fee_for_count(
    db, transaction_id, block_index, count, limit=config.MAX_INT, ahead=0
):
    """The fee of `count` more units of `transaction_id` in `block_index`. Each
    unit is priced like `get_transaction_fee`, at the average it brings the
    period to once the units before it are counted: those of the last period,
    those already counted in this block and the previous units of `count`. A
    bulk purchase therefore pays for the usage it creates, whether it is made
    in one transaction or split across several of the same block. The
    optional `min_unit_fee` and `max_unit_fee` fee parameters bound the price
    of a unit (see `get_unit_fee`). With `ahead`, that many more units are
    counted before `count`: the fee once the usage has grown by `ahead`, to
    bound the fee of a transaction that others may precede. Returns None when
    the fee exceeds `limit`."""
    fee_params = protocol.get_value_by_block_index("fee_parameters", block_index)
    if fee_params is None or count <= 0:
        return 0

    params = fee_params[str(transaction_id)]
    a = int(params["fee_lower_threshold"])
    b = int(params["fee_upper_threshold"])
    base_fee = int(params["base_fee"])
    k = int(params["fee_sigmoid_k"])
    min_fee = int(params.get("min_unit_fee", 0))
    max_fee = int(params["max_unit_fee"]) if "max_unit_fee" in params else None

    position = get_transaction_count_for_last_period(db, transaction_id, block_index)
    position += get_transaction_count_by_block(db, transaction_id, block_index)
    position += ahead
    end = position + count
    fee = 0
    # The average changes every PERIOD_DURATION units: price them by slice.
    # The unit fee only grows, so the units left cost at least the current one
    # each: the loop stops as soon as that lower bound exceeds `limit`, however
    # many units there are. Past `max_fee`, every unit left pays it: one step.
    while position < end:
        unit_fee = get_unit_fee(position // PERIOD_DURATION, a, b, base_fee, k, min_fee, max_fee)
        if fee + (end - position) * unit_fee > limit:
            return None
        slice_end = min(end, (position // PERIOD_DURATION + 1) * PERIOD_DURATION)
        if max_fee is not None and unit_fee >= max_fee:
            slice_end = end
        fee += (slice_end - position) * unit_fee
        position = slice_end
    return fee


def calculate_fee(x: int, a: int, b: int, base_fee: int, k: int):
    """
    Calculate the fee based on the number of transactions per block,
    ensuring continuity at the transition point.

    Parameters:
    x (int): Number of transactions per period
    a (int): Lower threshold (fee is zero below this)
    b (int): Upper threshold (transition point to exponential growth)
    base_fee (int): Base fee amount
    k (int): Sigmoid steepness factor

    Returns:
    float: Calculated fee
    """
    if x < 0 or a < 0 or b < 0 or base_fee < 0 or k < 0:
        raise ValueError("All inputs must be non-negative")
    if b <= a:
        raise ValueError("Upper threshold must be greater than lower threshold")

    x, a, b, base_fee, k = map(D, (x, a, b, base_fee, k))

    m = D(1.5)  # Exponent
    n = D(100)  # Exponential Scaling Factor

    def sigmoid(t):
        midpoint = (b - a) / 2 + a
        # math.exp is libm-backed and last-ulp drift varies across platforms.
        # int(fee * UNIT) at base_fee=1 absorbs the ~5.55e-9 sat drift via
        # the floor. If base_fee ever exceeds ~1.8e8, switch to (x).exp()
        # under a fixed-prec localcontext to keep consensus deterministic.
        return base_fee / (1 + D(math.exp(-k * (t - midpoint))))

    if x <= a:
        return 0
    if x <= b:
        return sigmoid(x)
    return base_fee + (((x - b) ** m) / n)
