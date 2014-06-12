#! /usr/bin/python3

import sys
import os
import threading
import decimal
import time
import json
import requests
import logging
from logging import handlers as logging_handlers
D = decimal.Decimal

import apsw
import cherrypy
from cherrypy import wsgiserver
import jsonrpc
from jsonrpc import dispatcher

from . import (config, bitcoin, exceptions, util)
from . import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, callback)

class APIServer(threading.Thread):

    def __init__ (self):
        threading.Thread.__init__(self)

    def run (self):
        db = util.connect_to_db(flags='SQLITE_OPEN_READONLY')

        ######################
        #READ API

        # Generate dynamically get_{table} methods
        def generate_get_method(table):
            def get_method(**kwargs):
                return util.get_rows(db, table=table, **kwargs)
            return get_method

        for table in config.API_TABLES:
            new_method = generate_get_method(table)
            new_method.__name__ = 'get_{}'.format(table)
            dispatcher.add_method(new_method)

        @dispatcher.add_method
        def sql(query, bindings=[]):
            return util.db_query(db, query, tuple(bindings))
        
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
                cursor = db.cursor()
                issuances = list(cursor.execute('''SELECT * FROM issuances WHERE (status = ? AND asset = ?) ORDER BY block_index ASC''', ('valid', asset)))
                cursor.close()
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
                'last_message_index': last_message['message_index'] if last_message else -1,
                'running_testnet': config.TESTNET,
                'running_testcoin': config.TESTCOIN,
                'version_major': config.VERSION_MAJOR,
                'version_minor': config.VERSION_MINOR,
                'version_revision': config.VERSION_REVISION
            }

        @dispatcher.add_method
        def asset_names():
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

        @dispatcher.add_method
        def get_asset_names():
            cursor = db.cursor()
            names = [row['asset'] for row in cursor.execute("SELECT DISTINCT asset FROM issuances WHERE status = 'valid' ORDER BY asset ASC")]
            cursor.close()
            return names

        ######################
        #WRITE/ACTION API
        @dispatcher.add_method
        def create_bet(source, feed_address, bet_type, deadline, wager, counterwager, expiration, target_value=0.0,
        leverage=5040, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False, fee=None):
            try:
                bet_type_id = util.BET_TYPE_ID[bet_type]
            except KeyError:
                raise exceptions.BetError('Unknown bet type.')
            tx_info = bet.compose(db, source, feed_address,
                              bet_type_id, deadline, wager,
                              counterwager, target_value,
                              leverage, expiration)
            return bitcoin.transaction(tx_info, encoding=encoding, exact_fee=fee, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_broadcast(source, fee_fraction, text, timestamp, value=-1, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False, fee=None):
            tx_info = broadcast.compose(db, source, timestamp,
                                    value, fee_fraction, text)
            return bitcoin.transaction(tx_info, encoding=encoding, exact_fee=fee, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_btcpay(source, order_match_id, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False, fee=None):
            tx_info = btcpay.compose(db, source, order_match_id)
            return bitcoin.transaction(tx_info, encoding=encoding, exact_fee=fee, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_burn(source, quantity, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False, fee=None):
            tx_info = burn.compose(db, source, quantity)
            return bitcoin.transaction(tx_info, encoding=encoding, exact_fee=fee, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_cancel(source, offer_hash, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False, fee=None):
            tx_info = cancel.compose(db, source, offer_hash)
            return bitcoin.transaction(tx_info, encoding=encoding, exact_fee=fee, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_callback(source, fraction, asset, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False, fee=None):
            tx_info = callback.compose(db, source, fraction, asset)
            return bitcoin.transaction(tx_info, encoding=encoding, exact_fee=fee, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_dividend(source, quantity_per_unit, asset, dividend_asset, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False, fee=None):
            tx_info = dividend.compose(db, source, quantity_per_unit, asset, dividend_asset)
            return bitcoin.transaction(tx_info, encoding=encoding, exact_fee=fee, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_issuance(source, asset, quantity, divisible, description, callable_=None, call_date=None,
        call_price=None, transfer_destination=None, lock=False, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False, fee=None):
            try:
                quantity = int(quantity)
            except ValueError:
                raise Exception("Invalid quantity")
            if lock:
                description = "LOCK"
            tx_info = issuance.compose(db, source, transfer_destination,
                                   asset, quantity, divisible, callable_,
                                   call_date, call_price, description)
            return bitcoin.transaction(tx_info, encoding=encoding, exact_fee=fee, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_order(source, give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required,
                         fee_provided, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False, fee=None):
            tx_info = order.compose(db, source, give_asset, give_quantity,
                                    get_asset, get_quantity, expiration,
                                    fee_required)
            return bitcoin.transaction(tx_info, encoding=encoding, exact_fee=fee, fee_provided=fee_provided, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def create_send(source, destination, asset, quantity, encoding='multisig', pubkey=None, allow_unconfirmed_inputs=False, fee=None):
            tx_info = send.compose(db, source, destination, asset, quantity)
            return bitcoin.transaction(tx_info, encoding=encoding, exact_fee=fee, public_key_hex=pubkey, allow_unconfirmed_inputs=allow_unconfirmed_inputs)

        @dispatcher.add_method
        def sign_tx(unsigned_tx_hex, privkey=None):
            return bitcoin.sign_tx(unsigned_tx_hex, private_key_wif=privkey)
                
        @dispatcher.add_method
        def broadcast_tx(signed_tx_hex):
            if not config.TESTNET and config.BROADCAST_TX_MAINNET in ['bci', 'bci-failover']:
                url = "https://blockchain.info/pushtx"
                params = {'tx': signed_tx_hex}
                response = requests.post(url, data=params)
                if response.text.lower() != 'transaction submitted' or response.status_code != 200:
                    if config.BROADCAST_TX_MAINNET == 'bci-failover':
                        return bitcoin.broadcast_tx(signed_tx_hex)
                    else:
                        raise Exception(response.text)
                return response.text
            else:
                return bitcoin.broadcast_tx(signed_tx_hex)

        class API(object):
            @cherrypy.expose
            def index(self):
                try:
                    data = cherrypy.request.body.read().decode('utf-8')
                except ValueError:
                    raise cherrypy.HTTPError(400, 'Invalid JSON document')

                cherrypy.response.headers["Content-Type"] = "application/json"
                #CORS logic is handled in the nginx config

                # Check version.
                # Check that bitcoind is running, communicable, and caught up with the blockchain.
                # Check that the database has caught up with bitcoind.
                if not config.FORCE:
                    try: self.last_check
                    except: self.last_check = 0
                    try:
                        if time.time() - self.last_check >= 4 * 3600: # Four hours since last check.
                            code = 10
                            util.version_check(db)
                        if time.time() - self.last_check > 10 * 60: # Ten minutes since last check.
                            code = 11
                            bitcoin.bitcoind_check(db)
                            code = 12
                            util.database_check(db, bitcoin.get_block_count())  # TODO: If not reparse or rollback, once those use API.
                        self.last_check = time.time()
                    except Exception as e:
                        exception_name = e.__class__.__name__
                        exception_text = str(e)
                        response = jsonrpc.exceptions.JSONRPCError(code=code, message=exception_name, data=exception_text)
                        return response.json.encode()

                response = jsonrpc.JSONRPCResponseManager.handle(data, dispatcher)
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
