import logging
import struct

from counterpartycore.lib import (
    config,
    exceptions,
    ledger,
)
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import messagetype, protocol
from counterpartycore.lib.utils import address, helpers

logger = logging.getLogger(config.LOGGER_NAME)

FORMAT = ">21sB"
LENGTH = 22
MAX_MEMO_LENGTH = 34  # Could be higher, but we will keep it consistent with enhanced send
ID = 4
ANTISPAM_FEE_DECIMAL = 0.5
ANTISPAM_FEE = ANTISPAM_FEE_DECIMAL * config.UNIT

FLAG_BALANCES = 1
FLAG_OWNERSHIP = 2
FLAG_BINARY_MEMO = 4

FLAGS_ALL = FLAG_BINARY_MEMO | FLAG_BALANCES | FLAG_OWNERSHIP


def get_total_fee(db, source, block_index):
    total_fee = ANTISPAM_FEE
    antispamfee = protocol.get_value_by_block_index("sweep_antispam_fee", block_index) * config.UNIT
    if antispamfee > 0:
        balances_count = ledger.balances.get_balances_count(db, source)[0]["cnt"]
        issuances_count = ledger.issuances.get_issuances_count(db, source)
        total_fee = int(balances_count * antispamfee * 2 + issuances_count * antispamfee * 4)
    return total_fee


def validate(db, source, destination, flags, memo, block_index):
    problems = []

    if source == destination:
        problems.append("destination cannot be the same as source")

    cursor = db.cursor()

    result = ledger.balances.get_balance(db, source, "XCP")

    total_fee = get_total_fee(db, source, block_index)

    if result < total_fee:
        problems.append(
            f"insufficient XCP balance for sweep. Need {total_fee / config.UNIT} XCP for antispam fee"
        )

    cursor.close()

    if flags > FLAGS_ALL:
        problems.append(f"invalid flags {flags}")
    elif not flags & (FLAG_BALANCES | FLAG_OWNERSHIP):
        problems.append("must specify which kind of transfer in flags")

    if memo and len(memo) > MAX_MEMO_LENGTH:
        problems.append("memo too long")

    return problems, total_fee


def compose(
    db, source: str, destination: str, flags: int, memo: str, skip_validation: bool = False
):
    if memo is None:
        memo_bytes = b""
    elif flags & FLAG_BINARY_MEMO:
        memo_bytes = bytes.fromhex(memo)
    else:
        memo_bytes = memo.encode("utf-8")
        memo_bytes = struct.pack(f">{len(memo_bytes)}s", memo_bytes)

    block_index = CurrentState().current_block_index()
    problems, _total_fee = validate(db, source, destination, flags, memo_bytes, block_index)
    if problems and not skip_validation:
        raise exceptions.ComposeError(problems)

    short_address_bytes = address.pack(destination)

    if protocol.enabled("taproot_support"):
        data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
        data += helpers.encode_data(
            short_address_bytes,
            flags,
            memo_bytes,
        )
    else:
        data = messagetype.pack(ID)
        data += struct.pack(FORMAT, short_address_bytes, flags)
        data += memo_bytes

    return (source, [], data)


def new_unpack(message):
    try:
        (short_address_bytes, flags_bytes, memo_bytes) = helpers.decode_data(message)

        flags = helpers.bytes_to_int(flags_bytes)

        if len(memo_bytes) == 0:
            memo_bytes = None
        elif not flags & FLAG_BINARY_MEMO:
            memo_bytes = memo_bytes.decode("utf-8")

        full_address = address.unpack(short_address_bytes)

        return {
            "destination": full_address,
            "flags": flags,
            "memo": memo_bytes,
        }
    except Exception as e:  # pylint: disable=broad-exception-caught
        raise exceptions.UnpackError("could not unpack") from e


def unpack(message):
    if protocol.enabled("taproot_support"):
        return new_unpack(message)

    try:
        memo_bytes_length = len(message) - LENGTH
        if memo_bytes_length < 0:
            raise exceptions.UnpackError("invalid message length")
        if memo_bytes_length > MAX_MEMO_LENGTH:
            raise exceptions.UnpackError("memo too long")

        struct_format = FORMAT + f"{memo_bytes_length}s"
        short_address_bytes, flags, memo_bytes = struct.unpack(struct_format, message)
        if len(memo_bytes) == 0:
            memo_bytes = None
        elif not flags & FLAG_BINARY_MEMO:
            memo_bytes = memo_bytes.decode("utf-8")
        # unpack address
        full_address = address.unpack(short_address_bytes)
    except struct.error as e:
        raise exceptions.UnpackError("could not unpack") from e

    unpacked = {
        "destination": full_address,
        "flags": flags,
        "memo": memo_bytes,
    }
    return unpacked


