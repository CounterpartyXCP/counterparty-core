#! /usr/bin/python3

from lib import (util, config)
from lib.scriptlib import (rlp, utils)

import logging
import pickle

class Block(object):

    def __init__(self, db):
        self.db = db
        return

    def postqueue_delete(self):
        cursor = self.db.cursor()
        cursor.execute('''DELETE FROM postqueue''')

    def postqueue_insert(self, message):
        cursor = self.db.cursor()
        cursor.execute('''INSERT INTO postqueue VALUES(:message)''', {'message': pickle.dumps(message)})

    def postqueue_get(self):
        cursor = self.db.cursor()
        return list(cursor.execute('''SELECT * FROM postqueue'''))

    def postqueue_append(self, post_msg):
        cursor = self.db.cursor()
        cursor.execute('''INSERT INTO postqueue VALUES(:message)''', {'message': pickle.dumps(post_msg)})

    def postqueue_pop(self):
        cursor = self.db.cursor()
        postqueues = list(cursor.execute('''SELECT * FROM postqueue ORDER BY rowid ASC'''))
        first_message_pickled = postqueues[0]['message']                                                # Get first entry.
        cursor.execute('''DELETE FROM postqueue WHERE rowid = (SELECT MIN(rowid) FROM postqueue)''')    # Delete first entry.
        return pickle.loads(first_message_pickled)


    def suicides_append(self, contract_id):
        cursor = self.db.cursor()
        cursor.execute('''INSERT INTO suicides VALUES(:contract_id)''', {'contract_id': contract_id})
        
    def suicides_get(self):
        cursor = self.db.cursor()
        return list(cursor.execute('''SELECT * FROM suicides'''))

    def suicides_delete(self):
        cursor = self.db.cursor()
        cursor.execute('''DELETE FROM suicides''')

    # TODO: don’t use `with` for snapshots?!?!
    def revert(snapshot):
        logging.debug('### REVERTING ###')

    def get_storage_data(self, contract_id, key=None):
        cursor = self.db.cursor()

        if key == None:
            cursor.execute('''SELECT * FROM storage WHERE contract_id = ? ''', (contract_id,))
            storages = list(cursor)
            return storages

        # print('prekey', key)
        key = key.to_bytes(32, byteorder='big')
        cursor.execute('''SELECT * FROM storage WHERE contract_id = ? AND key = ?''', (contract_id, key))
        storages = list(cursor)
        # print('key', key)
        if not storages:
            return 0
        value = storages[0]['value']

        # TODO
        value = rlp.big_endian_to_int(value)
        # value = rlp.decode(value)

        return value

    def set_storage_data(self, contract_id, key, value):
        # TODO: This could all be done more elegantly, I think.

        # TODO
        # value = rlp.int_to_big_endian(value)
        # value = rlp.encode(value)

        key = key.to_bytes(32, byteorder='big')
        value = value.to_bytes(32, byteorder='big')

        cursor = self.db.cursor()

        cursor.execute('''SELECT * FROM storage WHERE contract_id = ? AND key = ?''', (contract_id, key))
        storages = list(cursor)
        if storages:    # Update value.
            bindings = {
                'contract_id': contract_id,
                'key': key,
                'value': value
                }
            sql='update storage set value = :value where contract_id = :contract_id and key = :key'
            cursor.execute(sql, bindings)
        else:           # Insert value.
            bindings = {
                'contract_id': contract_id,
                'key': key,
                'value': value
                }
            sql='insert into storage values(:contract_id, :key, :value)'
            cursor.execute(sql, bindings)

        storages = cursor.execute('''SELECT * FROM storage WHERE contract_id = ? AND key = ?''', (contract_id, key))


        return value


    def account_to_dict(self, address):
        return {'nonce': Block.get_nonce(self, address), 'balance': Block.get_balance(self, address), 'storage': Block.get_storage_data(self, address), 'code': utils.hexprint(Block.get_code(self, address))}

    def get_code (self, contract_id):
        cursor = self.db.cursor()
        cursor.execute('''SELECT * FROM contracts WHERE contract_id = ?''', (contract_id,))
        contracts = list(cursor)

        if not contracts:
            return b''
            # TODO: IMPORTANT raise ContractError('no such contract')
        else: code = contracts[0]['code']

        return code

    def get_nonce(self, address):
        cursor = self.db.cursor()
        nonces = list(cursor.execute('''SELECT * FROM nonces WHERE (address = ?)''', (address,)))
        if not nonces: return 0
        else: return nonces[0]['nonce']

    def set_nonce(self, address, nonce):
        cursor = self.db.cursor()
        cursor.execute('''SELECT * FROM nonces WHERE (address = :address)''', {'address': address})
        nonces = list(cursor)
        if not nonces:
            cursor.execute('''INSERT INTO nonces VALUES(:address, :nonce)''', {'address': address, 'nonce': nonce})
        else:
            cursor.execute('''UPDATE nonces SET nonce = :nonce WHERE (address = :address)''', {'nonce': nonce, 'address': address})

    def increment_nonce(self, address):
        nonce = Block.get_nonce(self, address)
        Block.set_nonce(self, address, nonce + 1)

    def get_balance(self, address):
        return util.get_balance(self.db, address, config.XCP)

    def transfer_value(self, tx, source, destination, quantity):
        if source:
            util.debit(self.db, tx.block_index, source, config.XCP, quantity, action='transfer value', event=tx.tx_hash)
        if destination:
            util.credit(self.db, tx.block_index, destination, config.XCP, quantity, action='transfer value', event=tx.tx_hash)
        return True

    def del_account(self, suicide):
        cursor = self.db.cursor()
        contract_id = suicide['contract_id']
        logging.debug('SUICIDING {}'.format(contract_id))
        cursor.execute('''DELETE FROM contracts WHERE contract_id = :contract_id''', {'contract_id': contract_id})
        cursor.execute('''DELETE FROM storage WHERE contract_id = :contract_id''', {'contract_id': contract_id})

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
