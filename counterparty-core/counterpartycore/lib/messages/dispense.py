import logging
import struct
from math import floor

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import dispenser as dispenser_module
from counterpartycore.lib.parser import protocol
from counterpartycore.lib.utils import helpers

logger = logging.getLogger(config.LOGGER_NAME)


def get_must_give(db, dispenser, btc_amount, block_index=None):
    if (dispenser["oracle_address"] is not None) and protocol.enabled(  # noqa: E711
        "oracle_dispensers", block_index
    ):
        last_price, _last_fee, _last_fiat_label, _last_updated = ledger.other.get_oracle_last_price(
            db, dispenser["oracle_address"], block_index or CurrentState().current_block_index()
        )
        if last_price is None:
            raise exceptions.NoPriceError(
                f"No price available for this oracle {dispenser['oracle_address']} at block {block_index}"
            )
        fiatrate = helpers.satoshirate_to_fiat(dispenser["satoshirate"])
        return int(floor(((btc_amount / config.UNIT) * last_price) / fiatrate))

    return int(floor(btc_amount / dispenser["satoshirate"]))


def validate_compose(db, source, destination, quantity):
    problems = []

    if not protocol.enabled("enable_dispense_tx"):
        problems.append("dispense tx is not enabled")
        return problems

    if source == destination:
        raise exceptions.ComposeError("source and destination must be different")

    dispensers = ledger.markets.get_dispensers(db, address=destination)
    if len(dispensers) == 0:
        problems.append("address doesn't have any open dispenser")
        return problems

    for dispenser in dispensers:
        dispenser_problems = []
        if dispenser["status"] != dispenser_module.STATUS_OPEN:
            dispenser_problems.append(f"dispenser for {dispenser['asset']} is not open")
        if dispenser["give_remaining"] == 0:
            dispenser_problems.append(f"dispenser for {dispenser['asset']} is empty")
        else:
            try:
                must_give = get_must_give(db, dispenser, quantity) * dispenser["give_quantity"]
                if must_give > dispenser["give_remaining"]:
                    dispenser_problems.append(
                        f"dispenser for {dispenser['asset']} doesn't have enough asset to give"
                    )
                elif must_give == 0:
                    dispenser_problems.append(
                        f"not enough BTC to trigger dispenser for {dispenser['asset']}"
                    )
            except exceptions.NoPriceError as e:
                dispenser_problems.append(str(e))
        # no error if at least one dispenser is valid
        if len(dispenser_problems) == 0 and protocol.enabled("accept_only_one_valid_dispenser"):
            return []
        problems += dispenser_problems
    return problems


def compose(db, source, destination, quantity, skip_validation: bool = False):
    problems = validate_compose(db, source, destination, quantity)

    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    # create data
    data = struct.pack(config.SHORT_TXTYPE_FORMAT, dispenser_module.DISPENSE_ID)
    data += b"\x00"
    return (source, [(destination, quantity)], data)


def unpack(message, return_dict=False):
    if return_dict:
        return {"data": message}
    return message


def parse(db, tx):
    cursor = db.cursor()

    outs = []
    if protocol.enabled("multiple_dispenses"):
        outs = ledger.blocks.get_vouts(db, tx["tx_hash"])
    else:
        outs = [tx]

    # if len(outs) == 0:
    #    outs = [tx]
    # or
    # assert len(outs) > 0 ?

    dispense_index = 0

    for next_out in outs:
        dispensers = []
        if next_out["destination"] is not None:
            dispensers = ledger.markets.get_dispensers(
                db, address=next_out["destination"], status_in=[0, 11], order_by="asset"
            )

        for dispenser in dispensers:
            satoshirate = dispenser["satoshirate"]
            give_quantity = dispenser["give_quantity"]

            if satoshirate > 0 and give_quantity > 0:
                must_give = get_must_give(
                    db, dispenser, next_out["btc_amount"], next_out["block_index"]
                )
                remaining = int(floor(dispenser["give_remaining"] / give_quantity))
                actually_given = min(must_give, remaining) * give_quantity
                give_remaining = dispenser["give_remaining"] - actually_given

                assert give_remaining >= 0

                # Skip dispense if quantity is 0
                if protocol.enabled("zero_quantity_value_adjustment_1") and actually_given == 0:
                    continue

                ledger.events.credit(
                    db,
                    next_out["source"],
                    dispenser["asset"],
                    actually_given,
                    tx["tx_index"],
                    action="dispense",
                    event=next_out["tx_hash"],
                )

                # Checking if the dispenser reach its max dispenses limit
                max_dispenses_limit = protocol.get_value_by_block_index(
                    "max_dispenses_limit", next_out["block_index"]
                )
                max_dispenser_limit_hit = False

                if dispenser["dispense_count"] + 1 >= max_dispenses_limit > 0:
                    max_dispenser_limit_hit = True

                dispenser["give_remaining"] = give_remaining
                if give_remaining < dispenser["give_quantity"] or max_dispenser_limit_hit:
                    # close the dispenser
                    dispenser["give_remaining"] = 0
                    if give_remaining > 0:
                        if max_dispenser_limit_hit:
                            credit_action = "Closed: Max dispenses reached"
                            dispenser["closing_reason"] = "max_dispenses_reached"
                        else:
                            credit_action = "dispenser close"
                            dispenser["closing_reason"] = "no_more_to_give"

                        # return the remaining to the owner
                        ledger.events.credit(
                            db,
                            dispenser["source"],
                            dispenser["asset"],
                            give_remaining,
                            tx["tx_index"],
                            action=credit_action,
                            event=next_out["tx_hash"],
                        )
                    else:
                        dispenser["closing_reason"] = "depleted"
                    dispenser["status"] = dispenser_module.STATUS_CLOSED

                dispenser["block_index"] = next_out["block_index"]
                dispenser["prev_status"] = dispenser_module.STATUS_OPEN

                set_data = {
                    "give_remaining": dispenser["give_remaining"],
                    "status": dispenser["status"],
                    "dispense_count": dispenser["dispense_count"] + 1,
                }
                ledger.markets.update_dispenser(
                    db,
                    dispenser["rowid"],
                    set_data,
                    {
                        "source": dispenser["source"],
                        "asset": dispenser["asset"],
                        "tx_hash": dispenser["tx_hash"],
                    },
                )

                bindings = {
                    "tx_index": next_out["tx_index"],
                    "tx_hash": next_out["tx_hash"],
                    "dispense_index": dispense_index,
                    "block_index": next_out["block_index"],
                    "source": next_out["destination"],
                    "destination": next_out["source"],
                    "asset": dispenser["asset"],
                    "dispense_quantity": actually_given,
                    "dispenser_tx_hash": dispenser["tx_hash"],
                    "btc_amount": next_out["btc_amount"],
                }
                ledger.events.insert_record(db, "dispenses", bindings, "DISPENSE")
                dispense_index += 1

                logger.info(
                    "Dispense %(dispense_quantity)s %(asset)s from %(source)s to %(destination)s (%(tx_hash)s) [valid]",
                    bindings,
                )

    cursor.close()
