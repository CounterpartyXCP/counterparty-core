import decimal
import logging
import math
import struct

import cbor2

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import fairminter as fairminter_mod
from counterpartycore.lib.parser import protocol

logger = logging.getLogger(config.LOGGER_NAME)

ID = 91


def D(value):  # pylint: disable=invalid-name
    return decimal.Decimal(str(value))


def resolve_asset_name(db, asset):
    return ledger.issuances.resolve_subasset_longname(db, asset)


def validate(
    db,
    source,
    asset,
    quantity=0,
    block_index=None,
):
    problems = []

    invalid_quantity = not isinstance(quantity, int)
    if invalid_quantity:
        problems.append("quantity must be an integer")

    # NOTE: do not resolve subasset longnames here. validate() is on the
    # consensus parse path (parse() calls it with the asset returned by
    # unpack(), which is already canonical for v2/CBOR fairmints and the raw
    # message string for legacy ones). Resolving here would change the stored
    # `status` of a legacy-format fairmint carrying a subasset longname without
    # a protocol change. Longname resolution happens in compose() instead.
    fairminter = ledger.issuances.get_fairminter_by_asset(db, asset)
    if not fairminter:
        problems.append(f"fairminter not found for asset: `{asset}`")
        return problems

    if invalid_quantity:
        return problems

    if fairminter["status"] != "open":
        problems.append(f"fairminter is not open for asset: `{asset}`")

    asset_supply = ledger.supplies.asset_supply(db, fairminter["asset"])

    if fairminter["max_mint_per_address"] is not None and fairminter["max_mint_per_address"] > 0:
        alread_minted = ledger.issuances.get_fairmint_by_address(db, fairminter["tx_hash"], source)
        if fairminter["price"] > 0:
            if alread_minted + quantity > fairminter["max_mint_per_address"]:
                problems.append("quantity exceeds maximum allowed by address")
        else:
            if alread_minted + fairminter["max_mint_per_tx"] > fairminter["max_mint_per_address"]:
                problems.append("quantity exceeds maximum allowed by address")

    if fairminter["price"] > 0:
        # if the fairminter is not free the quantity is mandatory
        if quantity <= 0:
            problems.append("Quantity must be greater than 0")
            return problems
        if fairminter["max_mint_per_tx"] > 0 and quantity > fairminter["max_mint_per_tx"]:
            problems.append("Quantity exceeds maximum allowed per transaction")
            return problems
        if quantity > config.MAX_INT:
            problems.append("quantity exceeds maximum allowed value")
            return problems
        if (
            protocol.enabled("fairmint_pool", block_index=block_index)
            and quantity % fairminter["quantity_by_price"] != 0
        ):
            problems.append("quantity is not a multiple of lot_size")
            return problems
        # check id we don't exceed the hard cap
        if fairminter["hard_cap"] > 0 and asset_supply + quantity > fairminter["hard_cap"]:
            problems.append("asset supply quantity exceeds hard cap")
        # check if the user has enough XCP
        xcp_total_price = (D(quantity) / D(fairminter["quantity_by_price"])) * D(
            fairminter["price"]
        )
        xcp_total_price = int(math.ceil(xcp_total_price))
        balance = ledger.balances.get_balance(db, source, config.XCP)
        if balance < xcp_total_price:
            problems.append("insufficient XCP balance")
    else:
        if protocol.enabled("fairmint_pool", block_index=block_index) and quantity > 0:
            problems.append("quantity is not allowed for free fairminters")
        if not protocol.enabled("partial_mint_to_reach_hard_cap"):
            if (
                fairminter["hard_cap"] > 0
                and asset_supply + fairminter["max_mint_per_tx"] > fairminter["hard_cap"]
            ):
                problems.append("asset supply quantity exceeds hard cap")

    return problems


def compose(db, source: str, asset: str, quantity: int = 0, skip_validation: bool = False):
    resolved_asset = resolve_asset_name(db, asset)
    if quantity != 0 and not skip_validation and isinstance(quantity, int):
        fairminter = ledger.issuances.get_fairminter_by_asset(db, resolved_asset)
        if fairminter and fairminter["price"] == 0:
            raise exceptions.ComposeError("quantity is not allowed for free fairminters")
        if fairminter and quantity % fairminter["quantity_by_price"] != 0:
            raise exceptions.ComposeError("quantity is not a multiple of lot_size")

    problems = validate(db, source, resolved_asset, quantity)
    if len(problems) > 0 and not skip_validation:
        raise exceptions.ComposeError(problems)

    # create message
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)

    if protocol.enabled("fairminter_v2"):
        asset_id = ledger.issuances.generate_asset_id(resolved_asset)
        data += cbor2.dumps([asset_id, quantity])
    else:
        data_content = "|".join(
            [
                str(value)
                for value in [
                    resolved_asset,
                    quantity,
                ]
            ]
        ).encode("utf-8")
        data += struct.pack(f">{len(data_content)}s", data_content)

    return (source, [], data)


