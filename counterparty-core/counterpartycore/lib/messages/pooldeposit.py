# Type 120: add liquidity to an AMM pool. First deposit creates the pool and
# LP token; subsequent deposits mint LP tokens proportional to contribution.
import logging
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import gas
from counterpartycore.lib.parser import messagetype
from counterpartycore.lib.utils import assetnames

logger = logging.getLogger(config.LOGGER_NAME)

ID = 120
FORMAT = ">QQQQQQ"  # asset_a_id, asset_b_id, quantity_a, quantity_b, min_lp_quantity, lp_asset_id
LENGTH = 48


def validate(
    db,
    source,
    asset_a,
    asset_b,
    quantity_a,
    quantity_b,
    min_lp_quantity=0,
    lp_asset=None,
    block_index=None,
):
    problems = []
    if block_index is None:
        block_index = CurrentState().current_block_index()

    if config.BTC in (asset_a, asset_b):
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

    # Block pool creation during active fairmint-pool
    for asset in [asset_a, asset_b]:
        if asset != config.XCP:
            fairminter = ledger.issuances.get_fairminter_by_asset(db, asset)
            if (
                fairminter
                and fairminter["status"] in ("open", "pending")
                and (fairminter.get("pool_quantity") or 0) > 0
            ):
                problems.append(
                    f"fairminter with pool_quantity is active for {asset}; "
                    f"pool creation blocked until fairmint resolves"
                )

    for param_name, param_value in {"quantity_a": quantity_a, "quantity_b": quantity_b}.items():
        if not isinstance(param_value, int):
            problems.append(f"{param_name} must be an integer")
        elif param_value <= 0:
            problems.append(f"{param_name} must be positive")
        elif param_value > config.MAX_INT:
            problems.append(f"{param_name} exceeds maximum value")

    if not isinstance(min_lp_quantity, int):
        problems.append("min_lp_quantity must be an integer")
    elif min_lp_quantity < 0:
        problems.append("min_lp_quantity cannot be negative")
    elif min_lp_quantity > config.MAX_INT:
        problems.append("min_lp_quantity exceeds maximum value")

    if not problems and quantity_a > 0 and quantity_b > config.MAX_INT // quantity_a:
        problems.append("quantity_a * quantity_b exceeds maximum value")

    if problems:
        return problems

    sorted_a, sorted_b = ledger.markets.sort_pair(asset_a, asset_b)
    existing_pool = ledger.markets.get_pool(db, sorted_a, sorted_b)

    if existing_pool is None:
        if not lp_asset:
            problems.append("first pool deposit requires an lp_asset")
        elif not assetnames.is_numeric(lp_asset):
            problems.append("lp_asset must be a numeric asset")
        elif ledger.issuances.get_issuances(db, asset=lp_asset, status="valid"):
            problems.append(f"lp_asset {lp_asset} is already in use")
        elif ledger.issuances.get_active_fairminter_by_lp_asset(db, lp_asset):
            problems.append(f"lp_asset {lp_asset} is earmarked by an active fairminter")

    if asset_a == sorted_a:
        sorted_quantity_a, sorted_quantity_b = quantity_a, quantity_b
    else:
        sorted_quantity_a, sorted_quantity_b = quantity_b, quantity_a

    total_lp_supply = 0
    if existing_pool is not None:
        lp_asset = existing_pool["lp_asset"]
        total_lp_supply = ledger.supplies.asset_issued_total_no_cache(
            db, lp_asset
        ) - ledger.supplies.asset_destroyed_total_no_cache(db, lp_asset)
        if not ledger.markets.pool_has_liquidity(existing_pool) and total_lp_supply > 0:
            # Abnormal: LP tokens exist but a reserve is zero — reject to prevent div-by-zero
            problems.append("pool has no liquidity")
            return problems
        # total_lp_supply == 0 means pool fully drained; treat as restart below

    if total_lp_supply == 0:
        actual_a_sorted = sorted_quantity_a
        actual_b_sorted = sorted_quantity_b
        quantity_minted = ledger.markets.isqrt(sorted_quantity_a * sorted_quantity_b)
    else:
        actual_a_sorted, actual_b_sorted = compute_actual_deposit_amounts(
            existing_pool, sorted_quantity_a, sorted_quantity_b
        )
        quantity_minted = min(
            actual_a_sorted * total_lp_supply // existing_pool["reserve_a"],
            actual_b_sorted * total_lp_supply // existing_pool["reserve_b"],
        )

    if quantity_minted <= 0:
        problems.append("deposit too small to mint LP tokens")
    elif quantity_minted > config.MAX_INT:
        problems.append("quantity_minted exceeds maximum value")
    elif min_lp_quantity > 0 and quantity_minted < min_lp_quantity:
        problems.append(
            f"slippage protection: would mint {quantity_minted} LP tokens, minimum is {min_lp_quantity}"
        )

    if asset_a == sorted_a:
        required_a, required_b = actual_a_sorted, actual_b_sorted
    else:
        required_a, required_b = actual_b_sorted, actual_a_sorted

    # Check balances and gas fee
    fee = gas.get_transaction_fee(db, ID, block_index)
    balance_a = ledger.balances.get_balance(db, source, asset_a)
    if balance_a < required_a:
        problems.append(f"insufficient balance of {asset_a}")
    balance_b = ledger.balances.get_balance(db, source, asset_b)
    if balance_b < required_b:
        problems.append(f"insufficient balance of {asset_b}")
    # fee is always paid in XCP
    if fee > 0:
        xcp_needed = fee
        if asset_a == config.XCP:
            xcp_needed += required_a
        if asset_b == config.XCP:
            xcp_needed += required_b
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
    min_lp_quantity: int = 0,
    lp_asset: str = None,
    skip_validation: bool = False,
):
    # resolve subassets
    asset_a = ledger.issuances.resolve_subasset_longname(db, asset_a)
    asset_b = ledger.issuances.resolve_subasset_longname(db, asset_b)

    sorted_a, sorted_b = ledger.markets.sort_pair(asset_a, asset_b)
    existing_pool = ledger.markets.get_pool(db, sorted_a, sorted_b)
    if existing_pool is None and lp_asset is None:
        lp_asset = assetnames.generate_random_asset(f"{sorted_a}:{sorted_b}")

    problems = validate(
        db, source, asset_a, asset_b, quantity_a, quantity_b, min_lp_quantity, lp_asset
    )
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    asset_a_id = ledger.issuances.get_asset_id(db, asset_a)
    asset_b_id = ledger.issuances.get_asset_id(db, asset_b)
    lp_asset_id = 0
    if existing_pool is None and lp_asset:
        lp_asset_id = ledger.issuances.generate_asset_id(lp_asset)

    data = messagetype.pack(ID)
    data += struct.pack(
        FORMAT, asset_a_id, asset_b_id, quantity_a, quantity_b, min_lp_quantity, lp_asset_id
    )

    return (source, [], data)


