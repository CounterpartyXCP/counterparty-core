#! /usr/bin/python3

import sys
import os
import threading
import decimal
import time
import json
import atexit
import logging
from logging import handlers as logging_handlers
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
        db = apsw.Connection(config.DATABASE)
        db.setrowtrace(util.rowtracer)

        ######################
        #READ API
        @dispatcher.add_method
        def get_address (address):
            try:
                return util.get_address(db, address=address)
            except exceptions.InvalidAddressError:
                return None
        
        @dispatcher.add_method
        def get_balances (filters=[], order_by=None, order_dir=None):
            if filters is None: filters=[]            
            return util.get_balances(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir)

        @dispatcher.add_method
        def get_bets(filters=[], is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            if filters is None: filters=[]            
            return util.get_bets(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_bet_matches(filters=[], is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            if filters is None: filters=[]            
            return util.get_bet_matches(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_broadcasts(filters=[], is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            if filters is None: filters=[]            
            return util.get_broadcasts(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_btcpays(filters=[], is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            if filters is None: filters=[]            
            return util.get_btcpays(db, 
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_burns(filters=[], is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            if filters is None: filters=[]            
            return util.get_burns(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_cancels(filters=[], is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            if filters is None: filters=[]            
            return util.get_cancels(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_credits (filters=[], order_by=None, order_dir=None):
            if filters is None: filters=[]            
            return util.get_credits(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir)

        @dispatcher.add_method
        def get_debits (filters=[], order_by=None, order_dir=None):
            if filters is None: filters=[]            
            return util.get_debits(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir)

        @dispatcher.add_method
        def get_dividends(filters=[], is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            if filters is None: filters=[]            
            return util.get_dividends(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_issuances(filters=[], is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            if filters is None: filters=[]            
            return util.get_issuances(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_orders (filters=[], is_valid=True, show_expired=True, order_by=None, order_dir=None, start_block=None, end_block=None):
            if filters is None: filters=[]            
            return util.get_orders(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                show_expired=show_expired,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)
        
        @dispatcher.add_method
        def get_order_matches (filters=[], is_valid=True, is_mine=False, order_by=None, order_dir=None, start_block=None, end_block=None):
            if filters is None: filters=[]            
            return util.get_order_matches(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                is_mine=is_mine,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        @dispatcher.add_method
        def get_sends (filters=[], is_valid=None, order_by=None, order_dir=None, start_block=None, end_block=None):
            if filters is None: filters=[]            
            return util.get_sends(db, 
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block)

        ######################
        #WRITE/ACTION API
        @dispatcher.add_method
        def do_bet(source, feed_address, bet_type, deadline, wager, counterwager, target_value=0.0, leverage=5040, unsigned=False):
            bet_type_id = util.BET_TYPE_ID[bet_type]
            unsigned_tx_hex = bet.create(db, source, feed_address,
                                         bet_type_id, deadline, wager,
                                         counterwager, target_value,
                                         leverage, expiration)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)

        @dispatcher.add_method
        def do_broadcast(source, fee_multiplier, text, timestamp, value=0, unsigned=False):
            unsigned_tx_hex = broadcast.create(db, source, timestamp,
                                               value, fee_multiplier, text)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)

        @dispatcher.add_method
        def do_btcpay(order_match_id, unsigned=False):
            unsigned_tx_hex = btcpay.create(db, order_match_id)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)

        @dispatcher.add_method
        def do_burn(source, quantity, unsigned=False):
            unsigned_tx_hex = burn.create(db, source, quantity)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)
        
        @dispatcher.add_method
        def do_cancel(offer_hash, unsigned=False):
            unsigned_tx_hex = cancel.create(db, offer_hash)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)

        @dispatcher.add_method
        def do_dividend(source, quantity_per_share, share_asset, unsigned=False):
            unsigned_tx_hex = dividend.create(db, source, quantity_per_share,
                                              share_asset)
            return bitcoin.transmit(unsigned_tx_hex, unsigned=unsigned, ask=False)

        @dispatcher.add_method
        def do_issuance(source, quantity, asset, divisible, transfer_destination=None, unsigned=False):
            unsigned_tx_hex = issuance.create(db, source, transfer_destination,
                                              asset, quantity, divisible)
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
        def do_send(source, destination, quantity, asset, unsigned=False):
            unsigned_tx_hex = send.create(db, source, destination, quantity, asset)
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

        cherrypy.config.update({
            'log.screen': False,
            "environment": "embedded",
            'log.error_log.propagate': False,
            'log.access_log.propagate': False,
            "server.logToScreen" : False
        })        
        app_config = {
            '/': { 
                'tools.trailing_slash.on': False,
            },
        }
        application = cherrypy.Application(Root(), script_name="/jsonrpc/", config=app_config)
        
        #disable logging of the access and error logs to the screen
        application.log.access_log.propagate = False
        application.log.error_log.propagate = False
        
        #set up a rotating log handler for this application
        # Remove the default FileHandlers if present.
        application.log.error_file = ""
        application.log.access_file = ""
        maxBytes = getattr(application.log, "rot_maxBytes", 10000000)
        backupCount = getattr(application.log, "rot_backupCount", 1000)
        # Make a new RotatingFileHandler for the error log.
        fname = getattr(application.log, "rot_error_file", os.path.join(config.data_dir, "api.error.log"))
        h = logging_handlers.RotatingFileHandler(fname, 'a', maxBytes, backupCount)
        h.setLevel(logging.DEBUG)
        h.setFormatter(cherrypy._cplogging.logfmt)
        application.log.error_log.addHandler(h)
        # Make a new RotatingFileHandler for the access log.
        fname = getattr(application.log, "rot_access_file", os.path.join(config.data_dir, "api.access.log"))
        h = logging_handlers.RotatingFileHandler(fname, 'a', maxBytes, backupCount)
        h.setLevel(logging.DEBUG)
        h.setFormatter(cherrypy._cplogging.logfmt)
        application.log.access_log.addHandler(h)

        #start up the API listener/handler
        server = wsgiserver.CherryPyWSGIServer(
            (config.RPC_HOST, int(config.RPC_PORT)), application)
        try:
            server.start()
        except OSError:
            raise Exception("Cannot start the API subsystem. Is counterpartyd"
                " already running, or is something else listening on port %s?" % config.RPC_PORT)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
