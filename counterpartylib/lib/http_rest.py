#! /usr/bin/python3

"""
Unauthenticated HTTP REST API based on https://github.com/bitcoin/bitcoin/pull/2844.
Allows obtaining block data in JSON and transaction data in hex, binary and JSON.
"""

import threading
import json
import logging
logger = logging.getLogger(__name__)
from logging import handlers as logging_handlers
import binascii

import apsw
import flask
import tornado
from tornado.wsgi import WSGIContainer
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop

from counterpartylib.lib import database, exceptions, config

b58_digits = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

class HTTPRESTError(Exception):
    pass

def init_http_rest_access_log():
    """Initialize HTTP REST API logger."""
    if config.HTTP_REST_LOG:
        access_logger = logging.getLogger("tornado.access")
        access_logger.setLevel(logging.INFO)
        access_logger.propagate = False

        handler = logging_handlers.RotatingFileHandler(config.HTTP_REST_LOG, 'a', API_MAX_LOG_SIZE, API_MAX_LOG_COUNT)
        formatter = tornado.log.LogFormatter(datefmt='%Y-%m-%d-T%H:%M:%S%z')    # Default date format is nuts.
        handler.setFormatter(formatter)
        access_logger.addHandler(handler)

class HTTPRESTServer(threading.Thread):
    """Handle HTTP REST API calls."""
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
        logger.info('Starting HTTP REST API Server.')
        db = database.get_connection(read_only=True, integrity_check=False)
        app = flask.Flask(__name__)

        # Block information. Since counterpartylib doesn't store block hexes, we only support JSON.
        def get_block_json(block_hash):
            """Return JSON data of specified block."""
            cursor = db.cursor()
            blocks = list(cursor.execute('''SELECT * FROM blocks WHERE block_hash = ?''', (block_hash,)))
            cursor.close()
            if len(blocks) == 0:
                raise exceptions.DatabaseError('No block found for hash: %s.' % block_hash)
            elif len(blocks) > 1:
                raise exceptions.DatabaseError('More than one block found for hash: %s.' % block_hash)
            block = blocks[0]
            block_json = json.dumps(block, use_decimal=True)
            return block_json

        # Transaction information.
        def get_tx_hex(tx_hash):
            """Return hex data of specified transaction."""
            cursor = db.cursor()
            txs = list(cursor.execute('''SELECT tx_hex FROM raw_transactions WHERE tx_hash = ?''', (tx_hash,)))
            cursor.close()
            if len(txs) == 0:
                raise exceptions.DatabaseError('No transaction found for hash %s.' % tx_hash)
            elif len(txs) > 1:
                raise exceptions.DatabaseError('More than one transaction found for hash %s.' % tx_hash)
            tx_hex = txs[0][0]
            return tx_hex

        def get_tx_binary(tx_hash):
            """Return binary data of specified transaction."""
            tx_hex = get_tx_hex(tx_hash)
            tx_bin = binascii.unhexlify(tx_hex)
            return tx_bin

        def get_tx_json(tx_hash):
            """Return JSON data of specified transaction."""
            cursor = db.cursor()
            txs = list(cursor.execute('''SELECT * FROM transactions WHERE tx_hash = ?''', (tx_hash,)))
            cursor.close()
            if len(txs) == 0:
                raise exceptions.DatabaseError('No transaction found for hash %s.' % tx_hash)
            elif len(txs) > 1:
                raise exceptions.DatabaseError('More than one transaction found for hash %s.' % tx_hash)
            tx_info = txs[0]
            tx_json = json.dumps(tx_info, use_decimal=True)
            return tx_json

        # Handle blocks route.
        @app.route('/rest/block/<block_hash>.<format>', methods=["GET",])
        def handle_get_block(block_hash, format):
            # Check for tx_hash validity.
            if block_hash == None or block_hash == '' or any([c not in b58_digits for c in block_hash]):
                error = 'Invalid block hash: %s' % block_hash
                return flask.Response(error, 400, mimetype='text/plain')
            try:
                if format == 'json':
                    response_data = get_block_json(block_hash)
                    response = flask.Response(response_data, 200, mimetype='application/json')
                    return response
                else:
                    error = 'Invalid file format: %s. Supported format is .json.' % format
                    return flask.Response(error, 400, mimetype='text/plain')
            except exceptions.DatabaseError as e:
                # Show the database error that was raised as 400.
                return flask.Response(str(e), 400, mimetype='text/plain')

        # Handle transaction route.
        @app.route('/rest/tx/<tx_hash>.<format>', methods=["GET",])
        def handle_get_tx(tx_hash, format):
            # Check for tx_hash validity.
            if tx_hash == None or tx_hash == '' or any([c not in b58_digits for c in tx_hash]):
                error = 'Invalid transaction hash: %s' % tx_hash
                return flask.Response(error, 400, mimetype='application/txt')
            try:
                if format == 'json':
                    # JSON
                    response_data = get_tx_json(tx_hash)
                    response = flask.Response(response_data, 200, mimetype='application/json')
                    return response
                elif format == 'dat':
                    # Binary
                    response_data = get_tx_bin(tx_hash)
                    response = flask.Response(response_data, 200, mimetype='application/octet-stream')
                    return response
                elif format == 'txt':
                    # Hex
                    response_data = get_tx_hex(tx_hash)
                    response = flask.Response(response_data, 200, mimetype='text/plain')
                    return response
                else:
                    error = 'Invalid file format: %s. Supported formats are .json, .dat, .txt.' % format
                    return flask.Response(error, 400, mimetype='text/plain')
            except exceptions.DatabaseError as e:
                # Show the database error that was raised as 400.
                return flask.Response(str(e), 400, mimetype='application/txt')

        init_http_rest_access_log()
        http_server = HTTPServer(WSGIContainer(app), xheaders=True)
        try:
            http_server.listen(config.HTTP_PORT, address=config.HTTP_HOST)
            self.is_ready = True
            self.ioloop.start()
        except OSError:
            raise HTTPRESTError("Cannot start the HTTP REST API subsystem. Is server already running, or is something else listening on port {}?".format(config.HTTP_PORT))

        db.close()
        http_server.stop()
        self.ioloop.close()
        return

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
