#! /usr/bin/python3

import struct

from counterpartylib.lib import exceptions
from counterpartylib.lib import config
from counterpartylib.lib import util
from counterpartylib.lib import log
from counterpartylib.lib import message_type
from counterpartylib.lib import address
from counterpartylib.lib.exceptions import *

FORMAT = '>21sB'
LENGTH = 22
MAX_MEMO_LENGTH = 34 # Could be higher, but we will keep it consistent with enhanced send
ID = 4
ANTISPAM_FEE_DECIMAL = 0.5
ANTISPAM_FEE = ANTISPAM_FEE_DECIMAL * config.UNIT

FLAG_BALANCES = 1
FLAG_OWNERSHIP = 2
FLAG_BINARY_MEMO = 4

FLAGS_ALL = FLAG_BINARY_MEMO | FLAG_BALANCES | FLAG_OWNERSHIP

def initialise(db):
    cursor = db.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS sweeps(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      flags INTEGER,
                      status TEXT,
                      memo BLOB,
                      fee_paid INTEGER,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON sweeps (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON sweeps (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      destination_idx ON sweeps (destination)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      memo_idx ON sweeps (memo)
                   ''')


def validate (db, source, destination, flags, memo, block_index):
    problems = []

    if source == destination:
        problems.append('destination cannot be the same as source')

    cursor = db.cursor()
    cursor.execute('''SELECT * FROM balances WHERE (address = ? AND asset = ?)''', (source, 'XCP'))
    result = cursor.fetchall()

    antispamfee = util.get_value_by_block_index("sweep_antispam_fee", block_index)*config.UNIT
    total_fee = ANTISPAM_FEE

    if antispamfee > 0:
        cursor.execute('''SELECT count(*) cnt FROM balances WHERE address = ?''', (source, ))
        balances_count = cursor.fetchall()[0]['cnt']

        cursor.execute('''SELECT COUNT(DISTINCT(asset)) cnt FROM issuances WHERE issuer = ?''', (source, ))
        issuances_count = cursor.fetchall()[0]['cnt']

        total_fee = int(balances_count * antispamfee * 2 + issuances_count * antispamfee * 4)
        
        if result[0]['quantity'] < total_fee:
            problems.append('insufficient XCP balance for sweep. Need %s XCP for antispam fee' % total_fee)
    else:
        if len(result) == 0:
            problems.append('insufficient XCP balance for sweep. Need %s XCP for antispam fee' % ANTISPAM_FEE_DECIMAL)
        elif result[0]['quantity'] < ANTISPAM_FEE:
            problems.append('insufficient XCP balance for sweep. Need %s XCP for antispam fee' % ANTISPAM_FEE_DECIMAL)

    cursor.close()

    if flags > FLAGS_ALL:
        problems.append('invalid flags %i' % flags)
    elif not(flags & (FLAG_BALANCES | FLAG_OWNERSHIP)):
        problems.append('must specify which kind of transfer in flags')

    if memo and len(memo) > MAX_MEMO_LENGTH:
        problems.append('memo too long')

    return problems, total_fee

def compose (db, source, destination, flags, memo):
    if memo is None:
        memo = b''
    elif flags & FLAG_BINARY_MEMO:
        memo = bytes.fromhex(memo)
    else:
        memo = memo.encode('utf-8')
        memo = struct.pack(">{}s".format(len(memo)), memo)

    block_index = util.CURRENT_BLOCK_INDEX
    problems, total_fee = validate(db, source, destination, flags, memo, block_index)
    if problems: raise exceptions.ComposeError(problems)

    short_address_bytes = address.pack(destination)

    data = message_type.pack(ID)
    data += struct.pack(FORMAT, short_address_bytes, flags)
    data += memo

    return (source, [], data)

def unpack(db, message, block_index):
    try:
        memo_bytes_length = len(message) - LENGTH
        if memo_bytes_length < 0:
            raise exceptions.UnpackError('invalid message length')
        if memo_bytes_length > MAX_MEMO_LENGTH:
            raise exceptions.UnpackError('memo too long')

        struct_format = FORMAT + ('{}s'.format(memo_bytes_length))
        short_address_bytes, flags, memo_bytes = struct.unpack(struct_format, message)
        if len(memo_bytes) == 0:
            memo_bytes = None
        elif not(flags & FLAG_BINARY_MEMO):
            memo_bytes = memo_bytes.decode('utf-8')

        # unpack address
        full_address = address.unpack(short_address_bytes)
    except (struct.error) as e:
        logger.warning("sweep send unpack error: {}".format(e))
        raise exceptions.UnpackError('could not unpack')

    unpacked = {
      'destination': full_address,
      'flags': flags,
      'memo': memo_bytes,
    }
    return unpacked

def parse (db, tx, message):
    cursor = db.cursor()

    fee_paid = round(config.UNIT/2)

    # Unpack message.
    try:
        unpacked = unpack(db, message, tx['block_index'])
        destination, flags, memo_bytes = unpacked['destination'], unpacked['flags'], unpacked['memo']

        status = 'valid'
    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error) as e:
        destination, flags, memo_bytes = None, None, None
        status = 'invalid: could not unpack ({})'.format(e)
    except BalanceError:
        destination, flags, memo_bytes = None, None, None
        status = 'invalid: insufficient balance for antispam fee for sweep'
    except Exception as err:
        destination, flags, memo_bytes = None, None, None
        status = 'invalid: could not unpack, ' + str(err)

    if status == 'valid':
        problems, total_fee = validate(db, tx['source'], destination, flags, memo_bytes, tx['block_index'])
        if problems: status = 'invalid: ' + '; '.join(problems)

    if status == 'valid':
        try:
            antispamfee = util.get_value_by_block_index("sweep_antispam_fee", tx['block_index'])*config.UNIT
            
            if antispamfee > 0:
                util.debit(db, tx['source'], 'XCP', total_fee, action='sweep fee', event=tx['tx_hash'])
            else:
                util.debit(db, tx['source'], 'XCP', fee_paid, action='sweep fee', event=tx['tx_hash'])
        except BalanceError:
            destination, flags, memo_bytes = None, None, None
            status = 'invalid: insufficient balance for antispam fee for sweep'

    if status == 'valid':
        cursor.execute('''SELECT * FROM balances WHERE address = ?''', (tx['source'],))
        balances = cursor.fetchall()
        if flags & FLAG_BALANCES:
            for balance in balances:
                util.debit(db, tx['source'], balance['asset'], balance['quantity'], action='sweep', event=tx['tx_hash'])
                util.credit(db, destination, balance['asset'], balance['quantity'], action='sweep', event=tx['tx_hash'])

        if flags & FLAG_OWNERSHIP:
            sweep_pos = 0
            
            assets_issued = balances
            if util.enabled("zero_balance_ownership_sweep_fix", tx["block_index"]):
                cursor.execute('''SELECT DISTINCT(asset) FROM issuances WHERE issuer = ?''', (tx['source'],))
                assets_issued = cursor.fetchall()
                
            for next_asset_issued in assets_issued:
                cursor.execute('''SELECT * FROM issuances \
                                  WHERE (status = ? AND asset = ?)
                                  ORDER BY tx_index ASC''', ('valid', next_asset_issued['asset']))
                issuances = cursor.fetchall()
                if len(issuances) > 0:
                    last_issuance = issuances[-1]
                    if last_issuance['issuer'] == tx['source']:
                        bindings= {
                            'tx_index': tx['tx_index'],
                            'tx_hash': tx['tx_hash'],
                            'msg_index': sweep_pos,
                            'block_index': tx['block_index'],
                            'asset': next_asset_issued['asset'],
                            'quantity': 0,
                            'divisible': last_issuance['divisible'],
                            'source': last_issuance['source'],
                            'issuer': destination,
                            'transfer': True,
                            'callable': last_issuance['callable'],
                            'call_date': last_issuance['call_date'],
                            'call_price': last_issuance['call_price'],
                            'description': last_issuance['description'],
                            'fee_paid': 0,
                            'locked': last_issuance['locked'],
                            'status': status,
                            'asset_longname': last_issuance['asset_longname'],
                            'reset': False
                        }
                        sql='insert into issuances values(:tx_index, :tx_hash, :msg_index, :block_index, :asset, :quantity, :divisible, :source, :issuer, :transfer, :callable, :call_date, :call_price, :description, :fee_paid, :locked, :status, :asset_longname, :reset)'
                        cursor.execute(sql, bindings)
                        sweep_pos += 1

        bindings = {
            'tx_index': tx['tx_index'],
            'tx_hash': tx['tx_hash'],
            'block_index': tx['block_index'],
            'source': tx['source'],
            'destination': destination,
            'flags': flags,
            'status': status,
            'memo': memo_bytes,
            'fee_paid': total_fee if antispamfee > 0 else fee_paid
        }
        sql = 'insert into sweeps values(:tx_index, :tx_hash, :block_index, :source, :destination, :flags, :status, :memo, :fee_paid)'
        cursor.execute(sql, bindings)

    cursor.close()
