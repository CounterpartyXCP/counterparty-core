def hash160(x):
    x = hashlib.sha256(x).digest()
    m = hashlib.new('ripemd160')
    m.update(x)
    return m.digest()

def pubkey_to_pubkeyhash(pubkey):
    pubkeyhash = hash160(pubkey)
    pubkey = base58_check_encode(binascii.hexlify(pubkeyhash).decode('utf-8'), config.ADDRESSVERSION)
    return pubkey

def get_asm(scriptpubkey):
    try:
        asm = []
        for op in scriptpubkey:
            if type(op) == bitcoinlib.core.script.CScriptOp:
                asm.append(str(op))
            else:
                asm.append(op)
    except bitcoinlib.core.script.CScriptTruncatedPushDataError:
        raise DecodeError('invalid pushdata due to truncation')
    if not asm:
        raise DecodeError('empty output')
    return asm

def get_checksig(asm):
    if len(asm) == 5 and asm[0] == 'OP_DUP' and asm[1] == 'OP_HASH160' and asm[3] == 'OP_EQUALVERIFY' and asm[4] == 'OP_CHECKSIG':
        pubkeyhash = asm[2]
        if type(pubkeyhash) == bytes:
            return pubkeyhash
    raise DecodeError('invalid OP_CHECKSIG')

def get_checkmultisig(asm):
    # N‐of‐2
    if len(asm) == 5 and asm[3] == 2 and asm[4] == 'OP_CHECKMULTISIG':
        pubkeys, signatures_required = asm[1:3], asm[0]
        if all([type(pubkey) == bytes for pubkey in pubkeys]):
            return pubkeys, signatures_required
    # N‐of‐3
    if len(asm) == 6 and asm[4] == 3 and asm[5] == 'OP_CHECKMULTISIG':
        pubkeys, signatures_required = asm[1:4], asm[0]
        if all([type(pubkey) == bytes for pubkey in pubkeys]):
            return pubkeys, signatures_required
    raise DecodeError('invalid OP_CHECKMULTISIG')

def scriptpubkey_to_address(scriptpubkey):
    asm = get_asm(scriptpubkey)
    if asm[-1] == 'OP_CHECKSIG':
        return base58_check_encode(binascii.hexlify(get_checksig(asm)).decode('utf-8'), config.ADDRESSVERSION)
    elif asm[-1] == 'OP_CHECKMULTISIG':
        pubkeys, signatures_required = get_checkmultisig(asm)
        pubkeyhashes = [pubkey_to_pubkeyhash(pubkey) for pubkey in pubkeys]
        return construct_array(signatures_required, pubkeyhashes, len(pubkeyhashes))
    return None

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
