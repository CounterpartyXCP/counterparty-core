#! /usr/bin/python3

import sqlite3
import logging
import threading

from werkzeug.wrappers import Request, Response
from werkzeug.serving import run_simple
from jsonrpc import JSONRPCResponseManager, dispatcher

from . import (util, config)

class reqthread ( threading.Thread):

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
            return util.get_address(db, kwargs['address'])
        @dispatcher.add_method
        def get_debits (**kwargs):
            return util.get_debits(db, kwargs['address'], kwargs['asset'])
        @dispatcher.add_method
        def get_credits (**kwargs):
            return util.get_credits(db, kwargs['address'], kwargs['asset'])
        @dispatcher.add_method
        def get_balances (**kwargs):
            return util.get_balances(db, kwargs['address'], kwargs['asset'])

        @dispatcher.add_method
        def get_sends (**kwargs):
            return util.get_sends(db, kwargs['validity'], kwargs['source'], kwargs['destination'])
        @dispatcher.add_method
        def get_orders (**kwargs):
            return util.get_orders(db, kwargs['validity'], kwargs['address'], kwargs['show_empty'], kwargs['show_expired'])
        @dispatcher.add_method
        def get_order_matches (**kwargs):
            return util.get_order_matches(db, kwargs['validity'], kwargs['is_mine'], kwargs['address'], kwargs['tx0_hash'], kwargs['tx1_hash'])
        @dispatcher.add_method
        def get_btcpays(**kwargs):
            return util.get_btcpays(db, kwargs['validity'])
        @dispatcher.add_method
        def get_issuances(**kwargs):
            return util.get_issuances(db, kwargs['validity'], kwargs['asset'], kwargs['issuer'])
        @dispatcher.add_method
        def get_broadcasts(**kwargs):
            return util.get_broadcasts(db, kwargs['validity'], kwargs['source'], kwargs['order_by'])
        @dispatcher.add_method
        def get_bets (**kwargs):
            return util.get_bets(db, kwargs['validity'], kwargs['address'], kwargs['show_empty'])
        @dispatcher.add_method
        def get_bet_matches (**kwargs):
            return util.get_bet_matches(db, kwargs['validity'], kwargs['address'], kwargs['tx0_hash'], kwargs['tx1_hash'])
        @dispatcher.add_method
        def get_dividends(**kwargs):
            return util.get_dividends(db, kwargs['validity'], kwargs['address'], kwargs['asset'])
        @dispatcher.add_method
        def get_burns(**kwargs):
            return util.get_burns(db, kwargs['validity'], kwargs['address'])

        @Request.application
        def application (request):
            # TODO: util.database_check(db)

            response = JSONRPCResponseManager.handle(
                request.get_data(cache=False, as_text=True), dispatcher)
            return Response(response.json, mimetype='application/json')

        try: # HACK for unit tests
            if config.TESTNET:
                run_simple('localhost', 14000, application)
            else:
                run_simple('localhost', 4000, application)
        except:
            run_simple('localhost', 9999, application)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
