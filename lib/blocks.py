"""
Initialise database.

Sieve blockchain for Counterparty transactions, and add them to the database.
"""

import os
import time
import binascii
import struct
import decimal
D = decimal.Decimal
import logging
import collections
from Crypto.Cipher import ARC4
import apsw

from . import (config, exceptions, util, bitcoin)
from . import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, callback, rps, rpsresolve)

# Order matters for FOREIGN KEY constraints.
TABLES = ['credits', 'debits', 'messages'] + \
         ['bet_match_resolutions', 'order_match_expirations',
          'order_matches', 'order_expirations', 'orders', 'bet_match_expirations',
          'bet_matches', 'bet_expirations', 'bets', 'broadcasts', 'btcpays',
          'burns', 'callbacks', 'cancels', 'dividends', 'issuances', 'sends',
          'rps_match_expirations', 'rps_expirations', 'rpsresolves', 'rps_matches', 'rps']

def check_conservation (db):
    logging.debug('Status: Checking for conservation of assets.')

    supplies = util.supplies(db)
    for asset in supplies.keys():

        issued = supplies[asset]
        held = sum([holder['address_quantity'] for holder in util.holders(db, asset)])
        # import json
        # json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))
        # json_print(util.holders(db, asset))
        if held != issued:
            raise exceptions.SanityError('{} {} issued ≠ {} {} held'.format(util.devise(db, issued, asset, 'output'), asset, util.devise(db, held, asset, 'output'), asset))
        logging.debug('Status: {} has been conserved ({} {} both issued and held)'.format(asset, util.devise(db, issued, asset, 'output'), asset))

def parse_tx (db, tx):
    cursor = db.cursor()
    # Burns.
    if tx['destination'] == config.UNSPENDABLE:
        burn.parse(db, tx)
        return

    try:
        message_type_id = struct.unpack(config.TXTYPE_FORMAT, tx['data'][:4])[0]
    except:
        # Mark transaction as of unsupported type.
        message_type_id = None

    # Protocol change.
    rps_enabled = tx['block_index'] >= 308500 or config.TESTNET

    message = tx['data'][4:]
    if message_type_id == send.ID:
        send.parse(db, tx, message)
    elif message_type_id == order.ID:
        order.parse(db, tx, message)
    elif message_type_id == btcpay.ID:
        btcpay.parse(db, tx, message)
    elif message_type_id == issuance.ID:
        issuance.parse(db, tx, message)
    elif message_type_id == broadcast.ID:
        broadcast.parse(db, tx, message)
    elif message_type_id == bet.ID:
        bet.parse(db, tx, message)
    elif message_type_id == dividend.ID:
        dividend.parse(db, tx, message)
    elif message_type_id == cancel.ID:
        cancel.parse(db, tx, message)
    elif message_type_id == callback.ID:
        callback.parse(db, tx, message)
    elif message_type_id == rps.ID and rps_enabled:
        rps.parse(db, tx, message)
    elif message_type_id == rpsresolve.ID and rps_enabled:
        rpsresolve.parse(db, tx, message)
    else:
        cursor.execute('''UPDATE transactions \
                                   SET supported=? \
                                   WHERE tx_hash=?''',
                                (False, tx['tx_hash']))
        if tx['block_index'] != config.MEMPOOL_BLOCK_INDEX:
            logging.info('Unsupported transaction: hash {}; data {}'.format(tx['tx_hash'], tx['data']))
        cursor.close()
        return False

    # Check for conservation of assets every CAREFULNESS transactions.
    if config.CAREFULNESS and not tx['tx_index'] % config.CAREFULNESS:
        check_conservation(db)

    cursor.close()
    return True

def parse_block (db, block_index, block_time):
    cursor = db.cursor()

    # Expire orders, bets and rps.
    order.expire(db, block_index)
    bet.expire(db, block_index, block_time)
    rps.expire(db, block_index)

    # Parse transactions, sorting them by type.
    cursor.execute('''SELECT * FROM transactions \
                      WHERE block_index=? ORDER BY tx_index''',
                   (block_index,))
    for tx in list(cursor):
        parse_tx(db, tx)

    cursor.close()

