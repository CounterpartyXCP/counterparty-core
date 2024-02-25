"""
None of the functions/objects in this module need be passed `db`.

Naming convention: a `pub` is either a pubkey or a pubkeyhash
"""

import hashlib
import binascii
import functools

import bitcoin as bitcoinlib
from bitcoin.core.key import CPubKey
from bitcoin.bech32 import CBech32Data
from Crypto.Hash import RIPEMD160
from pycoin_rs import b58, utils

from counterpartylib.lib import util
from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import ledger
from counterpartylib.lib import opcodes
from counterpartylib.lib.opcodes import *

b58_digits = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

class InputError (Exception):
    pass
class AddressError(Exception):
    pass
class MultiSigAddressError(AddressError):
    pass
class VersionByteError (AddressError):
    pass
class Base58Error (AddressError):
    pass
class Base58ChecksumError (Base58Error):
    pass


def validate(address, allow_p2sh=True):
    """Make sure the address is valid.

    May throw `AddressError`.
    """
    # Get array of pubkeyhashes to check.
    if is_multisig(address):
        pubkeyhashes = pubkeyhash_array(address)
    else:
        pubkeyhashes = [address]

    # Check validity by attempting to decode.
    for pubkeyhash in pubkeyhashes:
        try:
            if ledger.enabled('segwit_support'):
                if not is_bech32(pubkeyhash):
                    base58_check_decode(pubkeyhash, config.ADDRESSVERSION)
            else:
                base58_check_decode(pubkeyhash, config.ADDRESSVERSION)
        except VersionByteError as e:
            if not allow_p2sh:
                raise e
            base58_check_decode(pubkeyhash, config.P2SH_ADDRESSVERSION)
        except Base58Error as e:
            if not ledger.enabled('segwit_support') or not is_bech32(pubkeyhash):
                raise e



def base58_encode(binary):
    """Encode the address in base58."""
    # Convert big‐endian bytes to integer
    n = int('0x0' + util.hexlify(binary), 16)

    # Divide that integer into base58
    res = []
    while n > 0:
        n, r = divmod(n, 58)
        res.append(b58_digits[r])
    res = ''.join(res[::-1])

    return res


def base58_check_encode_py(original, version):
    """Check if base58 encoding is valid."""
    b = binascii.unhexlify(bytes(original, 'utf-8'))
    d = version + b

    binary = d + util.dhash(d)[:4]
    res = base58_encode(binary)

    # Encode leading zeros as base58 zeros
    czero = 0
    pad = 0
    for c in d:
        if c == czero:
            pad += 1
        else:
            break

    address = b58_digits[0] * pad + res

    if original != util.hexlify(base58_check_decode(address, version)):
        raise AddressError('encoded address does not decode properly')

    return address


def base58_check_encode(original, version):
    return b58.b58_encode(version + binascii.unhexlify(original))


def base58_decode(s):
    # Convert the string to an integer
    n = 0
    for c in s:
        n *= 58
        if c not in b58_digits:
            raise Base58Error('Not a valid Base58 character: ‘{}’'.format(c))
        digit = b58_digits.index(c)
        n += digit

    # Convert the integer to bytes
    h = '%x' % n
    if len(h) % 2:
        h = '0' + h
    res = binascii.unhexlify(h.encode('utf8'))

    # Add padding back.
    pad = 0
    for c in s[:-1]:
        if c == b58_digits[0]:
            pad += 1
        else:
            break
    k = b'\x00' * pad + res

    return k


def base58_check_decode_parts(s):
    """Decode from base58 and return parts."""

    k = base58_decode(s)

    addrbyte, data, chk0 = k[0:1], k[1:-4], k[-4:]

    return addrbyte, data, chk0


