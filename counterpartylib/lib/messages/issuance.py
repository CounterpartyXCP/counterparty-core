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

#Lock Reset issuances. Default composed message
LR_ISSUANCE_ID = 22
LR_SUBASSET_ID = 23

DESCRIPTION_MARK_BYTE = b'\xc0'
DESCRIPTION_NULL_ACTION = "NULL"

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
                      reset BOOL,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')

    # Add asset_longname for sub-assets
    #   SQLite can’t do `ALTER TABLE IF COLUMN NOT EXISTS`.
    columns = [column['name'] for column in cursor.execute('''PRAGMA table_info(issuances)''')]
    if 'asset_longname' not in columns:
        cursor.execute('''ALTER TABLE issuances ADD COLUMN asset_longname TEXT''')
    if 'reset' not in columns:
        cursor.execute('''ALTER TABLE issuances ADD COLUMN reset BOOL''')

    # If sweep_hotfix activated, Create issuances copy, copy old data, drop old table, rename new table, recreate indexes
    #   SQLite can’t do `ALTER TABLE IF COLUMN NOT EXISTS` nor can drop UNIQUE constraints
    if 'msg_index' not in columns:
            cursor.execute('''CREATE TABLE IF NOT EXISTS new_issuances(
                              tx_index INTEGER,
                              tx_hash TEXT,
                              msg_index INTEGER DEFAULT 0,
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
                              reset BOOL,
                              PRIMARY KEY (tx_index, msg_index),
                              FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                              UNIQUE (tx_hash, msg_index))
                           ''')
            cursor.execute('''INSERT INTO new_issuances(tx_index, tx_hash, msg_index,
                block_index, asset, quantity, divisible, source, issuer, transfer, callable,
                call_date, call_price, description, fee_paid, locked, status, asset_longname, reset)
                SELECT tx_index, tx_hash, 0, block_index, asset, quantity, divisible, source,
                issuer, transfer, callable, call_date, call_price, description, fee_paid,
                locked, status, asset_longname, reset FROM issuances''', {})
            cursor.execute('DROP TABLE issuances')
            cursor.execute('ALTER TABLE new_issuances RENAME TO issuances')

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

    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_longname_idx ON issuances (asset_longname)
                   ''')

def validate (db, source, destination, asset, quantity, divisible, lock, reset, callable_, call_date, call_price, description, subasset_parent, subasset_longname, block_index):
    problems = []
    fee = 0

    if asset in (config.BTC, config.XCP):
        problems.append('cannot issue {} or {}'.format(config.BTC, config.XCP))

    if call_date is None: call_date = 0
    if call_price is None: call_price = 0.0
    if description is None: description = ""
    if divisible is None: divisible = True
    if lock is None: lock = False
    if reset is None: reset = False

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
        issuance_locked = False
        if util.enabled('issuance_lock_fix'):
            for issuance in issuances:
                if issuance['locked']:
                    issuance_locked = True
                    break
        elif last_issuance['locked']:
            # before the issuance_lock_fix, only the last issuance was checked
            issuance_locked = True

        if last_issuance['issuer'] != source:
            problems.append('issued by another address')
        if (bool(last_issuance['divisible']) != bool(divisible)) and ((not util.enabled("cip03", block_index)) or (not reset)):
            problems.append('cannot change divisibility')
        if (not util.enabled("issuance_callability_parameters_removal", block_index)) and bool(last_issuance['callable']) != bool(callable_):
            problems.append('cannot change callability')
        if last_issuance['call_date'] > call_date and (call_date != 0 or (block_index < 312500 and (not config.TESTNET or not config.REGTEST))):
            problems.append('cannot advance call date')
        if last_issuance['call_price'] > call_price:
            problems.append('cannot reduce call price')
        if issuance_locked and quantity:
            problems.append('locked asset and non‐zero quantity')
        if issuance_locked and reset:
            problems.append('cannot reset a locked asset')
    else:
        reissuance = False
        if description.lower() == 'lock':
            problems.append('cannot lock a non‐existent asset')
        #if destination:
        #    problems.append('cannot transfer a non‐existent asset')
        if reset:
            problems.append('cannot reset a non existent asset')

    # validate parent ownership for subasset
    if subasset_longname is not None and not reissuance:
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
        if not reissuance or (block_index < 310000 and not config.TESTNET and not config.REGTEST):  # Pay fee only upon first issuance. (Protocol change.)
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
    assert isinstance(quantity, int)
    if reset and util.enabled("cip03", block_index):#reset will overwrite the quantity
        if quantity > config.MAX_INT:
            problems.append('total quantity overflow')  
    else:
        total = sum([issuance['quantity'] for issuance in issuances])
        if total + quantity > config.MAX_INT:
            problems.append('total quantity overflow')

    if util.enabled("cip03", block_index) and reset and issuances:
        cursor = db.cursor()
        #Checking that all supply are held by the owner of the asset
        cursor.execute('''SELECT * FROM balances \
                            WHERE asset = ? AND quantity > 0''', (asset,))
        balances = cursor.fetchall()
        cursor.close()
        
        if (len(balances) == 0):
            if util.asset_supply(db, asset) > 0:
                problems.append('Cannot reset an asset with no holder')
        elif (len(balances) > 1):
            problems.append('Cannot reset an asset with many holders')
        elif (len(balances) == 1):
            if (balances[0]['address'] != last_issuance["issuer"]):
                problems.append('Cannot reset an asset held by a different address than the owner')

    #if destination and quantity:
    #    problems.append('cannot issue and transfer simultaneously')

    # For SQLite3
    if util.enabled('integer_overflow_fix', block_index=block_index) and (fee > config.MAX_INT or quantity > config.MAX_INT):
        problems.append('integer overflow')

    return call_date, call_price, problems, fee, description, divisible, lock, reset, reissuance, reissued_asset_longname


def compose (db, source, transfer_destination, asset, quantity, divisible, lock, reset, description):

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

    asset_id = util.generate_asset_id(asset, util.CURRENT_BLOCK_INDEX)
    asset_name = util.generate_asset_name(asset_id, util.CURRENT_BLOCK_INDEX) #This will remove leading zeros in the numeric assets
    
    call_date, call_price, problems, fee, validated_description, divisible, lock, reset, reissuance, reissued_asset_longname = validate(db, source, transfer_destination, asset_name, quantity, divisible, lock, reset, callable_, call_date, call_price, description, subasset_parent, subasset_longname, util.CURRENT_BLOCK_INDEX)
    if problems: raise exceptions.ComposeError(problems)

    if subasset_longname is None or reissuance:
        asset_format = util.get_value_by_block_index("issuance_asset_serialization_format")
        asset_format_length = util.get_value_by_block_index("issuance_asset_serialization_length")
        
        # Type 20 standard issuance FORMAT_2 >QQ??If
        #   used for standard issuances and all reissuances
        if util.enabled("issuance_backwards_compatibility"):
            data = message_type.pack(LR_ISSUANCE_ID)
        else:    
            data = message_type.pack(ID)
        
        if description == None and util.enabled("issuance_description_special_null"):
            #a special message is created to be catched by the parse function
            curr_format = asset_format + '{}s'.format(len(DESCRIPTION_MARK_BYTE)+len(DESCRIPTION_NULL_ACTION))
            encoded_description = DESCRIPTION_MARK_BYTE+DESCRIPTION_NULL_ACTION.encode('utf-8')
        else:
            if (len(validated_description) <= 42) and not util.enabled('pascal_string_removed'):
                curr_format = FORMAT_2 + '{}p'.format(len(validated_description) + 1)
            else:
                curr_format = asset_format + '{}s'.format(len(validated_description))
            
            encoded_description = validated_description.encode('utf-8')
        
        
        
        
        if (asset_format_length <= 19):# callbacks parameters were removed
            data += struct.pack(curr_format, asset_id, quantity, 1 if divisible else 0, 1 if lock else 0, 1 if reset else 0, encoded_description)
        elif (asset_format_length <= 26):
            data += struct.pack(curr_format, asset_id, quantity, 1 if divisible else 0, 1 if callable_ else 0,
                call_date or 0, call_price or 0.0, encoded_description)
        elif (asset_format_length <= 27):# param reset was inserted
            data += struct.pack(curr_format, asset_id, quantity, 1 if divisible else 0, 1 if reset else 0, 1 if callable_ else 0,
                call_date or 0, call_price or 0.0, encoded_description)
        elif (asset_format_length <= 28):# param lock was inserted
            data += struct.pack(curr_format, asset_id, quantity, 1 if divisible else 0, 1 if lock else 0, 1 if reset else 0, 1 if callable_ else 0,
                call_date or 0, call_price or 0.0, encoded_description)
    else:
        subasset_format = util.get_value_by_block_index("issuance_subasset_serialization_format",util.CURRENT_BLOCK_INDEX)
        subasset_format_length = util.get_value_by_block_index("issuance_subasset_serialization_length",util.CURRENT_BLOCK_INDEX)

        # Type 21 subasset issuance SUBASSET_FORMAT >QQ?B
        #   Used only for initial subasset issuance
        # compacts a subasset name to save space
        compacted_subasset_longname = util.compact_subasset_longname(subasset_longname)
        compacted_subasset_length = len(compacted_subasset_longname)
        if util.enabled("issuance_backwards_compatibility"):
            data = message_type.pack(LR_SUBASSET_ID)
        else:    
            data = message_type.pack(SUBASSET_ID)
        
        if description == None and util.enabled("issuance_description_special_null"):
            #a special message is created to be catched by the parse function
            curr_format = subasset_format + '{}s'.format(compacted_subasset_length) + '{}s'.format(len(DESCRIPTION_MARK_BYTE)+len(DESCRIPTION_NULL_ACTION))
            encoded_description = DESCRIPTION_MARK_BYTE+DESCRIPTION_NULL_ACTION.encode('utf-8')
        else:       
            curr_format = subasset_format + '{}s'.format(compacted_subasset_length) + '{}s'.format(len(validated_description))          
            encoded_description = validated_description.encode('utf-8')
        
        if subasset_format_length <= 18:
            data += struct.pack(curr_format, asset_id, quantity, 1 if divisible else 0, compacted_subasset_length, compacted_subasset_longname, encoded_description)
        elif subasset_format_length <= 19:# param reset was inserted
            data += struct.pack(curr_format, asset_id, quantity, 1 if divisible else 0, 1 if reset else 0, compacted_subasset_length, compacted_subasset_longname, encoded_description) 
        elif subasset_format_length <= 20:# param lock was inserted
            data += struct.pack(curr_format, asset_id, quantity, 1 if divisible else 0, 1 if lock else 0, 1 if reset else 0, compacted_subasset_length, compacted_subasset_longname, encoded_description)

    if transfer_destination:
        destination_outputs = [(transfer_destination, None)]
    else:
        destination_outputs = []
    return (source, destination_outputs, data)

def parse (db, tx, message, message_type_id):
    issuance_parse_cursor = db.cursor()
    asset_format = util.get_value_by_block_index("issuance_asset_serialization_format",tx['block_index'])
    asset_format_length = util.get_value_by_block_index("issuance_asset_serialization_length",tx['block_index'])
    subasset_format = util.get_value_by_block_index("issuance_subasset_serialization_format",tx['block_index'])
    subasset_format_length = util.get_value_by_block_index("issuance_subasset_serialization_length",tx['block_index'])

    # Unpack message.
    try:
        subasset_longname = None
        if message_type_id == LR_SUBASSET_ID or message_type_id == SUBASSET_ID:
            if not util.enabled('subassets', block_index=tx['block_index']):
                logger.warn("subassets are not enabled at block %s" % tx['block_index'])
                raise exceptions.UnpackError

            # parse a subasset original issuance message
            lock = None
            reset = None
            
            if subasset_format_length <= 18:
                asset_id, quantity, divisible, compacted_subasset_length = struct.unpack(subasset_format, message[0:subasset_format_length])
            elif subasset_format_length <= 19:# param reset was inserted
                asset_id, quantity, divisible, reset, compacted_subasset_length = struct.unpack(subasset_format, message[0:subasset_format_length])            
            elif subasset_format_length <= 20:# param lock was inserted
                asset_id, quantity, divisible, lock, reset, compacted_subasset_length = struct.unpack(subasset_format, message[0:subasset_format_length])
                
            description_length = len(message) - subasset_format_length - compacted_subasset_length
            if description_length < 0:
                logger.warn("invalid subasset length: [issuance] tx [%s]: %s" % (tx['tx_hash'], compacted_subasset_length))
                raise exceptions.UnpackError
            messages_format = '>{}s{}s'.format(compacted_subasset_length, description_length)
            compacted_subasset_longname, description = struct.unpack(messages_format, message[subasset_format_length:])
            subasset_longname = util.expand_subasset_longname(compacted_subasset_longname)
            callable_, call_date, call_price = False, 0, 0.0
            try:
                description = description.decode('utf-8')
            except UnicodeDecodeError:
                description_data = description
                description = ''
                if description_data[0:1] == DESCRIPTION_MARK_BYTE:
                    try:
                        if description_data[1:].decode('utf-8') == DESCRIPTION_NULL_ACTION:
                            description = None
                    except UnicodeDecodeError:
                        description = '' 
        elif (tx['block_index'] > 283271 or config.TESTNET or config.REGTEST) and len(message) >= asset_format_length: # Protocol change.
            if (len(message) - asset_format_length <= 42) and not util.enabled('pascal_string_removed'):
                curr_format = asset_format + '{}p'.format(len(message) - asset_format_length)
            else:
                curr_format = asset_format + '{}s'.format(len(message) - asset_format_length)
            
            lock = None
            reset = None
            if (asset_format_length <= 19):# callbacks parameters were removed
                asset_id, quantity, divisible, lock, reset, description = struct.unpack(curr_format, message)
                callable_, call_date, call_price = False, 0, 0.0
            elif (asset_format_length <= 26):#the reset param didn't even exist
                asset_id, quantity, divisible, callable_, call_date, call_price, description = struct.unpack(curr_format, message)
            elif (asset_format_length <= 27):# param reset was inserted
                asset_id, quantity, divisible, reset, callable_, call_date, call_price, description = struct.unpack(curr_format, message)
            elif (asset_format_length <= 28):# param lock was inserted
                asset_id, quantity, divisible, lock, reset, callable_, call_date, call_price, description = struct.unpack(curr_format, message)
            
            call_price = round(call_price, 6) # TODO: arbitrary
            try:
                description = description.decode('utf-8')
            except UnicodeDecodeError:
                description_data = description
                description = ''
                if description_data[0:1] == DESCRIPTION_MARK_BYTE:
                    try:
                        if description_data[1:].decode('utf-8') == DESCRIPTION_NULL_ACTION:
                            description = None
                    except UnicodeDecodeError:
                        description = ''        
        else:
            if len(message) != LENGTH_1:
                raise exceptions.UnpackError
            asset_id, quantity, divisible = struct.unpack(FORMAT_1, message)
            lock, reset, callable_, call_date, call_price, description = False, False, False, 0, 0.0, ''
        try:
            asset = util.generate_asset_name(asset_id, tx['block_index'])
                        
            ##This is for backwards compatibility with assets names longer than 12 characters
            if asset.startswith('A'):
                namedAsset = util.get_asset_name(db, asset_id, tx['block_index'])
            
                if (namedAsset != 0):
                    asset = namedAsset
            
            if description == None:
                description = util.get_asset_description(db, asset)
            
            status = 'valid'
        except exceptions.AssetIDError:
            asset = None
            status = 'invalid: bad asset name'
    except exceptions.UnpackError as e:
        asset, quantity, divisible, lock, reset, callable_, call_date, call_price, description = None, None, None, None, None, None, None, None, None
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
        call_date, call_price, problems, fee, description, divisible, lock, reset, reissuance, reissued_asset_longname = validate(db, tx['source'], tx['destination'], asset, quantity, divisible, lock, reset, callable_, call_date, call_price, description, subasset_parent, subasset_longname, block_index=tx['block_index'])

        if problems: status = 'invalid: ' + '; '.join(problems)
        if not util.enabled('integer_overflow_fix', block_index=tx['block_index']) and 'total quantity overflow' in problems:
            quantity = 0

    # Reset?
    if (status == 'valid') and reset and util.enabled("cip03", tx['block_index']):
        balances_cursor = issuance_parse_cursor.execute('''SELECT * FROM balances WHERE asset = ? AND quantity > 0''', (asset,))
        balances_result = balances_cursor.fetchall()
        
        if len(balances_result) <= 1:
            if len(balances_result) == 0:
                issuances_cursor = issuance_parse_cursor.execute('''SELECT * FROM issuances WHERE asset = ? ORDER BY tx_index DESC''', (asset,))
                issuances_result = issuances_cursor.fetchall()
                
                owner_balance = 0
                owner_address = issuances_result[0]['issuer']
            else:
                owner_balance = balances_result[0]["quantity"]
                owner_address = balances_result[0]["address"]
            
            if owner_address == tx['source']:
                if owner_balance > 0:
                    util.debit(db, tx['source'], asset, owner_balance, 'reset destroy', tx['tx_hash'])
                    
                    bindings = {
                        'tx_index': tx['tx_index'],
                        'tx_hash': tx['tx_hash'],
                        'block_index': tx['block_index'],
                        'source': tx['source'],
                        'asset': asset,
                        'quantity': owner_balance,
                        'tag': "reset",
                        'status': "valid",
                        'reset': True,
                       }
                    sql = 'insert into destructions values(:tx_index, :tx_hash, :block_index, :source, :asset, :quantity, :tag, :status)'
                    issuance_parse_cursor.execute(sql, bindings)
        
                bindings= {
                    'tx_index': tx['tx_index'],
                    'tx_hash': tx['tx_hash'],
                    'block_index': tx['block_index'],
                    'asset': asset,
                    'quantity': quantity,
                    'divisible': divisible,
                    'source': tx['source'],
                    'issuer': tx['source'],
                    'transfer': False,
                    'callable': callable_,
                    'call_date': call_date,
                    'call_price': call_price,
                    'description': description,
                    'fee_paid': 0,
                    'locked': lock,
                    'status': status,
                    'reset': True,
                    'asset_longname': reissued_asset_longname,
                }
            
                sql='insert into issuances values(:tx_index, :tx_hash, 0, :block_index, :asset, :quantity, :divisible, :source, :issuer, :transfer, :callable, :call_date, :call_price, :description, :fee_paid, :locked, :status, :asset_longname, :reset)'
                issuance_parse_cursor.execute(sql, bindings)
            
                # Credit.
                if quantity:
                    util.credit(db, tx['source'], asset, quantity, action="reset issuance", event=tx['tx_hash'])

    else:
        if tx['destination']:
            issuer = tx['destination']
            transfer = True
            #quantity = 0
        else:
            issuer = tx['source']
            transfer = False

        # Debit fee.
        if status == 'valid':
            util.debit(db, tx['source'], config.XCP, fee, action="issuance fee", event=tx['tx_hash'])

        # Lock?
        if not isinstance(lock,bool):
            lock = False
        if status == 'valid':
            if (description and description.lower() == 'lock') or lock:
                lock = True
                cursor = db.cursor()
                issuances = list(cursor.execute('''SELECT * FROM issuances \
                                                   WHERE (status = ? AND asset = ?)
                                                   ORDER BY tx_index ASC''', ('valid', asset)))
                cursor.close()
                if description.lower() == 'lock' and len(issuances) > 0:
                    description = issuances[-1]['description']  # Use last description

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
            'reset': reset,
            'status': status,
            'asset_longname': asset_longname,
        }
        if "integer overflow" not in status:
            sql='insert into issuances values(:tx_index, :tx_hash, 0, :block_index, :asset, :quantity, :divisible, :source, :issuer, :transfer, :callable, :call_date, :call_price, :description, :fee_paid, :locked, :status, :asset_longname, :reset)'
            issuance_parse_cursor.execute(sql, bindings)
        else:
            logger.warn("Not storing [issuance] tx [%s]: %s" % (tx['tx_hash'], status))
            logger.debug("Bindings: %s" % (json.dumps(bindings), ))

        # Credit.
        if status == 'valid' and quantity:
            util.credit(db, tx['source'], asset, quantity, action="issuance", event=tx['tx_hash'])

        issuance_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