def unpack_legacy(message):
    return struct.unpack(f">{len(message)}s", message)[0].decode("utf-8").split("|")


def unpack_new(message):
    (asset_id, quantity) = cbor2.loads(message)  # pylint: disable=unbalanced-tuple-unpacking
    asset = ledger.issuances.generate_asset_name(asset_id)
    return (asset, quantity)


def unpack(message, return_dict=False, block_index=None):
    try:
        if protocol.enabled("fairminter_v2", block_index=block_index):
            try:
                (asset, quantity) = unpack_new(message)
            except Exception:  # pylint: disable=broad-exception-caught
                # fallback to legacy unpacking
                (asset, quantity) = unpack_legacy(message)
        else:
            (asset, quantity) = unpack_legacy(message)

        if return_dict:
            return {"asset": asset, "quantity": int(quantity)}

        return (asset, int(quantity))
    except Exception:  # pylint: disable=broad-exception-caught
        return ("", 0)


def _handle_hard_cap_reached(db, fairminter, block_index):
    if fairminter["soft_cap"] == 0:
        ledger.issuances.update_fairminter(db, fairminter["tx_hash"], {"status": "closed"})
        return

    pool_quantity = fairminter.get("pool_quantity") or 0
    deadline = fairminter["soft_cap_deadline_block"]

    if pool_quantity > 0:
        # defer pool creation to after_block (anti-sandwich)
        if deadline > block_index:
            ledger.issuances.update_fairminter(
                db, fairminter["tx_hash"], {"soft_cap_deadline_block": block_index}
            )
        elif deadline < block_index:
            # Unreachable: after_block(deadline) would have closed the fairminter
            # already, so fairmint.validate would have rejected this mint upstream.
            # Halt rather than silently close — closing here leaves the escrowed
            # pool tokens stranded at UNSPENDABLE.
            raise exceptions.ParseTransactionError(
                f"fairminter {fairminter['tx_hash']}: hard cap reached at block {block_index} "
                f"but soft_cap_deadline {deadline} already passed"
            )
        return

    if deadline >= block_index:
        fairminter_mod.soft_cap_deadline_reached(db, fairminter, block_index)
    ledger.issuances.update_fairminter(db, fairminter["tx_hash"], {"status": "closed"})