def base58_check_decode_py(s, version):
    """Decode from base58 and return data part."""

    addrbyte, data, chk0 = base58_check_decode_parts(s)

    if addrbyte != version:
        raise VersionByteError('incorrect version byte')

    chk1 = util.dhash(addrbyte + data)[:4]
    if chk0 != chk1:
        raise Base58ChecksumError('Checksum mismatch: 0x{} ≠ 0x{}'.format(util.hexlify(chk0), util.hexlify(chk1)))

    return data


def base58_check_decode(s, version):
    try:
        decoded = b58.b58_decode(s)
    except BaseException: # TODO: update pycoin_rs to raise a specific exception
        raise Base58Error('invalid base58 string')

    if decoded[0] != ord(version):
        raise VersionByteError('incorrect version byte')

    return decoded[1:]


def is_multisig(address):
    """Check if the address is multi‐signature."""
    array = address.split('_')
    return len(array) > 1


def is_p2sh(address):
    if is_multisig(address):
        return False

    try:
        base58_check_decode(address, config.P2SH_ADDRESSVERSION)
        return True
    except (VersionByteError, Base58Error):
        return False


def is_bech32(address):
    try:
        b32data = CBech32Data(address)
        return True
    except:
        return False


def is_fully_valid(pubkey_bin):
    """Check if the public key is valid."""
    cpubkey = CPubKey(pubkey_bin)
    return cpubkey.is_fullyvalid


def make_canonical(address):
    """Return canonical version of the address."""
    if is_multisig(address):
        signatures_required, pubkeyhashes, signatures_possible = extract_array(address)
        try:
            [base58_check_decode(pubkeyhash, config.ADDRESSVERSION) for pubkeyhash in pubkeyhashes]
        except Base58Error:
            raise MultiSigAddressError('Multi‐signature address must use PubKeyHashes, not public keys.')
        return construct_array(signatures_required, pubkeyhashes, signatures_possible)
    else:
        return address


def test_array(signatures_required, pubs, signatures_possible):
    """Check if multi‐signature data is valid."""
    try:
        signatures_required, signatures_possible = int(signatures_required), int(signatures_possible)
    except (ValueError, TypeError):
        raise MultiSigAddressError('Signature values not integers.')
    if signatures_required < 1 or signatures_required > 3:
        raise MultiSigAddressError('Invalid signatures_required.')
    if signatures_possible < 2 or signatures_possible > 3:
        raise MultiSigAddressError('Invalid signatures_possible.')
    for pubkey in pubs:
        if '_' in pubkey:
            raise MultiSigAddressError('Invalid characters in pubkeys/pubkeyhashes.')
    if signatures_possible != len(pubs):
        raise InputError('Incorrect number of pubkeys/pubkeyhashes in multi‐signature address.')


def construct_array(signatures_required, pubs, signatures_possible):
    """Create a multi‐signature address."""
    test_array(signatures_required, pubs, signatures_possible)
    address = '_'.join([str(signatures_required)] + sorted(pubs) + [str(signatures_possible)])
    return address


def extract_array(address):
    """Extract data from multi‐signature address."""
    assert is_multisig(address)
    array = address.split('_')
    signatures_required, pubs, signatures_possible = array[0], sorted(array[1:-1]), array[-1]
    test_array(signatures_required, pubs, signatures_possible)
    return int(signatures_required), pubs, int(signatures_possible)


def pubkeyhash_array(address):
    """Return PubKeyHashes from an address."""
    signatures_required, pubs, signatures_possible = extract_array(address)
    if not all([is_pubkeyhash(pub) for pub in pubs]):
        raise MultiSigAddressError('Invalid PubKeyHashes. Multi‐signature address must use PubKeyHashes, not public keys.')
    pubkeyhashes = pubs
    return pubkeyhashes


def hash160(x):
    x = hashlib.sha256(x).digest()
    m = RIPEMD160.new()
    m.update(x)
    return m.digest()


def pubkey_to_pubkeyhash(pubkey):
    """Convert public key to PubKeyHash."""
    pubkeyhash = hash160(pubkey)
    pubkey = base58_check_encode(binascii.hexlify(pubkeyhash).decode('utf-8'), config.ADDRESSVERSION)
    return pubkey


