import logging
import math
import struct

from bitstring import BitArray, ConstBitStream
from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.utils import address

logger = logging.getLogger(config.LOGGER_NAME)

## encoding functions


def _encode_construct_base_lut(snds):
    # t is a tuple of the form (asset, addr, amnt [, memo, is_hex])
    return sorted(list(set([t[1] for t in snds])))  # Sorted to make list determinist


def _encode_construct_base_assets(sends):
    # t is a tuple of the form (asset, addr, amnt [, memo, is_hex])
    return sorted(list(set([t[0] for t in sends])))  # Sorted to make list determinist


def _encode_construct_lut(sends):
    base_lut = _encode_construct_base_lut(sends)

    # What's this? It calculates the minimal number of bits needed to represent an item index inside the base_lut
    lut_nbits = math.ceil(math.log2(len(base_lut)))

    return {"nbits": lut_nbits, "addrs": base_lut}


def _encode_compress_lut(lut):
    return b"".join(
        [struct.pack(">H", len(lut["addrs"]))] + [address.pack(addr) for addr in lut["addrs"]]
    )


def _encode_memo(memo=None, is_hex=False):
    """Tightly pack a memo as a Bit array"""

    if memo is not None:
        # signal a 1 bit for existence of the memo
        barr = BitArray("0b1")

        if is_hex:
            # signal a 1 bit for hex encoded memos
            barr.append("0b1")
            if isinstance(memo, str):  # append the string as hex-string  # noqa: E721
                barr.append(f"uint:6={len(memo) >> 1}")
                memo = f"0x{memo}"
            else:
                barr.append(f"uint:6={len(memo)}")

            barr.append(memo)
        else:
            # signal a 0 bit for a string encoded memo
            barr.append("0b0")
            barr.append(f"uint:6={len(memo)}")
            barr.append(BitArray(memo.encode("utf-8")))

        return barr
    # if the memo is None, return just a 0 bit
    return BitArray("0b0")


def _safe_tuple_index(t, i):
    """Get an element from a tuple, returning None if it's out of bounds"""
    if len(t) <= i:
        return None
    return t[i]


def _encode_construct_send_list(send_asset, lut, sends):
    # t is a tuple of the form (asset, addr, amnt, memo, is_hex)
    # if there's no memo specified, memo and is_hex are None
    return [
        (lut["addrs"].index(t[1]), t[2], _safe_tuple_index(t, 3), _safe_tuple_index(t, 4))
        for t in sends
        if t[0] == send_asset
    ]


def _solve_asset(db, asset_name):
    asset = ledger.issuances.resolve_subasset_longname(db, asset_name)
    return ledger.issuances.get_asset_id(db, asset)


def _encode_compress_send_list(db, nbits, send):
    r = BitArray()
    r.append(f"uintbe:64={_solve_asset(db, send['assetName'])}")
    r.append(f"uint:{nbits}={len(send['sendList']) - 1}")

    for send_item in send["sendList"]:
        idx = send_item[0]
        amnt = send_item[1]
        r.append(f"uint:{nbits}={idx}")
        r.append(f"uintbe:64={amnt}")

        try:
            memo_str = _encode_memo(memo=send_item[2], is_hex=send_item[3])
        except:  # noqa: E722  # pylint: disable=bare-except
            memo_str = BitArray("0b0")

        r.append(memo_str)
    return r


def _encode_construct_sends(sends):
    lut = _encode_construct_lut(sends)
    assets = _encode_construct_base_assets(sends)

    send_lists = [
        {"assetName": asset, "sendList": _encode_construct_send_list(asset, lut, sends)}
        for asset in assets
    ]

    return {"lut": lut, "sendLists": send_lists}


def _encode_compress_sends(db, mpma_send, memo=None, memo_is_hex=False):
    compressed_lut = _encode_compress_lut(mpma_send["lut"])
    memo_arr = _encode_memo(memo, memo_is_hex).bin

    isends = (
        "0b"
        + memo_arr
        + "".join(
            [
                "".join(
                    [
                        "1",
                        _encode_compress_send_list(db, mpma_send["lut"]["nbits"], send_list).bin,
                    ]
                )
                for send_list in mpma_send["sendLists"]
            ]
        )
    )
    bstr = "".join([isends, "0"])
    pad = "0" * ((8 - (len(bstr) - 2)) % 8)  # That -2 is because the prefix 0b is there
    barr = BitArray(bstr + pad)
    return b"".join([compressed_lut, barr.bytes])


def _encode_mpma_send(db, sends, memo=None, memo_is_hex=False):
    mpma = _encode_construct_sends(sends)
    send = _encode_compress_sends(db, mpma, memo=memo, memo_is_hex=memo_is_hex)

    return send


## decoding functions


def _decode_decode_lut(data):
    (num_addresses,) = struct.unpack(">H", data[0:2])
    if num_addresses == 0:
        raise exceptions.DecodeError("address list can't be empty")
    p = 2
    address_list = []
    bytes_per_address = 21

    for _i in range(0, num_addresses):  # noqa: B007
        addr_raw = data[p : p + bytes_per_address]

        address_list.append(address.unpack(addr_raw))
        p += bytes_per_address

    lut_nbits = math.ceil(math.log2(num_addresses))

    return address_list, lut_nbits, data[p:]


def _decode_decode_send_list(stream, nbits, lut):
    asset_id = stream.read("uintbe:64")

    if nbits > 0:
        num_recipients = stream.read(f"uint:{nbits}")
        range_limit = num_recipients + 1
    else:
        num_recipients = 1
        range_limit = num_recipients
    send_list = []
    asset = ledger.issuances.generate_asset_name(asset_id)
    for _i in range(0, range_limit):  # noqa: B007
        if nbits > 0:
            idx = stream.read(f"uint:{nbits}")
        else:
            idx = 0
        addr = lut[idx]
        amount = stream.read("uintbe:64")

        memo, is_hex = _decode_memo(stream)
        if memo is not None:
            send_list.append((addr, amount, memo, is_hex))
        else:
            send_list.append((addr, amount))

    return asset, send_list


def _decode_decode_sends(stream, nbits, lut):
    # stream = ConstBitStream(data)
    sends = {}

    while stream.read("bool"):
        asset, send_list = _decode_decode_send_list(stream, nbits, lut)
        sends[asset] = send_list

    return sends


def _decode_memo(stream):
    if stream.read("bool"):
        is_hex = stream.read("bool")
        mlen = stream.read("uint:6")
        data = stream.read(f"bytes:{mlen}")

        if not (is_hex):
            # is an utf8 string
            data = data.decode("utf-8")

        return data, is_hex

    return None, None


def _decode_mpma_send_decode(data):
    lut, nbits, remain = _decode_decode_lut(data)
    stream = ConstBitStream(remain)
    memo, is_hex = _decode_memo(stream)
    sends = _decode_decode_sends(stream, nbits, lut)
    if memo is not None:
        for send_list in sends.values():
            for idx, send in enumerate(send_list):
                if len(send) == 2:
                    send_list[idx] = (send[0], send[1], memo, is_hex)

    return sends