def parse(db, tx, message):
    (asset, quantity) = unpack(message, block_index=tx["block_index"])
    problems = validate(db, tx["source"], asset, quantity, block_index=tx["block_index"])

    # if problems, insert into fairmints table with status invalid and return
    status = "valid"
    if problems:
        status = "invalid: " + "; ".join(problems)
        bindings = {
            "tx_hash": tx["tx_hash"],
            "tx_index": tx["tx_index"],
            "block_index": tx["block_index"],
            "source": tx["source"],
            "status": status,
        }
        ledger.events.insert_record(db, "fairmints", bindings, "NEW_FAIRMINT")
        logger.info("Fairmint %s  is invalid: %s", tx["tx_hash"], status)

    ledger.blocks.set_transaction_status(
        db,
        tx["tx_index"],
        status == "valid",
    )

    if problems:
        # stop here to avoid further processing
        return

    # get corresponding fairminter
    fairminter = ledger.issuances.get_fairminter_by_asset(db, asset)

    # determine if the soft cap has been reached
    soft_cap_not_reached = (
        fairminter["soft_cap"] > 0 and fairminter["soft_cap_deadline_block"] >= tx["block_index"]
    )

    # we determine who to send the payment and assets to
    # By default the assets are sent to the minter
    # and the payment to the issuer
    xcp_action = "fairmint payment"
    xcp_destination = fairminter["source"]
    asset_action = "fairmint"
    asset_destination = tx["source"]

    # if the soft cap is not reached we escrow the assets and payments
    # which will be distributed in the `fairminters.perform_soft_cap_operations()` function.
    if soft_cap_not_reached:
        xcp_action = "escrowed fairmint"
        xcp_destination = config.UNSPENDABLE
        asset_action = "escrowed fairmint"
        asset_destination = config.UNSPENDABLE
    # if the soft cap is reached but the payment must
    # be burned there is no destination.
    elif fairminter["burn_payment"]:
        xcp_action = "burn fairmint payment"
        xcp_destination = None
    # we determine how many assets we need to send
    # and the price paid by the user
    if fairminter["price"] > 0:
        paid_quantity = (D(quantity) / D(fairminter["quantity_by_price"])) * D(fairminter["price"])
        paid_quantity = int(math.ceil(paid_quantity))
        earn_quantity = quantity
    else:
        paid_quantity = 0
        if protocol.enabled("partial_mint_to_reach_hard_cap"):
            asset_supply = ledger.supplies.asset_supply(db, fairminter["asset"])
            if (
                fairminter["hard_cap"] > 0
                and asset_supply + fairminter["max_mint_per_tx"] > fairminter["hard_cap"]
            ):
                earn_quantity = fairminter["hard_cap"] - asset_supply
            else:
                earn_quantity = fairminter["max_mint_per_tx"]
        else:
            earn_quantity = fairminter["max_mint_per_tx"]

    # we determine the commission to be paid to the issuer
    # and we subtract it from the assets to be sent to the user
    commission = 0
    if fairminter["minted_asset_commission_int"] > 0:
        commission = int((D(fairminter["minted_asset_commission_int"]) / D(1e8)) * D(earn_quantity))
        earn_quantity -= commission

    if paid_quantity > 0:
        # we debit the user
        ledger.events.debit(
            db, tx["source"], config.XCP, paid_quantity, tx["tx_index"], xcp_action, tx["tx_hash"]
        )
        if xcp_destination:
            # we credit the destination if it exists (issuer or escrow)
            ledger.events.credit(
                db,
                xcp_destination,
                config.XCP,
                paid_quantity,
                tx["tx_index"],
                xcp_action,
                tx["tx_hash"],
            )
        else:
            # else we burn the payment
            bindings = {
                "tx_index": tx["tx_index"],
                "tx_hash": tx["tx_hash"],
                "block_index": tx["block_index"],
                "source": tx["source"],
                "asset": config.XCP,
                "quantity": paid_quantity,
                "tag": xcp_action,
                "status": "valid",
            }
            ledger.events.insert_record(db, "destructions", bindings, "ASSET_DESTRUCTION")

    if asset_destination == config.UNSPENDABLE:
        # the minted amount and commission are escrowed
        ledger.events.credit(
            db,
            asset_destination,
            asset,
            earn_quantity + commission,
            tx["tx_index"],
            asset_action,
            tx["tx_hash"],
        )
    else:
        # the minted amount is sent to the user
        ledger.events.credit(
            db, asset_destination, asset, earn_quantity, tx["tx_index"], asset_action, tx["tx_hash"]
        )
        if commission > 0:
            # the commission is sent to the issuer
            ledger.events.credit(
                db,
                fairminter["source"],
                asset,
                commission,
                tx["tx_index"],
                "fairmint commission",
                tx["tx_hash"],
            )

    # we insert the fairmint record
    bindings = {
        "tx_hash": tx["tx_hash"],
        "tx_index": tx["tx_index"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "fairminter_tx_hash": fairminter["tx_hash"],
        "asset": fairminter["asset"],
        "earn_quantity": earn_quantity,
        "paid_quantity": paid_quantity,
        "commission": commission,
        "status": status,
    }
    ledger.events.insert_record(db, "fairmints", bindings, "NEW_FAIRMINT")

    # we prepare the new issuance
    last_issuance = ledger.issuances.get_last_issuance(db, asset)
    bindings = last_issuance | {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "quantity": earn_quantity + commission,
        "source": tx["source"],
        "status": "valid",
        "fee_paid": 0,
        "asset_events": "fairmint",
    }

    # we check if the hard cap is reached and in this case...
    if fairminter["hard_cap"] > 0:
        asset_supply = ledger.supplies.asset_supply(db, fairminter["asset"])
        alredy_minted = asset_supply + earn_quantity + commission
        if alredy_minted == fairminter["hard_cap"]:
            # ...we unlock the issuances for this assets
            bindings["fair_minting"] = False
            # we check if we need to lock the assets
            if fairminter["lock_quantity"]:
                bindings["locked"] = True
            if fairminter["lock_description"]:
                bindings["description_locked"] = True
            _handle_hard_cap_reached(db, fairminter, tx["block_index"])

    # we insert the new issuance
    ledger.events.insert_record(db, "issuances", bindings, "ASSET_ISSUANCE")

    # log
    logger.info(
        "%s %s minted for %s XCP by %s",
        earn_quantity + commission,
        asset,
        paid_quantity,
        tx["source"],
    )