def pubkey_to_p2whash(pubkey):
    """Convert public key to PayToWitness."""
    pubkeyhash = hash160(pubkey)
    pubkey = CBech32Data.from_bytes(0, pubkeyhash)
    return str(pubkey)


def bech32_to_scripthash(address):
    bech32 = CBech32Data(address)
    return bytes(bech32)


@functools.cache
def get_asm(scriptpubkey):
    # TODO: When is an exception thrown here? Can this `try` block be tighter? Can it be replaced by a conditional?
    try:
        asm = []
        # TODO: This should be `for element in scriptpubkey`.
        for op in scriptpubkey:
            if type(op) == bitcoinlib.core.script.CScriptOp:
                # TODO: `op = element`
                asm.append(getattr(opcodes, str(op)))
            else:
                # TODO: `data = element` (?)
                asm.append(op)
    except bitcoinlib.core.script.CScriptTruncatedPushDataError:
        raise exceptions.PushDataDecodeError('invalid pushdata due to truncation')
    if not asm:
        raise exceptions.DecodeError('empty output')
    return asm


@functools.cache
def script_to_asm(scriptpubkey):
    try:
        script = bytes(scriptpubkey, 'utf-8') if type(scriptpubkey) == str else bytes(scriptpubkey)
        asm = utils.script_to_asm(script)
        if asm[-1] == OP_CHECKMULTISIG:
            asm[-2] = int.from_bytes(asm[-2])
            asm[0] = int.from_bytes(asm[0])
        return asm
    except BaseException as e:
        raise exceptions.DecodeError('invalid script')


