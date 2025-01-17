import binascii
import decimal
import json
import logging
import math

from counterpartycore.lib import (
    config,
    exceptions,
    ledger,
)
from counterpartycore.lib.api import compose
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.utils import helpers

D = decimal.Decimal
logger = logging.getLogger(config.LOGGER_NAME)


def normalize_price(value):
    decimal.getcontext().prec = 32
    return "{0:.16f}".format(D(value))


def inject_issuances_and_block_times(ledger_db, state_db, result_list):
    asset_fields = [
        "asset",
        "give_asset",
        "get_asset",
        "dividend_asset",
        "forward_asset",
        "backward_asset",
    ]

    # gather asset list and block indexes
    asset_list = []
    block_indexes = []
    for result_item in result_list:
        for field_name in [
            "block_index",
            "first_issuance_block_index",
            "last_issuance_block_index",
        ]:
            if field_name in result_item and result_item[field_name]:
                result_item[field_name] = int(result_item[field_name])
            if (
                "params" in result_item
                and field_name in result_item["params"]
                and result_item["params"][field_name]
            ):
                result_item["params"][field_name] = int(result_item["params"][field_name])
            if (
                field_name in result_item
                and result_item[field_name] not in block_indexes
                and result_item[field_name]
            ):
                block_indexes.append(result_item[field_name])
            if (
                "params" in result_item
                and field_name in result_item["params"]
                and result_item["params"][field_name] not in block_indexes
                and result_item["params"][field_name]
            ):
                block_indexes.append(result_item["params"][field_name])

        if (
            "asset_longname" in result_item
            and "description" in result_item
            and "max_mint_per_tx" not in result_item
        ):
            continue
        item = result_item
        if "params" in item:
            item = item["params"]
            if "unpacked_data" in item:
                item = item["unpacked_data"]["message_data"]
        elif "unpacked_data" in item:
            item = item["unpacked_data"]["message_data"]
        for field_name in asset_fields:
            if isinstance(item, list):
                for sub_item in item:
                    if field_name in sub_item:
                        if sub_item[field_name] not in asset_list:
                            asset_list.append(sub_item[field_name])
            elif field_name in item:
                if item[field_name] not in asset_list:
                    asset_list.append(item[field_name])

    # get asset issuances
    issuance_by_asset = ledger.issuances.get_assets_last_issuance(state_db, asset_list)

    # get block_time for each block_index
    block_times = ledger.blocks.get_blocks_time(ledger_db, block_indexes)

    # inject issuance and block_time
    for result_item in result_list:
        item = result_item
        for field_name in [
            "block_index",
            "first_issuance_block_index",
            "last_issuance_block_index",
        ]:
            field_name_time = field_name.replace("index", "time")
            if field_name in item and item[field_name] in [0, config.MEMPOOL_BLOCK_INDEX, None]:
                continue
            if field_name in item and item[field_name] in block_times:
                item[field_name_time] = block_times[item[field_name]]
            if (
                "params" in item
                and field_name in item["params"]
                and item["params"][field_name] in block_times
            ):
                if item["params"][field_name] in [0, config.MEMPOOL_BLOCK_INDEX]:
                    continue
                item["params"][field_name_time] = block_times[item["params"][field_name]]
        if "params" in item:
            item = item["params"]
            if "unpacked_data" in item:
                item = item["unpacked_data"]["message_data"]
        elif "unpacked_data" in item:
            item = item["unpacked_data"]["message_data"]
        for field_name in asset_fields:
            if isinstance(item, list):
                for sub_item in item:
                    if (
                        field_name in sub_item
                        and "divisible" not in sub_item
                        and sub_item[field_name] in issuance_by_asset
                    ):
                        sub_item[field_name + "_info"] = issuance_by_asset[sub_item[field_name]]
            elif (
                field_name in item
                and "divisible" not in item
                and item[field_name] in issuance_by_asset
            ):
                item[field_name + "_info"] = issuance_by_asset[item[field_name]]

    return result_list


