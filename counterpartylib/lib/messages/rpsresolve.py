#! /usr/bin/python3

import binascii
import struct
import logging
logger = logging.getLogger(__name__)
import string

from counterpartylib.lib import (config, exceptions, util)
from . import rps

# move random rps_match_id
FORMAT = '>H16s32s32s'
LENGTH = 2 + 16 + 32 + 32
ID = 81

def initialise (db):
    cursor = db.cursor()
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

def validate (db, source, move, random, rps_match_id):
    problems = []
    rps_match = None

    if not isinstance(move, int):
        problems.append('move must be a integer')
        return None, None, problems

    if not all(c in string.hexdigits for c in random):
        problems.append('random must be an hexadecimal string')
        return None, None, problems

    random_bytes = binascii.unhexlify(random)
    if len(random_bytes) != 16:
        problems.append('random must be 16 bytes in hexadecimal format')
        return None, None, problems

    cursor = db.cursor()
    rps_matches = list(cursor.execute('''SELECT * FROM rps_matches WHERE id = ?''', (rps_match_id,)))
    cursor.close()
    if len(rps_matches) == 0:
        problems.append('no such rps match')
        return None, rps_match, problems
    elif len(rps_matches) > 1:
        assert False

    rps_match = rps_matches[0]

    if move<1:
        problems.append('move must be greater than 0')
    elif move > rps_match['possible_moves']:
        problems.append('move must be lower than {}'.format(rps_match['possible_moves']))

    if source not in [rps_match['tx0_address'], rps_match['tx1_address']]:
        problems.append('invalid source address')
        return None, rps_match, problems

    if rps_match['tx0_address'] == source:
        txn = 0
        rps_match_status = ['pending', 'pending and resolved']
    else:
        txn = 1
        rps_match_status = ['pending', 'resolved and pending']

    move_random_hash = util.dhash(random_bytes + int(move).to_bytes(2, byteorder='big'))
    move_random_hash = binascii.hexlify(move_random_hash).decode('utf-8')
    if rps_match['tx{}_move_random_hash'.format(txn)] != move_random_hash:
        problems.append('invalid move or random value')
        return txn, rps_match, problems

    if rps_match['status'] == 'expired':
        problems.append('rps match expired')
    elif rps_match['status'].startswith('concluded'):
        problems.append('rps match concluded')
    elif rps_match['status'].startswith('invalid'):
        problems.append('rps match invalid')
    elif rps_match['status'] not in rps_match_status:
        problems.append('rps already resolved')

    return txn, rps_match, problems

def compose (db, source, move, random, rps_match_id):
    tx0_hash, tx1_hash = util.parse_id(rps_match_id)

    txn, rps_match, problems = validate(db, source, move, random, rps_match_id)
    if problems: raise exceptions.ComposeError(problems)

    # Warn if down to the wire.
    time_left = rps_match['match_expire_index'] - util.CURRENT_BLOCK_INDEX
    if time_left < 4:
        logger.warning('Only {} blocks until that rps match expires. The conclusion might not make into the blockchain in time.'.format(time_left))

    tx0_hash_bytes = binascii.unhexlify(bytes(tx0_hash, 'utf-8'))
    tx1_hash_bytes = binascii.unhexlify(bytes(tx1_hash, 'utf-8'))
    random_bytes = binascii.unhexlify(bytes(random, 'utf-8'))
    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, move, random_bytes, tx0_hash_bytes, tx1_hash_bytes)
    return (source, [], data)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        move, random, tx0_hash_bytes, tx1_hash_bytes = struct.unpack(FORMAT, message)
        tx0_hash, tx1_hash = binascii.hexlify(tx0_hash_bytes).decode('utf-8'), binascii.hexlify(tx1_hash_bytes).decode('utf-8')
        rps_match_id = util.make_id(tx0_hash, tx1_hash)
        random = binascii.hexlify(random).decode('utf-8')
        status = 'valid'
    except (exceptions.UnpackError, struct.error) as e:
        move, random, tx0_hash, tx1_hash, rps_match_id = None, None, None, None, None
        status = 'invalid: could not unpack'

    if status == 'valid':
        txn, rps_match, problems = validate(db, tx['source'], move, random, rps_match_id)
        if problems:
            rps_match = None
            status = 'invalid: ' + '; '.join(problems)

    # Add parsed transaction to message-type–specific table.
    rpsresolves_bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'move': move,
        'random': random,
        'rps_match_id': rps_match_id,
        'status': status
    }

    if status == 'valid':
        rps_match_status = 'concluded'

        if rps_match['status'] == 'pending':
            rps_match_status = 'resolved and pending' if txn==0 else 'pending and resolved'

        if rps_match_status == 'concluded':
            counter_txn = 0 if txn == 1 else 1
            counter_source = rps_match['tx{}_address'.format(counter_txn)]
            sql = '''SELECT * FROM rpsresolves WHERE rps_match_id = ? AND source = ? AND status = ?'''
            counter_games = list(cursor.execute(sql, (rps_match_id, counter_source, 'valid')))
            assert len(counter_games) == 1
            counter_game = counter_games[0]

            winner = resolve_game(db, rpsresolves_bindings, counter_game)

            if winner == 0:
                rps_match_status = 'concluded: tie'
            elif winner == counter_game['tx_index']:
                rps_match_status = 'concluded: {} player wins'.format('first' if counter_txn == 0 else 'second')
            else:
                rps_match_status = 'concluded: {} player wins'.format('first' if txn == 0 else 'second')

        rps.update_rps_match_status(db, rps_match, rps_match_status, tx['block_index'])

    sql = '''INSERT INTO rpsresolves VALUES (:tx_index, :tx_hash, :block_index, :source, :move, :random, :rps_match_id, :status)'''
    cursor.execute(sql, rpsresolves_bindings)

    cursor.close()

# https://en.wikipedia.org/wiki/Rock-paper-scissors#Additional_weapons:
def resolve_game(db, resovlerps1, resovlerps2):

    move1 = resovlerps1['move']
    move2 = resovlerps2['move']

    same_parity = (move1 % 2) == (move2 % 2)
    if (same_parity and move1 < move2) or (not same_parity and move1 > move2):
        return resovlerps1['tx_index']
    elif (same_parity and move1 > move2) or (not same_parity and move1 < move2):
        return resovlerps2['tx_index']
    else:
        return 0


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
