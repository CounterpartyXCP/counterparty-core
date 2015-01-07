#! /usr/bin/python3

import sys
import os
import threading
import decimal
import time
import json
import re
import requests
import collections
import logging
logger = logging.getLogger(__name__)
from logging import handlers as logging_handlers
D = decimal.Decimal
import binascii

import struct
import apsw
import flask
from flask.ext.httpauth import HTTPBasicAuth
from tornado.wsgi import WSGIContainer
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
import jsonrpc
from jsonrpc import dispatcher
import inspect

from lib import config
from lib import exceptions
from lib import util
from lib import check
from lib import backend
from lib import database
from lib import transaction
from lib import blocks
from lib import script
from lib.messages import send
from lib.messages import order
from lib.messages import btcpay
from lib.messages import issuance
from lib.messages import broadcast
from lib.messages import bet
from lib.messages import dividend
from lib.messages import burn
from lib.messages import cancel
from lib.messages import rps
from lib.messages import rpsresolve
from lib.messages import publish
from lib.messages import execute

API_TABLES = ['balances', 'credits', 'debits', 'bets', 'bet_matches',
              'broadcasts', 'btcpays', 'burns', 'cancels',
              'dividends', 'issuances', 'orders', 'order_matches', 'sends',
              'bet_expirations', 'order_expirations', 'bet_match_expirations',
              'order_match_expirations', 'bet_match_resolutions', 'rps',
              'rpsresolves', 'rps_matches', 'rps_expirations', 'rps_match_expirations',
              'mempool']

API_TRANSACTIONS = ['bet', 'broadcast', 'btcpay', 'burn', 'cancel',
                    'dividend', 'issuance', 'order', 'send',
                    'rps', 'rpsresolve', 'publish', 'execute']

COMMONS_ARGS = ['encoding', 'fee_per_kb', 'regular_dust_size',
                'multisig_dust_size', 'op_return_value', 'pubkey',
                'allow_unconfirmed_inputs', 'fee', 'fee_provided']

API_MAX_LOG_SIZE = 10 * 1024 * 1024 #max log size of 20 MB before rotation (make configurable later)
API_MAX_LOG_COUNT = 10

current_api_status_code = None #is updated by the APIStatusPoller
current_api_status_response_json = None #is updated by the APIStatusPoller

class APIError(Exception):
    pass

# TODO: ALL queries EVERYWHERE should be done with these methods
def db_query(db, statement, bindings=(), callback=None, **callback_args):
    """Allow direct access to the database in a parametrized manner."""
    cursor = db.cursor()
    if hasattr(callback, '__call__'):
        cursor.execute(statement, bindings)
        for row in cursor:
            callback(row, **callback_args)
        results = None
    else:
        results = list(cursor.execute(statement, bindings))
    cursor.close()
    return results