# f'{block_index}-{script_to_address(scriptpubkey)}': f'{decode_p2w(scriptpubkey)}'
BAD_ADDRESSES = {
    # tesnet
    '2431884-tb1qudy5g780rm5yxnp9c7atvq6uas957qk2pxc84d26uv84w4c3jd8qay4mhj': 'tb1qudy5g780rm5yxnp9c7atvq6uas957qk2jrekv4',
    '2434482-tb1qu9ns8lzf2lylqk04yv6ax5rrywkm8kl543u3xxh75n0pta3pue4qhuh94m': 'tb1qu9ns8lzf2lylqk04yv6ax5rrywkm8kl5u606fz',
    # mainnet
    '675550-bc1qmj7zxs9arakv82c28zrsypj8a3r35fu78jyfldzpfhesu0w4n7tqw23az4': 'bc1qmj7zxs9arakv82c28zrsypj8a3r35fu7pure55',
    '706207-bc1qmlsh88wqwy0kfnkenx3rqe53l7v0lupckt6q4mpttt53wcgw5zkqyw35cd': 'bc1qmlsh88wqwy0kfnkenx3rqe53l7v0lupc6q5xx6',
    '709410-bc1qcv6gpxjvmv03ss7renvpdfmltfmjrnsdwy2gdjr8xjmdltcnr4vsth4ze7': 'bc1qcv6gpxjvmv03ss7renvpdfmltfmjrnsdy30wl7',
    '711342-bc1qmfk84cztyfffqdsstthngv6t58xj6tntuc3yr3nmmx4fn7ax696q2jh3y7': 'bc1qmfk84cztyfffqdsstthngv6t58xj6tnt8uf8hc',
    '711417-bc1q08udlxcvdjmrenecx26lnlt6kp67lsnxttaarn3j6zj2hld07fgsn4avkh': 'bc1q08udlxcvdjmrenecx26lnlt6kp67lsnxzd2ag8',
    '713108-bc1qnewecfxr65eplygyw2xsng2uuvsgh6wpk6p33gsnx3rwq4jl3n9qyesnlw': 'bc1qnewecfxr65eplygyw2xsng2uuvsgh6wpkgyjsz',
    '717322-bc1ql3gt2uk4pyr67s8hn40y3qlrvwn5r7nftx85nks3skv0sjuq39rqxdjf2g': 'bc1ql3gt2uk4pyr67s8hn40y3qlrvwn5r7nfp0c57p',
    '718552-bc1qwzj0jxl65ze5a9hqrmnr8ygycgsvctratf7d0rd5tqrj4swq8zws4eg8u3': 'bc1qwzj0jxl65ze5a9hqrmnr8ygycgsvctra2krt2y',
    '718926-bc1qtjfmsnaa3zte7avxgpc5tp3n8dvksa7qqv2ftvmjmuf6vlgva0vsjw8xmf': 'bc1qtjfmsnaa3zte7avxgpc5tp3n8dvksa7qzjxegv',
    '719361-bc1qh6awyk7mljfh8m6dt4c9grsaq3u9khytt0ktgl3npusnzt02ke5qknu3da': 'bc1qh6awyk7mljfh8m6dt4c9grsaq3u9khytq5xv6q',
    '719804-bc1qf8fhznt8lnnrc24zjskxrghvvfngjpgfe8ssp5t9ppfmzm0a7yzqelly03': 'bc1qf8fhznt8lnnrc24zjskxrghvvfngjpgffu9z48',
    '720270-bc1qaxjsnmkem70y4kh089fr9cll0aecqv4afmujlw4j5k9d7n82hc3qdngalk': 'bc1qaxjsnmkem70y4kh089fr9cll0aecqv4aechlaj',
    '721335-bc1q7lxr8c9r8fx7a3e79r3ycp0uycchl5jugvy6pnfp8j6rg56avh6qz8wx42': 'bc1q7lxr8c9r8fx7a3e79r3ycp0uycchl5juljxq6a',
    '722422-bc1qwzj0jxl65ze5a9hqrmnr8ygycgsvctratf7d0rd5tqrj4swq8zws4eg8u3': 'bc1qwzj0jxl65ze5a9hqrmnr8ygycgsvctra2krt2y',
    '722741-bc1qry2hcfl067vaqdq3khry6engj0gpmweepevp75qd8efcwl8j0wsqvzzce9': 'bc1qry2hcfl067vaqdq3khry6engj0gpmwee58dzer',
    '723213-bc1qfx8s3d7vj2m82hcdqpc4yeafng9ydqrqcgmz3dtdwetm95ua3ups7adl56': 'bc1qfx8s3d7vj2m82hcdqpc4yeafng9ydqrqyzq4st',
    '724942-bc1qvketfkv0c6sv4x023ae4aprly7xvqcuad2dmqpdflf0t7rd0ewwsq55z46': 'bc1qvketfkv0c6sv4x023ae4aprly7xvqcua2nhqqr',
    '724954-bc1q9wu266dexw0upuvme627uyhj9c4agtxr5gvdkm7f6w5dpahnlwfqfexmdy': 'bc1q9wu266dexw0upuvme627uyhj9c4agtxrvplk6n',
    '725761-bc1qtsafn3yp7ldnk0n8xhl8qajc3ex3vdlehn67x6422g9ffkpn5jqquv268u': 'bc1qtsafn3yp7ldnk0n8xhl8qajc3ex3vdlehgz8r6',
    '725906-bc1qwzj0jxl65ze5a9hqrmnr8ygycgsvctratf7d0rd5tqrj4swq8zws4eg8u3': 'bc1qwzj0jxl65ze5a9hqrmnr8ygycgsvctra2krt2y',
    '727175-bc1qwe27pg5khnlavdess22xv476ur3v6ftzc8yrk8cwudtfc23hptssgwvl6c': 'bc1qwe27pg5khnlavdess22xv476ur3v6ftzha7ay8',
    '730719-bc1q7vlsdw4ya0m0h87jpf3u8x3fzeqp787nllt0ehmgqyz5s7ejknxqplrwx2': 'bc1q7vlsdw4ya0m0h87jpf3u8x3fzeqp787nxp7zrz',
    '730884-bc1qq3rljq7rej7z80eqkm0xpmag0wdvcrvk2qpaj46msp369fp2cegs86q8xr': 'bc1qq3rljq7rej7z80eqkm0xpmag0wdvcrvkwaqfll',
    '732351-bc1qmp4aq6zvm2nzny75yqyrptdtp4f3nur8ypt395c0msdylm0tp8asgj6j97': 'bc1qmp4aq6zvm2nzny75yqyrptdtp4f3nur86nhkmx',
    '732701-bc1qlkacwq8nhylu58p4xquaczq83edtdukpwg8wnnulk5sq7zzc3sjscfhsc9': 'bc1qlkacwq8nhylu58p4xquaczq83edtdukp5ug39a',
    '732705-bc1qelquv8hf7km6dg77t2ft8kln873509wtcd38jmvv3y47kkdgh5hqu3feay': 'bc1qelquv8hf7km6dg77t2ft8kln873509wtqefdqz',
    '734920-bc1ql9wn97d2xhpkpvvxldhg82kr6eplsv434fkd80n6vg29kpdqsw6ses9ea8': 'bc1ql9wn97d2xhpkpvvxldhg82kr6eplsv43j0h62q',
    '738151-bc1qcd52n69ps78tjumlky5dxm7g6e5aer48lkyjyqja9mwtadsk5q2qjtrsc9': 'bc1qcd52n69ps78tjumlky5dxm7g6e5aer48p05xzn',
    '738151-bc1q9lcmgf3t89txr3ncmehp2l6h94ppsvc839pcldgdtcd33yfextssnd4efk': 'bc1q9lcmgf3t89txr3ncmehp2l6h94ppsvc87a6hn9',
    '740527-bc1qjgchsxj0ra0x4frvfw45y3nwhwpxgrtljtnwwulcvuh3wpzy3xkst0e2xt': 'bc1qjgchsxj0ra0x4frvfw45y3nwhwpxgrtlqvh54n',
    '746425-bc1qwfgdjyy95aay2686fn74h6a4nu9eev6np7q4fn204dkj3274frlqrskvx0': 'bc1qwfgdjyy95aay2686fn74h6a4nu9eev6np0mzee',
    '747656-bc1qz707axlr7wtvy6k7lesde52jecpeeqe2qahg8vkdc47469g588nqpmsq0u': 'bc1qz707axlr7wtvy6k7lesde52jecpeeqe2lmrehl',
    '752024-bc1q08fy7sv8p59ly4mrfuccd6kwwqsaq04mmjwfxvt9ls4vm2l2s8lsrls7ws': 'bc1q08fy7sv8p59ly4mrfuccd6kwwqsaq04mspyrv0',
    '754305-bc1q0hjfmnqafqpcdrcur27uyh9zpchtnh8ezsnnn57qyjm0h7lx0ydqlqm7xe': 'bc1q0hjfmnqafqpcdrcur27uyh9zpchtnh8e4enp8z',
    '757284-bc1qt32naa7a5l7perdt65wwfac4xa69z302yc7jayvn8s6wm2xdsc6qurxkr5': 'bc1qt32naa7a5l7perdt65wwfac4xa69z302d4crh6',
    '759190-bc1qn8y38x955443r0a2kl8typ3sxevpdlklhcmdm9htgkct9h37c72s6m85fy': 'bc1qn8y38x955443r0a2kl8typ3sxevpdlklg062r9',
    '761547-bc1qgv2n6nf2fku66qmdugs6ful3tk2h3vcj9d52h5k0sxruqxdeqfpqh5emyx': 'bc1qgv2n6nf2fku66qmdugs6ful3tk2h3vcj48683v',
    '762694-bc1qary3ng3wtlqvglqx3vdkqlw0d7j92qvcapdzekrsg8g9p3hve5us9w2snm': 'bc1qary3ng3wtlqvglqx3vdkqlw0d7j92qvcmhzate',
    '768271-bc1q226aruacmq4jl7slqhgfhajz2xlxk2ektdm5cdy0dudyf2prlcrsvk3xgv': 'bc1q226aruacmq4jl7slqhgfhajz2xlxk2ekvy2ncg',
    '773926-bc1qj0tw3recrlm4fag5v7f033rhmlmudc9h5eqnm3s5u47e8zedx42qxp5shd': 'bc1qj0tw3recrlm4fag5v7f033rhmlmudc9hrxddyp',
    '774617-bc1qfygdhvh64zyjqe4ll2nvnhq7tyq4krujlzs5l32th4jmgyr0xtnqs4yhrt': 'bc1qfygdhvh64zyjqe4ll2nvnhq7tyq4krujxr2lft',
    '774984-bc1qscx4zsnhgv0lc0mqsmqv6lmtv6qdnvvqsxe5vmjpt37qny42rlzqy4fg6p': 'bc1qscx4zsnhgv0lc0mqsmqv6lmtv6qdnvvqhl4l9g',
    '777117-bc1qp78hjqgh47kpq5gq65vxty4js4sc6evga8gs8ekf4d7zjpapcxfq5zt6z6': 'bc1qp78hjqgh47kpq5gq65vxty4js4sc6evgmwftju',
    '777497-bc1q69sspds2zus36wg5a93guwefx85a8cqhwhhks7mlq009f8jhqlfquuqwcf': 'bc1q69sspds2zus36wg5a93guwefx85a8cqhdhqdzt',
    '778297-bc1qwfgdjyy95aay2686fn74h6a4nu9eev6np7q4fn204dkj3274frlqrskvx0': 'bc1qwfgdjyy95aay2686fn74h6a4nu9eev6np0mzee',
    '779659-bc1q86p9t3058zsehdnwvafm8w55yz0meww38w30y70y3y36p4w369ysxad2cz': 'bc1q86p9t3058zsehdnwvafm8w55yz0meww3xfu2g5',
    '780711-bc1qk7elr482ng27p0gfjhx643wu72fkgjzj8sh9588fkgxy3jp6dd5qmjvrl3': 'bc1qk7elr482ng27p0gfjhx643wu72fkgjzja6epe2',
    '781325-bc1qf8g554f43ce3677s4vdt8pj98mq60g6s7sw02eptyk8y327dtc3sxzy7vt': 'bc1qf8g554f43ce3677s4vdt8pj98mq60g6s96prq7',
    '788609-bc1qwfgdjyy95aay2686fn74h6a4nu9eev6np7q4fn204dkj3274frlqrskvx0': 'bc1qwfgdjyy95aay2686fn74h6a4nu9eev6np0mzee',
    '794139-bc1qp653euwemkejn6qcs7gmf8q7283c7xvck4gm59jvr0nd9ljryhqq7pnknm': 'bc1qp653euwemkejn6qcs7gmf8q7283c7xvcx2rx7d',
    '797636-bc1qcjyrrk6ll4zly8em0m6w9r4awha2ctrk26x09y47t5rjtfzrp0csw5xvfz': 'bc1qcjyrrk6ll4zly8em0m6w9r4awha2ctrk8nkev4',
    '801339-bc1q0uvuy894mmm44aaphk92j8f2l2tjdel39jnwut6lmyfyecpcsh4q62aqwq': 'bc1q0uvuy894mmm44aaphk92j8f2l2tjdel34vhfff',
    '801560-bc1qm00nan6e87c9af33gm4a2ujc0qvjj5lqj7lfu7sw7yfrr5mm8epqejmuqj': 'bc1qm00nan6e87c9af33gm4a2ujc0qvjj5lq9vjkve',
    '801574-bc1qfvkmkxyxhcvqk0s7vckatp60mxht9gwq2z660pmj2pgrj0dgqp2s782qlm': 'bc1qfvkmkxyxhcvqk0s7vckatp60mxht9gwq86hhx2',
    '802911-bc1q7mdlmz382xzrx5z0mcu3862uczqezql0uusru4na6rtrkjg0z55qkgpzm9': 'bc1q7mdlmz382xzrx5z0mcu3862uczqezql02ef2rd',
}

