import getpass
import binascii
from functools import lru_cache

import bitcoin as bitcoinlib

def dumpprivkey():
   return util.rpc('dumpprivkey', [address])

def wallet_unlock ():
    getinfo = rpc.getinfo()
    if 'unlocked_until' in getinfo:
        if getinfo['unlocked_until'] >= 60:
            return True # Wallet is unlocked for at least the next 60 seconds.
        else:
            passphrase = getpass.getpass('Enter your Bitcoind[‐Qt] wallet passhrase: ')
            print('Unlocking wallet for 60 (more) seconds.')
            util.rpc('walletpassphrase', [passphrase, 60])
    else:
        return True    # Wallet is unencrypted.

def deserialize(tx_hex):
    return bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(tx_hex))
def serialize(ctx):
    return bitcoinlib.core.CTransaction.serialize(ctx)

def is_valid (address):
    return rpc.validateAddress(address)['isvalid']
def is_mine (address):
    return rpc.validateAddress(address)['ismine']

def get_txhash_list(block):
    return [bitcoinlib.core.b2lx(ctx.GetHash()) for ctx in block.vtx]

@lru_cache(maxsize=4096)
def get_cached_raw_transaction(tx_hash):
    return rpc.getrawtransaction(bitcoinlib.core.lx(tx_hash))

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