def get_rows(db, table, filters=None, filterop='AND', order_by=None, order_dir=None, start_block=None, end_block=None,
              status=None, limit=1000, offset=0, show_expired=True):
    """SELECT * FROM wrapper. Filters results based on a filter data structure (as used by the API)."""

    if filters == None:
        filters = []

    def value_to_marker(value):
        # if value is an array place holder is (?,?,?,..)
        if isinstance(value, list):
            return '''({})'''.format(','.join(['?' for e in range(0, len(value))]))
        else:
            return '''?'''

    # TODO: Document that op can be anything that SQLite3 accepts.
    if not table or table.lower() not in API_TABLES:
        raise APIError('Unknown table')
    if filterop and filterop.upper() not in ['OR', 'AND']:
        raise APIError('Invalid filter operator (OR, AND)')
    if order_dir and order_dir.upper() not in ['ASC', 'DESC']:
        raise APIError('Invalid order direction (ASC, DESC)')
    if not isinstance(limit, int):
        raise APIError('Invalid limit')
    elif limit > 1000:
        raise APIError('Limit should be lower or equal to 1000')
    if not isinstance(offset, int):
        raise APIError('Invalid offset')
    # TODO: accept an object:  {'field1':'ASC', 'field2': 'DESC'}
    if order_by and not re.compile('^[a-z0-9_]+$').match(order_by):
        raise APIError('Invalid order_by, must be a field name')

    if isinstance(filters, dict): #single filter entry, convert to a one entry list
        filters = [filters,]
    elif not isinstance(filters, list):
        filters = []

    # TODO: Document this! (Each filter can be an ordered list.)
    new_filters = []
    for filter_ in filters:
        if type(filter_) in (list, tuple) and len(filter_) in [3, 4]:
            new_filter = {'field': filter_[0], 'op': filter_[1], 'value':  filter_[2]}
            if len(filter_) == 4:
                new_filter['case_sensitive'] = filter_[3]
            new_filters.append(new_filter)
        elif type(filter_) == dict:
            new_filters.append(filter_)
        else:
            raise APIError('Unknown filter type')
    filters = new_filters

    # validate filter(s)
    for filter_ in filters:
        for field in ['field', 'op', 'value']: #should have all fields
            if field not in filter_:
                raise APIError("A specified filter is missing the '%s' field" % field)
        if not isinstance(filter_['value'], (str, int, float, list)):
            raise APIError("Invalid value for the field '%s'" % filter_['field'])
        if isinstance(filter_['value'], list) and filter_['op'].upper() not in ['IN', 'NOT IN']:
            raise APIError("Invalid value for the field '%s'" % filter_['field'])
        if filter_['op'].upper() not in ['=', '==', '!=', '>', '<', '>=', '<=', 'IN', 'LIKE', 'NOT IN', 'NOT LIKE']:
            raise APIError("Invalid operator for the field '%s'" % filter_['field'])
        if 'case_sensitive' in filter_ and not isinstance(filter_['case_sensitive'], bool):
            raise APIError("case_sensitive must be a boolean")

    # SELECT
    statement = '''SELECT * FROM {}'''.format(table)
    # WHERE
    bindings = []
    conditions = []
    for filter_ in filters:
        case_sensitive = False if 'case_sensitive' not in filter_ else filter_['case_sensitive']
        if filter_['op'] == 'LIKE' and case_sensitive == False:
            filter_['field'] = '''UPPER({})'''.format(filter_['field'])
            filter_['value'] = filter_['value'].upper()
        marker = value_to_marker(filter_['value'])
        conditions.append('''{} {} {}'''.format(filter_['field'], filter_['op'], marker))
        if isinstance(filter_['value'], list):
            bindings += filter_['value']
        else:
            bindings.append(filter_['value'])
    # AND filters
    more_conditions = []
    if table not in ['balances', 'order_matches', 'bet_matches']:
        if start_block != None:
            more_conditions.append('''block_index >= ?''')
            bindings.append(start_block)
        if end_block != None:
            more_conditions.append('''block_index <= ?''')
            bindings.append(end_block)
    elif table in ['order_matches', 'bet_matches']:
        if start_block != None:
            more_conditions.append('''tx0_block_index >= ?''')
            bindings.append(start_block)
        if end_block != None:
            more_conditions.append('''tx1_block_index <= ?''')
            bindings.append(end_block)

    # status
    if isinstance(status, list) and len(status) > 0:
        more_conditions.append('''status IN {}'''.format(value_to_marker(status)))
        bindings += status
    elif isinstance(status, str) and status != '':
        more_conditions.append('''status == ?''')
        bindings.append(status)

    # legacy filters
    if not show_expired and table == 'orders':
        #Ignore BTC orders one block early.
        expire_index = util.CURRENT_BLOCK_INDEX + 1
        more_conditions.append('''((give_asset == ? AND expire_index > ?) OR give_asset != ?)''')
        bindings += [config.BTC, expire_index, config.BTC]

    if (len(conditions) + len(more_conditions)) > 0:
        statement += ''' WHERE'''
        all_conditions = []
        if len(conditions) > 0:
            all_conditions.append('''({})'''.format(''' {} '''.format(filterop.upper()).join(conditions)))
        if len(more_conditions) > 0:
            all_conditions.append('''({})'''.format(''' AND '''.join(more_conditions)))
        statement += ''' {}'''.format(''' AND '''.join(all_conditions))

    # ORDER BY
    if order_by != None:
        statement += ''' ORDER BY {}'''.format(order_by)
        if order_dir != None:
            statement += ''' {}'''.format(order_dir.upper())
    # LIMIT
    if limit:
        statement += ''' LIMIT {}'''.format(limit)
        if offset:
            statement += ''' OFFSET {}'''.format(offset)

    return db_query(db, statement, tuple(bindings))