def unpack(db, message, return_dict=False):
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        (
            asset_a_id,
            asset_b_id,
            quantity_a,
            quantity_b,
            min_lp_quantity,
            lp_asset_id,
        ) = struct.unpack(FORMAT, message)
        asset_a = ledger.issuances.get_asset_name(db, asset_a_id)
        asset_b = ledger.issuances.get_asset_name(db, asset_b_id)

        if return_dict:
            return {
                "asset_a": asset_a,
                "asset_b": asset_b,
                "quantity_a": quantity_a,
                "quantity_b": quantity_b,
                "min_lp_quantity": min_lp_quantity,
                "lp_asset_id": lp_asset_id,
            }
        return asset_a, asset_b, quantity_a, quantity_b, min_lp_quantity, lp_asset_id
    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error):
        if return_dict:
            return {
                "asset_a": "",
                "asset_b": "",
                "quantity_a": 0,
                "quantity_b": 0,
                "min_lp_quantity": 0,
                "lp_asset_id": 0,
            }
        return "", "", 0, 0, 0, 0


def parse(db, tx, message):
    asset_a, asset_b, quantity_a, quantity_b, min_lp_quantity, lp_asset_id = unpack(db, message)

    lp_asset = None
    if lp_asset_id > 0:
        try:
            lp_asset = ledger.issuances.generate_asset_name(lp_asset_id)
        except exceptions.AssetIDError:
            lp_asset = None

    status = "valid"
    if not asset_a or not asset_b or quantity_a <= 0 or quantity_b <= 0:
        status = "invalid: could not unpack"
    else:
        problems = validate(
            db,
            tx["source"],
            asset_a,
            asset_b,
            quantity_a,
            quantity_b,
            min_lp_quantity,
            lp_asset,
            block_index=tx["block_index"],
        )
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

    # execute deposit — remap to sorted pair order
    sorted_a, sorted_b = ledger.markets.sort_pair(asset_a, asset_b)
    if asset_a != sorted_a:
        quantity_a, quantity_b = quantity_b, quantity_a

    existing_pool = ledger.markets.get_pool(db, sorted_a, sorted_b)

    actual_a, actual_b = quantity_a, quantity_b
    if existing_pool is None:
        quantity_minted = first_deposit(
            db, tx, sorted_a, sorted_b, quantity_a, quantity_b, lp_asset
        )
    else:
        lp_asset = existing_pool["lp_asset"]
        supply = ledger.supplies.asset_issued_total_no_cache(
            db, lp_asset
        ) - ledger.supplies.asset_destroyed_total_no_cache(db, lp_asset)
        if supply == 0:
            quantity_minted = restart_pool(
                db, tx, existing_pool, sorted_a, sorted_b, quantity_a, quantity_b
            )
        else:
            quantity_minted, actual_a, actual_b = subsequent_deposit(
                db, tx, existing_pool, sorted_a, sorted_b, quantity_a, quantity_b
            )

    # record valid deposit
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "asset_a": sorted_a,
        "asset_b": sorted_b,
        "quantity_a": actual_a,
        "quantity_b": actual_b,
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


