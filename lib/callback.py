#! /usr/bin/python3

"""Callback a callable asset."""

import struct
import logging
import decimal
D = decimal.Decimal

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>dQ'
LENGTH = 8 + 8
ID = 21


def validate (db, source, fraction_per_share, asset, block_time):
    problems = []

    if fraction_per_share > 1:
        problems.append('fraction per share greater than one')
    elif fraction_per_share <= 0:
        problems.append('fraction per share less than or equal to zero')

    issuances = util.get_issuances(db, validity='Valid', asset=asset)
    if not issuances:
        problems.append('no such asset, {}.'.format(asset))
        return None, None, None, problems
    else:
        last_issuance = issuances[-1]
        if block_time == None:
            if config.PREFIX == config.UNITTEST_PREFIX:
                import time
                block_time = time.time()
            else:
                block_time = util.last_block(db)['block_time']

        if last_issuance['issuer'] != source:
            problems.append('not asset owner')
            return None, None, None, problems

        if not last_issuance['callable']:
            problems.append('uncallable asset')
            return None, None, None, problems
        elif last_issuance['call_date'] > block_time: problems.append('before call date')

        call_price = round(last_issuance['call_price'], 6)  # TODO: arbitrary
        divisible = last_issuance['divisible']

    if not divisible:   # Pay per output unit.
        call_price *= config.UNIT

    outputs = []
    balances = util.get_balances(db, asset=asset)
    for balance in balances:
        address, address_amount = balance['address'], balance['amount']
        if address == source: continue
        callback_amount = int(address_amount * fraction_per_share)   # Round down.
        fraction_actual = callback_amount / address_amount
        outputs.append({'address': address, 'shares': address_amount, 'callback_amount': callback_amount, 'fraction_actual': fraction_actual})

    callback_total = sum([output['callback_amount'] for output in outputs])
    if not callback_total: problems.append('nothing called back')

    balances = util.get_balances(db, address=source, asset='XCP')
    if not balances or balances[0]['amount'] < (call_price * callback_total):
        problems.append('insufficient funds')

    return call_price, callback_total, outputs, problems

def create (db, source, fraction_per_share, asset, unsigned=False):
    call_price, callback_total, outputs, problems = validate(db, source, fraction_per_share, asset, None)
    if problems: raise exceptions.CallbackError(problems)
    print('Total amount to be called back:', util.devise(db, callback_total, asset, 'output'), asset)

    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, fraction_per_share, asset_id)
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, unsigned=unsigned)

def parse (db, tx, message):
    callback_parse_cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        fraction_per_share, asset_id = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(asset_id)
        validity = 'Valid'
    except struct.error as e:
        fraction_per_share, asset = None, None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        block_hash = bitcoin.rpc('getblockhash', [tx['block_index'],])  # TODO: Use block time of last block in DB instead?
        block = bitcoin.rpc('getblock', [block_hash,])
        call_price, callback_total, outputs, problems = validate(db, tx['source'], fraction_per_share, asset, block['time'])
        if problems: validity = 'Invalid: ' + ';'.join(problems)

    if validity == 'Valid':
        # Issuer.
        assert call_price * callback_total == int(call_price * callback_total)
        util.debit(db, tx['block_index'], tx['source'], 'XCP', int(call_price * callback_total))
        util.credit(db, tx['block_index'], tx['source'], asset, callback_total)

        # Holders.
        for output in outputs:
            assert call_price * output['callback_amount'] == int(call_price * output['callback_amount'])
            util.debit(db, tx['block_index'], output['address'], asset, output['callback_amount'])
            util.credit(db, tx['block_index'], output['address'], 'XCP', int(call_price * output['callback_amount']))

    # Add parsed transaction to message-type–specific table.
    element_data = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'asset': asset,
        'fraction_per_share': fraction_per_share,
        'validity': validity,
    }
    callback_parse_cursor.execute(*util.get_insert_sql('callbacks', element_data))


    if validity == 'Valid':
        decimal.getcontext().prec = 9   # TODO: also arbitrary
        logging.info('Callback: {} called back {}% of asset {} ({})'.format(tx['source'], float(D(fraction_per_share) * D(100)), asset, tx['tx_hash']))

    callback_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