def compose_transaction(db, name, params,
                        encoding='auto',
                        fee_per_kb=config.DEFAULT_FEE_PER_KB,
                        regular_dust_size=config.DEFAULT_REGULAR_DUST_SIZE,
                        multisig_dust_size=config.DEFAULT_MULTISIG_DUST_SIZE,
                        op_return_value=config.DEFAULT_OP_RETURN_VALUE,
                        pubkey=None,
                        allow_unconfirmed_inputs=False,
                        fee=None,
                        fee_provided=0):
    """Create and return a transaction."""

    # Get provided pubkeys.
    if type(pubkey) == str:
        provided_pubkeys = [pubkey]
    elif type(pubkey) == list:
        provided_pubkeys = pubkey
    elif pubkey == None:
        provided_pubkeys = []
    else:
        assert False

    # Get additional pubkeys from `source` and `destination` params.
    # Convert `source` and `destination` to pubkeyhash form.
    for address_name in ['source', 'destination']:
        if address_name in params:
            address = params[address_name]
            provided_pubkeys += script.extract_pubkeys(address)
            params[address_name] = script.make_pubkeyhash(address)

    # Check validity of collected pubkeys.
    for pubkey in provided_pubkeys:
        if not script.is_fully_valid(binascii.unhexlify(pubkey)):
            raise script.AddressError('invalid public key: {}'.format(pubkey))

    compose_method = sys.modules['lib.messages.{}'.format(name)].compose
    compose_params = inspect.getargspec(compose_method)[0]
    missing_params = [p for p in compose_params if p not in params and p != 'db']
    for param in missing_params:
        params[param] = None

    # try:  # NOTE: For debugging, e.g. with `Invalid Params` error.
    tx_info = compose_method(db, **params)
    return transaction.construct(db, tx_info, encoding=encoding,
                                        fee_per_kb=fee_per_kb,
                                        regular_dust_size=regular_dust_size,
                                        multisig_dust_size=multisig_dust_size,
                                        op_return_value=op_return_value,
                                        provided_pubkeys=provided_pubkeys,
                                        allow_unconfirmed_inputs=allow_unconfirmed_inputs,
                                        exact_fee=fee,
                                        fee_provided=fee_provided)
    # except:
        # import traceback
        # traceback.print_exc()

def sign_transaction(unsigned_tx_hex, private_key_wif):
    """Sign the transaction."""
    return transaction.sign_tx(proxy, unsigned_tx_hex,
        private_key_wif=private_key_wif)

def broadcast_transaction(signed_tx_hex):
    """Broadcast a transaction."""
    if not config.TESTNET and config.BROADCAST_TX_MAINNET in ['bci', 'bci-failover']:
        url = "https://blockchain.info/pushtx"
        params = {'tx': signed_tx_hex}
        response = requests.post(url, data=params)
        if response.text.lower() != 'transaction submitted' or response.status_code != 200:
            if config.BROADCAST_TX_MAINNET == 'bci-failover':
                return transaction.broadcast_tx(signed_tx_hex)
            else:
                raise APIError(response.text)
        return response.text
    else:
        return transaction.broadcast_tx(signed_tx_hex)

def do_transaction(db, name, params, private_key_wif, **kwargs):
    """Create, sign and broadcast transaction."""
    unsigned_tx = compose_transaction(db, proxy, name, params, **kwargs)
    signed_tx = sign_transaction(proxy, unsigned_tx, private_key_wif=private_key_wif)
    return broadcast_transaction(proxy, signed_tx)

def init_api_access_log():
    """Init API logger."""
    api_logger = logging.getLogger("tornado")
    h = logging_handlers.RotatingFileHandler(os.path.join(config.DATA_DIR, "api.access.log"), 'a', API_MAX_LOG_SIZE, API_MAX_LOG_COUNT)
    api_logger.setLevel(logging.INFO)
    api_logger.addHandler(h)
    api_logger.propagate = False