def compute_actual_deposit_amounts(pool, quantity_a, quantity_b):
    """Clamp a deposit to the pool's current reserve ratio. Returns (actual_a, actual_b)."""
    if pool["reserve_a"] <= 0 or pool["reserve_b"] <= 0:
        return 0, 0
    ratio_a = quantity_a * pool["reserve_b"]
    ratio_b = quantity_b * pool["reserve_a"]
    if ratio_a <= ratio_b:
        return quantity_a, quantity_a * pool["reserve_b"] // pool["reserve_a"]
    return quantity_b * pool["reserve_a"] // pool["reserve_b"], quantity_b


def first_deposit(db, tx, asset_a, asset_b, quantity_a, quantity_b, lp_asset):
    """Create pool and LP token, mint all LP tokens to depositor."""
    source = tx["source"]

    total_lp = ledger.markets.isqrt(quantity_a * quantity_b)

    # Debit both assets from source (escrow into pool)
    ledger.events.debit(
        db, source, asset_a, quantity_a, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )
    ledger.events.debit(
        db, source, asset_b, quantity_b, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )

    lp_asset_id = ledger.issuances.generate_asset_id(lp_asset)

    # Register LP token as asset
    ledger.events.insert_record(
        db,
        "assets",
        {
            "asset_id": str(lp_asset_id),
            "asset_name": lp_asset,
            "block_index": tx["block_index"],
            "asset_longname": None,
        },
        "ASSET_CREATION",
    )

    # Record issuance
    issuance_bindings = make_lp_issuance_bindings(
        db, tx, lp_asset, total_lp, asset_a, asset_b, "creation"
    )
    ledger.events.insert_record(db, "issuances", issuance_bindings, "ASSET_ISSUANCE")

    # Credit LP tokens to depositor
    ledger.events.credit(
        db,
        source,
        lp_asset,
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
            "reserve_a": quantity_a,
            "reserve_b": quantity_b,
            "lp_asset": lp_asset,
        },
    )

    return total_lp


def restart_pool(db, tx, pool, asset_a, asset_b, quantity_a, quantity_b):
    """Re-seed a pool whose LP supply is zero, reusing the existing LP asset."""
    source = tx["source"]
    lp_asset = pool["lp_asset"]

    total_lp = ledger.markets.isqrt(quantity_a * quantity_b)

    # Debit both assets
    ledger.events.debit(
        db, source, asset_a, quantity_a, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )
    ledger.events.debit(
        db, source, asset_b, quantity_b, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )

    # Record issuance for the new minted tokens
    issuance_bindings = make_lp_issuance_bindings(
        db, tx, lp_asset, total_lp, asset_a, asset_b, "pool_restart"
    )
    ledger.events.insert_record(db, "issuances", issuance_bindings, "ASSET_ISSUANCE")

    # Credit LP tokens to depositor
    ledger.events.credit(
        db, source, lp_asset, total_lp, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )

    new_reserve_a = pool["reserve_a"] + quantity_a
    new_reserve_b = pool["reserve_b"] + quantity_b
    ledger.markets.update_pool(db, asset_a, asset_b, new_reserve_a, new_reserve_b)

    return total_lp