def inject_normalized_quantity(item, field_name, asset_info):
    if field_name not in item:
        return item

    if item[field_name] is not None:
        if field_name in ["give_price", "get_price", "forward_price", "backward_price"]:
            # use 16 decimal places for prices
            item[field_name + "_normalized"] = normalize_price(item[field_name])
        elif field_name == "price":
            if "satoshirate" in item:
                price = D(item["satoshirate_normalized"]) / D(item["give_quantity_normalized"])
                item[field_name + "_normalized"] = normalize_price(price)
            else:
                item[field_name + "_normalized"] = normalize_price(item[field_name])
        else:
            item[field_name + "_normalized"] = (
                helpers.divide(item[field_name], 10**8)
                if asset_info["divisible"]
                else str(item[field_name])
            )

    return item


def inject_normalized_quantities(result_list):
    quantity_fields = {
        "quantity": {"asset_field": "asset_info", "divisible": None},
        "give_quantity": {"asset_field": "give_asset_info", "divisible": None},
        "get_quantity": {"asset_field": "get_asset_info", "divisible": None},
        "get_remaining": {"asset_field": "get_asset_info", "divisible": None},
        "give_remaining": {"asset_field": "give_asset_info", "divisible": None},
        "forward_quantity": {"asset_field": "forward_asset_info", "divisible": None},
        "backward_quantity": {"asset_field": "backward_asset_info", "divisible": None},
        "escrow_quantity": {"asset_field": "asset_info", "divisible": None},
        "dispense_quantity": {"asset_field": "asset_info", "divisible": None},
        "quantity_per_unit": {"asset_field": "dividend_asset_info", "divisible": None},
        "supply": {"asset_field": "asset_info", "divisible": None},
        "satoshirate": {"asset_field": None, "divisible": True},
        "satoshi_price": {"asset_field": None, "divisible": True},
        "burned": {"asset_field": None, "divisible": True},
        "earned": {"asset_field": None, "divisible": True},
        "btc_amount": {"asset_field": None, "divisible": True},
        "fee_paid": {"asset_field": None, "divisible": True},
        "fee_provided": {"asset_field": None, "divisible": True},
        "fee_required": {"asset_field": None, "divisible": True},
        "fee_required_remaining": {"asset_field": None, "divisible": True},
        "fee_provided_remaining": {"asset_field": None, "divisible": True},
        "fee_fraction_int": {"asset_field": None, "divisible": True},
        "price": {"asset_field": "asset_info", "divisible": None},
        "hard_cap": {"asset_field": "asset_info", "divisible": None},
        "soft_cap": {"asset_field": "asset_info", "divisible": None},
        "quantity_by_price": {"asset_field": "asset_info", "divisible": None},
        "max_mint_per_tx": {"asset_field": "asset_info", "divisible": None},
        "premint_quantity": {"asset_field": "asset_info", "divisible": None},
        "earned_quantity": {"asset_field": "asset_info", "divisible": None},
        "earn_quantity": {"asset_field": "asset_info", "divisible": None},
        "commission": {"asset_field": "asset_info", "divisible": None},
        "paid_quantity": {"asset_field": "asset_info", "divisible": None},
        "give_price": {"asset_field": "give_asset_info", "divisible": None},
        "get_price": {"asset_field": "get_asset_info", "divisible": None},
        "forward_price": {"asset_field": "forward_asset_info", "divisible": None},
        "backward_price": {"asset_field": "backward_asset_info", "divisible": None},
    }

    enriched_result_list = []
    for result_item in result_list:
        item = result_item.copy()
        if "addresses" in item:
            for i, address in enumerate(item["addresses"]):
                item["addresses"][i] = inject_normalized_quantity(
                    address, "quantity", {"divisible": item["asset_info"]["divisible"]}
                )
            item = inject_normalized_quantity(
                item, "total", {"divisible": item["asset_info"]["divisible"]}
            )
            enriched_result_list.append(item)
            continue
        for field_name, field_info in quantity_fields.items():
            if field_info["divisible"] is not None:
                if field_name in item:
                    item = inject_normalized_quantity(
                        item, field_name, {"divisible": field_info["divisible"]}
                    )
                if "params" in item and field_name in item["params"]:
                    item["params"] = inject_normalized_quantity(
                        item["params"], field_name, {"divisible": field_info["divisible"]}
                    )
                    if "unpacked_data" in item["params"]:
                        item["params"]["unpacked_data"]["message_data"] = (
                            inject_normalized_quantity(
                                item["params"]["unpacked_data"]["message_data"],
                                field_name,
                                {"divisible": field_info["divisible"]},
                            )
                        )
                if "unpacked_data" in item:
                    item["unpacked_data"]["message_data"] = inject_normalized_quantity(
                        item["unpacked_data"]["message_data"],
                        field_name,
                        {"divisible": field_info["divisible"]},
                    )
                if "dispenser" in item and field_name in item["dispenser"]:
                    item["dispenser"] = inject_normalized_quantity(
                        item["dispenser"], field_name, {"divisible": field_info["divisible"]}
                    )
                continue

            if field_name == "supply" and field_name in item:
                item = inject_normalized_quantity(
                    item, field_name, {"divisible": item["divisible"]}
                )
                continue

            if "unpacked_data" in item and isinstance(
                item["unpacked_data"]["message_data"], list
            ):  # mpma send
                for pos, sub_item in enumerate(item["unpacked_data"]["message_data"]):
                    if field_info["asset_field"] in sub_item:
                        asset_info = sub_item["asset_info"]
                        item["unpacked_data"]["message_data"][pos] = inject_normalized_quantity(
                            sub_item, field_name, asset_info
                        )
                continue
            if (
                "params" in item
                and "unpacked_data" in item["params"]
                and isinstance(item["params"]["unpacked_data"]["message_data"], list)
            ):  # mpma send
                for pos, sub_item in enumerate(item["params"]["unpacked_data"]["message_data"]):
                    if field_info["asset_field"] in sub_item:
                        asset_info = sub_item["asset_info"]
                        item["params"]["unpacked_data"]["message_data"][pos] = (
                            inject_normalized_quantity(sub_item, field_name, asset_info)
                        )

            asset_info = None
            if field_info["asset_field"] in item:
                asset_info = item[field_info["asset_field"]]
            elif "params" in item and field_info["asset_field"] in item["params"]:
                asset_info = item["params"][field_info["asset_field"]]
            elif (
                "params" in item
                and "unpacked_data" in item["params"]
                and field_info["asset_field"] in item["params"]["unpacked_data"]["message_data"]
            ):
                asset_info = item["params"]["unpacked_data"]["message_data"][
                    field_info["asset_field"]
                ]
            elif (
                "unpacked_data" in item
                and field_info["asset_field"] in item["unpacked_data"]["message_data"]
            ):
                asset_info = item["unpacked_data"]["message_data"][field_info["asset_field"]]
            elif "divisible" in item and field_name in item:
                asset_info = {"divisible": item["divisible"]}
            elif (
                "params" in item and "divisible" in item["params"] and field_name in item["params"]
            ):
                asset_info = {"divisible": item["params"]["divisible"]}
            elif "unpacked_data" in item and "divisible" in item["unpacked_data"]["message_data"]:
                asset_info = {"divisible": item["unpacked_data"]["message_data"]["divisible"]}

            if asset_info is None:
                if "asset_info" in item:
                    asset_info = item["asset_info"]
                elif "params" in item and "asset_info" in item["params"]:
                    asset_info = item["params"]["asset_info"]
                elif (
                    "params" in item
                    and "unpacked_data" in item["params"]
                    and "asset_info" in item["params"]["unpacked_data"]["message_data"]
                ):
                    asset_info = item["params"]["unpacked_data"]["message_data"]["asset_info"]
                elif (
                    "unpacked_data" in item
                    and "asset_info" in item["unpacked_data"]["message_data"]
                ):
                    asset_info = item["unpacked_data"]["message_data"]["asset_info"]
                else:
                    continue

            if field_name in item:
                item = inject_normalized_quantity(item, field_name, asset_info)  # noqa
            if "params" in item and field_name in item["params"]:
                item["params"] = inject_normalized_quantity(  # noqa
                    item["params"], field_name, asset_info
                )
            if (
                "params" in item
                and "unpacked_data" in item["params"]
                and field_name in item["params"]["unpacked_data"]["message_data"]
            ):
                item["params"]["unpacked_data"]["message_data"] = inject_normalized_quantity(  # noqa
                    item["params"]["unpacked_data"]["message_data"], field_name, asset_info
                )
            if "unpacked_data" in item and field_name in item["unpacked_data"]["message_data"]:
                item["unpacked_data"]["message_data"] = inject_normalized_quantity(  # noqa
                    item["unpacked_data"]["message_data"], field_name, asset_info
                )
            if "dispenser" in item and field_name in item["dispenser"]:
                item["dispenser"] = inject_normalized_quantity(  # noqa
                    item["dispenser"], field_name, asset_info
                )

        if "get_quantity" in item and "give_quantity" in item and "market_dir" in item:
            if item["market_dir"] == "SELL":
                item["market_price"] = helpers.divide(
                    item["get_quantity_normalized"], item["give_quantity_normalized"]
                )
            else:
                item["market_price"] = helpers.divide(
                    item["give_quantity_normalized"], item["get_quantity_normalized"]
                )

        enriched_result_list.append(item)

    return enriched_result_list


