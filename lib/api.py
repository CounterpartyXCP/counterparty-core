#! /usr/bin/python3

import sqlite3
import logging
import threading

from werkzeug.wrappers import Request, Response
from werkzeug.serving import run_simple
from jsonrpc import JSONRPCResponseManager, dispatcher

from . import (util, config, exceptions)


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
            try:
                return util.get_address(db, kwargs.get('address', None))
            except exceptions.InvalidAddressError:
                return None
        
        @dispatcher.add_method
        def get_debits (**kwargs):
            return util.get_debits(db,
                address=kwargs.get('address', None),
                asset=kwargs.get('asset', None),
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))
        
        @dispatcher.add_method
        def get_credits (**kwargs):
            return util.get_credits(db,
                address=kwargs.get('address', None),
                asset=kwargs.get('asset', None),
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))
        
        @dispatcher.add_method
        def get_balances (**kwargs):
            return util.get_balances(db,
                address=kwargs.get('address', None),
                asset=kwargs.get('asset', None),
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))

        @dispatcher.add_method
        def get_sends (**kwargs):
            return util.get_sends(db, 
                source=kwargs.get('source', None),
                destination=kwargs.get('destination', None),
                validity='Valid' if kwargs.get('is_valid', True) else None,
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))
        
        @dispatcher.add_method
        def get_orders (**kwargs):
            return util.get_orders(db,
                address=kwargs.get('address', None),
                show_empty=kwargs.get('show_empty', True),
                show_expired=kwargs.get('show_expired', True),
                validity='Valid' if kwargs.get('is_valid', True) else None,
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))
        
        @dispatcher.add_method
        def get_order_matches (**kwargs):
            return util.get_order_matches(db,
                is_mine=kwargs.get('is_mine', False),
                address=kwargs.get('address', None),
                tx0_hash=kwargs.get('tx0_hash', None),
                tx1_hash=kwargs.get('tx1_hash', None),
                validity='Valid' if kwargs.get('is_valid', True) else None,
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))

        @dispatcher.add_method
        def get_btcpays(**kwargs):
            return util.get_btcpays(db, 
                validity='Valid' if kwargs.get('is_valid', True) else None,
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))

        @dispatcher.add_method
        def get_issuances(**kwargs):
            return util.get_issuances(db,
                asset=kwargs.get('asset', None),
                issuer=kwargs.get('issuer', None),
                validity='Valid' if kwargs.get('is_valid', True) else None,
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))
        
        @dispatcher.add_method
        def get_broadcasts(**kwargs):
            return util.get_broadcasts(db,
                source=kwargs.get('source', None),
                validity='Valid' if kwargs.get('is_valid', True) else None,
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))
        
        @dispatcher.add_method
        def get_bets (**kwargs):
            return util.get_bets(db,
                address=kwargs.get('address', None),
                show_empty=kwargs.get('show_empty', True),
                validity='Valid' if kwargs.get('is_valid', True) else None,
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))
        
        @dispatcher.add_method
        def get_bet_matches (**kwargs):
            return util.get_bet_matches(db,
                address=kwargs.get('address', None),
                tx0_hash=kwargs.get('tx0_hash', None),
                tx1_hash=kwargs.get('tx1_hash', None),
                validity='Valid' if kwargs.get('is_valid', True) else None,
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))
        
        @dispatcher.add_method
        def get_dividends(**kwargs):
            return util.get_dividends(db,
                address=kwargs.get('address', None),
                asset=kwargs.get('asset', None),
                validity='Valid' if kwargs.get('is_valid', True) else None,
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))
        
        @dispatcher.add_method
        def get_burns(**kwargs):
            return util.get_burns(db,
                address=kwargs.get('address', None),
                validity='Valid' if kwargs.get('is_valid', True) else None,
                order_by=kwargs.get('order_by', None),
                order_dir=kwargs.get('order_dir', None))

        @Request.application
        def application (request):
            response = JSONRPCResponseManager.handle(
                request.get_data(cache=False, as_text=True), dispatcher)
            return Response(response.json, mimetype='application/json')

        # util.database_check(db) # TODO Have this run regularly.
        run_simple('localhost', config.RPC_PORT, application)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
