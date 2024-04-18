from counterpartycore.lib import (
    backend,
    config,
    ledger,
    transaction,
)
from counterpartycore.lib.api import util

# Define the API routes except root (`/`) defined in `api_server.py`
ROUTES = {
    ### /blocks ###
    "/blocks": ledger.get_blocks,
    "/blocks/<int:block_index>": ledger.get_block,
    "/blocks/<int:block_index>/transactions": ledger.get_transactions_by_block,
    "/blocks/<int:block_index>/events": ledger.get_events_by_block,
    "/blocks/<int:block_index>/events/counts": ledger.get_events_counts_by_block,
    "/blocks/<int:block_index>/events/<event>": ledger.get_events_by_block_and_event,
    "/blocks/<int:block_index>/credits": ledger.get_credits_by_block,
    "/blocks/<int:block_index>/debits": ledger.get_debits_by_block,
    "/blocks/<int:block_index>/expirations": ledger.get_expirations,
    "/blocks/<int:block_index>/cancels": ledger.get_cancels,
    "/blocks/<int:block_index>/destructions": ledger.get_destructions,
    "/blocks/<int:block_index>/issuances": ledger.get_issuances_by_block,
    "/blocks/<int:block_index>/sends": ledger.get_sends_or_receives_by_block,
    "/blocks/<int:block_index>/dispenses": ledger.get_dispenses_by_block,
    "/blocks/<int:block_index>/sweeps": ledger.get_sweeps_by_block,
    ### /transactions ###
    "/transactions/info": transaction.info,
    "/transactions/unpack": transaction.unpack,
    "/transactions/<tx_hash>": ledger.get_transaction,
    ### /addresses ###
    "/addresses/<address>/balances": ledger.get_address_balances,
    "/addresses/<address>/balances/<asset>": ledger.get_balance_object,
    "/addresses/<address>/credits": ledger.get_credits_by_address,
    "/addresses/<address>/debits": ledger.get_debits_by_address,
    "/addresses/<address>/bets": ledger.get_bet_by_feed,
    "/addresses/<address>/broadcasts": ledger.get_broadcasts_by_source,
    "/addresses/<address>/burns": ledger.get_burns,
    "/addresses/<address>/sends": ledger.get_send_by_address,
    "/addresses/<address>/receives": ledger.get_receive_by_address,
    "/addresses/<address>/sends/<asset>": ledger.get_send_by_address_and_asset,
    "/addresses/<address>/receives/<asset>": ledger.get_receive_by_address_and_asset,
    "/addresses/<address>/dispensers": ledger.get_dispensers_by_address,
    "/addresses/<address>/dispensers/<asset>": ledger.get_dispensers_by_address_and_asset,
    "/addresses/<address>/sweeps": ledger.get_sweeps_by_address,
    ### /assets ###
    "/assets": {
        "function": ledger.get_valid_assets,
    },
    "/assets/<asset>": {
        "function": ledger.get_asset_info,
    },
    "/assets/<asset>/balances": {
        "function": ledger.get_asset_balances,
    },
    "/assets/<asset>/balances/<address>": {
        "function": ledger.get_balance_object,
    },
    "/assets/<asset>/orders": {
        "function": ledger.get_orders_by_asset,
        "args": [("status", str, "open")],
    },
    "/assets/<asset>/credits": {
        "function": ledger.get_credits,
    },
    "/assets/<asset>/debits": {
        "function": ledger.get_debits,
    },
    "/assets/<asset>/dividends": {
        "function": ledger.get_dividends,
    },
    "/assets/<asset>/issuances": {
        "function": ledger.get_issuances,
    },
    "/assets/<asset>/sends": {
        "function": ledger.get_sends_or_receives,
    },
    "/assets/<asset>/dispensers": ledger.get_dispensers_by_asset,
    "/assets/<asset>/dispensers/<address>": {
        "function": ledger.get_dispensers,
        "args": [("status", int, 0)],
    },
    "/assets/<asset>/holders": {
        "function": ledger.get_asset_holders,
    },
    ### /orders ###
    "/orders/<tx_hash>": {
        "function": ledger.get_order,
    },
    "/orders/<tx_hash>/matches": {
        "function": ledger.get_order_matches_by_order,
        "args": [("status", str, "pending")],
    },
    "/orders/<tx_hash>/btcpays": {
        "function": ledger.get_btcpays_by_order,
        "args": [("status", str, "pending")],
    },
    ### /bets ###
    "/bets/<tx_hash>": {
        "function": ledger.get_bet,
    },
    "/bets/<tx_hash>/matches": {
        "function": ledger.get_bet_matches_by_bet,
        "args": [("status", str, "pending")],
    },
    "/bets/<tx_hash>/resolutions": {
        "function": ledger.get_resolutions_by_bet,
        "args": [("status", str, "pending")],
    },
    ### /burns ###
    "/burns": {
        "function": ledger.get_burns,
    },
    ### /dispensers ###
    "/dispensers/<tx_hash>": {
        "function": ledger.get_dispenser_info,
    },
    "/dispensers/<tx_hash>/dispenses": {
        "function": ledger.get_dispenses,
    },
    ### /events ###
    "/events": {
        "function": ledger.get_events,
        "args": [("last", int, None), ("limit", int, 100)],
    },
    "/events/<int:event_index>": {
        "function": ledger.get_events,
    },
    "/events/counts": {
        "function": ledger.get_events_counts,
    },
    "/events/<event>": {
        "function": ledger.get_events,
        "args": [("last", int, None), ("limit", int, 100)],
    },
    ### /healthz ###
    "/healthz": {
        "function": util.handle_healthz_route,
        "args": [("check_type", str, "heavy")],
    },
    ### /backend ###
    "/backend/addresses/<address>/transactions": {
        "function": backend.search_raw_transactions,
        "args": [("unconfirmed", bool, True), ("only_tx_hashes", bool, False)],
    },
    "/backend/addresses/<address>/transactions/oldest": {
        "function": backend.get_oldest_tx,
    },
    "/backend/addresses/<address>/utxos": {
        "function": backend.get_unspent_txouts,
        "args": [("unconfirmed", bool, True), ("unspent_tx_hash", str, None)],
    },
    "/backend/addresses/<address>/pubkey": {
        "function": util.pubkeyhash_to_pubkey,
        "args": [("provided_pubkeys", str, "")],
    },
    "/backend/transactions": {
        "function": util.getrawtransactions,
        "args": [("tx_hashes", str, ""), ("verbose", bool, False), ("skip_missing", bool, False)],
    },
    "/backend/transactions/<tx_hash>": {
        "function": backend.getrawtransaction,
        "args": [("verbose", bool, False), ("skip_missing", bool, False)],
    },
    "/backend/estimatesmartfee": {
        "function": backend.fee_per_kb,
        "args": [
            ("conf_target", int, config.ESTIMATE_FEE_CONF_TARGET),
            ("mode", str, config.ESTIMATE_FEE_MODE),
        ],
    },
    ### /mempool ###
    "/mempool/events": {
        "function": ledger.get_mempool_events,
    },
    "/mempool/events/<event>": {
        "function": ledger.get_mempool_events,
    },
}

for path, route in ROUTES.items():
    if not isinstance(route, dict):
        ROUTES[path] = {
            "function": route,
        }

# Add compose routes for each transaction type
### /address/<source>/compose/<transaction_name> ###
for transaction_name, compose_function in transaction.COMPOSE_FUNCTIONS.items():
    ROUTES[f"/address/<source>/compose/{transaction_name}"] = {
        "function": compose_function,
        "pass_all_args": True,
    }

# Add description and args to each route
for path, route in ROUTES.items():
    if "/compose/" in path:
        continue
    ROUTES[path]["description"] = util.get_function_description(route["function"])
    ROUTES[path]["args"] = util.prepare_route_args(route["function"])