def initialise(db):
    cursor = db.cursor()

    # Blocks
    cursor.execute('''CREATE TABLE IF NOT EXISTS blocks(
                      block_index INTEGER UNIQUE,
                      block_hash TEXT UNIQUE,
                      block_time INTEGER,
                      PRIMARY KEY (block_index, block_hash))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON blocks (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      index_hash_idx ON blocks (block_index, block_hash)
                   ''')

    # Transactions
    cursor.execute('''CREATE TABLE IF NOT EXISTS transactions(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      block_hash TEXT,
                      block_time INTEGER,
                      source TEXT,
                      destination TEXT,
                      btc_amount INTEGER,
                      fee INTEGER,
                      data BLOB,
                      supported BOOL DEFAULT 1,
                      FOREIGN KEY (block_index, block_hash) REFERENCES blocks(block_index, block_hash),
                      PRIMARY KEY (tx_index, tx_hash, block_index))
                    ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON transactions (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx_index_idx ON transactions (tx_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx_hash_idx ON transactions (tx_hash)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      index_index_idx ON transactions (block_index, tx_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      index_hash_index_idx ON transactions (tx_index, tx_hash, block_index)
                   ''')

    # Purge database of blocks, transactions from before BLOCK_FIRST.
    cursor.execute('''DELETE FROM blocks WHERE block_index < ?''', (config.BLOCK_FIRST,))
    cursor.execute('''DELETE FROM transactions WHERE block_index < ?''', (config.BLOCK_FIRST,))


    # (Valid) debits
    cursor.execute('''CREATE TABLE IF NOT EXISTS debits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      action TEXT,
                      event TEXT,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      address_idx ON debits (address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON debits (asset)
                   ''')

    # (Valid) credits
    cursor.execute('''CREATE TABLE IF NOT EXISTS credits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      calling_function TEXT,
                      event TEXT,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      address_idx ON credits (address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON credits (asset)
                   ''')

    # Balances
    cursor.execute('''CREATE TABLE IF NOT EXISTS balances(
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      address_asset_idx ON balances (address, asset)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      address_idx ON balances (address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON balances (asset)
                   ''')

    # Sends
    cursor.execute('''CREATE TABLE IF NOT EXISTS sends(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON sends (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON sends (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      destination_idx ON sends (destination)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON sends (asset)
                   ''')

    # Orders
    cursor.execute('''CREATE TABLE IF NOT EXISTS orders(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      give_asset TEXT,
                      give_quantity INTEGER,
                      give_remaining INTEGER,
                      get_asset TEXT,
                      get_quantity INTEGER,
                      get_remaining INTEGER,
                      expiration INTEGER,
                      expire_index INTEGER,
                      fee_required INTEGER,
                      fee_required_remaining INTEGER,
                      fee_provided INTEGER,
                      fee_provided_remaining INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      PRIMARY KEY (tx_index, tx_hash))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON orders (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      index_hash_idx ON orders (tx_index, tx_hash)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      expire_idx ON orders (status, expire_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      give_status_idx ON orders (status, give_asset)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      give_get_status_idx ON orders (get_asset, give_asset, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON orders (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      give_asset_idx ON orders (give_asset)
                   ''')

    # Order Matches
    cursor.execute('''CREATE TABLE IF NOT EXISTS order_matches(
                      id TEXT PRIMARY KEY,
                      tx0_index INTEGER,
                      tx0_hash TEXT,
                      tx0_address TEXT,
                      tx1_index INTEGER,
                      tx1_hash TEXT,
                      tx1_address TEXT,
                      forward_asset TEXT,
                      forward_quantity INTEGER,
                      backward_asset TEXT,
                      backward_quantity INTEGER,
                      tx0_block_index INTEGER,
                      tx1_block_index INTEGER,
                      block_index INTEGER,
                      tx0_expiration INTEGER,
                      tx1_expiration INTEGER,
                      match_expire_index INTEGER,
                      fee_paid INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx0_index, tx0_hash, tx0_block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      FOREIGN KEY (tx1_index, tx1_hash, tx1_block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      match_expire_idx ON order_matches (status, match_expire_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      forward_status_idx ON order_matches (forward_asset, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      backward_status_idx ON order_matches (backward_asset, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      id_idx ON order_matches (id)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx0_address_idx ON order_matches (tx0_address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx1_address_idx ON order_matches (tx1_address)
                   ''')

    # BTCpays
    cursor.execute('''CREATE TABLE IF NOT EXISTS btcpays(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      btc_amount INTEGER,
                      order_match_id TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
                      # Disallows invalids: FOREIGN KEY (order_match_id) REFERENCES order_matches(id))
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON btcpays (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON btcpays (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      destination_idx ON btcpays (destination)
                   ''')

    # Issuances
    cursor.execute('''CREATE TABLE IF NOT EXISTS issuances(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      asset TEXT,
                      quantity INTEGER,
                      divisible BOOL,
                      source TEXT,
                      issuer TEXT,
                      transfer BOOL,
                      callable BOOL,
                      call_date INTEGER,
                      call_price REAL,
                      description TEXT,
                      fee_paid INTEGER,
                      locked BOOL,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON issuances (block_index)
                    ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      valid_asset_idx ON issuances (asset, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_idx ON issuances (status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON issuances (source)
                   ''')

    # Broadcasts
    cursor.execute('''CREATE TABLE IF NOT EXISTS broadcasts(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      timestamp INTEGER,
                      value REAL,
                      fee_fraction_int INTEGER,
                      text TEXT,
                      locked BOOL,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON broadcasts (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_source_idx ON broadcasts (status, source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_source_index_idx ON broadcasts (status, source, tx_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      timestamp_idx ON broadcasts (timestamp)
                   ''')

    # Bets.
    cursor.execute('''CREATE TABLE IF NOT EXISTS bets(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      feed_address TEXT,
                      bet_type INTEGER,
                      deadline INTEGER,
                      wager_quantity INTEGER,
                      wager_remaining INTEGER,
                      counterwager_quantity INTEGER,
                      counterwager_remaining INTEGER,
                      target_value REAL,
                      leverage INTEGER,
                      expiration INTEGER,
                      expire_index INTEGER,
                      fee_fraction_int INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      PRIMARY KEY (tx_index, tx_hash))
                  ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON bets (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      index_hash_idx ON bets (tx_index, tx_hash)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      expire_idx ON bets (status, expire_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      feed_valid_bettype_idx ON bets (feed_address, status, bet_type)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON bets (source)
                   ''')

    # Bet Matches
    cursor.execute('''CREATE TABLE IF NOT EXISTS bet_matches(
                      id TEXT PRIMARY KEY,
                      tx0_index INTEGER,
                      tx0_hash TEXT,
                      tx0_address TEXT,
                      tx1_index INTEGER,
                      tx1_hash TEXT,
                      tx1_address TEXT,
                      tx0_bet_type INTEGER,
                      tx1_bet_type INTEGER,
                      feed_address TEXT,
                      initial_value INTEGER,
                      deadline INTEGER,
                      target_value REAL,
                      leverage INTEGER,
                      forward_quantity INTEGER,
                      backward_quantity INTEGER,
                      tx0_block_index INTEGER,
                      tx1_block_index INTEGER,
                      block_index INTEGER,
                      tx0_expiration INTEGER,
                      tx1_expiration INTEGER,
                      match_expire_index INTEGER,
                      fee_fraction_int INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx0_index, tx0_hash, tx0_block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      FOREIGN KEY (tx1_index, tx1_hash, tx1_block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      match_expire_idx ON bet_matches (status, match_expire_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      valid_feed_idx ON bet_matches (feed_address, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      id_idx ON bet_matches (id)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx0_address_idx ON bet_matches (tx0_address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx1_address_idx ON bet_matches (tx1_address)
                   ''')

    # Dividends
    cursor.execute('''CREATE TABLE IF NOT EXISTS dividends(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      asset TEXT,
                      dividend_asset TEXT,
                      quantity_per_unit INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON dividends (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON dividends (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON dividends (asset)
                   ''')

    # Burns
    cursor.execute('''CREATE TABLE IF NOT EXISTS burns(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      burned INTEGER,
                      earned INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_idx ON burns (status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      address_idx ON burns (source)
                   ''')

    # Cancels
    cursor.execute('''CREATE TABLE IF NOT EXISTS cancels(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      offer_hash TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
                      # Offer hash is not a foreign key. (And it cannot be, because of some invalid cancels.)
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      cancels_block_index_idx ON cancels (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON cancels (source)
                   ''')

    # Callbacks
    cursor.execute('''CREATE TABLE IF NOT EXISTS callbacks(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      fraction TEXT,
                      asset TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON callbacks (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON callbacks (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON callbacks (asset)
                   ''')

    # RPS (Rock-Paper-Scissors)
    cursor.execute('''CREATE TABLE IF NOT EXISTS rps(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      possible_moves INTEGER,
                      wager INTEGER,
                      move_random_hash TEXT,
                      expiration INTEGER,
                      expire_index INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      PRIMARY KEY (tx_index, tx_hash))
                  ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON rps (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      matching_idx ON rps (wager, possible_moves)
                   ''')

    # RPS Matches
    cursor.execute('''CREATE TABLE IF NOT EXISTS rps_matches(
                      id TEXT PRIMARY KEY,
                      tx0_index INTEGER,
                      tx0_hash TEXT,
                      tx0_address TEXT,
                      tx1_index INTEGER,
                      tx1_hash TEXT,
                      tx1_address TEXT,
                      tx0_move_random_hash TEXT,
                      tx1_move_random_hash TEXT,
                      wager INTEGER,
                      possible_moves INTEGER,
                      tx0_block_index INTEGER,
                      tx1_block_index INTEGER,
                      block_index INTEGER,
                      tx0_expiration INTEGER,
                      tx1_expiration INTEGER,
                      match_expire_index INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx0_index, tx0_hash, tx0_block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      FOREIGN KEY (tx1_index, tx1_hash, tx1_block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      rps_match_expire_idx ON rps_matches (status, match_expire_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      rps_tx0_address_idx ON rps_matches (tx0_address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      rps_tx1_address_idx ON rps_matches (tx1_address)
                   ''')

    # RPS Resolves
    cursor.execute('''CREATE TABLE IF NOT EXISTS rpsresolves(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      move INTEGER,
                      random TEXT,
                      rps_match_id TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON rpsresolves (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON rpsresolves (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      rps_match_id_idx ON rpsresolves (rps_match_id)
                   ''')

    # Order Expirations
    cursor.execute('''CREATE TABLE IF NOT EXISTS order_expirations(
                      order_index INTEGER PRIMARY KEY,
                      order_hash TEXT UNIQUE,
                      source TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index),
                      FOREIGN KEY (order_index, order_hash) REFERENCES orders(tx_index, tx_hash))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON order_expirations (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON order_expirations (source)
                   ''')

    # Bet Expirations
    cursor.execute('''CREATE TABLE IF NOT EXISTS bet_expirations(
                      bet_index INTEGER PRIMARY KEY,
                      bet_hash TEXT UNIQUE,
                      source TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index),
                      FOREIGN KEY (bet_index, bet_hash) REFERENCES bets(tx_index, tx_hash))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON bet_expirations (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON bet_expirations (source)
                   ''')

    # RPS Expirations
    cursor.execute('''CREATE TABLE IF NOT EXISTS rps_expirations(
                      rps_index INTEGER PRIMARY KEY,
                      rps_hash TEXT UNIQUE,
                      source TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index),
                      FOREIGN KEY (rps_index, rps_hash) REFERENCES rps(tx_index, tx_hash))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON rps_expirations (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON rps_expirations (source)
                   ''')

    # Order Match Expirations
    cursor.execute('''CREATE TABLE IF NOT EXISTS order_match_expirations(
                      order_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (order_match_id) REFERENCES order_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON order_match_expirations (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx0_address_idx ON order_match_expirations (tx0_address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx1_address_idx ON order_match_expirations (tx1_address)
                   ''')

    # Bet Match Expirations
    cursor.execute('''CREATE TABLE IF NOT EXISTS bet_match_expirations(
                      bet_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (bet_match_id) REFERENCES bet_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON bet_match_expirations (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx0_address_idx ON bet_match_expirations (tx0_address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx1_address_idx ON bet_match_expirations (tx1_address)
                   ''')

    # Bet Match Resolutions
    cursor.execute('''CREATE TABLE IF NOT EXISTS bet_match_resolutions(
                      bet_match_id TEXT PRIMARY KEY,
                      bet_match_type_id INTEGER,
                      block_index INTEGER,
                      winner TEXT,
                      settled BOOL,
                      bull_credit INTEGER,
                      bear_credit INTEGER,
                      escrow_less_fee INTEGER,
                      fee INTEGER,
                      FOREIGN KEY (bet_match_id) REFERENCES bet_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   ''')

    # RPS Match Expirations
    cursor.execute('''CREATE TABLE IF NOT EXISTS rps_match_expirations(
                      rps_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (rps_match_id) REFERENCES rps_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON rps_match_expirations (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx0_address_idx ON rps_match_expirations (tx0_address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx1_address_idx ON rps_match_expirations (tx1_address)
                   ''')

    # Messages
    cursor.execute('''CREATE TABLE IF NOT EXISTS messages(
                      message_index INTEGER PRIMARY KEY,
                      block_index INTEGER,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER)
                  ''')
                      # TODO: FOREIGN KEY (block_index) REFERENCES blocks(block_index) DEFERRABLE INITIALLY DEFERRED)
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON messages (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_message_index_idx ON messages (block_index, message_index)
                   ''')

    # Mempool messages
    # NOTE: `status`, 'block_index` are removed from bindings.
    cursor.execute('''DROP TABLE IF EXISTS mempool''')
    cursor.execute('''CREATE TABLE mempool(
                      tx_hash TEXT,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER)
                  ''')

    cursor.close()

def get_pubkeyhash (scriptpubkey):
    asm = scriptpubkey['asm'].split(' ')
    if len(asm) != 5 or asm[0] != 'OP_DUP' or asm[1] != 'OP_HASH160' or asm[3] != 'OP_EQUALVERIFY' or asm[4] != 'OP_CHECKSIG':
        return False
    return asm[2]

def get_address (scriptpubkey):
    pubkeyhash = get_pubkeyhash(scriptpubkey)
    if not pubkeyhash: return False

    address = bitcoin.base58_check_encode(pubkeyhash, config.ADDRESSVERSION)

    # Test decoding of address.
    if address != config.UNSPENDABLE and binascii.unhexlify(bytes(pubkeyhash, 'utf-8')) != bitcoin.base58_decode(address, config.ADDRESSVERSION):
        return False

    return address

def get_tx_info (tx, block_index):
    """
    The destination, if it exists, always comes before the data output; the
    change, if it exists, always comes after.
    """

    # Fee is the input values minus output values.
    fee = 0

    # Get destination output and data output.
    destination, btc_amount, data = None, None, b''
    pubkeyhash_encoding = False
    for vout in tx['vout']:
        fee -= vout['value'] * config.UNIT

        # Sum data chunks to get data. (Can mix OP_RETURN and multi-sig.)
        asm = vout['scriptPubKey']['asm'].split(' ')
        if len(asm) == 2 and asm[0] == 'OP_RETURN':                                                 # OP_RETURN
            try: data_chunk = binascii.unhexlify(bytes(asm[1], 'utf-8'))
            except binascii.Error: continue
            data += data_chunk
        elif len(asm) == 5 and asm[0] == '1' and asm[3] == '2' and asm[4] == 'OP_CHECKMULTISIG':    # Multi-sig
            try: data_pubkey = binascii.unhexlify(bytes(asm[2], 'utf-8'))
            except binascii.Error: continue
            data_chunk_length = data_pubkey[0]  # No ord() necessary.
            data_chunk = data_pubkey[1:data_chunk_length + 1]
            data += data_chunk
        elif len(asm) == 5 and (block_index >= 293000 or config.TESTNET):    # Protocol change.
            # Be strict.
            pubkeyhash_string = get_pubkeyhash(vout['scriptPubKey'])
            try: pubkeyhash = binascii.unhexlify(bytes(pubkeyhash_string, 'utf-8'))
            except binascii.Error: continue

            if 'coinbase' in tx['vin'][0]: return b'', None, None, None, None
            obj1 = ARC4.new(binascii.unhexlify(bytes(tx['vin'][0]['txid'], 'utf-8')))
            data_pubkey = obj1.decrypt(pubkeyhash)
            if data_pubkey[1:9] == config.PREFIX or pubkeyhash_encoding:
                pubkeyhash_encoding = True
                data_chunk_length = data_pubkey[0]  # No ord() necessary.
                data_chunk = data_pubkey[1:data_chunk_length + 1]
                if data_chunk[-8:] == config.PREFIX:
                    data += data_chunk[:-8]
                    break
                else:
                    data += data_chunk

        # Destination is the first output before the data.
        if not destination and not btc_amount and not data:
            address = get_address(vout['scriptPubKey'])
            if address:
                destination = address
                btc_amount = round(vout['value'] * config.UNIT) # Floats are awful.

    # Check for, and strip away, prefix (except for burns).
    if destination == config.UNSPENDABLE:
        pass
    elif data[:len(config.PREFIX)] == config.PREFIX:
        data = data[len(config.PREFIX):]
    else:
        return b'', None, None, None, None

    # Only look for source if data were found or destination is UNSPENDABLE, for speed.
    if not data and destination != config.UNSPENDABLE:
        return b'', None, None, None, None

    # Collect all possible source addresses; ignore coinbase transactions and anything but the simplest Pay‐to‐PubkeyHash inputs.
    source_list = []
    for vin in tx['vin']:                                               # Loop through input transactions.
        if 'coinbase' in vin: return b'', None, None, None, None
        vin_tx = bitcoin.get_raw_transaction(vin['txid'])     # Get the full transaction data for this input transaction.
        vout = vin_tx['vout'][vin['vout']]
        fee += vout['value'] * config.UNIT

        address = get_address(vout['scriptPubKey'])
        if not address: return b'', None, None, None, None
        else: source_list.append(address)

    # Require that all possible source addresses be the same.
    if all(x == source_list[0] for x in source_list): source = source_list[0]
    else: source = None

    return source, destination, btc_amount, round(fee), data


def reparse (db, block_index=None, quiet=False):
    """Reparse all transactions (atomically). If block_index is set, rollback
    to the end of that block.
    """
    # TODO: This is not thread-safe!
    logging.warning('Status: Reparsing all transactions.')
    cursor = db.cursor()

    with db:

        # Delete all of the results of parsing.
        for table in TABLES + ['balances']:
            cursor.execute('''DROP TABLE IF EXISTS {}'''.format(table))

        # For rollbacks, just delete new blocks and then reparse what’s left.
        if block_index:
            cursor.execute('''DELETE FROM transactions WHERE block_index > ?''', (block_index,))
            cursor.execute('''DELETE FROM blocks WHERE block_index > ?''', (block_index,))

        # Reparse all blocks, transactions.
        if quiet:
            log = logging.getLogger('')
            log.setLevel(logging.WARNING)
        initialise(db)
        cursor.execute('''SELECT * FROM blocks ORDER BY block_index''')
        for block in cursor.fetchall():
            logging.info('Block (re‐parse): {}'.format(str(block['block_index'])))
            parse_block(db, block['block_index'], block['block_time'])
        if quiet:
            log.setLevel(logging.INFO)

        # Check for conservation of assets.
        check_conservation(db)

        # Update minor version number.
        minor_version = cursor.execute('PRAGMA user_version = {}'.format(int(config.VERSION_MINOR))) # Syntax?!
        logging.info('Status: Database minor version number updated.')

    cursor.close()
    return

def list_tx (db, block_hash, block_index, block_time, tx_hash, tx_index):
    cursor = db.cursor()
    # Get the important details about each transaction.
    tx = bitcoin.get_raw_transaction(tx_hash)
    logging.debug('Status: Examining transaction {}.'.format(tx_hash))
    source, destination, btc_amount, fee, data = get_tx_info(tx, block_index)
    if source and (data or destination == config.UNSPENDABLE):
        cursor.execute('''INSERT INTO transactions(
                            tx_index,
                            tx_hash,
                            block_index,
                            block_hash,
                            block_time,
                            source,
                            destination,
                            btc_amount,
                            fee,
                            data) VALUES(?,?,?,?,?,?,?,?,?,?)''',
                            (tx_index,
                             tx_hash,
                             block_index,
                             block_hash,
                             block_time,
                             source,
                             destination,
                             btc_amount,
                             fee,
                             data)
                      )
    cursor.close()
    return

def follow (db):
    # TODO: This is not thread-safe!
    cursor = db.cursor()

    # Initialise.
    initialise(db)

    # Get index of last block.
    try:
        block_index = util.last_block(db)['block_index'] + 1

        # Reparse all transactions if minor version has changed.
        minor_version = cursor.execute('PRAGMA user_version').fetchall()[0]['user_version']
        if minor_version != config.VERSION_MINOR:
            logging.info('Status: client minor version number mismatch ({} ≠ {}).'.format(minor_version, config.VERSION_MINOR))
            reparse(db, quiet=False)
        logging.info('Status: Connecting to backend.')
        bitcoin.get_info()
        logging.info('Status: Resuming parsing.')

    except exceptions.DatabaseError:
        logging.warning('Status: New database.')
        block_index = config.BLOCK_FIRST

    # Get index of last transaction.
    txes = list(cursor.execute('''SELECT * FROM transactions WHERE tx_index = (SELECT MAX(tx_index) from transactions)'''))
    if txes:
        assert len(txes) == 1
        tx_index = txes[0]['tx_index'] + 1
    else:
        tx_index = 0

    not_supported = {}   # No false positives. Use a dict to allow for O(1) lookups
    not_supported_sorted = collections.deque()
    # ^ Entries in form of (block_index, tx_hash), oldest first. Allows for easy removal of past, unncessary entries 
    mempool_initialised = False
    # a reorg can happen without the block count increasing, or even for that
        # matter, with the block count decreasing. This should only delay
        # processing of the new blocks a bit.
    while True:

        # Get new blocks.
        block_count = bitcoin.get_block_count()
        if block_index <= block_count:

            logging.info('Block: {}'.format(str(block_index)))

            # Backwards check for incorrect blocks due to chain reorganisation, and stop when a common parent is found.
            c = block_index
            requires_rollback = False
            while True:
                if c == config.BLOCK_FIRST: break

                # Bitcoind parent hash.
                c_hash = bitcoin.get_block_hash(c)
                c_block = bitcoin.get_block(c_hash)
                bitcoind_parent = c_block['previousblockhash']

                # DB parent hash.
                blocks = list(cursor.execute('''SELECT * FROM blocks
                                                WHERE block_index = ?''', (c - 1,)))
                if len(blocks) != 1: break  # For empty DB.
                db_parent = blocks[0]['block_hash']

                # Compare.
                if db_parent == bitcoind_parent:
                    break
                else:
                    c -= 1
                    requires_rollback = True

            # Rollback for reorganisation.
            if requires_rollback:
                # Record reorganisation.
                logging.warning('Status: Blockchain reorganisation at block {}.'.format(c))
                util.message(db, block_index, 'reorg', None, {'block_index': c})

                # Rollback the DB.
                reparse(db, block_index=c-1, quiet=True)
                block_index = c
                continue

            # Get and parse transactions in this block (atomically).
            block_hash = bitcoin.get_block_hash(block_index)
            block = bitcoin.get_block(block_hash)
            block_time = block['time']
            tx_hash_list = block['tx']
            with db:
                # List the block.
                cursor.execute('''INSERT INTO blocks(
                                    block_index,
                                    block_hash,
                                    block_time) VALUES(?,?,?)''',
                                    (block_index,
                                    block_hash,
                                    block_time)
                              )

                # List the transactions in the block.
                for tx_hash in tx_hash_list:
                    list_tx(db, block_hash, block_index, block_time, tx_hash, tx_index)
                    tx_index += 1

                # Parse the transactions in the block.
                parse_block(db, block_index, block_time)

            # When newly caught up, check for conservation of assets.
            if block_index == block_count:
                check_conservation(db)

            # Remove any non‐supported transactions older than ten blocks.
            while len(not_supported_sorted) and not_supported_sorted[0][0] <= block_index - 10:
                (i, tx_h) = not_supported_sorted.popleft()
                del not_supported[tx_h]
            
            # Increment block index.
            block_count = bitcoin.get_block_count()
            block_index +=1

        else:
            # First mempool fill for session?
            if mempool_initialised:
                logging.debug('Status: Updating mempool.')
            else:
                logging.debug('Status: Initialising mempool.')

            # Get old counterpartyd mempool.
            old_mempool = list(cursor.execute('''SELECT * FROM mempool'''))
            old_mempool_hashes = [message['tx_hash'] for message in old_mempool]

            # Fake values for fake block.
            curr_time = int(time.time())
            mempool_tx_index = tx_index

            # For each transaction in Bitcoin Core mempool, if it’s new, create
            # a fake block, a fake transaction, capture the generated messages,
            # and then save those messages.
            # Every transaction in mempool is parsed independently. (DB is rolled back after each one.)
            mempool = []
            for tx_hash in bitcoin.get_mempool():

                # If already in counterpartyd mempool, copy to new one.
                if tx_hash in old_mempool_hashes:
                    for message in old_mempool:
                        if message['tx_hash'] == tx_hash:
                            mempool.append((tx_hash, message))

                # If already skipped, skip it again.
                elif tx_hash not in not_supported:

                    # Else: list, parse and save it.
                    try:
                        with db:
                            # List the fake block.
                            cursor.execute('''INSERT INTO blocks(
                                                block_index,
                                                block_hash,
                                                block_time) VALUES(?,?,?)''',
                                                (config.MEMPOOL_BLOCK_INDEX,
                                                 config.MEMPOOL_BLOCK_HASH,
                                                 curr_time)
                                          )

                            # List transaction.
                            try:    # Sometimes the transactions can’t be found: `{'code': -5, 'message': 'No information available about transaction'} Is txindex enabled in Bitcoind?`
                                list_tx(db, config.MEMPOOL_BLOCK_HASH, config.MEMPOOL_BLOCK_INDEX, curr_time, tx_hash, mempool_tx_index)
                                mempool_tx_index += 1
                            except exceptions.BitcoindError:
                                assert False

                            # Parse transaction.
                            cursor.execute('''SELECT * FROM transactions \
                                              WHERE tx_hash = ?''',
                                           (tx_hash,))
                            transactions = list(cursor)
                            if transactions:
                                assert len(transactions) == 1
                                transaction = transactions[0]
                                supported = parse_tx(db, transaction)
                                if not supported:
                                    not_supported[tx_hash] = ''
                                    not_supported_sorted.append((block_index, tx_hash))
                            else:
                                # If a transaction hasn’t been added to the
                                # table `transactions`, then it’s not a
                                # Counterparty transaction.
                                not_supported[tx_hash] = ''
                                not_supported_sorted.append((block_index, tx_hash))
                                assert False

                            # Save transaction and side‐effects in memory.
                            cursor.execute('''SELECT * FROM messages WHERE block_index = ?''', (config.MEMPOOL_BLOCK_INDEX,))
                            for message in list(cursor):
                                mempool.append((tx_hash, message))

                            # Rollback.
                            assert False
                    except AssertionError:
                        pass

            # Re‐write mempool messages to database.
            with db:
                cursor.execute('''DELETE FROM mempool''')
                for message in mempool:
                    tx_hash, new_message = message
                    new_message['tx_hash'] = tx_hash
                    cursor.execute('''INSERT INTO mempool VALUES(:tx_hash, :command, :category, :bindings, :timestamp)''', (new_message))

            # Wait
            mempool_initialised = True
            time.sleep(2)

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
