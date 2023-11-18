import binascii
from Crypto.Cipher import ARC4

def init_arc4(seed):
    if isinstance(seed, str):
        seed = binascii.unhexlify(seed)
    return ARC4.new(seed)
