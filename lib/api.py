#! /usr/bin/python3

import sqlite3
import logging
import threading

from werkzeug.wrappers import Request, Response
from werkzeug.serving import run_simple
from jsonrpc import JSONRPCResponseManager, dispatcher

from . import (util, config)

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

        @Request.application
        def application (request):
            response = JSONRPCResponseManager.handle(
                request.get_data(cache=False, as_text=True), dispatcher)
            return Response(response.json, mimetype='application/json')

        # util.database_check(db) # TODO Have this run regularly.
        run_simple('localhost', config.RPC_PORT, application)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
