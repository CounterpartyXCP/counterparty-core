# Type 120: add liquidity to an AMM pool. First deposit creates the pool and
# LP token; subsequent deposits mint LP tokens proportional to contribution.
import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import gas
from counterpartycore.lib.messages import pool as pool_mod
from counterpartycore.lib.parser import messagetype
from counterpartycore.lib.utils import assetnames

logger = logging.getLogger(config.LOGGER_NAME)

ID = 120
FORMAT = ">QQQQ"  # asset_a_id, asset_b_id, quantity_a, quantity_b
LENGTH = 8 + 8 + 8 + 8  # 32 bytes


def validate(db, source, asset_a, asset_b, quantity_a, quantity_b):
    problems = []

    if asset_a == config.BTC or asset_b == config.BTC:
        problems.append("BTC pairs are not supported for AMM pools")

    if asset_a == asset_b:
        problems.append("assets must be different")

    # Validate each asset exists and has correct properties
    for asset in [asset_a, asset_b]:
        if asset not in (config.BTC, config.XCP):
            # Must exist
            last_issuance = ledger.issuances.get_last_issuance(db, asset)
            if last_issuance is None:
                problems.append(f"asset {asset} does not exist")
                continue
            # Cannot be an LP token (check if any pool uses this as lp_asset)
            if ledger.markets.get_pool_by_lp_asset(db, asset):
                problems.append(f"{asset} is an LP token; LP tokens cannot be pooled")

    for param_name, param_value in {"quantity_a": quantity_a, "quantity_b": quantity_b}.items():
        if not isinstance(param_value, int):
            problems.append(f"{param_name} must be an integer")
        elif param_value <= 0:
            problems.append(f"{param_name} must be positive")
        elif param_value > config.MAX_INT:
            problems.append(f"{param_name} exceeds maximum value")

    if problems:
        return problems

    # Check balances and gas fee
    fee = gas.get_transaction_fee(db, ID, CurrentState().current_block_index())
    balance_a = ledger.balances.get_balance(db, source, asset_a)
    if balance_a < quantity_a:
        problems.append(f"insufficient balance of {asset_a}")
    balance_b = ledger.balances.get_balance(db, source, asset_b)
    if balance_b < quantity_b:
        problems.append(f"insufficient balance of {asset_b}")
    # fee is always paid in XCP
    if fee > 0:
        xcp_needed = fee
        if asset_a == config.XCP:
            xcp_needed += quantity_a
        if asset_b == config.XCP:
            xcp_needed += quantity_b
        xcp_balance = ledger.balances.get_balance(db, source, config.XCP)
        if xcp_balance < xcp_needed:
            problems.append("insufficient XCP for fee")

    return problems


def compose(
    db,
    source: str,
    asset_a: str,
    asset_b: str,
    quantity_a: int,
    quantity_b: int,
    skip_validation: bool = False,
):
    # resolve subassets
    asset_a = ledger.issuances.resolve_subasset_longname(db, asset_a)
    asset_b = ledger.issuances.resolve_subasset_longname(db, asset_b)

    problems = validate(db, source, asset_a, asset_b, quantity_a, quantity_b)
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    asset_a_id = ledger.issuances.get_asset_id(db, asset_a)
    asset_b_id = ledger.issuances.get_asset_id(db, asset_b)
    data = messagetype.pack(ID)
    data += struct.pack(FORMAT, asset_a_id, asset_b_id, quantity_a, quantity_b)

    return (source, [], data)


def unpack(db, message, return_dict=False):
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        asset_a_id, asset_b_id, quantity_a, quantity_b = struct.unpack(FORMAT, message)
        asset_a = ledger.issuances.get_asset_name(db, asset_a_id)
        asset_b = ledger.issuances.get_asset_name(db, asset_b_id)

        if return_dict:
            return {
                "asset_a": asset_a,
                "asset_b": asset_b,
                "quantity_a": quantity_a,
                "quantity_b": quantity_b,
            }
        return asset_a, asset_b, quantity_a, quantity_b
    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error):
        if return_dict:
            return {"asset_a": "", "asset_b": "", "quantity_a": 0, "quantity_b": 0}
        return "", "", 0, 0


