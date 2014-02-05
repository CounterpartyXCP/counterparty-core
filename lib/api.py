#! /usr/bin/python3

import sys
import os
import threading
import decimal
import time
import json
import logging
from logging import handlers as logging_handlers
D = decimal.Decimal

import apsw
import cherrypy
from cherrypy import wsgiserver
from jsonrpc import JSONRPCResponseManager, dispatcher

from . import (config, exceptions, util, bitcoin)
from . import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel)

class APIServer(threading.Thread):

    def __init__ (self):
        threading.Thread.__init__(self)

    def run (self):
        db = util.connect_to_db()

        ######################
        #READ API
        @dispatcher.add_method
        def get_address (address):
            try:
                return util.get_address(db, address=address)
            except exceptions.InvalidAddressError:
                return None

        @dispatcher.add_method
        def xcp_supply ():
            return util.xcp_supply(db)

        @dispatcher.add_method
        def get_balances (filters=None, order_by=None, order_dir=None, filterop="and"):
            return util.get_balances(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                filterop=filterop)

        @dispatcher.add_method
        def get_bets(filters=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_bets(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_bet_matches(filters=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_bet_matches(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_broadcasts(filters=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_broadcasts(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_btcpays(filters=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_btcpays(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_burns(filters=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_burns(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_cancels(filters=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_cancels(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_credits (filters=None, order_by=None, order_dir=None, filterop="and"):
            return util.get_credits(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                filterop=filterop)

        @dispatcher.add_method
        def get_debits (filters=None, order_by=None, order_dir=None, filterop="and"):
            return util.get_debits(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                filterop=filterop)

        @dispatcher.add_method
        def get_dividends(filters=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_dividends(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_issuances(filters=None, is_valid=True, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_issuances(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_orders (filters=None, is_valid=True, show_expired=True, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_orders(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                show_expired=show_expired,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_order_matches (filters=None, is_valid=True, is_mine=False, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_order_matches(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                is_mine=is_mine,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_sends (filters=None, is_valid=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_sends(db,
                filters=filters,
                validity='Valid' if bool(is_valid) else None,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_asset_info(asset):
            #gets some useful info for the given asset
            issuances = util.get_issuances(db,
                filters={'field': 'asset', 'op': '==', 'value': asset},
                validity='Valid',
                order_by='block_index',
                order_dir='asc')
            if not issuances: return None #asset not found, most likely
            else: last_issuance = issuances[-1]

            #get the last issurance message for this asset, which should reflect the current owner and if
            # its divisible (and if it was locked, for that matter)
            locked = not last_issuance['amount'] and not last_issuance['transfer']
            total_issued = sum([e['amount'] for e in issuances])
            return {'owner': last_issuance['issuer'], 'divisible': last_issuance['divisible'], 'locked': locked, 'total_issued': total_issued, 'callable': last_issuance['callable'], 'call_date': util.isodt(last_issuance['call_date']) if last_issuance['call_date'] else None, 'call_price': last_issuance['call_price'], 'description': last_issuance['description']}


        ######################
        #WRITE/ACTION API
        @dispatcher.add_method
        def do_bet(source, feed_address, bet_type, deadline, wager, counterwager, target_value=0.0, leverage=5040, unsigned=False):
            bet_type_id = util.BET_TYPE_ID[bet_type]
            unsigned_tx_hex = bet.create(db, source, feed_address,
                                         bet_type_id, deadline, wager,
                                         counterwager, target_value,
                                         leverage, expiration, unsigned=unsigned)
            return unsigned_tx_hex if unsigned else bitcoin.transmit(unsigned_tx_hex, ask=False)

        @dispatcher.add_method
        def do_broadcast(source, fee_multiplier, text, timestamp, value=0, unsigned=False):
            unsigned_tx_hex = broadcast.create(db, source, timestamp,
                                               value, fee_multiplier, text, unsigned=unsigned)
            return unsigned_tx_hex if unsigned else bitcoin.transmit(unsigned_tx_hex, ask=False)

        @dispatcher.add_method
        def do_btcpay(order_match_id, unsigned=False):
            unsigned_tx_hex = btcpay.create(db, order_match_id, unsigned=unsigned)
            return unsigned_tx_hex if unsigned else bitcoin.transmit(unsigned_tx_hex, ask=False)

        @dispatcher.add_method
        def do_burn(source, quantity, unsigned=False):
            unsigned_tx_hex = burn.create(db, source, quantity, unsigned=unsigned)
            return unsigned_tx_hex if unsigned else bitcoin.transmit(unsigned_tx_hex, ask=False)

        @dispatcher.add_method
        def do_cancel(offer_hash, unsigned=False):
            unsigned_tx_hex = cancel.create(db, offer_hash, unsigned=unsigned)
            return unsigned_tx_hex if unsigned else bitcoin.transmit(unsigned_tx_hex, ask=False)

        @dispatcher.add_method
        def do_dividend(source, quantity_per_share, share_asset, unsigned=False):
            unsigned_tx_hex = dividend.create(db, source, quantity_per_share,
                                              share_asset, unsigned=unsigned)
            return unsigned_tx_hex if unsigned else bitcoin.transmit(unsigned_tx_hex, ask=False)

        @dispatcher.add_method
        def do_issuance(source, quantity, asset, divisible, transfer_destination=None, unsigned=False):
            try:
                quantity = int(quantity)
            except ValueError:
                raise Exception("Invalid quantity")
            unsigned_tx_hex = issuance.create(db, source, transfer_destination,
                asset, quantity, divisible, unsigned=unsigned)
            return unsigned_tx_hex if unsigned else bitcoin.transmit(unsigned_tx_hex, ask=False)

        @dispatcher.add_method
        def do_order(source, give_quantity, give_asset, get_quantity, get_asset, expiration, fee_required=0,
                     fee_provided=config.MIN_FEE / config.UNIT, unsigned=False):
            unsigned_tx_hex = order.create(db, source, give_asset,
                                           give_quantity, get_asset,
                                           get_quantity, expiration,
                                           fee_required, fee_provided,
                                           unsigned=unsigned)
            return unsigned_tx_hex if unsigned else bitcoin.transmit(unsigned_tx_hex, ask=False)

        @dispatcher.add_method
        def do_send(source, destination, quantity, asset, unsigned=False):
            unsigned_tx_hex = send.create(db, source, destination, quantity, asset, unsigned=unsigned)
            return unsigned_tx_hex if unsigned else bitcoin.transmit(unsigned_tx_hex, ask=False)


        class API(object):
            @cherrypy.expose
            def index(self):
                cherrypy.response.headers["Content-Type"] = "application/json"
                cherrypy.response.headers["Access-Control-Allow-Origin"] = '*'
                cherrypy.response.headers["Access-Control-Allow-Methods"] = 'POST, GET, OPTIONS'
                cherrypy.response.headers["Access-Control-Allow-Headers"] = 'Origin, X-Requested-With, Content-Type, Accept'

                if cherrypy.request.method == "OPTIONS": #web client will send us this before making a request
                    return

                try:
                    data = cherrypy.request.body.read().decode('utf-8')
                except ValueError:
                    raise cherrypy.HTTPError(400, 'Invalid JSON document')
                response = JSONRPCResponseManager.handle(data, dispatcher)
                return response.json.encode()

        cherrypy.config.update({
            'log.screen': False,
            "environment": "embedded",
            'log.error_log.propagate': False,
            'log.access_log.propagate': False,
            "server.logToScreen" : False
        })
        checkpassword = cherrypy.lib.auth_basic.checkpassword_dict(
            {config.RPC_USER: config.RPC_PASSWORD})
        app_config = {
            '/': {
                'tools.trailing_slash.on': False,
                'tools.auth_basic.on': True,
                'tools.auth_basic.realm': 'counterpartyd',
                'tools.auth_basic.checkpassword': checkpassword,
            },
        }
        application = cherrypy.Application(API(), script_name="/jsonrpc/", config=app_config)

        #disable logging of the access and error logs to the screen
        application.log.access_log.propagate = False
        application.log.error_log.propagate = False

        if config.PREFIX != config.UNITTEST_PREFIX:  #skip setting up logs when for the test suite
            #set up a rotating log handler for this application
            # Remove the default FileHandlers if present.
            application.log.error_file = ""
            application.log.access_file = ""
            maxBytes = getattr(application.log, "rot_maxBytes", 10000000)
            backupCount = getattr(application.log, "rot_backupCount", 1000)
            # Make a new RotatingFileHandler for the error log.
            fname = getattr(application.log, "rot_error_file", os.path.join(config.DATA_DIR, "api.error.log"))
            h = logging_handlers.RotatingFileHandler(fname, 'a', maxBytes, backupCount)
            h.setLevel(logging.DEBUG)
            h.setFormatter(cherrypy._cplogging.logfmt)
            application.log.error_log.addHandler(h)
            # Make a new RotatingFileHandler for the access log.
            fname = getattr(application.log, "rot_access_file", os.path.join(config.DATA_DIR, "api.access.log"))
            h = logging_handlers.RotatingFileHandler(fname, 'a', maxBytes, backupCount)
            h.setLevel(logging.DEBUG)
            h.setFormatter(cherrypy._cplogging.logfmt)
            application.log.access_log.addHandler(h)

        #start up the API listener/handler
        server = wsgiserver.CherryPyWSGIServer(
            (config.RPC_HOST, int(config.RPC_PORT)), application)
        #logging.debug("Initializing API interface…")
        try:
            server.start()
        except OSError:
            raise Exception("Cannot start the API subsystem. Is counterpartyd"
                " already running, or is something else listening on port %s?" % config.RPC_PORT)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
