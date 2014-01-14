#! /usr/bin/python3

import sqlite3
import logging
import threading
import decimal
D = decimal.Decimal

from werkzeug.wrappers import Request, Response
from werkzeug.serving import run_simple
from jsonrpc import JSONRPCResponseManager, dispatcher

from . import (config, util, bitcoin)
from . import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel)

class reqthread ( threading.Thread ):

    def __init__ (self):
        threading.Thread.__init__(self)

    def run ( self ):
        logger = logging.getLogger('werkzeug')
        logger.setLevel(logging.WARNING)

        db = sqlite3.connect(config.DATABASE)
        db.row_factory = sqlite3.Row
        db.isolation_level = None

        @dispatcher.add_method
        def get_address (**kwargs):
            return util.get_address(db, kwargs.get('address', None))
        @dispatcher.add_method
        def get_debits (**kwargs):
            return util.get_debits(db, kwargs.get('address', None), kwargs.get('asset', None))
        @dispatcher.add_method
        def get_credits (**kwargs):
            return util.get_credits(db, kwargs.get('address', None), kwargs.get('asset', None))
        @dispatcher.add_method
        def get_balances (**kwargs):
            return util.get_balances(db, kwargs.get('address', None), kwargs.get('asset', None))

        @dispatcher.add_method
        def get_sends (**kwargs):
            return util.get_sends(db, kwargs.get('validity', None), kwargs.get('source', None), kwargs.get('destination', None))
        @dispatcher.add_method
        def get_orders (**kwargs):
            return util.get_orders(db, kwargs.get('validity', None), kwargs.get('address', None), kwargs.get('show_empty', True), kwargs.get('show_expired', True))
        @dispatcher.add_method
        def get_order_matches (**kwargs):
            return util.get_order_matches(db, kwargs.get('validity', None), kwargs.get('is_mine', False), kwargs.get('address', None), kwargs.get('tx0_hash', None), kwargs.get('tx1_hash', None))
        @dispatcher.add_method
        def get_btcpays(**kwargs):
            return util.get_btcpays(db, kwargs.get('validity', None))
        @dispatcher.add_method
        def get_issuances(**kwargs):
            return util.get_issuances(db, kwargs.get('validity', None), kwargs.get('asset', None), kwargs.get('issuer', None))
        @dispatcher.add_method
        def get_broadcasts(**kwargs):
            return util.get_broadcasts(db, kwargs.get('validity', None), kwargs.get('source', None), kwargs.get('order_by', None))
        @dispatcher.add_method
        def get_bets (**kwargs):
            return util.get_bets(db, kwargs.get('validity', None), kwargs.get('address', None), kwargs.get('show_empty', True))
        @dispatcher.add_method
        def get_bet_matches (**kwargs):
            return util.get_bet_matches(db, kwargs.get('validity', None), kwargs.get('address', None), kwargs.get('tx0_hash', None), kwargs.get('tx1_hash', None))
        @dispatcher.add_method
        def get_dividends(**kwargs):
            return util.get_dividends(db, kwargs.get('validity', None), kwargs.get('address', None), kwargs.get('asset', None))
        @dispatcher.add_method
        def get_burns(**kwargs):
            return util.get_burns(db, kwargs.get('validity', None), kwargs.get('address', None))

        @dispatcher.add_method
        def do_send(**kwargs):
            source = kwargs.get('source')
            destination = kwargs.get('destination')
            quantity = kwargs.get('quantity')
            asset = kwargs.get('asset')
            unsigned = kwargs.get('unsigned', False)
            unsigned_tx_hex = send.create(db, source, destination, quantity,
                                          asset)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=args.unsigned)
        @dispatcher.add_method
        def do_order(**kwargs):
            source = kwargs.get('source')
            give_quantity = kwargs.get('give_quantity')
            give_asset = kwargs.get('give_asset')
            get_quantity = kwargs.get('get_quantity')
            get_asset = kwargs.get('get_asset')
            expiration = kwargs.get('expiration')
            fee_required = kwargs.get('fee_required')
            fee_provided = kwargs.get('fee_provided')
            unsigned = kwargs.get('unsigned', False)
            unsigned_tx_hex = order.create(db, source, give_asset,
                                           give_quantity, get_asset,
                                           get_quantity, expiration,
                                           fee_required, fee_provided)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        @dispatcher.add_method
        def do_btcpay(**kwargs):
            order_match_id = kwargs.get('order_match_id')
            unsigned = kwargs.get('unsigned', False)
            unsigned_tx_hex = btcpay.create(db, order_match_id)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        @dispatcher.add_method
        def do_issuance(**kwargs):
            source = kwargs.get('source')
            quantity = kwargs.get('quantity')
            transfer_destination = kwargs.get('transfer_destination', None)
            quantity = kwargs.get('quantity')
            asset = kwargs.get('asset')
            divisible = kwargs.get('divisible')
            unsigned = kwargs.get('unsigned', False)
            unsigned_tx_hex = issuance.create(db, source, transfer_destination,
                                              asset, quantity, divisible)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        @dispatcher.add_method
        def do_broadcast(**kwargs):
            source = kwargs.get('source')
            timestamp = kwargs.get('timestamp')
            value = kwargs.get('value')
            fee_multiplier = kwargs.get('fee_multiplier')
            text = kwargs.get('text')
            unsigned = kwargs.get('unsigned', False)
            unsigned_tx_hex = broadcast.create(db, source, timestamp,
                                               value, fee_multiplier, text)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        @dispatcher.add_method
        def do_bet(**kwargs):
            source = kwargs.get('source')
            feed_address = kwargs.get('feed_address')
            bet_type_id = util.BET_TYPE_ID[kwargs('bet_type')]
            deadline = kwargs.get('deadline')
            wager = kwargs.get('wager')
            counterwager = kwargs.get('counterwager')
            target_value = kwargs.get('target_value')
            leverage = kwargs.get('leverage', 5040)
            unsigned = kwargs.get('unsigned', False)
            unsigned_tx_hex = bet.create(db, source, feed_address,
                                         bet_type_id, deadline, wager,
                                         counterwager, target_value,
                                         leverage, expiration)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        @dispatcher.add_method
        def do_dividend(**kwargs):
            source = kwargs.get('source')
            quantity_per_share = kwargs.get('quantity_per_share')
            share_asset = kwargs.get('share_asset')
            unsigned = kwargs.get('unsigned', False)
            unsigned_tx_hex = dividend.create(db, source, quantity_per_share,
                                              share_asset)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        @dispatcher.add_method
        def do_burn(**kwargs):
            source = kwargs.get('source')
            quantity = kwargs.get('quantity')
            unsigned = kwargs.get('unsigned', False)
            unsigned_tx_hex = burn.create(db, source, quantity)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        @dispatcher.add_method
        def do_cancel(**kwargs):
            offer_hash = kwargs.get('offer_hash')
            unsigned = kwargs.get('unsigned', False)
            unsigned_tx_hex = cancel.create(db, offer_hash)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)

        @Request.application
        def application (request):
            response = JSONRPCResponseManager.handle(
                request.get_data(cache=False, as_text=True), dispatcher)
            return Response(response.json, mimetype='application/json')

        # util.database_check(db) # TODO Have this run regularly.
        run_simple('localhost', config.RPC_PORT, application)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