class APIStatusPoller(threading.Thread):
    """Perform regular checks on the state of the backend and the database."""
    def __init__(self):
        self.last_database_check = 0
        threading.Thread.__init__(self)
        self.stop_event = threading.Event()

    def stop(self):
        self.stop_event.set()

    def run(self):
        logger.debug('Starting API Status Poller.')
        global current_api_status_code, current_api_status_response_json
        db = database.get_connection(integrity_check=False)

        while self.stop_event.is_set() != True:
            try:
                # Check that bitcoind is running, communicable, and caught up with the blockchain.
                # Check that the database has caught up with bitcoind.
                if time.time() - self.last_database_check > 10 * 60: # Ten minutes since last check.
                    code = 11
                    logger.debug('Checking backend state.')
                    check.backend_state()
                    code = 12
                    logger.debug('Checking database state.')
                    check.database_state(db, backend.getblockcount())
                    self.last_database_check = time.time()
            except (check.BackendError, exceptions.DatabaseError) as e:
                exception_name = e.__class__.__name__
                exception_text = str(e)
                logger.debug("API Status Poller: %s", exception_text)
                jsonrpc_response = jsonrpc.exceptions.JSONRPCServerError(message=exception_name, data=exception_text)
                current_api_status_code = code
                current_api_status_response_json = jsonrpc_response.json.encode()
            else:
                current_api_status_code = None
                current_api_status_response_json = None
            time.sleep(config.BACKEND_POLL_INTERVAL)