#@functools.cache
def script_to_address(scriptpubkey):
    try:
        network = 'mainnet' if config.TESTNET == False else 'testnet'
        script = bytes(scriptpubkey, 'utf-8') if type(scriptpubkey) == str else bytes(scriptpubkey)

        address = utils.script_to_address(script, network)

        # reproduce bug with the old decode_p2w() function
        address = BAD_ADDRESSES.get(f"{ledger.CURRENT_BLOCK_INDEX}-{address}", address)

        return address
    except BaseException as e:
        raise exceptions.DecodeError('scriptpubkey decoding error')


def get_checksig(asm):
    try:
        op_dup, op_hash160, pubkeyhash, op_equalverify, op_checksig = asm
    except ValueError:
        raise exceptions.DecodeError('invalid OP_CHECKSIG') from None
    
    if (op_dup, op_hash160, op_equalverify, op_checksig) == (OP_DUP, OP_HASH160, OP_EQUALVERIFY, OP_CHECKSIG) and type(pubkeyhash) == bytes:
        return pubkeyhash
    
    raise exceptions.DecodeError('invalid OP_CHECKSIG')


def get_checkmultisig(asm):
    # N‐of‐2
    if len(asm) == 5 and asm[3] == 2 and asm[4] == OP_CHECKMULTISIG:
        pubkeys, signatures_required = asm[1:3], asm[0]
        if all([type(pubkey) == bytes for pubkey in pubkeys]):
            return pubkeys, signatures_required
    # N‐of‐3
    if len(asm) == 6 and asm[4] == 3 and asm[5] == OP_CHECKMULTISIG:
        pubkeys, signatures_required = asm[1:4], asm[0]
        if all([type(pubkey) == bytes for pubkey in pubkeys]):
            return pubkeys, signatures_required
    raise exceptions.DecodeError('invalid OP_CHECKMULTISIG')


