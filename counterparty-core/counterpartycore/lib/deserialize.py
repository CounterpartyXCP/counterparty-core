from counterpartycore.lib.bc_data_stream import BCDataStream
from counterpartycore.lib.util import (
    b2h,
    double_hash,
    ib2h,
)


def read_tx_in(vds):
    tx_in = {}
    tx_in["hash"] = vds.read_bytes(32)
    tx_in["n"] = vds.read_uint32()
    script_sig_size = vds.read_compact_size()
    tx_in["script_sig"] = vds.read_bytes(script_sig_size)
    tx_in["sequence"] = vds.read_uint32()
    tx_in["coinbase"] = False
    if (
        tx_in["hash"]
        == b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
    ):
        tx_in["coinbase"] = True
    return tx_in


def read_tx_out(vds):
    tx_out = {}
    tx_out["value"] = vds.read_int64()
    script = vds.read_bytes(vds.read_compact_size())
    tx_out["script_pub_key"] = script
    return tx_out


def read_transaction(vds, use_txid=True):
    transaction = {}
    start_pos = vds.read_cursor
    transaction["version"] = vds.read_int32()

    flag = vds.read_bytes(2)
    if flag == b"\x00\x01":
        transaction["segwit"] = True
    else:
        transaction["segwit"] = False
        vds.read_cursor = vds.read_cursor - 2

    transaction["coinbase"] = False
    transaction["vin"] = []
    for _i in range(vds.read_compact_size()):  # noqa: B007
        vin = read_tx_in(vds)
        transaction["vin"].append(vin)
        transaction["coinbase"] = transaction["coinbase"] or vin["coinbase"]

    transaction["vout"] = []
    for i in range(vds.read_compact_size()):  # noqa: B007
        transaction["vout"].append(read_tx_out(vds))

    transaction["vtxinwit"] = []
    if transaction["segwit"]:
        offset_before_tx_witnesses = vds.read_cursor - start_pos
        for vin in transaction["vin"]:  # noqa: B007
            witnesses_count = vds.read_compact_size()
            for i in range(witnesses_count):  # noqa: B007
                witness_length = vds.read_compact_size()
                witness = vds.read_bytes(witness_length)
                transaction["vtxinwit"].append(witness)

    transaction["lock_time"] = vds.read_uint32()
    data = vds.input[start_pos : vds.read_cursor]

    transaction["tx_hash"] = ib2h(double_hash(data))
    if transaction["segwit"]:
        hash_data = data[:4] + data[6:offset_before_tx_witnesses] + data[-4:]
        transaction["tx_id"] = ib2h(double_hash(hash_data))
        if use_txid:
            transaction["tx_hash"] = transaction["tx_id"]

    transaction["__data__"] = b2h(data)

    return transaction


def read_block_header(vds):
    block_header = {}
    block_header["magic_bytes"] = vds.read_int32()
    # if block_header['magic_bytes'] != 118034699:
    #   raise Exception('Not a block')
    block_header["block_size"] = vds.read_int32()
    header_start = vds.read_cursor
    block_header["version"] = vds.read_int32()
    block_header["hash_prev"] = ib2h(vds.read_bytes(32))
    block_header["hash_merkle_root"] = ib2h(vds.read_bytes(32))
    block_header["block_time"] = vds.read_uint32()
    block_header["bits"] = vds.read_uint32()
    block_header["nonce"] = vds.read_uint32()
    header_end = vds.read_cursor
    header = vds.input[header_start:header_end]
    block_header["block_hash"] = ib2h(double_hash(header))
    # block_header['__header__'] = b2h(header)
    return block_header


def read_block(vds, only_header=False, use_txid=True):
    block = read_block_header(vds)
    if only_header:
        return block
    block["transaction_count"] = vds.read_compact_size()
    block["transactions"] = []
    for _i in range(block["transaction_count"]):  # noqa: B007
        block["transactions"].append(read_transaction(vds, use_txid=use_txid))
    return block


def deserialize_tx(tx_hex, use_txid):
    ds = BCDataStream()
    ds.map_hex(tx_hex)
    tx = read_transaction(ds, use_txid=use_txid)
    return tx


def deserialize_block(block_hex, use_txid, only_header=False):
    block_hex = ("00" * 8) + block_hex  # fake magic bytes and block size
    ds = BCDataStream()
    ds.map_hex(block_hex)
    return read_block(ds, only_header=only_header, use_txid=use_txid)