def parse(db, tx, message):
    asset_a, asset_b, quantity_a, quantity_b = unpack(db, message)

    status = "valid"
    if not asset_a or not asset_b or quantity_a <= 0 or quantity_b <= 0:
        status = "invalid: could not unpack"
    else:
        problems = validate(db, tx["source"], asset_a, asset_b, quantity_a, quantity_b)
        if problems:
            status = "invalid: " + "; ".join(problems)

    # if invalid, record and return early
    if status != "valid":
        sorted_a, sorted_b = (
            ledger.markets.sort_pair(asset_a, asset_b)
            if asset_a and asset_b
            else (asset_a, asset_b)
        )
        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "block_index": tx["block_index"],
            "source": tx["source"],
            "asset_a": sorted_a,
            "asset_b": sorted_b,
            "quantity_a": quantity_a if asset_a == sorted_a else quantity_b,
            "quantity_b": quantity_b if asset_a == sorted_a else quantity_a,
            "quantity_minted": 0,
            "status": status,
        }
        ledger.events.insert_record(db, "pool_deposits", bindings, "NEW_POOL_DEPOSIT")
        logger.info("Pool deposit %(tx_hash)s is invalid: %(status)s", bindings)
        ledger.blocks.set_transaction_status(db, tx["tx_index"], False)
        return

    # pay gas fee and increment counter
    fee = gas.get_transaction_fee(db, ID, tx["block_index"])
    if fee > 0:
        ledger.events.debit(
            db,
            tx["source"],
            config.XCP,
            fee,
            tx["tx_index"],
            action="pool deposit fee",
            event=tx["tx_hash"],
        )
    gas.increment_counter(db, ID, tx["block_index"])

    # execute deposit
    sorted_a, sorted_b = ledger.markets.sort_pair(asset_a, asset_b)
    if asset_a == sorted_a:
        qty_a, qty_b = quantity_a, quantity_b
    else:
        qty_a, qty_b = quantity_b, quantity_a

    existing_pool = ledger.markets.get_pool(db, sorted_a, sorted_b)

    if existing_pool is None:
        quantity_minted = first_deposit(db, tx, sorted_a, sorted_b, qty_a, qty_b)
    elif existing_pool["reserve_a"] == 0:
        quantity_minted = refund_empty_pool(db, tx, existing_pool, sorted_a, sorted_b, qty_a, qty_b)
    else:
        quantity_minted = subsequent_deposit(
            db, tx, existing_pool, sorted_a, sorted_b, qty_a, qty_b
        )

    # match resting orders against the new/updated pool
    pool_mod.match_resting_orders_against_pool(db, tx, sorted_a, sorted_b)

    # record valid deposit
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "asset_a": sorted_a,
        "asset_b": sorted_b,
        "quantity_a": qty_a,
        "quantity_b": qty_b,
        "quantity_minted": quantity_minted,
        "status": "valid",
    }
    ledger.events.insert_record(db, "pool_deposits", bindings, "NEW_POOL_DEPOSIT")
    logger.info(
        "Pool deposit: %(quantity_a)s %(asset_a)s + %(quantity_b)s %(asset_b)s "
        "-> %(quantity_minted)s LP tokens [%(tx_hash)s]",
        bindings,
    )
    ledger.blocks.set_transaction_status(db, tx["tx_index"], True)


def make_lp_issuance_bindings(db, tx, lp_asset, quantity, asset_a, asset_b, asset_events):
    """Build the issuance record for LP token minting."""
    return {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "msg_index": ledger.other.get_issuance_msg_index(db, tx["tx_hash"]),
        "block_index": tx["block_index"],
        "asset": lp_asset,
        "quantity": quantity,
        "divisible": True,
        "source": config.UNSPENDABLE,
        "issuer": config.UNSPENDABLE,
        "transfer": False,
        "callable": False,
        "call_date": 0,
        "call_price": 0,
        "description": f"LP token for {asset_a}/{asset_b} pool",
        "fee_paid": 0,
        "locked": False,
        "description_locked": True,
        "reset": False,
        "status": "valid",
        "asset_longname": None,
        "fair_minting": False,
        "asset_events": asset_events,
        "mime_type": "text/plain",
    }


