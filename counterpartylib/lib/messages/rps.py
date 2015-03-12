#! /usr/bin/python3

"""
Transaction 1: rps (Open the game)
source: address used to play the game
wager: amount to bet
move_random_hash: sha256(sha256(move + random)) (stored as bytes, 16 bytes random)
possible_moves: arbitrary odd number >= 3
expiration: how many blocks the game is valid

Matching conditions:
- tx0_possible_moves = tx1_possible_moves
- tx0_wager = tx1_wager

Transaction 2:  rpsresolve (Resolve the game)
source: same address as first transaction
random: 16 bytes random
move: the move number
rps_match_id: matching id
"""

import struct
import decimal
D = decimal.Decimal
import time
import binascii
import string

from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import util
from counterpartylib.lib import log

# possible_moves wager move_random_hash expiration
FORMAT = '>HQ32sI'
LENGTH = 2 + 8 + 32 + 4
ID = 80

def initialise (db):
    cursor = db.cursor()

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
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_idx ON rps (status)
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
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_idx ON rps_matches (status)
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


def cancel_rps (db, rps, status, block_index):
    cursor = db.cursor()

    # Update status of rps.
    bindings = {
        'status': status,
        'tx_hash': rps['tx_hash']
    }
    sql='''UPDATE rps SET status = :status WHERE tx_hash = :tx_hash'''
    cursor.execute(sql, bindings)
    log.message(db, block_index, 'update', 'rps', bindings)

    util.credit(db, rps['source'], 'XCP', rps['wager'], action='recredit wager', event=rps['tx_hash'])

    cursor.close()

def update_rps_match_status (db, rps_match, status, block_index):
    cursor = db.cursor()

    if status in ['expired', 'concluded: tie']:
        # Recredit tx0 address.
        util.credit(db, rps_match['tx0_address'], 'XCP',
                    rps_match['wager'], action='recredit wager', event=rps_match['id'])
        # Recredit tx1 address.
        util.credit(db, rps_match['tx1_address'], 'XCP',
                    rps_match['wager'], action='recredit wager', event=rps_match['id'])
    elif status.startswith('concluded'):
        # Credit the winner
        winner = rps_match['tx0_address'] if status == 'concluded: first player wins' else rps_match['tx1_address']
        util.credit(db, winner, 'XCP',
                    2 * rps_match['wager'], action='wins', event=rps_match['id'])

    # Update status of rps match.
    bindings = {
        'status': status,
        'rps_match_id': rps_match['id']
    }
    sql='UPDATE rps_matches SET status = :status WHERE id = :rps_match_id'
    cursor.execute(sql, bindings)
    log.message(db, block_index, 'update', 'rps_matches', bindings)

    cursor.close()

def validate (db, source, possible_moves, wager, move_random_hash, expiration, block_index):
    problems = []

    if util.enabled('disable_rps'):
        problems.append('rps disabled')

    if not isinstance(possible_moves, int):
        problems.append('possible_moves must be a integer')
        return problems
    if not isinstance(wager, int):
        problems.append('wager must be in satoshis')
        return problems
    if not isinstance(expiration, int):
        problems.append('expiration must be expressed as an integer block delta')
        return problems

    if not all(c in string.hexdigits for c in move_random_hash):
        problems.append('move_random_hash must be an hexadecimal string')
        return problems
    move_random_hash_bytes = binascii.unhexlify(move_random_hash)

    if possible_moves < 3:
        problems.append('possible moves must be at least 3')
    if possible_moves % 2 == 0:
        problems.append('possible moves must be odd')
    if wager <= 0:
        problems.append('non‐positive wager')
    if expiration < 0: problems.append('negative expiration')
    if expiration == 0 and not (block_index >= 317500 or config.TESTNET):   # Protocol change.
        problems.append('zero expiration')
    if expiration > config.MAX_EXPIRATION:
        problems.append('expiration overflow')
    if len(move_random_hash_bytes) != 32:
        problems.append('move_random_hash must be 32 bytes in hexadecimal format')

    return problems

