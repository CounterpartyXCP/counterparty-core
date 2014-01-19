#! /usr/bin/python3

import sys
import logging
import threading
import decimal
import time
import json
import atexit
D = decimal.Decimal

import apsw
import cherrypy
from cherrypy import wsgiserver
from jsonrpc import JSONRPCResponseManager, dispatcher

from . import (config, exceptions, util, bitcoin)
from . import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel)

class reqthread ( threading.Thread ):

    def __init__ (self):
        threading.Thread.__init__(self)
        
    def run ( self ):
        logger = logging.getLogger('api')
        logger.setLevel(logging.WARNING)
        
        db = apsw.Connection(config.DATABASE)
        db.setrowtrace(util.rowtracer)

        @dispatcher.add_method
        def get_address (address):
            try:
                return util.get_address(db,
                    address=address)
            except exceptions.InvalidAddressError:
                return None
        
        @dispatcher.add_method
        def get_debits (address=None, asset=None, order_by=None, order_dir=None):
            return util.get_debits(db,
                address=address,
                asset=asset,
                order_by=order_by,
                order_dir=order_dir)
        
        @dispatcher.add_method
        def get_credits (address=None, asset=None, order_by=None, order_dir=None):
            return util.get_credits(db,
                address=address,
                asset=asset,
                order_by=order_by,
                order_dir=order_dir)
        
        @dispatcher.add_method
        def get_balances (address=None, asset=None, order_by=None, order_dir=None):
            return util.get_balances(db,
                address=address,
                asset=asset,
                order_by=order_by,
                order_dir=order_dir)

        @dispatcher.add_method
        def get_sends (source=None, destination=None, is_valid=None, order_by=None, order_dir=None, start_block=None, end_block=None):
            return util.get_sends(db, 
                source=source,
                destination=destination,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)
        
        @dispatcher.add_method
        def get_orders (address=None, is_valid=True, show_empty=True, show_expired=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            return util.get_orders(db,
                address=address,
                show_empty=show_empty,
                show_expired=show_expired,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)
        
        @dispatcher.add_method
        def get_order_matches (address=None, is_valid=True, is_mine=False, tx0_hash=None, tx1_hash=None, order_by=None, order_dir=None, start_block=None, end_block=None):
            return util.get_order_matches(db,
                is_mine=is_mine,
                address=address,
                tx0_hash=tx0_hash,
                tx1_hash=tx1_hash,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_btcpays(is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            return util.get_btcpays(db, 
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_issuances(asset=None, issuer=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            return util.get_issuances(db,
                asset=asset,
                issuer=issuer,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)
        
        @dispatcher.add_method
        def get_broadcasts(source=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            return util.get_broadcasts(db,
                source=source,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)
        
        @dispatcher.add_method
        def get_bets(address=None, show_empty=False, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            return util.get_bets(db,
                address=address,
                show_empty=show_empty,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)
        
        @dispatcher.add_method
        def get_bet_matches(address=None, is_valid=True, tx0_hash=None, tx1_hash=None, order_by=None, order_dir=None, start_block=None, end_block=None):
            return util.get_bet_matches(db,
                address=address,
                tx0_hash=tx0_hash,
                tx1_hash=tx1_hash,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)
        
        @dispatcher.add_method
        def get_dividends(address=None, asset=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            return util.get_dividends(db,
                address=address,
                asset=asset,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)
        
        @dispatcher.add_method
        def get_burns(address=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            return util.get_burns(db,
                address=address,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_cancels(source=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            return util.get_cancels(db,
                source=source,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def do_send(source, destination, quantity, asset, unsigned=False):
            unsigned_tx_hex = send.create(db, source, destination, quantity, asset)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        
        @dispatcher.add_method
        def do_order(source, give_quantity, give_asset, get_quantity, get_asset, expiration, fee_required=0,
                     fee_provided=config.MIN_FEE / config.UNIT, unsigned=False):
            unsigned_tx_hex = order.create(db, source, give_asset,
                                           give_quantity, get_asset,
                                           get_quantity, expiration,
                                           fee_required, fee_provided)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        
        @dispatcher.add_method
        def do_btcpay(order_match_id, unsigned=False):
            unsigned_tx_hex = btcpay.create(db, order_match_id)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        
        @dispatcher.add_method
        def do_issuance(source, quantity, asset, divisible, transfer_destination=None, unsigned=False):
            unsigned_tx_hex = issuance.create(db, source, transfer_destination,
                                              asset, quantity, divisible)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        
        @dispatcher.add_method
        def do_broadcast(source, fee_multiplier, text, timestamp, value=0, unsigned=False):
            unsigned_tx_hex = broadcast.create(db, source, timestamp,
                                               value, fee_multiplier, text)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        
        @dispatcher.add_method
        def do_bet(source, feed_address, bet_type, deadline, wager, counterwager, target_value=0.0, leverage=5040, unsigned=False):
            bet_type_id = util.BET_TYPE_ID[bet_type]
            unsigned_tx_hex = bet.create(db, source, feed_address,
                                         bet_type_id, deadline, wager,
                                         counterwager, target_value,
                                         leverage, expiration)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        
        @dispatcher.add_method
        def do_dividend(source, quantity_per_share, share_asset, unsigned=False):
            unsigned_tx_hex = dividend.create(db, source, quantity_per_share,
                                              share_asset)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        
        @dispatcher.add_method
        def do_burn(source, quantity, unsigned=False):
            unsigned_tx_hex = burn.create(db, source, quantity)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        
        @dispatcher.add_method
        def do_cancel(offer_hash, unsigned=False):
            unsigned_tx_hex = cancel.create(db, offer_hash)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)

        class Root(object):
            @cherrypy.expose
            @cherrypy.tools.json_out()
            def index(self):
                try:
                    data = cherrypy.request.body.read().decode('utf-8')
                except ValueError:
                    raise cherrypy.HTTPError(400, 'Invalid JSON document')
                response = JSONRPCResponseManager.handle(data, dispatcher)
                return response.json

        application = cherrypy.Application(Root(), script_name="/jsonrpc/", config=None)
        server = wsgiserver.CherryPyWSGIServer(
                    (config.RPC_HOST, int(config.RPC_PORT)), application,)
        server.start()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