def inject_fiat_price(ledger_db, dispenser):
    if "satoshirate" not in dispenser:
        return dispenser
    if dispenser["oracle_address"] != None:  # noqa: E711
        dispenser["fiat_price"] = helpers.satoshirate_to_fiat(dispenser["satoshirate"])
        (
            dispenser["oracle_price"],
            _oracle_fee,
            dispenser["fiat_unit"],
            dispenser["oracle_price_last_updated"],
        ) = ledger.other.get_oracle_last_price(
            ledger_db, dispenser["oracle_address"], CurrentState().current_block_index()
        )

        if dispenser["oracle_price"] > 0:
            dispenser["satoshi_price"] = math.ceil(
                (dispenser["fiat_price"] / dispenser["oracle_price"]) * config.UNIT
            )
        else:
            raise exceptions.APIError("Last oracle price is zero")
    else:
        dispenser["fiat_price"] = None
        dispenser["oracle_price"] = None
        dispenser["fiat_unit"] = None
        dispenser["oracle_price_last_updated"] = None
        dispenser["satoshi_price"] = dispenser["satoshirate"]
    return dispenser


def inject_fiat_prices(ledger_db, result_list):
    enriched_result_list = []
    for result_item in result_list:
        enriched_result_list.append(inject_fiat_price(ledger_db, result_item))
    return enriched_result_list


