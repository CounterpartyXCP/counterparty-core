import inspect
import typing

from docstring_parser import parse as parse_docstring

from counterpartycore.lib.api import apiv1, compose, composer, healthz, queries
from counterpartycore.lib.backend import bitcoind, electrs


def get_routes():
    """Return the API routes."""
    return ROUTES


ALL_ROUTES = {
    ### /blocks ###
    "/v2/blocks": queries.get_blocks,
    "/v2/blocks/last": queries.get_last_block,
    "/v2/blocks/<int:block_index>": queries.get_block_by_height,
    "/v2/blocks/<block_hash>": queries.get_block_by_hash,
    "/v2/blocks/<int:block_index>/transactions": queries.get_transactions_by_block,
    "/v2/blocks/<int:block_index>/transactions/counts": queries.get_transaction_types_count_by_block,
    "/v2/blocks/<int:block_index>/events": queries.get_events_by_block,
    "/v2/blocks/<int:block_index>/events/counts": queries.get_event_counts_by_block,
    "/v2/blocks/<int:block_index>/events/<event>": queries.get_events_by_block_and_event,
    "/v2/blocks/<int:block_index>/credits": queries.get_credits_by_block,
    "/v2/blocks/<int:block_index>/debits": queries.get_debits_by_block,
    "/v2/blocks/<int:block_index>/expirations": queries.get_expirations,
    "/v2/blocks/<int:block_index>/cancels": queries.get_cancels,
    "/v2/blocks/<int:block_index>/destructions": queries.get_valid_destructions_by_block,
    "/v2/blocks/<int:block_index>/issuances": queries.get_issuances_by_block,
    "/v2/blocks/<int:block_index>/sends": queries.get_sends_by_block,
    "/v2/blocks/<int:block_index>/dispenses": queries.get_dispenses_by_block,
    "/v2/blocks/<int:block_index>/sweeps": queries.get_sweeps_by_block,
    "/v2/blocks/<int:block_index>/fairminters": queries.get_fairminters_by_block,
    "/v2/blocks/<int:block_index>/fairmints": queries.get_fairmints_by_block,
    ### /transactions ###
    "/v2/transactions": queries.get_transactions,
    "/v2/transactions/counts": queries.get_transaction_types_count,
    "/v2/transactions/info": compose.info,
    "/v2/transactions/<tx_hash>/info": compose.info_by_tx_hash,
    "/v2/transactions/unpack": compose.unpack,
    "/v2/transactions/<int:tx_index>": queries.get_transaction_by_tx_index,
    "/v2/transactions/<tx_hash>": queries.get_transaction_by_hash,
    "/v2/transactions/<int:tx_index>/events": queries.get_events_by_transaction_index,
    "/v2/transactions/<tx_hash>/events": queries.get_events_by_transaction_hash,
    "/v2/transactions/<tx_hash>/sends": queries.get_sends_by_transaction_hash,
    "/v2/transactions/<tx_hash>/dispenses": queries.get_dispenses_by_transaction_hash,
    "/v2/transactions/<int:tx_index>/events/<event>": queries.get_events_by_transaction_index_and_event,
    "/v2/transactions/<tx_hash>/events/<event>": queries.get_events_by_transaction_hash_and_event,
    ### /addresses ###
    "/v2/addresses/balances": queries.get_balances_by_addresses,
    "/v2/addresses/transactions": queries.get_transactions_by_addresses,
    "/v2/addresses/events": queries.get_events_by_addresses,
    "/v2/addresses/mempool": queries.get_mempool_events_by_addresses,
    "/v2/addresses/<address>/balances": queries.get_address_balances,
    "/v2/addresses/<address>/balances/<asset>": queries.get_balances_by_address_and_asset,
    "/v2/addresses/<address>/credits": queries.get_credits_by_address,
    "/v2/addresses/<address>/debits": queries.get_debits_by_address,
    "/v2/addresses/<address>/bets": queries.get_bet_by_feed,
    "/v2/addresses/<address>/broadcasts": queries.get_broadcasts_by_source,
    "/v2/addresses/<address>/burns": queries.get_burns_by_address,
    "/v2/addresses/<address>/sends": queries.get_sends_by_address,
    "/v2/addresses/<address>/receives": queries.get_receive_by_address,
    "/v2/addresses/<address>/sends/<asset>": queries.get_sends_by_address_and_asset,
    "/v2/addresses/<address>/receives/<asset>": queries.get_receive_by_address_and_asset,
    "/v2/addresses/<address>/destructions": queries.get_valid_destructions_by_address,
    "/v2/addresses/<address>/dispensers": queries.get_dispensers_by_address,
    "/v2/addresses/<address>/dispensers/<asset>": queries.get_dispenser_by_address_and_asset,
    "/v2/addresses/<address>/dispenses/sends": queries.get_dispenses_by_source,
    "/v2/addresses/<address>/dispenses/receives": queries.get_dispenses_by_destination,
    "/v2/addresses/<address>/dispenses/sends/<asset>": queries.get_dispenses_by_source_and_asset,
    "/v2/addresses/<address>/dispenses/receives/<asset>": queries.get_dispenses_by_destination_and_asset,
    "/v2/addresses/<address>/sweeps": queries.get_sweeps_by_address,
    "/v2/addresses/<address>/issuances": queries.get_issuances_by_address,
    "/v2/addresses/<address>/assets": queries.get_valid_assets_by_issuer_or_owner,
    "/v2/addresses/<address>/assets/issued": queries.get_valid_assets_by_issuer,
    "/v2/addresses/<address>/assets/owned": queries.get_valid_assets_by_owner,
    "/v2/addresses/<address>/transactions": queries.get_transactions_by_address,
    "/v2/addresses/<address>/transactions/counts": queries.get_transaction_types_count_by_address,
    "/v2/addresses/<address>/dividends": queries.get_dividends_distributed_by_address,
    "/v2/addresses/<address>/orders": queries.get_orders_by_address,
    "/v2/addresses/<address>/fairminters": queries.get_fairminters_by_address,
    "/v2/addresses/<address>/fairmints": queries.get_fairmints_by_address,
    "/v2/addresses/<address>/fairmints/<asset>": queries.get_fairmints_by_address_and_asset,
    "/v2/utxos/<utxo>/balances": queries.get_utxo_balances,
    "/v2/utxos/withbalances": queries.utxos_with_balances,
    ### /addresses/<address>/compose/ ###
    "/v2/addresses/<address>/compose/bet": compose.compose_bet,
    "/v2/addresses/<address>/compose/broadcast": compose.compose_broadcast,
    "/v2/addresses/<address>/compose/btcpay": compose.compose_btcpay,
    "/v2/addresses/<address>/compose/burn": compose.compose_burn,
    "/v2/addresses/<address>/compose/cancel": compose.compose_cancel,
    "/v2/addresses/<address>/compose/destroy": compose.compose_destroy,
    "/v2/addresses/<address>/compose/dispenser": compose.compose_dispenser,
    "/v2/addresses/<address>/compose/dividend": compose.compose_dividend,
    "/v2/addresses/<address>/compose/dividend/estimatexcpfees": compose.get_dividend_estimate_xcp_fee,
    "/v2/addresses/<address>/compose/issuance": compose.compose_issuance,
    "/v2/addresses/<address>/compose/mpma": compose.compose_mpma,
    "/v2/addresses/<address>/compose/order": compose.compose_order,
    "/v2/addresses/<address>/compose/send": compose.compose_send,
    "/v2/addresses/<address>/compose/sweep": compose.compose_sweep,
    "/v2/addresses/<address>/compose/sweep/estimatexcpfees": compose.get_sweep_estimate_xcp_fee,
    "/v2/addresses/<address>/compose/dispense": compose.compose_dispense,
    "/v2/addresses/<address>/compose/fairminter": compose.compose_fairminter,
    "/v2/addresses/<address>/compose/fairmint": compose.compose_fairmint,
    "/v2/addresses/<address>/compose/attach": compose.compose_attach,
    "/v2/addresses/<address>/compose/attach/estimatexcpfees": compose.get_attach_estimate_xcp_fee,
    "/v2/utxos/<utxo>/compose/detach": compose.compose_detach,
    "/v2/utxos/<utxo>/compose/movetoutxo": compose.compose_movetoutxo,
    "/v2/compose/attach/estimatexcpfees": compose.get_attach_estimate_xcp_fee,
    ### /assets ###
    "/v2/assets": queries.get_valid_assets,
    "/v2/assets/<asset>": queries.get_asset,
    "/v2/assets/<asset>/balances": queries.get_asset_balances,
    "/v2/assets/<asset>/balances/<address>": queries.get_balances_by_asset_and_address,
    "/v2/assets/<asset>/orders": queries.get_orders_by_asset,
    "/v2/assets/<asset>/matches": queries.get_order_matches_by_asset,
    "/v2/assets/<asset>/credits": queries.get_credits_by_asset,
    "/v2/assets/<asset>/debits": queries.get_debits_by_asset,
    "/v2/assets/<asset>/destructions": queries.get_valid_destructions_by_asset,
    "/v2/assets/<asset>/dividends": queries.get_dividends_by_asset,
    "/v2/assets/<asset>/issuances": queries.get_issuances_by_asset,
    "/v2/assets/<asset>/sends": queries.get_sends_by_asset,
    "/v2/assets/<asset>/dispensers": queries.get_dispensers_by_asset,
    "/v2/assets/<asset>/dispensers/<address>": queries.get_dispenser_by_address_and_asset,
    "/v2/assets/<asset>/holders": queries.get_asset_holders,
    "/v2/assets/<asset>/dispenses": queries.get_dispenses_by_asset,
    "/v2/assets/<asset>/subassets": queries.get_subassets_by_asset,
    "/v2/assets/<asset>/fairminters": queries.get_fairminters_by_asset,
    "/v2/assets/<asset>/fairmints": queries.get_fairmints_by_asset,
    "/v2/assets/<asset>/fairmints/<address>": queries.get_fairmints_by_address_and_asset,
    ### /orders ###
    "/v2/orders": queries.get_orders,
    "/v2/orders/<order_hash>": queries.get_order,
    "/v2/orders/<order_hash>/matches": queries.get_order_matches_by_order,
    "/v2/orders/<order_hash>/btcpays": queries.get_btcpays_by_order,
    "/v2/orders/<asset1>/<asset2>": queries.get_orders_by_two_assets,
    "/v2/orders/<asset1>/<asset2>/matches": queries.get_order_matches_by_two_assets,
    "/v2/order_matches": queries.get_all_order_matches,
    ### /bets ###
    "/v2/bets": queries.get_bets,
    "/v2/bets/<bet_hash>": queries.get_bet,
    "/v2/bets/<bet_hash>/matches": queries.get_bet_matches_by_bet,
    "/v2/bets/<bet_hash>/resolutions": queries.get_resolutions_by_bet,
    ### /burns ###
    "/v2/burns": queries.get_all_burns,
    ### /dispensers ###
    "/v2/dispensers": queries.get_dispensers,
    "/v2/dispensers/<dispenser_hash>": queries.get_dispenser_info_by_hash,
    "/v2/dispensers/<dispenser_hash>/dispenses": queries.get_dispenses_by_dispenser,
    ### /dividends ###
    "/v2/dividends": queries.get_dividends,
    "/v2/dividends/<dividend_hash>": queries.get_dividend,
    "/v2/dividends/<dividend_hash>/credits": queries.get_dividend_disribution,
    ### /events ###
    "/v2/events": queries.get_all_events,
    "/v2/events/<int:event_index>": queries.get_event_by_index,
    "/v2/events/counts": queries.get_all_events_counts,
    "/v2/events/<event>": queries.get_events_by_name,
    "/v2/events/<event>/count": queries.get_event_count,
    ### destructions ###
    "/v2/destructions": queries.get_all_valid_destructions,
    ### /dispenses ###
    "/v2/dispenses": queries.get_dispenses,
    "/v2/dispenses/<tx_hash>": queries.get_dispense,
    ### /sends ###
    "/v2/sends": queries.get_sends,
    ### /issuances ###
    "/v2/issuances": queries.get_issuances,
    "/v2/issuances/<tx_hash>": queries.get_issuance_by_transaction_hash,
    ### /sweeps ###
    "/v2/sweeps": queries.get_sweeps,
    "/v2/sweeps/<tx_hash>": queries.get_sweep_by_transaction_hash,
    ### /broadcasts ###
    "/v2/broadcasts": queries.get_valid_broadcasts,
    "/v2/broadcasts/<tx_hash>": queries.get_broadcast_by_transaction_hash,
    ### /fairminters ###
    "/v2/fairminters": queries.get_all_fairminters,
    "/v2/fairminters/<tx_hash>": queries.get_fairminter,
    "/v2/fairminters/<tx_hash>/fairmints": queries.get_fairmints_by_fairminter,
    ### /fairmints ###
    "/v2/fairmints": queries.get_all_fairmints,
    "/v2/fairmints/<tx_hash>": queries.get_fairmint,
    ### /bitcoin ###
    "/v2/bitcoin/addresses/utxos": electrs.get_utxos_by_addresses,
    "/v2/bitcoin/addresses/<address>/transactions": electrs.get_history,
    "/v2/bitcoin/addresses/<address>/utxos": electrs.get_utxos,
    "/v2/bitcoin/addresses/<address>/pubkey": electrs.pubkeyhash_to_pubkey,
    "/v2/bitcoin/transactions/<tx_hash>": bitcoind.get_transaction,
    "/v2/bitcoin/estimatesmartfee": bitcoind.fee_per_kb,
    "/v2/bitcoin/transactions": bitcoind.sendrawtransaction,
    "/v2/bitcoin/transactions/decode": bitcoind.decoderawtransaction,
    "/v2/bitcoin/getmempoolinfo": bitcoind.get_mempool_info,
    ### /mempool ###
    "/v2/mempool/events": queries.get_all_mempool_events,
    "/v2/mempool/events/<event>": queries.get_mempool_events_by_name,
    "/v2/mempool/transactions/<tx_hash>/events": queries.get_mempool_events_by_tx_hash,
    ### /routes ###
    "/v2/routes": get_routes,
    ### /healthz ###
    "/v2/healthz": healthz.check_server_health,
    "/healthz": healthz.check_server_health,
    ### API v1 ###
    "/": apiv1.redirect_to_rpc_v1,
    "/v1/": apiv1.redirect_to_rpc_v1,
    "/api/": apiv1.redirect_to_rpc_v1,
    "/rpc/": apiv1.redirect_to_rpc_v1,
}


