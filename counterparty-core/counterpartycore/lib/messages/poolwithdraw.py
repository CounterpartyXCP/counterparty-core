# Type 121: remove liquidity from an AMM pool. Destroys LP tokens and returns
# proportional share of both reserve assets to the source address.
import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import gas, pool as pool_mod
from counterpartycore.lib.parser import messagetype

logger = logging.getLogger(config.LOGGER_NAME)

ID = 121
FORMAT = ">QQQ"  # asset_a_id, asset_b_id, quantity
LENGTH = 8 + 8 + 8  # 24 bytes

def validate(db, source, asset_a, asset_b, quantity):
    problems = []

    if asset_a == config.BTC or asset_b == config.BTC:
        problems.append("BTC pairs are not supported for AMM pools")

    if asset_a == asset_b:
        problems.append("assets must be different")

    # Verify assets exist
    for asset in [asset_a, asset_b]:
        if asset not in (config.BTC, config.XCP):
            if ledger.issuances.get_last_issuance(db, asset) is None:
                problems.append(f"asset {asset} does not exist")

    if not isinstance(quantity, int):
        problems.append("quantity must be an integer")
    elif quantity <= 0:
        problems.append("quantity must be positive")
    elif quantity > config.MAX_INT:
        problems.append("quantity exceeds maximum value")

    if problems:
        return problems

    sorted_a, sorted_b = pool_mod.sort_pair(asset_a, asset_b)
    pool = pool_mod.get_pool(db, sorted_a, sorted_b)

    if pool is None:
        problems.append("pool does not exist")
    elif pool["reserve_a"] == 0 or pool["reserve_b"] == 0:
        problems.append("pool has no liquidity")
    else:
        lp_asset = pool["lp_asset"]
        lp_balance = ledger.balances.get_balance(db, source, lp_asset)
        if lp_balance < quantity:
            problems.append(f"insufficient LP token balance ({lp_balance} < {quantity})")

    # gas fee is paid in XCP
    if not problems:
        fee = gas.get_transaction_fee(db, ID, CurrentState().current_block_index())
        if fee > 0:
            xcp_balance = ledger.balances.get_balance(db, source, config.XCP)
            if xcp_balance < fee:
                problems.append("insufficient XCP for fee")

    return problems

def compose(db, source: str, asset_a: str, asset_b: str, quantity: int, skip_validation: bool = False):
    # resolve subassets
    asset_a = ledger.issuances.resolve_subasset_longname(db, asset_a)
    asset_b = ledger.issuances.resolve_subasset_longname(db, asset_b)

    problems = validate(db, source, asset_a, asset_b, quantity)
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    asset_a_id = ledger.issuances.get_asset_id(db, asset_a)
    asset_b_id = ledger.issuances.get_asset_id(db, asset_b)
    data = messagetype.pack(ID)
    data += struct.pack(FORMAT, asset_a_id, asset_b_id, quantity)

    return (source, [], data)

def unpack(db, message, return_dict=False):
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        asset_a_id, asset_b_id, quantity = struct.unpack(FORMAT, message)
        asset_a = ledger.issuances.get_asset_name(db, asset_a_id)
        asset_b = ledger.issuances.get_asset_name(db, asset_b_id)

        if return_dict:
            return {"asset_a": asset_a, "asset_b": asset_b, "quantity": quantity}
        return asset_a, asset_b, quantity
    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error):
        if return_dict:
            return {"asset_a": "", "asset_b": "", "quantity": 0}
        return "", "", 0

def parse(db, tx, message):
    asset_a, asset_b, quantity = unpack(db, message)

    status = "valid"
    if not asset_a or not asset_b or quantity <= 0:
        status = "invalid: could not unpack"
    else:
        problems = validate(db, tx["source"], asset_a, asset_b, quantity)
        if problems:
            status = "invalid: " + "; ".join(problems)

    # if invalid, record and return early
    if status != "valid":
        sorted_a, sorted_b = pool_mod.sort_pair(asset_a, asset_b) if asset_a and asset_b else (asset_a, asset_b)
        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "block_index": tx["block_index"],
            "source": tx["source"],
            "asset_a": sorted_a,
            "asset_b": sorted_b,
            "quantity_destroyed": quantity,
            "quantity_a": 0,
            "quantity_b": 0,
            "status": status,
        }
        ledger.events.insert_record(db, "pool_withdrawals", bindings, "NEW_POOL_WITHDRAWAL")
        logger.info("Pool withdrawal %(tx_hash)s is invalid: %(status)s", bindings)
        ledger.blocks.set_transaction_status(db, tx["tx_index"], False)
        return

    # pay gas fee and increment counter
    fee = gas.get_transaction_fee(db, ID, tx["block_index"])
    if fee > 0:
        ledger.events.debit(
            db, tx["source"], config.XCP, fee, tx["tx_index"],
            action="pool withdraw fee", event=tx["tx_hash"],
        )
    gas.increment_counter(db, ID, tx["block_index"])

    # execute withdrawal
    sorted_a, sorted_b = pool_mod.sort_pair(asset_a, asset_b)
    pool = pool_mod.get_pool(db, sorted_a, sorted_b)
    if pool is None or pool["reserve_a"] == 0 or pool["reserve_b"] == 0:
        raise exceptions.MessageError("pool state changed during execution")
    lp_asset = pool["lp_asset"]

    # Get total LP supply
    total_lp_supply = ledger.supplies.asset_supply(db, lp_asset)
    if total_lp_supply <= 0:
        raise exceptions.MessageError("LP supply is zero")

    # Compute proportional shares
    quantity_a = quantity * pool["reserve_a"] // total_lp_supply
    quantity_b = quantity * pool["reserve_b"] // total_lp_supply

    # Destroy LP tokens: debit from source
    ledger.events.debit(db, tx["source"], lp_asset, quantity,
                        tx["tx_index"], action="pool withdraw",
                        event=tx["tx_hash"])

    # Record destruction (keeps asset_supply() accurate)
    ledger.events.insert_record(db, "destructions", {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "asset": lp_asset,
        "quantity": quantity,
        "tag": "pool_withdraw",
        "status": "valid",
    }, "ASSET_DESTRUCTION")

    # Credit both assets back to source
    if quantity_a > 0:
        ledger.events.credit(db, tx["source"], sorted_a, quantity_a,
                             tx["tx_index"], action="pool withdraw",
                             event=tx["tx_hash"])
    if quantity_b > 0:
        ledger.events.credit(db, tx["source"], sorted_b, quantity_b,
                             tx["tx_index"], action="pool withdraw",
                             event=tx["tx_hash"])

    # Update pool reserves
    new_reserve_a = pool["reserve_a"] - quantity_a
    new_reserve_b = pool["reserve_b"] - quantity_b
    pool_mod.update_pool(db, sorted_a, sorted_b, new_reserve_a, new_reserve_b)

    # record valid withdrawal
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "asset_a": sorted_a,
        "asset_b": sorted_b,
        "quantity_destroyed": quantity,
        "quantity_a": quantity_a,
        "quantity_b": quantity_b,
        "status": "valid",
    }
    ledger.events.insert_record(db, "pool_withdrawals", bindings, "NEW_POOL_WITHDRAWAL")
    logger.info(
        "Pool withdrawal: %(quantity_destroyed)s LP tokens -> "
        "%(quantity_a)s %(asset_a)s + %(quantity_b)s %(asset_b)s [%(tx_hash)s]",
        bindings,
    )
    ledger.blocks.set_transaction_status(db, tx["tx_index"], True)