def subsequent_deposit(db, tx, pool, asset_a, asset_b, quantity_a, quantity_b):
    """Add liquidity to existing pool. Mint proportional LP tokens.

    Provided quantities are maximums; the largest proportional deposit that
    fits within both is debited and any excess is left with the depositor.
    """
    source = tx["source"]

    lp_asset = pool["lp_asset"]
    total_lp_supply = ledger.supplies.asset_issued_total_no_cache(
        db, lp_asset
    ) - ledger.supplies.asset_destroyed_total_no_cache(db, lp_asset)

    actual_a, actual_b = compute_actual_deposit_amounts(pool, quantity_a, quantity_b)
    # min of both bases: the partner side is floored, so A-basis alone would
    # over-issue LP relative to the smaller contribution.
    quantity_minted = min(
        actual_a * total_lp_supply // pool["reserve_a"],
        actual_b * total_lp_supply // pool["reserve_b"],
    )

    # Debit only the proportional amounts
    ledger.events.debit(
        db, source, asset_a, actual_a, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
    )
    ledger.events.debit(
        db, source, asset_b, actual_b, tx["tx_index"], action="pool deposit", event=tx["tx_hash"]
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
    new_reserve_a = pool["reserve_a"] + actual_a
    new_reserve_b = pool["reserve_b"] + actual_b
    ledger.markets.update_pool(db, asset_a, asset_b, new_reserve_a, new_reserve_b)

    return quantity_minted, actual_a, actual_b


def create_pool_from_fairminter(db, fairminter, block_index, asset, quantity_tokens, quantity_xcp):
    """Create an AMM pool from fairminter resolution.

    Called from fairminter.soft_cap_deadline_reached() when pool_quantity > 0.
    Pool tokens and collected XCP are already unescrowed from UNSPENDABLE by the
    bulk debit in soft_cap_deadline_reached(); this function only records the pool.
    LP tokens are permanently locked at UNSPENDABLE.
    """
    tx_hash = fairminter["tx_hash"]
    tx_index = fairminter["tx_index"]
    source = fairminter["source"]
    lp_destination = config.UNSPENDABLE  # LP always locked for fairminter pools

    sorted_a, sorted_b = ledger.markets.sort_pair(asset, config.XCP)
    if asset == sorted_a:
        quantity_a, quantity_b = quantity_tokens, quantity_xcp
    else:
        quantity_a, quantity_b = quantity_xcp, quantity_tokens

    if ledger.markets.get_pool(db, sorted_a, sorted_b) is not None:
        raise exceptions.ParseTransactionError(
            f"fairminter {tx_hash}: pool already exists at soft-cap close"
        )

    lp_asset_name = fairminter["lp_asset"] if "lp_asset" in fairminter.keys() else None
    if not lp_asset_name:
        raise exceptions.ParseTransactionError(
            f"fairminter {tx_hash} has pool_quantity>0 but missing lp_asset"
        )
    lp_asset_id = ledger.issuances.generate_asset_id(lp_asset_name)
    total_lp = ledger.markets.isqrt(quantity_a * quantity_b)

    # Register LP token
    ledger.events.insert_record(
        db,
        "assets",
        {
            "asset_id": str(lp_asset_id),
            "asset_name": lp_asset_name,
            "block_index": block_index,
            "asset_longname": None,
        },
        "ASSET_CREATION",
    )

    # Record LP issuance
    pseudo_tx = {"tx_index": tx_index, "tx_hash": tx_hash, "block_index": block_index}
    issuance_bindings = make_lp_issuance_bindings(
        db,
        pseudo_tx,
        lp_asset_name,
        total_lp,
        sorted_a,
        sorted_b,
        "fairminter_pool_creation",
    )
    ledger.events.insert_record(db, "issuances", issuance_bindings, "ASSET_ISSUANCE")

    # Credit LP tokens
    ledger.events.credit(
        db,
        lp_destination,
        lp_asset_name,
        total_lp,
        tx_index,
        action="fairminter pool deposit",
        event=tx_hash,
    )

    # Create pool record
    ledger.markets.insert_pool(
        db,
        {
            "tx_index": tx_index,
            "tx_hash": tx_hash,
            "block_index": block_index,
            "source": source,
            "asset_a": sorted_a,
            "asset_b": sorted_b,
            "reserve_a": quantity_a,
            "reserve_b": quantity_b,
            "lp_asset": lp_asset_name,
        },
    )

    # Record deposit event
    ledger.events.insert_record(
        db,
        "pool_deposits",
        {
            "tx_index": tx_index,
            "tx_hash": tx_hash,
            "block_index": block_index,
            "source": source,
            "asset_a": sorted_a,
            "asset_b": sorted_b,
            "quantity_a": quantity_a,
            "quantity_b": quantity_b,
            "quantity_minted": total_lp,
            "status": "valid",
        },
        "NEW_POOL_DEPOSIT",
    )

    logger.info(
        "Fairminter pool: %s %s + %s %s -> %s LP [%s]",
        quantity_a,
        sorted_a,
        quantity_b,
        sorted_b,
        total_lp,
        tx_hash,
    )

    return total_lp
