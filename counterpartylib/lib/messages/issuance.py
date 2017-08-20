#! /usr/bin/python3

"""
Allow simultaneous lock and transfer.
"""

import struct
import decimal
import json
import logging
logger = logging.getLogger(__name__)
D = decimal.Decimal

from counterpartylib.lib import (config, util, exceptions, util, message_type)

FORMAT_1 = '>QQ?'
LENGTH_1 = 8 + 8 + 1
FORMAT_2 = '>QQ??If'
LENGTH_2 = 8 + 8 + 1 + 1 + 4 + 4
SUBASSET_FORMAT = '>QQ?B'
SUBASSET_FORMAT_LENGTH = 8 + 8 + 1 + 1
ID = 20
SUBASSET_ID = 21
# NOTE: Pascal strings are used for storing descriptions for backwards‐compatibility.

def initialise(db):
    cursor = db.cursor()
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
                      asset_longname TEXT,
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

    # Add asset_longname for sub-assets
    #   SQLite can’t do `ALTER TABLE IF COLUMN NOT EXISTS`.
    columns = [column['name'] for column in cursor.execute('''PRAGMA table_info(issuances)''')]
    if 'asset_longname' not in columns:
        cursor.execute('''ALTER TABLE issuances ADD COLUMN asset_longname TEXT''')

    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_longname_idx ON issuances (asset_longname)
                   ''')

def validate (db, source, destination, asset, quantity, divisible, callable_, call_date, call_price, description, subasset_parent, subasset_longname, block_index):
    problems = []
    fee = 0

    if asset in (config.BTC, config.XCP):
        problems.append('cannot issue {} or {}'.format(config.BTC, config.XCP))

    if call_date is None: call_date = 0
    if call_price is None: call_price = 0.0
    if description is None: description = ""
    if divisible is None: divisible = True

    if isinstance(call_price, int): call_price = float(call_price)
    #^ helps especially with calls from JS‐based clients, where parseFloat(15) returns 15 (not 15.0), which json takes as an int

    if not isinstance(quantity, int):
        problems.append('quantity must be in satoshis')
        return call_date, call_price, problems, fee, description, divisible, None, None
    if call_date and not isinstance(call_date, int):
        problems.append('call_date must be epoch integer')
        return call_date, call_price, problems, fee, description, divisible, None, None
    if call_price and not isinstance(call_price, float):
        problems.append('call_price must be a float')
        return call_date, call_price, problems, fee, description, divisible, None, None

    if quantity < 0: problems.append('negative quantity')
    if call_price < 0: problems.append('negative call price')
    if call_date < 0: problems.append('negative call date')

    # Callable, or not.
    if not callable_:
        if block_index >= 312500 or config.TESTNET or config.REGTEST: # Protocol change.
            call_date = 0
            call_price = 0.0
        elif block_index >= 310000:                 # Protocol change.
            if call_date:
                problems.append('call date for non‐callable asset')
            if call_price:
                problems.append('call price for non‐callable asset')

    # Valid re-issuance?
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM issuances \
                      WHERE (status = ? AND asset = ?)
                      ORDER BY tx_index ASC''', ('valid', asset))
    issuances = cursor.fetchall()
    cursor.close()
    reissued_asset_longname = None
    if issuances:
        reissuance = True
        last_issuance = issuances[-1]
        reissued_asset_longname = last_issuance['asset_longname']

        if last_issuance['issuer'] != source:
            problems.append('issued by another address')
        if bool(last_issuance['divisible']) != bool(divisible):
            problems.append('cannot change divisibility')
        if bool(last_issuance['callable']) != bool(callable_):
            problems.append('cannot change callability')
        if last_issuance['call_date'] > call_date and (call_date != 0 or (block_index < 312500 and not config.TESTNET or config.REGTEST)):
            problems.append('cannot advance call date')
        if last_issuance['call_price'] > call_price:
            problems.append('cannot reduce call price')
        if last_issuance['locked'] and quantity:
            problems.append('locked asset and non‐zero quantity')
    else:
        reissuance = False
        if description.lower() == 'lock':
            problems.append('cannot lock a non‐existent asset')
        if destination:
            problems.append('cannot transfer a non‐existent asset')

    # validate parent ownership for subasset
    if subasset_longname is not None:
        cursor = db.cursor()
        cursor.execute('''SELECT * FROM issuances \
                          WHERE (status = ? AND asset = ?)
                          ORDER BY tx_index ASC''', ('valid', subasset_parent))
        parent_issuances = cursor.fetchall()
        cursor.close()
        if parent_issuances:
            last_parent_issuance = parent_issuances[-1]
            if last_parent_issuance['issuer'] != source:
                problems.append('parent asset owned by another address')
        else:
            problems.append('parent asset not found')

    # validate subasset issuance is not a duplicate
    if subasset_longname is not None and not reissuance:
        cursor = db.cursor()
        cursor.execute('''SELECT * FROM assets \
                          WHERE (asset_longname = ?)''', (subasset_longname,))
        assets = cursor.fetchall()
        if len(assets) > 0:
            problems.append('subasset already exists')

        # validate that the actual asset is numeric
        if asset[0] != 'A':
            problems.append('a subasset must be a numeric asset')



    # Check for existence of fee funds.
    if quantity or (block_index >= 315000 or config.TESTNET or config.REGTEST):   # Protocol change.
        if not reissuance or (block_index < 310000 and not (config.TESTNET or config.REGTEST)):  # Pay fee only upon first issuance. (Protocol change.)
            cursor = db.cursor()
            cursor.execute('''SELECT * FROM balances \
                              WHERE (address = ? AND asset = ?)''', (source, config.XCP))
            balances = cursor.fetchall()
            cursor.close()
            if util.enabled('numeric_asset_names'):  # Protocol change.
                if subasset_longname is not None and util.enabled('subassets'): # Protocol change.
                    # subasset issuance is 0.25
                    fee = int(0.25 * config.UNIT)
                elif len(asset) >= 13:
                    fee = 0
                else:
                    fee = int(0.5 * config.UNIT)
            elif block_index >= 291700 or config.TESTNET or config.REGTEST:     # Protocol change.
                fee = int(0.5 * config.UNIT)
            elif block_index >= 286000 or config.TESTNET or config.REGTEST:   # Protocol change.
                fee = 5 * config.UNIT
            elif block_index > 281236 or config.TESTNET or config.REGTEST:    # Protocol change.
                fee = 5
            if fee and (not balances or balances[0]['quantity'] < fee):
                problems.append('insufficient funds')

    if not (block_index >= 317500 or config.TESTNET or config.REGTEST):  # Protocol change.
        if len(description) > 42:
            problems.append('description too long')

    # For SQLite3
    call_date = min(call_date, config.MAX_INT)
    total = sum([issuance['quantity'] for issuance in issuances])
    assert isinstance(quantity, int)
    if total + quantity > config.MAX_INT:
        problems.append('total quantity overflow')

    if destination and quantity:
        problems.append('cannot issue and transfer simultaneously')

    # For SQLite3
    if util.enabled('integer_overflow_fix', block_index=block_index) and (fee > config.MAX_INT or quantity > config.MAX_INT):
        problems.append('integer overflow')

    return call_date, call_price, problems, fee, description, divisible, reissuance, reissued_asset_longname