def inject_dispensers(ledger_db, state_db, result_list):
    # gather dispenser list
    dispenser_list = []
    for result_item in result_list:
        if "dispenser_tx_hash" in result_item:
            if result_item["dispenser_tx_hash"] not in dispenser_list:
                dispenser_list.append(result_item["dispenser_tx_hash"])

    # get dispenser info
    dispenser_info = ledger.markets.get_dispensers_info(state_db, dispenser_list)

    # inject dispenser info
    enriched_result_list = []
    for result_item in result_list:
        if (
            "dispenser_tx_hash" in result_item
            and result_item["dispenser_tx_hash"] in dispenser_info
        ):
            result_item["dispenser"] = inject_fiat_price(
                ledger_db, dispenser_info[result_item["dispenser_tx_hash"]]
            )
        enriched_result_list.append(result_item)

    return enriched_result_list


def inject_unpacked_data_in_dict(ledger_db, item):
    if "data" in item:
        data = binascii.hexlify(item["data"]) if isinstance(item["data"], bytes) else item["data"]
        if data:
            block_index = item.get("block_index")
            item["unpacked_data"] = compose.unpack(ledger_db, data, block_index=block_index)
    return item


def inject_unpacked_data(ledger_db, result_list):
    enriched_result_list = []
    for result_item in result_list:
        result_item = inject_unpacked_data_in_dict(ledger_db, result_item)  # noqa PLW2901
        if "params" in result_item:
            result_item["params"] = inject_unpacked_data_in_dict(ledger_db, result_item["params"])
        enriched_result_list.append(result_item)
    return enriched_result_list