# TODO: Not used ?
def scriptpubkey_to_address(scriptpubkey):
    asm = script_to_asm(scriptpubkey)

    if asm[-1] == OP_CHECKSIG:
        try:
            checksig = get_checksig(asm)
        except exceptions.DecodeError:  # coinbase
            return None

        return base58_check_encode(binascii.hexlify(checksig).decode('utf-8'), config.ADDRESSVERSION)

    elif asm[-1] == OP_CHECKMULTISIG:
        pubkeys, signatures_required = get_checkmultisig(asm)
        pubkeyhashes = [pubkey_to_pubkeyhash(pubkey) for pubkey in pubkeys]
        return construct_array(signatures_required, pubkeyhashes, len(pubkeyhashes))

    elif len(asm) == 3 and asm[0] == OP_HASH160 and asm[2] == OP_EQUAL:
        return base58_check_encode(binascii.hexlify(asm[1]).decode('utf-8'), config.P2SH_ADDRESSVERSION)

    return None


# TODO: Use `python-bitcointools` instead. (Get rid of `pycoin` dependency.)
from pycoin.encoding.sec import public_pair_to_sec
from pycoin.encoding.exceptions import EncodingError
from pycoin.encoding.bytes32 import from_bytes_32
from pycoin.encoding.b58 import a2b_hashed_base58
from pycoin.ecdsa.secp256k1 import secp256k1_generator as generator_secp256k1