class APIServer(threading.Thread):
    """Handle JSON-RPC API calls."""
    def __init__(self):
        self.is_ready = False
        threading.Thread.__init__(self)
        self.stop_event = threading.Event()
        self.ioloop = IOLoop.instance()

    def stop(self):
        self.ioloop.stop()
        self.join()
        self.stop_event.set()

    def run(self):
        logger.debug('Starting API Server.')
        db = database.get_connection(integrity_check=False)
        app = flask.Flask(__name__)
        auth = HTTPBasicAuth()

        @auth.get_password
        def get_pw(username):
            if username == config.RPC_USER:
                return config.RPC_PASSWORD
            return None

        ######################
        #READ API

        # Generate dynamically get_{table} methods
        def generate_get_method(table):
            def get_method(**kwargs):
                try:
                    return get_rows(db, table=table, **kwargs)
                except TypeError as e:          #TODO: generalise for all API methods
                    raise APIError(str(e))
            return get_method

        for table in API_TABLES:
            new_method = generate_get_method(table)
            new_method.__name__ = 'get_{}'.format(table)
            dispatcher.add_method(new_method)

        @dispatcher.add_method
        def sql(query, bindings=None):
            if bindings == None:
                bindings = []
            return db_query(db, query, tuple(bindings))


        ######################
        #WRITE/ACTION API

        # Generate dynamically create_{transaction} and do_{transaction} methods
        def generate_create_method(tx):

            def split_params(**kwargs):
                transaction_args = {}
                common_args = {}
                private_key_wif = None
                for key in kwargs:
                    if key in COMMONS_ARGS:
                        common_args[key] = kwargs[key]
                    elif key == 'privkey':
                        private_key_wif = kwargs[key]
                    else:
                        transaction_args[key] = kwargs[key]
                return transaction_args, common_args, private_key_wif

            def create_method(**kwargs):
                try:
                    transaction_args, common_args, private_key_wif = split_params(**kwargs)
                    return compose_transaction(db, name=tx, params=transaction_args, **common_args)
                except TypeError as e:          #TODO: generalise for all API methods
                    raise APIError(str(e))

            def do_method(**kwargs):
                try:
                    transaction_args, common_args, private_key_wif = split_params(**kwargs)
                    return do_transaction(db, name=tx, params=transaction_args, private_key_wif=private_key_wif, **common_args)
                except TypeError as e:          #TODO: generalise for all API methods
                    raise APIError(str(e))

            return create_method, do_method

        for tx in API_TRANSACTIONS:
            create_method, do_method = generate_create_method(tx)
            create_method.__name__ = 'create_{}'.format(tx)
            do_method.__name__ = 'do_{}'.format(tx)
            dispatcher.add_method(create_method)
            dispatcher.add_method(do_method)

        @dispatcher.add_method
        def sign_tx(unsigned_tx_hex, privkey):
            return sign_transaction(unsigned_tx_hex, private_key_wif=privkey)

        @dispatcher.add_method
        def broadcast_tx(signed_tx_hex):
            return broadcast_transaction(signed_tx_hex)

        @dispatcher.add_method
        def get_messages(block_index):
            if not isinstance(block_index, int):
                raise APIError("block_index must be an integer.")

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
                    raise APIError("All items in message_indexes are not integers")

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
                raise APIError("assets must be a list of asset names, even if it just contains one entry")
            assetsInfo = []
            for asset in assets:

                # BTC and XCP.
                if asset in [config.BTC, config.XCP]:
                    if asset == config.BTC:
                        supply = backend.get_btc_supply(normalize=False)
                    else:
                        supply = util.xcp_supply(db)

                    assetsInfo.append({
                        'asset': asset,
                        'owner': None,
                        'divisible': True,
                        'locked': False,
                        'supply': supply,
                        'description': '',
                        'issuer': None
                    })
                    continue

                # User‐created asset.
                cursor = db.cursor()
                issuances = list(cursor.execute('''SELECT * FROM issuances WHERE (status = ? AND asset = ?) ORDER BY block_index ASC''', ('valid', asset)))
                cursor.close()
                if not issuances:
                    continue #asset not found, most likely
                else:
                    last_issuance = issuances[-1]
                locked = False
                for e in issuances:
                    if e['locked']: locked = True
                assetsInfo.append({
                    'asset': asset,
                    'owner': last_issuance['issuer'],
                    'divisible': bool(last_issuance['divisible']),
                    'locked': locked,
                    'supply': util.asset_supply(db, asset),
                    'description': last_issuance['description'],
                    'issuer': last_issuance['issuer']})
            return assetsInfo

        @dispatcher.add_method
        def get_block_info(block_index):
            assert isinstance(block_index, int)
            cursor = db.cursor()
            cursor.execute('''SELECT * FROM blocks WHERE block_index = ?''', (block_index,))
            blocks = list(cursor)
            if len(blocks) == 1:
                block = blocks[0]
            elif len(blocks) == 0:
                raise exceptions.DatabaseError('No blocks found.')
            else:
                assert False
            cursor.close()
            return block

        @dispatcher.add_method
        def get_blocks(block_indexes):
            """fetches block info and messages for the specified block indexes"""
            if not isinstance(block_indexes, (list, tuple)):
                raise APIError("block_indexes must be a list of integers.")
            if len(block_indexes) >= 250:
                raise APIError("can only specify up to 250 indexes at a time.")

            block_indexes_str = ','.join([str(x) for x in block_indexes])
            cursor = db.cursor()

            cursor.execute('SELECT * FROM blocks WHERE block_index IN (%s) ORDER BY block_index ASC'
                % (block_indexes_str,))
            blocks = cursor.fetchall()

            cursor.execute('SELECT * FROM messages WHERE block_index IN (%s) ORDER BY block_index ASC, message_index ASC'
                % (block_indexes_str,))
            messages = collections.deque(cursor.fetchall())

            for block in blocks:
                # messages_in_block = []
                block['_messages'] = []
                while len(messages) and messages[0]['block_index'] == block['block_index']:
                    block['_messages'].append(messages.popleft())
            assert not len(messages) #should have been cleared out

            cursor.close()
            return blocks

        @dispatcher.add_method
        def get_running_info():
            latestBlockIndex = backend.getblockcount()

            try:
                check.database_state(db, latestBlockIndex)
            except exceptions.DatabaseError:
                caught_up = False
            else:
                caught_up = True

            try:
                last_block = util.CURRENT_BLOCK_INDEX
            except:
                last_block = None

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
        def get_element_counts():
            counts = {}
            cursor = db.cursor()
            for element in ['transactions', 'blocks', 'debits', 'credits', 'balances', 'sends', 'orders',
                'order_matches', 'btcpays', 'issuances', 'broadcasts', 'bets', 'bet_matches', 'dividends',
                'burns', 'cancels', 'order_expirations', 'bet_expirations', 'order_match_expirations',
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

        @dispatcher.add_method
        def get_holder_count(asset):
            holders = util.holders(db, asset)
            addresses = []
            for holder in holders:
                addresses.append(holder['address'])
            return {asset: len(set(addresses))}

        @dispatcher.add_method
        def get_holders(asset):
            holders = util.holders(db, asset)
            return holders

        @dispatcher.add_method
        def search_raw_transactions(address):
            return backend.searchrawtransactions(address)

        @dispatcher.add_method
        def get_unspent_txouts(address, return_confirmed=False):
            result = backend.get_unspent_txouts(address, return_confirmed=return_confirmed)
            if return_confirmed:
                return {'all': result[0], 'confirmed': result[1]}
            else:
                return result

        @dispatcher.add_method
        def get_tx_info(tx_hex):
            source, destination, btc_amount, fee, data = blocks.get_tx_info(tx_hex, util.CURRENT_BLOCK_INDEX)
            return source, destination, btc_amount, fee, util.hexlify(data)

        @dispatcher.add_method
        def unpack(data_hex):
            data = binascii.unhexlify(data_hex)
            message_type_id = struct.unpack(config.TXTYPE_FORMAT, data[:4])[0]
            message = data[4:]

            for message_type in API_TRANSACTIONS:
                if message_type_id == sys.modules['lib.messages.{}'.format(message_type)].ID:
                    unpack_method = sys.modules['lib.messages.{}'.format(message_type)].unpack
                    unpacked = unpack_method(db, message, util.CURRENT_BLOCK_INDEX)
            return message_type_id, unpacked

        @dispatcher.add_method
        def search_pubkey(pubkeyhash, provided_pubkeys=None):
            return backend.pubkeyhash_to_pubkey(pubkeyhash, provided_pubkeys=provided_pubkeys)

        def _set_cors_headers(response):
            if config.RPC_ALLOW_CORS:
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
                response.headers['Access-Control-Allow-Headers'] = 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type'

        @app.route('/', methods=["OPTIONS",])
        @app.route('/api/', methods=["OPTIONS",])
        def handle_options():
            response = flask.Response('', 204)
            _set_cors_headers(response)
            return response

        @app.route('/', methods=["POST",])
        @app.route('/api/', methods=["POST",])
        @auth.login_required
        def handle_post():
            try:
                request_json = flask.request.get_data().decode('utf-8')
                request_data = json.loads(request_json)
                assert 'id' in request_data and request_data['jsonrpc'] == "2.0" and request_data['method']
                # params may be omitted
            except:
                obj_error = jsonrpc.exceptions.JSONRPCInvalidRequest(data="Invalid JSON-RPC 2.0 request format")
                return flask.Response(obj_error.json.encode(), 200, mimetype='application/json')

            #only arguments passed as a dict are supported
            if request_data.get('params', None) and not isinstance(request_data['params'], dict):
                obj_error = jsonrpc.exceptions.JSONRPCInvalidRequest(
                    data='Arguments must be passed as a JSON object (list of unnamed arguments not supported)')
                return flask.Response(obj_error.json.encode(), 200, mimetype='application/json')

            #return an error if API fails checks
            if not config.FORCE and current_api_status_code:
                return flask.Response(current_api_status_response_json, 200, mimetype='application/json')

            jsonrpc_response = jsonrpc.JSONRPCResponseManager.handle(request_json, dispatcher)
            response = flask.Response(jsonrpc_response.json.encode(), 200, mimetype='application/json')
            _set_cors_headers(response)
            return response

        init_api_access_log()

        http_server = HTTPServer(WSGIContainer(app), xheaders=True)
        try:
            http_server.listen(config.RPC_PORT, address=config.RPC_HOST)
            self.is_ready = True
            self.ioloop.start()
        except OSError:
            raise APIError("Cannot start the API subsystem. Is {} already running, or is something else listening on port {}?".format(config.XCP_CLIENT, config.RPC_PORT))

        db.close()
        http_server.stop()
        self.ioloop.close()
        return

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