def parse(db, tx, message):
    cursor = db.cursor()

    fee_paid = round(config.UNIT / 2)

    # Unpack message.
    try:
        unpacked = unpack(message)
        destination, flags, memo_bytes = (
            unpacked["destination"],
            unpacked["flags"],
            unpacked["memo"],
        )

        status = "valid"
    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error) as e:
        destination, flags, memo_bytes = None, None, None
        status = f"invalid: could not unpack ({e})"
    except exceptions.BalanceError:  # noqa: F405
        destination, flags, memo_bytes = None, None, None
        status = "invalid: insufficient balance for antispam fee for sweep"
    except Exception as err:  # pylint: disable=broad-exception-caught
        destination, flags, memo_bytes = None, None, None
        status = "invalid: could not unpack, " + str(err)

    if status == "valid":
        problems, total_fee = validate(
            db, tx["source"], destination, flags, memo_bytes, tx["block_index"]
        )
        if problems:
            status = "invalid: " + "; ".join(problems)

    if status == "valid":
        try:
            antispamfee = (
                protocol.get_value_by_block_index("sweep_antispam_fee", tx["block_index"])
                * config.UNIT
            )

            if antispamfee > 0:
                ledger.events.debit(
                    db,
                    tx["source"],
                    "XCP",
                    total_fee,
                    tx["tx_index"],
                    action="sweep fee",
                    event=tx["tx_hash"],
                )
            else:
                ledger.events.debit(
                    db,
                    tx["source"],
                    "XCP",
                    fee_paid,
                    tx["tx_index"],
                    action="sweep fee",
                    event=tx["tx_hash"],
                )
        except exceptions.BalanceError:  # noqa: F405
            destination, flags, memo_bytes = None, None, None
            status = "invalid: insufficient balance for antispam fee for sweep"

    if status == "valid":
        balances = ledger.balances.get_address_balances(db, tx["source"])

        if flags & FLAG_BALANCES:
            for balance in balances:
                ledger.events.debit(
                    db,
                    tx["source"],
                    balance["asset"],
                    balance["quantity"],
                    tx["tx_index"],
                    action="sweep",
                    event=tx["tx_hash"],
                )
                ledger.events.credit(
                    db,
                    destination,
                    balance["asset"],
                    balance["quantity"],
                    tx["tx_index"],
                    action="sweep",
                    event=tx["tx_hash"],
                )

        if flags & FLAG_OWNERSHIP:
            sweep_pos = 0

            assets_issued = balances
            if protocol.enabled("zero_balance_ownership_sweep_fix", tx["block_index"]):
                assets_issued = ledger.issuances.get_asset_issued(db, tx["source"])

            for next_asset_issued in assets_issued:
                issuances = ledger.issuances.get_issuances(
                    db,
                    asset=next_asset_issued["asset"],
                    status="valid",
                    first=True,
                    current_block_index=tx["block_index"],
                )
                if len(issuances) > 0:
                    last_issuance = issuances[-1]
                    if last_issuance["issuer"] == tx["source"]:
                        bindings = {
                            "tx_index": tx["tx_index"],
                            "tx_hash": tx["tx_hash"],
                            "msg_index": sweep_pos,
                            "block_index": tx["block_index"],
                            "asset": next_asset_issued["asset"],
                            "quantity": 0,
                            "divisible": last_issuance["divisible"],
                            "source": last_issuance["source"],
                            "issuer": destination,
                            "transfer": True,
                            "callable": last_issuance["callable"],
                            "call_date": last_issuance["call_date"],
                            "call_price": last_issuance["call_price"],
                            "description": last_issuance["description"],
                            "fee_paid": 0,
                            "locked": last_issuance["locked"],
                            "status": status,
                            "asset_longname": last_issuance["asset_longname"],
                            "reset": False,
                            "asset_events": "transfer",
                        }
                        ledger.events.insert_record(db, "issuances", bindings, "ASSET_TRANSFER")
                        sweep_pos += 1

        bindings = {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "block_index": tx["block_index"],
            "source": tx["source"],
            "destination": destination,
            "flags": flags,
            "status": status,
            "memo": memo_bytes,
            "fee_paid": total_fee if antispamfee > 0 else fee_paid,
        }
        ledger.events.insert_record(db, "sweeps", bindings, "SWEEP")

        logger.info("Sweep from %(source)s to %(destination)s (%(tx_hash)s) [%(status)s]", bindings)

    cursor.close()
