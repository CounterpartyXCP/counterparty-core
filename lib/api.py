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

from . import (config, bitcoin, exceptions, util)
from . import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, callback)

class APIServer(threading.Thread):

    def __init__ (self):
        threading.Thread.__init__(self)

    def run (self):
        db = util.connect_to_db(flags='SQLITE_OPEN_READONLY')

        ######################
        #READ API
        # TODO: Move all of these functions from util.py here (and use native SQLite queries internally).

        @dispatcher.add_method
        def get_balances(filters=None, order_by=None, order_dir=None, filterop="and"):
            return util.get_balances(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                filterop=filterop)

        @dispatcher.add_method
        def get_bets(filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_bets(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_bet_matches(filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_bet_matches(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_broadcasts(filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_broadcasts(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_btcpays(filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_btcpays(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_burns(filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_burns(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_callbacks(filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_callbacks(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_cancels(filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_cancels(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_credits (filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_credits(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_debits (filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_debits(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_dividends(filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_dividends(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_issuances(filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_issuances(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_orders (filters=None, show_expired=True, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            results = util.get_orders(db,
                filters=filters,
                show_expired=show_expired,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)
            return results

        @dispatcher.add_method
        def get_order_matches (filters=None, post_filter_status=None, is_mine=False, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            assert post_filter_status in (None, 'completed', 'pending')
            return util.get_order_matches(db,
                filters=filters,
                post_filter_status=post_filter_status,
                is_mine=is_mine,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_sends (filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_sends(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_bet_expirations (filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_bet_expirations(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_order_expirations (filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_order_expirations(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_bet_match_expirations (filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_bet_match_expirations(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)

        @dispatcher.add_method
        def get_order_match_expirations (filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop="and"):
            return util.get_order_match_expirations(db,
                filters=filters,
                order_by=order_by,
                order_dir=order_dir,
                start_block=start_block,
                end_block=end_block,
                filterop=filterop)
        
        @dispatcher.add_method
        def get_messages(block_index):
            if not isinstance(block_index, int):
                raise Exception("block_index must be an integer.")
            
            cursor = db.cursor()
            cursor.execute('select * from messages where block_index = ? order by message_index asc', (block_index,))
            messages = cursor.fetchall()
            cursor.close()
            return messages

        @dispatcher.add_method
        def get_messages_by_index(message_indexes):
            """Get specific messages from the feed, based on the message_index.
            
            @param message_index: A single index, or a list of one or more message indexes to retrieve.
            """
            if not isinstance(message_indexes, list):
                message_indexes = [message_indexes,]
            for idx in message_indexes:  #make sure the data is clean
                if not isinstance(idx, int):
                    raise Exception("All items in message_indexes are not integers")
                
            cursor = db.cursor()
            cursor.execute('SELECT * FROM messages WHERE message_index IN (%s) ORDER BY message_index ASC'
                % (','.join([str(x) for x in message_indexes]),))
            messages = cursor.fetchall()
            cursor.close()
            return messages

        @dispatcher.add_method
        def get_xcp_supply():
            return util.xcp_supply(db)

        @dispatcher.add_method
        def get_asset_info(assets):
            if not isinstance(assets, list):
                raise Exception("assets must be a list of asset names, even if it just contains one entry")
            assetsInfo = []
            for asset in assets:

                # BTC and XCP.
                if asset in ['BTC', 'XCP']:
                    if asset == 'BTC':
                        supply = bitcoin.get_btc_supply(normalize=False)
                    else:
                        supply = util.xcp_supply(db)
                    
                    assetsInfo.append({
                        'asset': asset,
                        'owner': None,
                        'divisible': True,
                        'locked': False,
                        'supply': supply,
                        'callable': False,
                        'call_date': None,
                        'call_price': None,
                        'description': '',
                        'issuer': None
                    })
                    continue
                
                # User‐created asset.
                issuances = util.get_issuances(db,
                    filters={'field': 'asset', 'op': '==', 'value': asset},
                    status='valid',
                    order_by='block_index',
                    order_dir='asc')
                if not issuances: break #asset not found, most likely
                else: last_issuance = issuances[-1]
                supply = 0
                locked = False
                for e in issuances:
                    if e['locked']: locked = True
                    supply += e['quantity']
                assetsInfo.append({
                    'asset': asset,
                    'owner': last_issuance['issuer'],
                    'divisible': bool(last_issuance['divisible']),
                    'locked': locked,
                    'supply': supply,
                    'callable': bool(last_issuance['callable']),
                    'call_date': last_issuance['call_date'],
                    'call_price': last_issuance['call_price'],
                    'description': last_issuance['description'],
                    'issuer': last_issuance['issuer']})
            return assetsInfo

        @dispatcher.add_method
        def get_block_info(block_index):
            assert isinstance(block_index, int) 
            cursor = db.cursor()
            cursor.execute('''SELECT * FROM blocks WHERE block_index = ?''', (block_index,))
            try:
                blocks = list(cursor)
                assert len(blocks) == 1
                block = blocks[0]
            except IndexError:
                raise exceptions.DatabaseError('No blocks found.')
            cursor.close()
            return block
            
        @dispatcher.add_method
        def get_running_info():
            latestBlockIndex = bitcoin.get_block_count()
            
            try:
                util.database_check(db, latestBlockIndex)
            except:
                caught_up = False
            else:
                caught_up = True

            try:
                last_block = util.last_block(db)
            except:
                last_block = {'block_index': None, 'block_hash': None, 'block_time': None}
            
            try:
                last_message = util.last_message(db)
            except:
                last_message = None
            
            return {
                'db_caught_up': caught_up,
                'bitcoin_block_count': latestBlockIndex,
                'last_block': last_block,
                'counterpartyd_version': config.CLIENT_VERSION_STRING,
                'last_message_index': last_message['message_index'] if last_message else -1,
                'running_testnet': config.TESTNET,
                'db_version_major': config.DB_VERSION_MAJOR,
                'db_version_minor': config.DB_VERSION_MINOR,
            }

        @dispatcher.add_method
        def get_asset_names():
            cursor = db.cursor()
            names = [row['asset'] for row in cursor.execute("SELECT DISTINCT asset FROM issuances WHERE status = 'valid' ORDER BY asset ASC")]
            cursor.close()
            return names

        @dispatcher.add_method
        def get_element_counts():
            counts = {}
            cursor = db.cursor()
            for element in ['transactions', 'blocks', 'debits', 'credits', 'balances', 'sends', 'orders',
                'order_matches', 'btcpays', 'issuances', 'broadcasts', 'bets', 'bet_matches', 'dividends',
                'burns', 'cancels', 'callbacks', 'order_expirations', 'bet_expirations', 'order_match_expirations',
                'bet_match_expirations', 'messages']:
                cursor.execute("SELECT COUNT(*) AS count FROM %s" % element)
                count_list = cursor.fetchall()
                assert len(count_list) == 1
                counts[element] = count_list[0]['count']
            cursor.close()
            return counts

        ######################
        #WRITE/ACTION API
        @dispatcher.add_method
        def create_bet(source, feed_address, bet_type, deadline, wager, counterwager, expiration, target_value=0.0,
        leverage=5040, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False):
            try:
                bet_type_id = util.BET_TYPE_ID[bet_type]
            except KeyError:
                raise exceptions.BetError('Unknown bet type.')
            tx_info = bet.compose(db, source, feed_address,
                              bet_type_id, deadline, wager,
                              counterwager, target_value,
                              leverage, expiration)
            return bitcoin.transaction(tx_info, encoding=encoding, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_broadcast(source, fee_fraction, text, timestamp, value=-1, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False):
            tx_info = broadcast.compose(db, source, timestamp,
                                    value, fee_fraction, text)
            return bitcoin.transaction(tx_info, encoding=encoding, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_btcpay(source, order_match_id, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False):
            tx_info = btcpay.compose(db, source, order_match_id)
            return bitcoin.transaction(tx_info, encoding=encoding, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_burn(source, quantity, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False):
            tx_info = burn.compose(db, source, quantity)
            return bitcoin.transaction(tx_info, encoding=encoding, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_cancel(source, offer_hash, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False):
            tx_info = cancel.compose(db, source, offer_hash)
            return bitcoin.transaction(tx_info, encoding=encoding, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_callback(source, fraction, asset, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False):
            tx_info = callback.compose(db, source, fraction, asset)
            return bitcoin.transaction(tx_info, encoding=encoding, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_dividend(source, quantity_per_unit, asset, dividend_asset, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False):
            tx_info = dividend.compose(db, source, quantity_per_unit, asset, dividend_asset)
            return bitcoin.transaction(tx_info, encoding=encoding, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_issuance(source, asset, quantity, divisible, description, callable_=None, call_date=None,
        call_price=None, transfer_destination=None, lock=False, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False):
            try:
                quantity = int(quantity)
            except ValueError:
                raise Exception("Invalid quantity")
            if lock:
                description = "LOCK"
            tx_info = issuance.compose(db, source, transfer_destination,
                                   asset, quantity, divisible, callable_,
                                   call_date, call_price, description)
            return bitcoin.transaction(tx_info, encoding=encoding, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_order(source, give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required=None,
        fee_provided=None, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False):
            if get_asset == 'BTC' and fee_required is None:
                #since no value is passed, set a default of 1% for fee_required if buying BTC
                fee_required = int(get_quantity / 100)
            elif fee_required is None:
                fee_required = 0 #no default set, but fee_required does not apply

            if give_asset == 'BTC' and fee_provided is None:
                #since no value is passed, set a default of 1% for fee_provided if selling BTC
                fee_provided = int(give_quantity / 100)
            elif fee_provided is None:
                fee_provided = 0 #no default set, but fee_required does not apply
            
            tx_info = order.compose(db, source, give_asset,
                                give_quantity, get_asset,
                                get_quantity, expiration,
                                fee_required, fee_provided)
            return bitcoin.transaction(tx_info, encoding=encoding, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_send(source, destination, asset, quantity, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False):
            tx_info = send.compose(db, source, destination, asset, quantity)
            return bitcoin.transaction(tx_info, encoding=encoding, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def sign_tx(unsigned_tx_hex, privkey=None):
            return bitcoin.sign_tx(unsigned_tx_hex, private_key_wif=privkey)
                
        @dispatcher.add_method
        def broadcast_tx(signed_tx_hex):
            return bitcoin.broadcast_tx(signed_tx_hex)

        class API(object):
            @cherrypy.expose
            def index(self):
                cherrypy.response.headers["Content-Type"] = "application/json"
                #CORS logic is handled in the nginx config

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
        application = cherrypy.Application(API(), script_name="/api", config=app_config)

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
        server = wsgiserver.CherryPyWSGIServer((config.RPC_HOST, config.RPC_PORT), application,
            numthreads=config.API_NUM_THREADS, request_queue_size=config.API_REQUEST_QUEUE_SIZE)
        #logging.debug("Initializing API interface…")
        try:
            server.start()
        except OSError:
            raise Exception("Cannot start the API subsystem. Is counterpartyd"
                " already running, or is something else listening on port %s?" % config.RPC_PORT)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
