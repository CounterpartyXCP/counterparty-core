from counterpartylib.lib import (
    backend,
    config,
    ledger,
    transaction,
)
from counterpartylib.lib.api import util

ROUTES = {
    ### /blocks ###
    "/blocks": {
        "function": ledger.get_blocks,
        "args": [("last", None), ("limit", 10)],
    },
    "/blocks/<int:block_index>": {
        "function": ledger.get_block,
    },
    "/blocks/<int:block_index>/transactions": {
        "function": ledger.get_transactions_by_block,
    },
    "/blocks/<int:block_index>/events": {
        "function": ledger.get_events,
    },
    "/blocks/<int:block_index>/events/counts": {
        "function": ledger.get_events_counts,
    },
    "/blocks/<int:block_index>/events/<event>": {
        "function": ledger.get_events,
    },
    "/blocks/mempool/events": {
        "function": ledger.get_mempool_events,
    },
    "/blocks/mempool/events/<event>": {
        "function": ledger.get_mempool_events,
    },
    "/blocks/<int:block_index>/credits": {
        "function": ledger.get_credits,
    },
    "/blocks/<int:block_index>/debits": {
        "function": ledger.get_debits,
    },
    "/blocks/<int:block_index>/expirations": {
        "function": ledger.get_expirations,
    },
    "/blocks/<int:block_index>/cancels": {
        "function": ledger.get_cancels,
    },
    "/blocks/<int:block_index>/destructions": {
        "function": ledger.get_destructions,
    },
    "/blocks/<int:block_index>/issuances": {
        "function": ledger.get_issuances,
    },
    "/blocks/<int:block_index>/sends": {
        "function": ledger.get_sends_or_receives,
    },
    "/blocks/<int:block_index>/dispenses": {
        "function": ledger.get_dispenses,
    },
    "/blocks/<int:block_index>/sweeps": {
        "function": ledger.get_sweeps,
    },
    ### /transactions ###
    "/transactions/compose/<transaction_name>": {
        "function": transaction.compose,
        "pass_all_args": True,
    },
    "/transactions/info": {
        "function": transaction.info,
        "args": [("rawtransaction", None), ("block_index", None)],
    },
    "/transactions/<tx_hash>": {
        "function": ledger.get_transaction,
    },
    ### /addresses ###
    "/addresses/<address>/balances": {
        "function": ledger.get_address_balances,
    },
    "/addresses/<address>/balances/<asset>": {
        "function": ledger.get_balance_object,
    },
    "/addresses/<address>/credits": {
        "function": ledger.get_credits,
    },
    "/addresses/<address>/debits": {
        "function": ledger.get_debits,
    },
    "/addresses/<address>/bets": {
        "function": ledger.get_bet_by_feed,
        "args": [("status", "open")],
    },
    "/addresses/<address>/broadcasts": {
        "function": ledger.get_broadcasts_by_source,
    },
    "/addresses/<address>/burns": {
        "function": ledger.get_burns,
    },
    "/addresses/<address>/sends": {
        "function": ledger.get_sends,
    },
    "/addresses/<address>/receives": {
        "function": ledger.get_receives,
    },
    "/addresses/<address>/sends/<asset>": {
        "function": ledger.get_sends,
    },
    "/addresses/<address>/receives/<asset>": {
        "function": ledger.get_receives,
    },
    "/addresses/<address>/dispensers": {
        "function": ledger.get_dispensers,
        "args": [("status", 0)],
    },
    "/addresses/<address>/dispensers/<asset>": {
        "function": ledger.get_dispensers,
        "args": [("status", 0)],
    },
    "/addresses/<address>/sweeps": {
        "function": ledger.get_sweeps,
    },
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
        "args": [("status", "open")],
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
    "/assets/<asset>/dispensers": {
        "function": ledger.get_dispensers,
        "args": [("status", 0)],
    },
    "/assets/<asset>/dispensers/<address>": {
        "function": ledger.get_dispensers,
        "args": [("status", 0)],
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
        "args": [("status", "pending")],
    },
    "/orders/<tx_hash>/btcpays": {
        "function": ledger.get_btcpays_by_order,
        "args": [("status", "pending")],
    },
    ### /bets ###
    "/bets/<tx_hash>": {
        "function": ledger.get_bet,
    },
    "/bets/<tx_hash>/matches": {
        "function": ledger.get_bet_matches_by_bet,
        "args": [("status", "pending")],
    },
    "/bets/<tx_hash>/resolutions": {
        "function": ledger.get_resolutions_by_bet,
        "args": [("status", "pending")],
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
        "args": [("last", None), ("limit", 100)],
    },
    "/events/<int:event_index>": {
        "function": ledger.get_events,
    },
    "/events/counts": {
        "function": ledger.get_events_counts,
    },
    "/events/<event>": {
        "function": ledger.get_events,
        "args": [("last", None), ("limit", 100)],
    },
    ### /healthz ###
    "/healthz": {
        "function": util.handle_healthz_route,
        "args": [("check", "heavy")],
    },
    ### /backend ###
    "/backend/addresses/<address>/transactions": {
        "function": backend.search_raw_transactions,
        "args": [("unconfirmed", True), ("only_tx_hashes", False)],
    },
    "/backend/addresses/<address>/transactions/oldest": {
        "function": backend.get_oldest_tx,
    },
    "/backend/addresses/<address>/utxos": {
        "function": backend.get_unspent_txouts,
        "args": [("unconfirmed", True), ("unspent_tx_hash", None)],
    },
    "/backend/addresses/<address>/pubkey": {
        "function": util.pubkeyhash_to_pubkey,
        "args": [("provided_pubkeys", "")],
    },
    "/backend/transactions": {
        "function": util.getrawtransactions,
        "args": [("tx_hashes", ""), ("verbose", False), ("skip_missing", False)],
    },
    "/backend/transactions/<tx_hash>": {
        "function": backend.getrawtransaction,
        "args": [("verbose", False), ("skip_missing", False)],
    },
    "/backend/estimatesmartfee": {
        "function": backend.fee_per_kb,
        "args": [
            ("conf_target", config.ESTIMATE_FEE_CONF_TARGET),
            ("mode", config.ESTIMATE_FEE_MODE),
        ],
    },
}
