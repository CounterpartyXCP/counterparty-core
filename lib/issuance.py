#! /usr/bin/python3

"""
Allow simultaneous lock and transfer.
"""

import struct
import decimal
D = decimal.Decimal

from . import (config, util, exceptions, bitcoin, util)

FORMAT_1 = '>QQ?'
LENGTH_1 = 8 + 8 + 1
FORMAT_2 = '>QQ??If42p'
LENGTH_2 = 8 + 8 + 1 + 1 + 4 + 4 + 42
ID = 20


def validate (db, source, destination, asset, amount, divisible, callable_, call_date, call_price, description, block_index=None):
    problems = []

    if asset in ('BTC', 'XCP'):
        problems.append('cannot issue BTC or XCP')

    if not isinstance(amount, int): problems.append('amount must be in satoshi')
    if not isinstance(call_date, int): problems.append('call_date must be epoch integer')
    if not isinstance(call_price, int): problems.append('call_price must be in satoshi')

    if amount <= 0: problems.append('non‐positive amount')
    if call_price < 0: problems.append('negative call_price')
    if call_date < 0: problems.append('negative call_date')

    # Valid re-issuance?
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM issuances \
                      WHERE (status = ? AND asset = ?)''', ('valid', asset))
    issuances = cursor.fetchall()
    cursor.close()
    if issuances:
        last_issuance = issuances[-1]
        if call_date is None: call_date = 0
        if call_price is None: call_price = 0
        
        if last_issuance['issuer'] != source:
            problems.append('asset exists and was not issued by this address')
        elif bool(last_issuance['divisible']) != bool(divisible):
            problems.append('asset exists with a different divisibility')
        elif bool(last_issuance['callable']) != bool(callable_) or last_issuance['call_date'] != call_date or last_issuance['call_price'] != call_price:
            problems.append('asset exists with a different callability, call date or call price')
        elif last_issuance['locked'] and amount:
            problems.append('locked asset and non‐zero amount')
    elif description.lower() == 'lock':
        problems.append('cannot lock a nonexistent asset')
    elif destination:
        problems.append('cannot transfer a nonexistent asset')

    cursor = db.cursor()
    cursor.execute('''SELECT * FROM balances \
                      WHERE (address = ? AND asset = ?)''', (source, 'XCP'))
    balances = cursor.fetchall()
    cursor.close()
    if block_index:
        fee = 0
        if block_index >= 286000:
            fee = config.ISSUANCE_FEE * config.UNIT
        elif block_index > 281236:
            fee = config.ISSUANCE_FEE
        if fee and (not balances or balances[0]['amount'] < fee):
            problems.append('insufficient funds')

    # For SQLite3
    call_date = min(call_date, config.MAX_INT)
    call_price = min(call_price, config.MAX_INT)
    total = sum([issuance['amount'] for issuance in issuances])
    assert isinstance(amount, int)
    if total + amount > config.MAX_INT:
        problems.append('maximum total quantity exceeded')

    if destination and amount:
        problems.append('cannot issue and transfer simultaneously')

    return problems

def compose (db, source, destination, asset, amount, divisible, callable_, call_date, call_price, description):
    problems = validate(db, source, destination, asset, amount, divisible, callable_, call_date, call_price, description)
    if problems: raise exceptions.IssuanceError(problems)

    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT_2, asset_id, amount, 1 if divisible else 0, 1 if callable_ else 0, 
        call_date or 0, call_price or 0, description.encode('utf-8'))
    if len(data) > 80:
        raise exceptions.IssuanceError('Description is greater than 52 bytes.')
    return (source, None, None, config.MIN_FEE, data)

def parse (db, tx, message):
    issuance_parse_cursor = db.cursor()

    # Unpack message.
    try:
        if (tx['block_index'] > 283271 or config.TESTNET) and len(message) == LENGTH_2:
            asset_id, amount, divisible, callable_, call_date, call_price, description = struct.unpack(FORMAT_2, message)
            call_price = round(call_price, 6) # TODO: arbitrary
            try:
                description = description.decode('utf-8')
            except UnicodeDecodeError:
                description = ''
        else:
            asset_id, amount, divisible = struct.unpack(FORMAT_1, message)
            callable_, call_date, call_price, description = False, 0, 0, ''
        try:
            asset = util.get_asset_name(asset_id)
        except:
            status = 'invalid: bad asset name'
        status = 'valid'
    except struct.error:
        asset, amount, divisible, callable_, call_date, call_price, description = None, None, None, None, None, None, None
        status = 'invalid: could not unpack'

    if status == 'valid':
        if not callable_: calldate, call_price = 0, 0
        problems = validate(db, tx['source'], tx['destination'], asset, amount, divisible, callable_, call_date, call_price, description, block_index=tx['block_index'])
        if problems: status = 'invalid: ' + ';'.join(problems)
        if 'maximum total quantity exceeded' in problems:
            amount = 0

    if tx['destination']:
        issuer = tx['destination']
        transfer = True
        amount = 0
    else:
        issuer = tx['source']
        transfer = False

    fee = 0
    if status == 'valid':
        # Debit fee.
        fee = 0
        if amount:
            if tx['block_index'] >= 286000:
                fee = config.ISSUANCE_FEE * config.UNIT
            elif tx['block_index'] > 281236:
                fee = config.ISSUANCE_FEE
            if fee:
                util.debit(db, tx['block_index'], tx['source'], 'XCP', fee)

    # Lock?
    if description and description.lower() == 'lock':
        lock = True
        cursor = db.cursor()
        issuances = list(cursor.execute('''SELECT * FROM issuances \
                                           WHERE (status = ? AND asset = ?)''', ('valid', asset)))
        cursor.close()
        description = issuances[-1]['description']  # Use last description.
        timestamp, value_int, fee_fraction_int = None, None, None
    else:
        lock = False

    # Add parsed transaction to message-type–specific table.
    bindings= {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'asset': asset,
        'amount': amount,
        'divisible': divisible,
        'issuer': issuer,
        'transfer': transfer,
        'callable': callable_,
        'call_date': call_date,
        'call_price': call_price,
        'description': description,
        'fee_paid': fee,
        'locked': lock,
        'status': status,
    }
    sql='insert into issuances values(:tx_index, :tx_hash, :block_index, :asset, :amount, :divisible, :issuer, :transfer, :callable, :call_date, :call_price, :description, :fee_paid, :lock, :status)'
    issuance_parse_cursor.execute(sql, bindings)

    # Credit.
    if status == 'valid' and amount:
        util.credit(db, tx['block_index'], tx['source'], asset, amount)

    issuance_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
