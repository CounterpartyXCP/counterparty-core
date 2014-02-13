#! /usr/bin/python3

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

    # Valid re-issuance?
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM issuances \
                      WHERE (validity = ? AND asset = ?)''', ('valid', asset))
    issuances = cursor.fetchall()
    cursor.close()
    if issuances:
        last_issuance = issuances[-1]
        if last_issuance['issuer'] != source:
            problems.append('asset exists and was not issued by this address')
        elif last_issuance['divisible'] != divisible:
            problems.append('asset exists with a different divisibility')
        elif last_issuance['callable'] != callable_ or last_issuance['call_date'] != call_date or last_issuance['call_price'] != call_price:
            problems.append('asset exists with a different callability, call date or call price')
        elif not last_issuance['amount'] and not last_issuance['transfer']:
            problems.append('asset is locked')
    elif not amount:
        problems.append('cannot lock or transfer an unissued asset')

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
    total = sum([issuance['amount'] for issuance in issuances])
    assert isinstance(amount, int)
    if total + amount > config.MAX_INT:
        problems.append('maximum total quantity exceeded')

    if destination and amount:
        problems.append('cannot issue and transfer simultaneously')

    return problems

def create (db, source, destination, asset, amount, divisible, callable_, call_date, call_price, description, unsigned=False):
    problems = validate(db, source, destination, asset, amount, divisible, callable_, call_date, call_price, description)
    if problems: raise exceptions.IssuanceError(problems)

    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT_2, asset_id, amount, divisible, callable_, call_date, call_price, description.encode('utf-8'))
    if len(data) > 80:
        raise exceptions.IssuanceError('Description is greater than 52 bytes.')
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, unsigned=unsigned)

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
            callable_, call_date, call_price, description = None, None, None, ''
        try:
            asset = util.get_asset_name(asset_id)
        except:
            validity = 'invalid: bad asset name'
        validity = 'valid'
    except struct.error:
        asset, amount, divisible, callable_, call_date, call_price, description = None, None, None, None, None, None, None
        validity = 'invalid: could not unpack'

    if validity == 'valid':
        problems = validate(db, tx['source'], tx['destination'], asset, amount, divisible, callable_, call_date, call_price, description, block_index=tx['block_index'])
        if problems: validity = 'invalid: ' + ';'.join(problems)
        if 'maximum total quantity exceeded' in problems:
            amount = 0

    if tx['destination']:
        issuer = tx['destination']
        transfer = True
    else:
        issuer = tx['source']
        transfer = False

    fee = 0
    if validity == 'valid':
        # Debit fee.
        fee = 0
        if amount:
            if tx['block_index'] >= 286000:
                fee = config.ISSUANCE_FEE * config.UNIT
            elif tx['block_index'] > 281236:
                fee = config.ISSUANCE_FEE
            if fee:
                util.debit(db, tx['block_index'], tx['source'], 'XCP', fee)

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
        'validity': validity,
    }
    sql='insert into issuances values(:tx_index, :tx_hash, :block_index, :asset, :amount, :divisible, :issuer, :transfer, :callable, :call_date, :call_price, :description, :fee_paid, :validity)'
    issuance_parse_cursor.execute(sql, bindings)

    # Credit.
    if validity == 'valid' and amount:
        util.credit(db, tx['block_index'], tx['source'], asset, amount)

    issuance_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
