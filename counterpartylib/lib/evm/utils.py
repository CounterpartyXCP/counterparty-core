import binascii

from counterpartylib.lib import script


def ethaddr_to_cpaddr(addr):
    if isinstance(addr, str):
        addr = addr.encode('ascii')

    b = binascii.unhexlify(addr)
    return script.base58_encode(b)


def cpaddr_to_ethaddr(addr):
    b = script.base58_decode(addr)

    return binascii.hexlify(b).decode('ascii')