def wif_to_tuple_of_prefix_secret_exponent_compressed(wif):
    """
    Return a tuple of (prefix, secret_exponent, is_compressed).
    """
    decoded = a2b_hashed_base58(wif)
    actual_prefix, private_key = decoded[:1], decoded[1:]
    compressed = len(private_key) > 32
    return actual_prefix, from_bytes_32(private_key[:32]), compressed


def wif_to_tuple_of_secret_exponent_compressed(wif, allowable_wif_prefixes=None):
    """Convert a WIF string to the corresponding secret exponent. Private key manipulation.
    Returns a tuple: the secret exponent, as a bignum integer, and a boolean indicating if the
    WIF corresponded to a compressed key or not.

    Not that it matters, since we can use the secret exponent to generate both the compressed
    and uncompressed Bitcoin address."""
    actual_prefix, secret_exponent, is_compressed = wif_to_tuple_of_prefix_secret_exponent_compressed(wif)
    if allowable_wif_prefixes and actual_prefix not in allowable_wif_prefixes:
        raise EncodingError("unexpected first byte of WIF %s" % wif)
    return secret_exponent, is_compressed


def public_pair_for_secret_exponent(generator, secret_exponent):
    return (generator*secret_exponent).pair()


class AltcoinSupportError (Exception): pass
def private_key_to_public_key(private_key_wif):
    """Convert private key to public key."""
    if config.TESTNET:
        allowable_wif_prefixes = [config.PRIVATEKEY_VERSION_TESTNET]
    elif config.REGTEST:
        allowable_wif_prefixes = [config.PRIVATEKEY_VERSION_REGTEST]
    else:
        allowable_wif_prefixes = [config.PRIVATEKEY_VERSION_MAINNET]
    try:
        secret_exponent, compressed = wif_to_tuple_of_secret_exponent_compressed(
                private_key_wif, allowable_wif_prefixes=allowable_wif_prefixes)
    except EncodingError:
        raise AltcoinSupportError('pycoin: unsupported WIF prefix')
    public_pair = public_pair_for_secret_exponent(generator_secp256k1, secret_exponent)
    public_key = public_pair_to_sec(public_pair, compressed=compressed)
    public_key_hex = binascii.hexlify(public_key).decode('utf-8')
    return public_key_hex


