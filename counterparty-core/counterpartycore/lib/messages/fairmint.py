import decimal
import logging
import math
import struct

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import fairminter as fairminter_mod
from counterpartycore.lib.parser import protocol

logger = logging.getLogger(config.LOGGER_NAME)

ID = 91


def D(value):  # pylint: disable=invalid-name
    return decimal.Decimal(str(value))


def validate(
    db,
    source,
    asset,
    quantity=0,
):
    problems = []

    if not isinstance(quantity, int):
        problems.append("quantity must be an integer")

    fairminter = ledger.issuances.get_fairminter_by_asset(db, asset)
    if not fairminter:
        problems.append(f"fairminter not found for asset: `{asset}`")
        return problems

    if fairminter["status"] != "open":
        problems.append(f"fairminter is not open for asset: `{asset}`")

    asset_supply = ledger.supplies.asset_supply(db, fairminter["asset"])

    if fairminter["max_mint_per_address"] > 0:
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
    elif not protocol.enabled("partial_mint_to_reach_hard_cap"):
        # check id we don't exceed the hard cap
        if (
            fairminter["hard_cap"] > 0
            and asset_supply + fairminter["max_mint_per_tx"] > fairminter["hard_cap"]
        ):
            problems.append("asset supply quantity exceeds hard cap")

    return problems


def compose(db, source: str, asset: str, quantity: int = 0, skip_validation: bool = False):
    problems = validate(db, source, asset, quantity)
    if len(problems) > 0 and not skip_validation:
        raise exceptions.ComposeError(problems)

    if quantity != 0:
        fairminter = ledger.issuances.get_fairminter_by_asset(db, asset)
        if fairminter["price"] == 0:
            raise exceptions.ComposeError("quantity is not allowed for free fairminters")

    # create message
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    # to optimize the data size (avoiding fixed sizes per parameter) we use a simple
    # string of characters separated by `|`.
    data_content = "|".join(
        [
            str(value)
            for value in [
                asset,
                quantity,
            ]
        ]
    ).encode("utf-8")
    data += struct.pack(f">{len(data_content)}s", data_content)
    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        data_content = struct.unpack(f">{len(message)}s", message)[0].decode("utf-8").split("|")
        (asset, quantity) = data_content
        if return_dict:
            return {"asset": asset, "quantity": int(quantity)}

        return (asset, int(quantity))
    except Exception:  # pylint: disable=broad-exception-caught
        return ("", 0)


def parse(db, tx, message):
    (asset, quantity) = unpack(message)
    problems = validate(db, tx["source"], asset, quantity)

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
            # and we close the fairminter
            if (
                fairminter["soft_cap"] > 0
                and fairminter["soft_cap_deadline_block"] >= tx["block_index"]
            ):
                fairminter_mod.soft_cap_deadline_reached(db, fairminter, tx["block_index"])
            ledger.issuances.update_fairminter(db, fairminter["tx_hash"], {"status": "closed"})

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
