#! /usr/bin/python3

def concat(s):
    '''
    :param s: a list, each item is a string of a rlp encoded data
    '''
    assert isinstance(s, list)
    output = ''.join(s)
    return encode_length(len(output), 192) + output

    def encode_length(L, offset):
        if L < 56:
            return chr(L + offset)
        elif L < 256 ** 8:
            BL = int_to_big_endian(L)
            return chr(len(BL) + offset + 55) + BL
        else:
            raise Exception("input too long")

def encode(s):
    if isinstance(s, str):
        if len(s) == 1 and ord(s) < 128:
            return s
        else:
            return encode_length(len(s), 128) + s
    elif isinstance(s, list):
        return rlp.concat(list(map(rlp.encode, s)))

    raise TypeError("Encoding of %s not supported" % type(s))

# TODO
# TODO: TERRIBLE HACK, but only using rlp.encode for addresses of one size and small nonces for testing.
def encode(s):
    sender, nonce = s[0], s[1]
    if nonce == b'': nonce_byte = b'\x80'
    else: nonce_byte = nonce
    return b'\xd6\x94' + bytes(s[0]) + nonce_byte
# TODO

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