def compose(db, source, possible_moves, wager, move_random_hash, expiration):

    problems = validate(db, source, possible_moves, wager, move_random_hash, expiration, util.CURRENT_BLOCK_INDEX)

    if problems: raise exceptions.ComposeError(problems)

    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, possible_moves, wager, binascii.unhexlify(move_random_hash), expiration)

    return (source, [], data)

def parse(db, tx, message):
    rps_parse_cursor = db.cursor()
    # Unpack message.
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        (possible_moves, wager, move_random_hash, expiration) = struct.unpack(FORMAT, message)
        status = 'open'
    except (exceptions.UnpackError, struct.error):
        (possible_moves, wager, move_random_hash, expiration) = 0, 0, '', 0
        status = 'invalid: could not unpack'

    if status == 'open':
        move_random_hash = binascii.hexlify(move_random_hash).decode('utf8')
        # Overbet
        rps_parse_cursor.execute('''SELECT * FROM balances \
                                    WHERE (address = ? AND asset = ?)''', (tx['source'], 'XCP'))
        balances = list(rps_parse_cursor)
        if not balances:
            wager = 0
        else:
            balance = balances[0]['quantity']
            if balance < wager:
                wager = balance

        problems = validate(db, tx['source'], possible_moves, wager, move_random_hash, expiration, tx['block_index'])
        if problems: status = 'invalid: {}'.format(', '.join(problems))

    # Debit quantity wagered. (Escrow.)
    if status == 'open':
        util.debit(db, tx['source'], 'XCP', wager, action="open RPS", event=tx['tx_hash'])

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'possible_moves': possible_moves,
        'wager': wager,
        'move_random_hash': move_random_hash,
        'expiration': expiration,
        'expire_index': tx['block_index'] + expiration,
        'status': status,
    }
    sql = '''INSERT INTO rps VALUES (:tx_index, :tx_hash, :block_index, :source, :possible_moves, :wager, :move_random_hash, :expiration, :expire_index, :status)'''
    rps_parse_cursor.execute(sql, bindings)

    # Match.
    if status == 'open':
        match(db, tx, tx['block_index'])

    rps_parse_cursor.close()

def match (db, tx, block_index):
    cursor = db.cursor()

    # Get rps in question.
    rps = list(cursor.execute('''SELECT * FROM rps WHERE tx_index = ? AND status = ?''', (tx['tx_index'], 'open')))
    if not rps:
        cursor.close()
        return
    else:
        assert len(rps) == 1
    tx1 = rps[0]
    possible_moves = tx1['possible_moves']
    wager = tx1['wager']
    tx1_status = 'open'

    # Get rps match
    bindings = (possible_moves, 'open', wager, tx1['source'])
    # dont match twice same RPS
    already_matched = []
    old_rps_matches = cursor.execute('''SELECT * FROM rps_matches WHERE tx0_hash = ? OR tx1_hash = ?''', (tx1['tx_hash'], tx1['tx_hash']))
    for old_rps_match in old_rps_matches:
        counter_tx_hash = old_rps_match['tx1_hash'] if tx1['tx_hash'] == old_rps_match['tx0_hash'] else old_rps_match['tx0_hash']
        already_matched.append(counter_tx_hash)
    already_matched_cond = ''
    if already_matched:
        already_matched_cond = '''AND tx_hash NOT IN ({})'''.format(','.join(['?' for e in range(0, len(already_matched))]))
        bindings += tuple(already_matched)

    sql = '''SELECT * FROM rps WHERE (possible_moves = ? AND status = ? AND wager = ? AND source != ? {}) ORDER BY tx_index LIMIT 1'''.format(already_matched_cond)
    rps_matches = list(cursor.execute(sql, bindings))

    if rps_matches:
        tx0 = rps_matches[0]

        # update status
        for txn in [tx0, tx1]:
            bindings = {
                'status': 'matched',
                'tx_index': txn['tx_index']
            }
            cursor.execute('''UPDATE rps SET status = :status WHERE tx_index = :tx_index''', bindings)
            log.message(db, block_index, 'update', 'rps', bindings)

        bindings = {
            'id': util.make_id(tx0['tx_hash'], tx1['tx_hash']),
            'tx0_index': tx0['tx_index'],
            'tx0_hash': tx0['tx_hash'],
            'tx0_address': tx0['source'],
            'tx1_index': tx1['tx_index'],
            'tx1_hash': tx1['tx_hash'],
            'tx1_address': tx1['source'],
            'tx0_move_random_hash': tx0['move_random_hash'],
            'tx1_move_random_hash': tx1['move_random_hash'],
            'wager': wager,
            'possible_moves': possible_moves,
            'tx0_block_index': tx0['block_index'],
            'tx1_block_index': tx1['block_index'],
            'block_index': block_index,
            'tx0_expiration': tx0['expiration'],
            'tx1_expiration': tx1['expiration'],
            'match_expire_index': block_index + 20,
            'status': 'pending'
        }
        sql = '''INSERT INTO rps_matches VALUES (:id, :tx0_index, :tx0_hash, :tx0_address, :tx1_index, :tx1_hash, :tx1_address,
                                                 :tx0_move_random_hash, :tx1_move_random_hash, :wager, :possible_moves,
                                                 :tx0_block_index, :tx1_block_index, :block_index, :tx0_expiration, :tx1_expiration,
                                                 :match_expire_index, :status)'''
        cursor.execute(sql, bindings)

    cursor.close()