def get_args_description(function):
    docstring = parse_docstring(function.__doc__)
    args = {}
    for param in docstring.params:
        args[param.arg_name] = param.description
    return args


def function_needs_db(function):
    dbs = []
    parameters = inspect.signature(function).parameters
    if "ledger_db" in parameters or "db" in parameters:
        dbs.append("ledger_db")
    if "state_db" in parameters:
        dbs.append("state_db")
    return " ".join(dbs)


def prepare_route_args(function):
    args = []
    function_args = inspect.signature(function).parameters
    args_description = get_args_description(function)
    for arg_name, arg in function_args.items():
        if arg_name == "construct_params":
            for carg_name, carg_info in composer.CONSTRUCT_PARAMS.items():
                args.append(
                    {
                        "name": carg_name,
                        "type": carg_info[0].__name__,
                        "default": carg_info[1],
                        "description": carg_info[2],
                        "required": False,
                    }
                )
            continue
        annotation = arg.annotation
        if annotation is inspect.Parameter.empty:
            continue
        route_arg = {"name": arg_name}
        default = arg.default
        if default is not inspect.Parameter.empty:
            route_arg["default"] = default
            route_arg["required"] = False
        else:
            route_arg["required"] = True
        route_arg["type"] = arg.annotation.__name__
        if route_arg["type"] == "Literal":
            route_arg["type"] = "enum[str]"
            route_arg["members"] = list(typing.get_args(annotation))
        if arg_name in args_description:
            route_arg["description"] = args_description[arg_name]
        args.append(route_arg)
    if not function.__name__.endswith("_v1"):
        args.append(
            {
                "name": "verbose",
                "type": "bool",
                "default": "false",
                "description": "Include asset and dispenser info and normalized quantities in the response.",
                "required": False,
            }
        )
    return args


def get_function_description(function):
    docstring = parse_docstring(function.__doc__)
    return docstring.description


def prepare_routes(routes):
    prepared_routes = {}
    for route, function in routes.items():
        prepared_routes[route] = {
            "function": function,
            "description": get_function_description(function),
            "args": prepare_route_args(function),
        }
    return prepared_routes


# Define the API routes except root (`/`) defined in `apiserver.py`
ROUTES = prepare_routes(ALL_ROUTES)