def inject_transactions_events(ledger_db, state_db, result_list):
    if len(result_list) == 0:
        return result_list
    if "tx_hash" not in result_list[0]:
        return result_list

    cursor = ledger_db.cursor()

    transaction_hashes = [tx["tx_hash"] for tx in result_list]
    exclude_events = [
        "NEW_TRANSACTION",
        "TRANSACTION_PARSED",
        "CREDIT",
        "DEBIT",
        "INCREMENT_TRANSACTION_COUNT",
        "NEW_TRANSACTION_OUTPUT",
    ]
    sql = f"""
        SELECT message_index AS event_index, event, bindings AS params, tx_hash, block_index 
        FROM messages 
        WHERE tx_hash IN ({",".join("?" * len(transaction_hashes))}) 
        AND event NOT IN ({",".join("?" * len(exclude_events))})
    """  # noqa S608
    events = cursor.execute(sql, transaction_hashes + exclude_events).fetchall()
    for event in events:
        event["params"] = json.loads(event["params"])

    events = inject_dispensers(ledger_db, state_db, events)
    events = inject_fiat_prices(ledger_db, events)
    events = inject_issuances_and_block_times(ledger_db, state_db, events)
    events = inject_normalized_quantities(events)

    events_by_tx_hash = {}
    for event in events:
        if event["tx_hash"] not in events_by_tx_hash:
            events_by_tx_hash[event["tx_hash"]] = []
        events_by_tx_hash[event["tx_hash"]].append(event)
    for result_item in result_list:
        result_item["events"] = events_by_tx_hash.get(result_item["tx_hash"], [])
    return result_list


def inject_details(ledger_db, state_db, result, table=None):
    if isinstance(result, (int, str)):
        return result
    # let's work with a list
    result_list = result
    result_is_dict = False
    if isinstance(result, dict):
        result_list = [result]
        result_is_dict = True

    if table == "transactions":
        result_list = inject_transactions_events(ledger_db, state_db, result_list)
        result_list = inject_unpacked_data(ledger_db, result_list)

    result_list = inject_dispensers(ledger_db, state_db, result_list)
    result_list = inject_fiat_prices(ledger_db, result_list)
    result_list = inject_issuances_and_block_times(ledger_db, state_db, result_list)
    result_list = inject_normalized_quantities(result_list)

    if result_is_dict:
        result = result_list[0]
    else:
        result = result_list

    return result


def clean_rowids_and_confirmed_fields(query_result):
    """Remove the rowid field from the query result."""
    if isinstance(query_result, list):
        filtered_results = []
        for row in list(query_result):
            if "rowid" in row:
                del row["rowid"]
            if "MAX(rowid)" in row:
                del row["MAX(rowid)"]
            if "block_index" in row and row["block_index"] in [0, config.MEMPOOL_BLOCK_INDEX]:
                row["block_index"] = None
                if "tx_index" in row:
                    row["tx_index"] = None
            filtered_results.append(row)
        return filtered_results
    if isinstance(query_result, dict):
        filtered_results = query_result
        if "rowid" in filtered_results:
            del filtered_results["rowid"]
        if "MAX(rowid)" in filtered_results:
            del filtered_results["MAX(rowid)"]
        if "block_index" in filtered_results and filtered_results["block_index"] in [
            0,
            config.MEMPOOL_BLOCK_INDEX,
        ]:
            filtered_results["block_index"] = None
            if "tx_index" in filtered_results:
                filtered_results["tx_index"] = None
        return filtered_results
    return query_result