def first_deposit(db, tx, asset_a, asset_b, qty_a, qty_b):
    """Create pool and LP token, mint all LP tokens to depositor."""
    source = tx["source"]

    # Debit both assets from source (escrow into pool)
    ledger.events.debit(
        db, source, asset_a, qty_a, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )
    ledger.events.debit(
        db, source, asset_b, qty_b, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )

    # Generate LP token name (deterministic in regtest, random in production)
    lp_asset_name = assetnames.generate_random_asset(f"{asset_a}:{asset_b}")
    lp_asset_id = ledger.issuances.generate_asset_id(lp_asset_name)

    # Compute initial LP supply
    total_lp = ledger.markets.isqrt(qty_a * qty_b)

    # Register LP token as asset
    ledger.events.insert_record(
        db,
        "assets",
        {
            "asset_id": str(lp_asset_id),
            "asset_name": lp_asset_name,
            "block_index": tx["block_index"],
            "asset_longname": None,
        },
        "ASSET_CREATION",
    )

    # Record issuance
    issuance_bindings = make_lp_issuance_bindings(
        db, tx, lp_asset_name, total_lp, asset_a, asset_b, "creation"
    )
    ledger.events.insert_record(db, "issuances", issuance_bindings, "ASSET_ISSUANCE")

    # Credit LP tokens to depositor
    ledger.events.credit(
        db,
        source,
        lp_asset_name,
        total_lp,
        tx["tx_index"],
        action="pool deposit",
        event=tx["tx_hash"],
    )

    # Create pool record
    ledger.markets.insert_pool(
        db,
        {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "block_index": tx["block_index"],
            "source": source,
            "asset_a": asset_a,
            "asset_b": asset_b,
            "reserve_a": qty_a,
            "reserve_b": qty_b,
            "lp_asset": lp_asset_name,
        },
    )

    return total_lp


def refund_empty_pool(db, tx, pool, asset_a, asset_b, qty_a, qty_b):
    """Re-fund a fully drained pool, reusing the existing LP token.

    Same logic as first_deposit but does NOT create a new LP token or
    asset record — uses the pool's existing lp_asset.  Prevents orphaned
    LP tokens from accumulating if a pool is repeatedly drained and re-funded.
    """
    source = tx["source"]
    lp_asset = pool["lp_asset"]

    # Debit both assets
    ledger.events.debit(
        db, source, asset_a, qty_a, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )
    ledger.events.debit(
        db, source, asset_b, qty_b, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )

    # Compute LP supply (same as first deposit)
    total_lp = ledger.markets.isqrt(qty_a * qty_b)

    # Record issuance for the new minted tokens
    issuance_bindings = make_lp_issuance_bindings(
        db, tx, lp_asset, total_lp, asset_a, asset_b, "pool_refund"
    )
    ledger.events.insert_record(db, "issuances", issuance_bindings, "ASSET_ISSUANCE")

    # Credit LP tokens to depositor
    ledger.events.credit(
        db, source, lp_asset, total_lp, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )

    # Update pool reserves
    ledger.markets.update_pool(db, asset_a, asset_b, qty_a, qty_b)

    return total_lp


def subsequent_deposit(db, tx, pool, asset_a, asset_b, qty_a, qty_b):
    """Add liquidity to existing pool. Mint proportional LP tokens."""
    source = tx["source"]

    # Get current LP supply
    lp_asset = pool["lp_asset"]
    total_lp_supply = ledger.supplies.asset_supply(db, lp_asset)

    # Pre-check: ensure deposit would mint at least 1 LP token
    lp_from_a = qty_a * total_lp_supply // pool["reserve_a"]
    lp_from_b = qty_b * total_lp_supply // pool["reserve_b"]
    quantity_minted = min(lp_from_a, lp_from_b)
    if quantity_minted <= 0:
        raise exceptions.MessageError("deposit too small to mint LP tokens")

    # Debit both assets
    ledger.events.debit(
        db, source, asset_a, qty_a, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )
    ledger.events.debit(
        db, source, asset_b, qty_b, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )

    # Record issuance
    issuance_bindings = make_lp_issuance_bindings(
        db, tx, lp_asset, quantity_minted, asset_a, asset_b, "pool_deposit_mint"
    )
    ledger.events.insert_record(db, "issuances", issuance_bindings, "ASSET_ISSUANCE")

    # Credit LP tokens to depositor
    ledger.events.credit(
        db,
        source,
        lp_asset,
        quantity_minted,
        tx["tx_index"],
        action="pool deposit",
        event=tx["tx_hash"],
    )

    # Update pool reserves
    new_reserve_a = pool["reserve_a"] + qty_a
    new_reserve_b = pool["reserve_b"] + qty_b
    ledger.markets.update_pool(db, asset_a, asset_b, new_reserve_a, new_reserve_b)

    return quantity_minted