def expire (db, block_index):
    cursor = db.cursor()

    # Expire rps and give refunds for the quantity wager.
    cursor.execute('''SELECT * FROM rps WHERE (status = ? AND expire_index < ?)''', ('open', block_index))
    for rps in cursor.fetchall():
        cancel_rps(db, rps, 'expired', block_index)

        # Record rps expiration.
        bindings = {
            'rps_index': rps['tx_index'],
            'rps_hash': rps['tx_hash'],
            'source': rps['source'],
            'block_index': block_index
        }
        sql = '''INSERT INTO rps_expirations VALUES (:rps_index, :rps_hash, :source, :block_index)'''
        cursor.execute(sql, bindings)

    # Expire rps matches
    expire_bindings = ('pending', 'pending and resolved', 'resolved and pending', block_index)
    cursor.execute('''SELECT * FROM rps_matches WHERE (status IN (?, ?, ?) AND match_expire_index < ?)''', expire_bindings)
    for rps_match in cursor.fetchall():

        new_rps_match_status = 'expired'
        # pending loses against resolved
        if rps_match['status'] == 'pending and resolved':
            new_rps_match_status = 'concluded: second player wins'
        elif rps_match['status'] == 'resolved and pending':
            new_rps_match_status = 'concluded: first player wins'
        update_rps_match_status(db, rps_match, new_rps_match_status, block_index)

        # Record rps match expiration.
        bindings = {
            'rps_match_id': rps_match['id'],
            'tx0_address': rps_match['tx0_address'],
            'tx1_address': rps_match['tx1_address'],
            'block_index': block_index
        }
        sql = '''INSERT INTO rps_match_expirations VALUES (:rps_match_id, :tx0_address, :tx1_address, :block_index)'''
        cursor.execute(sql, bindings)

        # Rematch not expired and not resolved RPS
        if new_rps_match_status == 'expired':
            sql = '''SELECT * FROM rps WHERE tx_hash IN (?, ?) AND status = ? AND expire_index >= ?'''
            bindings = (rps_match['tx0_hash'], rps_match['tx1_hash'], 'matched', block_index)
            matched_rps = list(cursor.execute(sql, bindings))
            for rps in matched_rps:
                cursor.execute('''UPDATE rps SET status = ? WHERE tx_index = ?''', ('open', rps['tx_index']))
                # Re-debit XCP refund by close_rps_match.
                util.debit(db, rps['source'], 'XCP', rps['wager'], action='reopen RPS after matching expiration', event=rps_match['id'])
                # Rematch
                match(db, {'tx_index': rps['tx_index']}, block_index)

    cursor.close()


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