def compose (db, source, transfer_destination, asset, quantity, divisible, description):

    # Callability is deprecated, so for re‐issuances set relevant parameters
    # to old values; for first issuances, make uncallable.
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM issuances \
                      WHERE (status = ? AND asset = ?)
                      ORDER BY tx_index ASC''', ('valid', asset))
    issuances = cursor.fetchall()
    if issuances:
        last_issuance = issuances[-1]
        callable_ = last_issuance['callable']
        call_date = last_issuance['call_date']
        call_price = last_issuance['call_price']
    else:
        callable_ = False
        call_date = 0
        call_price = 0.0
    cursor.close()

    # check subasset
    subasset_parent = None
    subasset_longname = None
    if util.enabled('subassets'): # Protocol change.
        subasset_parent, subasset_longname = util.parse_subasset_from_asset_name(asset)
        if subasset_longname is not None:
            # try to find an existing subasset
            sa_cursor = db.cursor()
            sa_cursor.execute('''SELECT * FROM assets \
                              WHERE (asset_longname = ?)''', (subasset_longname,))
            assets = sa_cursor.fetchall()
            sa_cursor.close()
            if len(assets) > 0:
                # this is a reissuance
                asset = assets[0]['asset_name']
            else:
                # this is a new issuance
                #   generate a random numeric asset id which will map to this subasset
                asset = util.generate_random_asset()

    call_date, call_price, problems, fee, description, divisible, reissuance, reissued_asset_longname = validate(db, source, transfer_destination, asset, quantity, divisible, callable_, call_date, call_price, description, subasset_parent, subasset_longname, util.CURRENT_BLOCK_INDEX)
    if problems: raise exceptions.ComposeError(problems)

    asset_id = util.generate_asset_id(asset, util.CURRENT_BLOCK_INDEX)
    if subasset_longname is None or reissuance:
        # Type 20 standard issuance FORMAT_2 >QQ??If
        #   used for standard issuances and all reissuances
        data = message_type.pack(ID)
        if len(description) <= 42:
            curr_format = FORMAT_2 + '{}p'.format(len(description) + 1)
        else:
            curr_format = FORMAT_2 + '{}s'.format(len(description))
        data += struct.pack(curr_format, asset_id, quantity, 1 if divisible else 0, 1 if callable_ else 0,
            call_date or 0, call_price or 0.0, description.encode('utf-8'))
    else:
        # Type 21 subasset issuance SUBASSET_FORMAT >QQ?B
        #   Used only for initial subasset issuance
        # compacts a subasset name to save space
        compacted_subasset_longname = util.compact_subasset_longname(subasset_longname)
        compacted_subasset_length = len(compacted_subasset_longname)
        data = message_type.pack(SUBASSET_ID)
        curr_format = SUBASSET_FORMAT + '{}s'.format(compacted_subasset_length) + '{}s'.format(len(description))
        data += struct.pack(curr_format, asset_id, quantity, 1 if divisible else 0, compacted_subasset_length, compacted_subasset_longname, description.encode('utf-8'))

    if transfer_destination:
        destination_outputs = [(transfer_destination, None)]
    else:
        destination_outputs = []
    return (source, destination_outputs, data)

def parse (db, tx, message, message_type_id):
    issuance_parse_cursor = db.cursor()

    # Unpack message.
    try:
        subasset_longname = None
        if message_type_id == SUBASSET_ID:
            if not util.enabled('subassets', block_index=tx['block_index']):
                logger.warn("subassets are not enabled at block %s" % tx['block_index'])
                raise exceptions.UnpackError

            # parse a subasset original issuance message
            asset_id, quantity, divisible, compacted_subasset_length = struct.unpack(SUBASSET_FORMAT, message[0:SUBASSET_FORMAT_LENGTH])
            description_length = len(message) - SUBASSET_FORMAT_LENGTH - compacted_subasset_length
            if description_length < 0:
                logger.warn("invalid subasset length: [issuance] tx [%s]: %s" % (tx['tx_hash'], compacted_subasset_length))
                raise exceptions.UnpackError
            messages_format = '>{}s{}s'.format(compacted_subasset_length, description_length)
            compacted_subasset_longname, description = struct.unpack(messages_format, message[SUBASSET_FORMAT_LENGTH:])
            subasset_longname = util.expand_subasset_longname(compacted_subasset_longname)
            callable_, call_date, call_price = False, 0, 0.0
            try:
                description = description.decode('utf-8')
            except UnicodeDecodeError:
                description = ''
        elif (tx['block_index'] > 283271 or config.TESTNET or config.REGTEST) and len(message) >= LENGTH_2: # Protocol change.
            if len(message) - LENGTH_2 <= 42:
                curr_format = FORMAT_2 + '{}p'.format(len(message) - LENGTH_2)
            else:
                curr_format = FORMAT_2 + '{}s'.format(len(message) - LENGTH_2)
            asset_id, quantity, divisible, callable_, call_date, call_price, description = struct.unpack(curr_format, message)

            call_price = round(call_price, 6) # TODO: arbitrary
            try:
                description = description.decode('utf-8')
            except UnicodeDecodeError:
                description = ''
        else:
            if len(message) != LENGTH_1:
                raise exceptions.UnpackError
            asset_id, quantity, divisible = struct.unpack(FORMAT_1, message)
            callable_, call_date, call_price, description = False, 0, 0.0, ''
        try:
            asset = util.generate_asset_name(asset_id, tx['block_index'])
        except exceptions.AssetNameError:
            asset = None
            status = 'invalid: bad asset name'
        status = 'valid'
    except exceptions.UnpackError as e:
        asset, quantity, divisible, callable_, call_date, call_price, description = None, None, None, None, None, None, None
        status = 'invalid: could not unpack'

    # parse and validate the subasset from the message
    subasset_parent = None
    if status == 'valid' and subasset_longname is not None: # Protocol change.
        try:
            # ensure the subasset_longname is valid
            util.validate_subasset_longname(subasset_longname)
            subasset_parent, subasset_longname = util.parse_subasset_from_asset_name(subasset_longname)
        except exceptions.AssetNameError as e:
            asset = None
            status = 'invalid: bad subasset name'

    reissuance = None
    fee = 0
    if status == 'valid':
        call_date, call_price, problems, fee, description, divisible, reissuance, reissued_asset_longname = validate(db, tx['source'], tx['destination'], asset, quantity, divisible, callable_, call_date, call_price, description, subasset_parent, subasset_longname, block_index=tx['block_index'])

        if problems: status = 'invalid: ' + '; '.join(problems)
        if not util.enabled('integer_overflow_fix', block_index=tx['block_index']) and 'total quantity overflow' in problems:
            quantity = 0

    if tx['destination']:
        issuer = tx['destination']
        transfer = True
        quantity = 0
    else:
        issuer = tx['source']
        transfer = False

    # Debit fee.
    if status == 'valid':
        util.debit(db, tx['source'], config.XCP, fee, action="issuance fee", event=tx['tx_hash'])

    # Lock?
    lock = False
    if status == 'valid':
        if description and description.lower() == 'lock':
            lock = True
            cursor = db.cursor()
            issuances = list(cursor.execute('''SELECT * FROM issuances \
                                               WHERE (status = ? AND asset = ?)
                                               ORDER BY tx_index ASC''', ('valid', asset)))
            cursor.close()
            description = issuances[-1]['description']  # Use last description. (Assume previous issuance exists because tx is valid.)
            timestamp, value_int, fee_fraction_int = None, None, None

        if not reissuance:
            # Add to table of assets.
            bindings= {
                'asset_id': str(asset_id),
                'asset_name': str(asset),
                'block_index': tx['block_index'],
                'asset_longname': subasset_longname,
            }
            sql='insert into assets values(:asset_id, :asset_name, :block_index, :asset_longname)'
            issuance_parse_cursor.execute(sql, bindings)

    if status == 'valid' and reissuance:
        # when reissuing, add the asset_longname to the issuances table for API lookups
        asset_longname = reissued_asset_longname
    else:
        asset_longname = subasset_longname

    # Add parsed transaction to message-type–specific table.
    bindings= {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'asset': asset,
        'quantity': quantity,
        'divisible': divisible,
        'source': tx['source'],
        'issuer': issuer,
        'transfer': transfer,
        'callable': callable_,
        'call_date': call_date,
        'call_price': call_price,
        'description': description,
        'fee_paid': fee,
        'locked': lock,
        'status': status,
        'asset_longname': asset_longname,
    }
    if "integer overflow" not in status:
        sql='insert into issuances values(:tx_index, :tx_hash, :block_index, :asset, :quantity, :divisible, :source, :issuer, :transfer, :callable, :call_date, :call_price, :description, :fee_paid, :locked, :status, :asset_longname)'
        issuance_parse_cursor.execute(sql, bindings)
    else:
        logger.warn("Not storing [issuance] tx [%s]: %s" % (tx['tx_hash'], status))
        logger.debug("Bindings: %s" % (json.dumps(bindings), ))

    # Credit.
    if status == 'valid' and quantity:
        util.credit(db, tx['source'], asset, quantity, action="issuance", event=tx['tx_hash'])

    issuance_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
