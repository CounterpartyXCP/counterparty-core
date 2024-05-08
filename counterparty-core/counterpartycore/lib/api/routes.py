from counterpartycore.lib import (
    backend,
    ledger,
    transaction,
)
from counterpartycore.lib.api import util
from counterpartycore.lib.backend import bitcoind

# Define the API routes except root (`/`) defined in `api_server.py`
ROUTES = util.prepare_routes(
    {
        ### /blocks ###
        "/v2/blocks": ledger.get_blocks,
        "/v2/blocks/<int:block_index>": ledger.get_block,
        "/v2/blocks/<int:block_index>/transactions": ledger.get_transactions_by_block,
        "/v2/blocks/<int:block_index>/events": ledger.get_events_by_block,
        "/v2/blocks/<int:block_index>/events/counts": ledger.get_event_counts_by_block,
        "/v2/blocks/<int:block_index>/events/<event>": ledger.get_events_by_block_and_event,
        "/v2/blocks/<int:block_index>/credits": ledger.get_credits_by_block,
        "/v2/blocks/<int:block_index>/debits": ledger.get_debits_by_block,
        "/v2/blocks/<int:block_index>/expirations": ledger.get_expirations,
        "/v2/blocks/<int:block_index>/cancels": ledger.get_cancels,
        "/v2/blocks/<int:block_index>/destructions": ledger.get_destructions,
        "/v2/blocks/<int:block_index>/issuances": ledger.get_issuances_by_block,
        "/v2/blocks/<int:block_index>/sends": ledger.get_sends_by_block,
        "/v2/blocks/<int:block_index>/dispenses": ledger.get_dispenses_by_block,
        "/v2/blocks/<int:block_index>/sweeps": ledger.get_sweeps_by_block,
        ### /transactions ###
        "/v2/transactions/info": transaction.info,
        "/v2/transactions/unpack": transaction.unpack,
        "/v2/transactions/<tx_hash>": transaction.get_transaction_by_hash,
        ### /addresses ###
        "/v2/addresses/<address>/balances": ledger.get_address_balances,
        "/v2/addresses/<address>/balances/<asset>": ledger.get_balance_by_address_and_asset,
        "/v2/addresses/<address>/credits": ledger.get_credits_by_address,
        "/v2/addresses/<address>/debits": ledger.get_debits_by_address,
        "/v2/addresses/<address>/bets": ledger.get_bet_by_feed,
        "/v2/addresses/<address>/broadcasts": ledger.get_broadcasts_by_source,
        "/v2/addresses/<address>/burns": ledger.get_burns_by_address,
        "/v2/addresses/<address>/sends": ledger.get_send_by_address,
        "/v2/addresses/<address>/receives": ledger.get_receive_by_address,
        "/v2/addresses/<address>/sends/<asset>": ledger.get_send_by_address_and_asset,
        "/v2/addresses/<address>/receives/<asset>": ledger.get_receive_by_address_and_asset,
        "/v2/addresses/<address>/dispensers": ledger.get_dispensers_by_address,
        "/v2/addresses/<address>/dispensers/<asset>": ledger.get_dispensers_by_address_and_asset,
        "/v2/addresses/<address>/sweeps": ledger.get_sweeps_by_address,
        ### /addresses/<address>/compose/ ###
        "/v2/addresses/<address>/compose/bet": transaction.compose_bet,
        "/v2/addresses/<address>/compose/broadcast": transaction.compose_broadcast,
        "/v2/addresses/<address>/compose/btcpay": transaction.compose_btcpay,
        "/v2/addresses/<address>/compose/burn": transaction.compose_burn,
        "/v2/addresses/<address>/compose/cancel": transaction.compose_cancel,
        "/v2/addresses/<address>/compose/destroy": transaction.compose_destroy,
        "/v2/addresses/<address>/compose/dispenser": transaction.compose_dispenser,
        "/v2/addresses/<address>/compose/dividend": transaction.compose_dividend,
        "/v2/addresses/<address>/compose/issuance": transaction.compose_issuance,
        "/v2/addresses/<address>/compose/mpma": transaction.compose_mpma,
        "/v2/addresses/<address>/compose/order": transaction.compose_order,
        "/v2/addresses/<address>/compose/send": transaction.compose_send,
        "/v2/addresses/<address>/compose/sweep": transaction.compose_sweep,
        ### /assets ###
        "/v2/assets": ledger.get_valid_assets,
        "/v2/assets/<asset>": ledger.get_asset_info,
        "/v2/assets/<asset>/balances": ledger.get_asset_balances,
        "/v2/assets/<asset>/balances/<address>": ledger.get_balance_by_address_and_asset,
        "/v2/assets/<asset>/orders": ledger.get_orders_by_asset,
        "/v2/assets/<asset>/credits": ledger.get_credits_by_asset,
        "/v2/assets/<asset>/debits": ledger.get_debits_by_asset,
        "/v2/assets/<asset>/dividends": ledger.get_dividends,
        "/v2/assets/<asset>/issuances": ledger.get_issuances_by_asset,
        "/v2/assets/<asset>/sends": ledger.get_sends_by_asset,
        "/v2/assets/<asset>/dispensers": ledger.get_dispensers_by_asset,
        "/v2/assets/<asset>/dispensers/<address>": ledger.get_dispensers_by_address_and_asset,
        "/v2/assets/<asset>/holders": ledger.get_asset_holders,
        ### /orders ###
        "/v2/orders/<order_hash>": ledger.get_order,
        "/v2/orders/<order_hash>/matches": ledger.get_order_matches_by_order,
        "/v2/orders/<order_hash>/btcpays": ledger.get_btcpays_by_order,
        "/v2/orders/<asset1>/<asset2>": ledger.get_orders_by_two_assets,
        ### /bets ###
        "/v2/bets/<bet_hash>": ledger.get_bet,
        "/v2/bets/<bet_hash>/matches": ledger.get_bet_matches_by_bet,
        "/v2/bets/<bet_hash>/resolutions": ledger.get_resolutions_by_bet,
        ### /burns ###
        "/v2/burns": ledger.get_all_burns,
        ### /dispensers ###
        "/v2/dispensers/<dispenser_hash>": ledger.get_dispenser_info_by_hash,
        "/v2/dispensers/<dispenser_hash>/dispenses": ledger.get_dispenses_by_dispenser,
        ### /events ###
        "/v2/events": ledger.get_all_events,
        "/v2/events/<int:event_index>": ledger.get_event_by_index,
        "/v2/events/counts": ledger.get_all_events_counts,
        "/v2/events/<event>": ledger.get_events_by_name,
        ### /healthz ###
        "/v2/healthz": util.check_server_health,
        ### /bitcoin ###
        "/v2/bitcoin/addresses/<address>/transactions": backend.get_transactions_by_address,
        "/v2/bitcoin/addresses/<address>/transactions/oldest": util.get_oldest_transaction_by_address,
        "/v2/bitcoin/addresses/<address>/utxos": backend.get_unspent_txouts,
        "/v2/bitcoin/addresses/<address>/pubkey": util.pubkeyhash_to_pubkey,
        "/v2/bitcoin/transactions/<tx_hash>": util.get_transaction,
        "/v2/bitcoin/estimatesmartfee": bitcoind.fee_per_kb,
        ### /mempool ###
        "/v2/mempool/events": ledger.get_all_mempool_events,
        "/v2/mempool/events/<event>": ledger.get_mempool_events_by_name,
        ### API v1 ###
        "/": util.redirect_to_api_v1,
        "/v1/<path:subpath>": util.redirect_to_api_v1,
        "/api/<path:subpath>": util.redirect_to_api_v1,
        "/rpc/<path:subpath>": util.redirect_to_api_v1,
        "/<path:subpath>": util.redirect_to_api_v1,
    }
)
