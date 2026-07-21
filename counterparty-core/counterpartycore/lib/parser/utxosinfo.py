from counterpartycore.lib.parser import protocol

MAX_VOUT = 0xFFFFFFFF


def is_utxo_format(value, block_index=None):
    if not isinstance(value, str):
        return False
    values = value.split(":")
    if len(values) != 2:
        return False
    if not values[1].isnumeric():
        return False
    vout = int(values[1])
    if str(vout) != values[1]:
        return False
    if vout > MAX_VOUT and protocol.enabled("enforce_utxo_vout_max", block_index):
        # Rejecting out-of-range vouts changes the UTXO/address classification of a
        # transaction (attach vs detach, debit/credit routing), so it is a consensus
        # change and must be gated. Before activation the legacy behaviour is kept
        # (any non-negative integer vout that round-trips through str(int())).
        return False
    try:
        int(values[0], 16)
    except ValueError:
        return False
    if len(values[0]) != 64:
        return False
    return True


def parse_utxos_info(utxos_info):
    info = utxos_info.split(" ")

    # new format
    if len(info) == 4 and not is_utxo_format(info[-1]):
        sources = [source for source in info[0].split(",") if source]
        destination = info[1] or None
        outputs_count = int(info[2])
        op_return_output = int(info[3]) if info[3] != "" else None
        return sources, destination, outputs_count, op_return_output

    # old format
    destination = info[-1]
    sources = info[:-1]
    return sources, destination, None, None


def get_destination_from_utxos_info(utxos_info):
    _sources, destination, _outputs_count, _op_return_output = parse_utxos_info(utxos_info)
    return destination


def get_sources_from_utxos_info(utxos_info):
    sources, _destination, _outputs_count, _op_return_output = parse_utxos_info(utxos_info)
    return sources


def get_outputs_count_from_utxos_info(utxos_info):
    _sources, _destination, outputs_count, _op_return_output = parse_utxos_info(utxos_info)
    return outputs_count


def get_op_return_output_from_utxos_info(utxos_info):
    _sources, _destination, _outputs_count, op_return_output = parse_utxos_info(utxos_info)
    return op_return_output