def is_pubkeyhash(monosig_address):
    """Check if PubKeyHash is valid P2PKH address. """
    assert not is_multisig(monosig_address)
    try:
        base58_check_decode(monosig_address, config.ADDRESSVERSION)
        return True
    except (Base58Error, VersionByteError):
        return False


def make_pubkeyhash(address):
    """Create a new PubKeyHash."""
    if is_multisig(address):
        signatures_required, pubs, signatures_possible = extract_array(address)
        pubkeyhashes = []
        for pub in pubs:
            if is_pubkeyhash(pub):
                pubkeyhash = pub
            else:
                pubkeyhash = pubkey_to_pubkeyhash(binascii.unhexlify(bytes(pub, 'utf-8')))
            pubkeyhashes.append(pubkeyhash)
        pubkeyhash_address = construct_array(signatures_required, pubkeyhashes, signatures_possible)
    else:
        if ledger.enabled('segwit_support') and is_bech32(address):
            pubkeyhash_address = address # Some bech32 addresses are valid base58 data
        elif is_pubkeyhash(address):
            pubkeyhash_address = address
        elif is_p2sh(address):
            pubkeyhash_address = address
        else:
            pubkeyhash_address = pubkey_to_pubkeyhash(binascii.unhexlify(bytes(address, 'utf-8')))
    return pubkeyhash_address


def extract_pubkeys(pub):
    """Assume pubkey if not pubkeyhash. (Check validity later.)"""
    pubkeys = []
    if is_multisig(pub):
        _, pubs, _ = extract_array(pub)
        for pub in pubs:
            if not is_pubkeyhash(pub):
                pubkeys.append(pub)
    elif is_p2sh(pub):
        pass
    elif ledger.enabled('segwit_support') and is_bech32(pub):
        pass
    else:
        if not is_pubkeyhash(pub):
            pubkeys.append(pub)
    return pubkeys
