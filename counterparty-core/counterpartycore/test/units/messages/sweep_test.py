import cbor2
import pytest
from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages import sweep
from counterpartycore.lib.utils import address as address_util
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_validate(ledger_db, defaults, monkeypatch):
    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 1, None, config.BURN_START
    ) == ([], 400000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 2, None, config.BURN_START
    ) == ([], 400000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 3, None, config.BURN_START
    ) == ([], 800000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 1, "test", config.BURN_START
    ) == ([], 400000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 1, b"test", config.BURN_START
    ) == ([], 400000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 0, None, config.BURN_START
    ) == (["must specify which kind of transfer in flags"], 800000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][6], 1, None, config.BURN_START
    ) == (["destination cannot be the same as source"], 400000)

    assert sweep.validate(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 8, None, config.BURN_START
    ) == (["invalid flags 8"], 800000)

    assert sweep.validate(
        ledger_db,
        defaults["addresses"][6],
        defaults["addresses"][5],
        1,
        "012345678900123456789001234567890012345",
        config.BURN_START,
    ) == (["memo too long"], 400000)

    monkeypatch.setattr(
        "counterpartycore.lib.messages.sweep.get_total_fee",
        lambda db, source, block_index, flags=None: 1000000000000,
    )

    assert sweep.validate(
        ledger_db, defaults["addresses"][8], defaults["addresses"][5], 1, None, config.BURN_START
    ) == (
        ["insufficient XCP balance for sweep. Need 10000.0 XCP for antispam fee"],
        1000000000000,
    )

    assert sweep.validate(
        ledger_db, defaults["addresses"][8], defaults["addresses"][5], 1, None, config.BURN_START
    ) == (
        ["insufficient XCP balance for sweep. Need 10000.0 XCP for antispam fee"],
        1000000000000,
    )


def test_compose(ledger_db, defaults, monkeypatch):
    with ProtocolChangesDisabled("taproot_support"):
        assert sweep.compose(
            ledger_db, defaults["addresses"][6], defaults["addresses"][5], 1, None, False
        ) == (
            defaults["addresses"][6],
            [],
            b"\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01",
        )

        assert sweep.compose(
            ledger_db, defaults["addresses"][6], defaults["addresses"][5], 2, None
        ) == (
            "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            [],
            b"\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x02",
        )

        assert sweep.compose(
            ledger_db, defaults["addresses"][6], defaults["addresses"][5], 3, None
        ) == (
            "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            [],
            b"\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03",
        )

        assert sweep.compose(
            ledger_db, defaults["addresses"][6], defaults["addresses"][5], 3, "test"
        ) == (
            "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            [],
            b"\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03test",
        )

        assert sweep.compose(
            ledger_db, defaults["addresses"][6], defaults["addresses"][5], 7, "cafebabe"
        ) == (
            "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            [],
            b"\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x07\xca\xfe\xba\xbe",
        )

        monkeypatch.setattr(
            "counterpartycore.lib.messages.sweep.get_total_fee",
            lambda db, source, block_index, flags=None: 1000000000000,
        )

        with pytest.raises(
            exceptions.ComposeError,
            match="insufficient XCP balance for sweep. Need 10000.0 XCP for antispam fee",
        ):
            (sweep.compose(ledger_db, defaults["addresses"][8], defaults["addresses"][5], 1, None),)


def test_compose_rejects_invalid_hex_memo(ledger_db, defaults):
    with pytest.raises(exceptions.ComposeError, match="memo must be valid hexadecimal"):
        sweep.compose(ledger_db, defaults["addresses"][6], defaults["addresses"][5], 7, "not hex")


def test_compose_rejects_non_integer_flags_with_memo(ledger_db, defaults):
    with pytest.raises(exceptions.ComposeError, match="flags must be an int"):
        sweep.compose(ledger_db, defaults["addresses"][6], defaults["addresses"][5], "1", "memo")


def test_compose_rejects_non_string_memo(ledger_db, defaults):
    with pytest.raises(exceptions.ComposeError, match="memo must be a string"):
        sweep.compose(ledger_db, defaults["addresses"][6], defaults["addresses"][5], 1, ["memo"])


def test_compose_2(ledger_db, defaults):
    assert sweep.compose(
        ledger_db, defaults["addresses"][0], defaults["addresses"][1], 1, None, False
    ) == (
        defaults["addresses"][0],
        [],
        b"\x04\x83U\x01\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec\x01@",
    )

    assert sweep.compose(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 7, "cafebabe"
    ) == (
        "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
        [],
        b"\x04\x83U\x01\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x07D\xca\xfe\xba\xbe",
    )

    assert sweep.compose(
        ledger_db, defaults["addresses"][6], defaults["addresses"][5], 3, "test"
    ) == (
        "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
        [],
        b"\x04\x83U\x01\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03Dtest",
    )


def test_compose_empty_address_reports_no_sweepable_content(ledger_db, defaults):
    with pytest.raises(
        exceptions.ComposeError, match="address has no balances or asset ownerships to sweep"
    ):
        sweep.compose(
            ledger_db,
            defaults["addresses"][7],
            defaults["addresses"][5],
            sweep.FLAG_BALANCES | sweep.FLAG_OWNERSHIP,
            None,
        )


def test_empty_sweep_problem_reports_single_requested_kind(ledger_db, defaults):
    assert (
        sweep.empty_sweep_problem(
            ledger_db, defaults["addresses"][7], sweep.FLAG_BALANCES, config.BURN_START
        )
        == "address has no balances to sweep"
    )

    assert (
        sweep.empty_sweep_problem(ledger_db, defaults["addresses"][7], "1", config.BURN_START)
        is None
    )


def test_has_asset_ownership_to_sweep(ledger_db, defaults, monkeypatch):
    source = defaults["addresses"][0]

    monkeypatch.setattr(
        sweep.ledger.issuances,
        "get_asset_issued",
        lambda _db, _source: [{"asset": "TESTASSET"}],
    )
    monkeypatch.setattr(
        sweep.ledger.issuances,
        "get_issuances",
        lambda _db, **_kwargs: [{"issuer": source}],
    )

    assert sweep.has_asset_ownership_to_sweep(ledger_db, source, config.BURN_START)


def test_new_unpack(defaults):
    assert sweep.unpack(
        b"\x83U\x01\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec\x01@"
    ) == {"destination": defaults["addresses"][1], "flags": 1, "memo": None}

    assert sweep.unpack(
        b"\x83U\x01\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x07D\xca\xfe\xba\xbe"
    ) == {"destination": defaults["addresses"][5], "flags": 7, "memo": b"\xca\xfe\xba\xbe"}

    assert sweep.unpack(
        b"\x83U\x01\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03Dtest"
    ) == {"destination": defaults["addresses"][5], "flags": 3, "memo": "test"}

    with pytest.raises(exceptions.UnpackError, match="could not unpack"):
        sweep.new_unpack(
            b"\x01\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01\x03"
        )


def test_unpack(defaults):
    with ProtocolChangesDisabled("taproot_support"):
        assert sweep.unpack(
            b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01"
        ) == {"destination": defaults["addresses"][5], "flags": 1, "memo": None}

        assert sweep.unpack(
            b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x02"
        ) == {"destination": defaults["addresses"][5], "flags": 2, "memo": None}

        assert sweep.unpack(
            b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03test"
        ) == {"destination": defaults["addresses"][5], "flags": 3, "memo": "test"}

        assert sweep.unpack(
            b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x07\xca\xfe\xba\xbe"
        ) == {"destination": defaults["addresses"][5], "flags": 7, "memo": b"\xca\xfe\xba\xbe"}


def test_legacy_unpack_taproot_activated(defaults):
    assert sweep.unpack(
        b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01"
    ) == {"destination": defaults["addresses"][5], "flags": 1, "memo": None}

    assert sweep.unpack(
        b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x02"
    ) == {"destination": defaults["addresses"][5], "flags": 2, "memo": None}

    assert sweep.unpack(
        b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03test"
    ) == {"destination": defaults["addresses"][5], "flags": 3, "memo": "test"}

    assert sweep.unpack(
        b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x07\xca\xfe\xba\xbe"
    ) == {"destination": defaults["addresses"][5], "flags": 7, "memo": b"\xca\xfe\xba\xbe"}


def test_parse_flag_1(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    with ProtocolChangesDisabled("taproot_support"):
        tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
        message = b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01"
        sweep.parse(ledger_db, tx, message)

        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "sweeps",
                    "values": {
                        "block_index": tx["block_index"],
                        "destination": defaults["addresses"][5],
                        "source": defaults["addresses"][0],
                        "status": "valid",
                        "flags": 1,
                        "tx_hash": tx["tx_hash"],
                        "tx_index": tx["tx_index"],
                    },
                },
                {
                    "table": "credits",
                    "values": {
                        "address": defaults["addresses"][5],
                        "asset": "XCP",
                        "block_index": current_block_index,
                        "calling_function": "sweep",
                        "event": tx["tx_hash"],
                        "quantity": 91397199693,
                    },
                },
                {
                    "table": "debits",
                    "values": {
                        "action": "sweep",
                        "address": defaults["addresses"][0],
                        "asset": "XCP",
                        "block_index": current_block_index,
                        "event": tx["tx_hash"],
                        "quantity": 91397199693,
                    },
                },
                {
                    "table": "credits",
                    "values": {
                        "address": defaults["addresses"][5],
                        "asset": "LOCKED",
                        "block_index": current_block_index,
                        "calling_function": "sweep",
                        "event": tx["tx_hash"],
                        "quantity": 1000,
                    },
                },
                {
                    "table": "debits",
                    "values": {
                        "action": "sweep",
                        "address": defaults["addresses"][0],
                        "asset": "LOCKED",
                        "block_index": current_block_index,
                        "event": tx["tx_hash"],
                        "quantity": 1000,
                    },
                },
                {
                    "table": "transactions_status",
                    "values": {
                        "tx_index": tx["tx_index"],
                        "valid": True,
                    },
                },
            ],
        )


def add_zero_balance(ledger_db, address, asset, tx_index, event):
    # Register the asset first: balances store the compact ``asset_index`` and
    # ``credit``/``debit`` only ever reference issued assets in production, so
    # the synthetic asset must exist in ``assets`` to resolve its index.
    ledger.events.ensure_asset(
        ledger_db,
        ledger.issuances.generate_asset_id(asset),
        asset,
        ledger.currentstate.CurrentState().current_block_index(),
        None,
    )
    ledger.events.credit(ledger_db, address, asset, 1, tx_index, action="test setup", event=event)
    ledger.events.debit(ledger_db, address, asset, 1, tx_index, action="test setup", event=event)


def test_parse_skips_zero_quantity_balances(ledger_db, blockchain_mock, defaults):
    source = defaults["addresses"][0]
    destination = defaults["addresses"][1]
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    add_zero_balance(ledger_db, source, "ZEROASSET", tx["tx_index"], "zero-balance-setup")

    message = b"\x83U\x01\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec\x01@"
    sweep.parse(ledger_db, tx, message)

    zero_sweep_records = ledger_db.execute(
        """
        SELECT COUNT(*) AS count
        FROM (
            SELECT quantity FROM credits
            WHERE address = ? AND asset = (SELECT asset_index FROM assets WHERE asset_name = ?) AND calling_function = ? AND event = ?
            UNION ALL
            SELECT quantity FROM debits
            WHERE address = ? AND asset = (SELECT asset_index FROM assets WHERE asset_name = ?) AND action = ? AND event = ?
        )
        """,
        (
            destination,
            "ZEROASSET",
            "sweep",
            tx["tx_hash"],
            source,
            "ZEROASSET",
            "sweep",
            tx["tx_hash"],
        ),
    ).fetchone()["count"]

    assert zero_sweep_records == 0


def test_parse_zero_quantity_balances_legacy_path(ledger_db, blockchain_mock, defaults):
    source = defaults["addresses"][0]
    destination = defaults["addresses"][1]
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    add_zero_balance(ledger_db, source, "ZEROASSET", tx["tx_index"], "zero-balance-setup")

    message = b"\x83U\x01\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec\x01@"
    with ProtocolChangesDisabled(["sweep_skip_zero_balances"]):
        sweep.parse(ledger_db, tx, message)

    zero_sweep_records = ledger_db.execute(
        """
        SELECT COUNT(*) AS count
        FROM (
            SELECT quantity FROM credits
            WHERE address = ? AND asset = (SELECT asset_index FROM assets WHERE asset_name = ?) AND calling_function = ? AND event = ?
            UNION ALL
            SELECT quantity FROM debits
            WHERE address = ? AND asset = (SELECT asset_index FROM assets WHERE asset_name = ?) AND action = ? AND event = ?
        )
        """,
        (
            destination,
            "ZEROASSET",
            "sweep",
            tx["tx_hash"],
            source,
            "ZEROASSET",
            "sweep",
            tx["tx_hash"],
        ),
    ).fetchone()["count"]

    assert zero_sweep_records == 2


def test_total_fee_ignores_zero_quantity_balances(ledger_db, blockchain_mock, defaults):
    source = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    fee_before = sweep.get_total_fee(ledger_db, source, tx["block_index"], sweep.FLAG_BALANCES)

    add_zero_balance(ledger_db, source, "ZEROASSET", tx["tx_index"], "zero-balance-setup")

    fee_after = sweep.get_total_fee(ledger_db, source, tx["block_index"], sweep.FLAG_BALANCES)
    assert fee_after == fee_before

    with ProtocolChangesDisabled(["sweep_skip_zero_balances"]):
        legacy_fee = sweep.get_total_fee(ledger_db, source, tx["block_index"], sweep.FLAG_BALANCES)

    assert legacy_fee > fee_after


def test_parse_empty_ownership_sweep_charges_no_fee(ledger_db, blockchain_mock, defaults):
    # An address that holds XCP but owns no assets, sweeping ownership-only, has
    # total_fee == 0 under the gate. It must be charged nothing rather than falling
    # back to the legacy flat fee_paid (which would charge for a no-op sweep, the
    # exact behavior #3089 fixes).
    source = next(
        a
        for a in defaults["addresses"]
        if ledger.balances.get_balance(ledger_db, a, "XCP") > config.UNIT
        and ledger.issuances.get_issuances_count(ledger_db, a) == 0
    )
    destination = next(a for a in defaults["addresses"] if a != source)

    tx = blockchain_mock.dummy_tx(ledger_db, source)
    assert sweep.get_total_fee(ledger_db, source, tx["block_index"], sweep.FLAG_OWNERSHIP) == 0

    xcp_before = ledger.balances.get_balance(ledger_db, source, "XCP")

    message = cbor2.dumps([address_util.pack(destination), sweep.FLAG_OWNERSHIP, b""])
    sweep.parse(ledger_db, tx, message)

    fee_debits = ledger_db.execute(
        "SELECT quantity FROM debits WHERE address = ? "
        "AND asset = (SELECT asset_index FROM assets WHERE asset_name = 'XCP') "
        "AND action = 'sweep fee' AND event = ?",
        (source, tx["tx_hash"]),
    ).fetchall()
    assert fee_debits == []
    assert ledger.balances.get_balance(ledger_db, source, "XCP") == xcp_before


def test_parse_empty_ownership_sweep_legacy_path_charges_fee(ledger_db, blockchain_mock, defaults):
    # With the gate disabled, the same sweep keeps charging the legacy fee.
    source = next(
        a
        for a in defaults["addresses"]
        if ledger.balances.get_balance(ledger_db, a, "XCP") > config.UNIT
        and ledger.issuances.get_issuances_count(ledger_db, a) == 0
    )
    destination = next(a for a in defaults["addresses"] if a != source)

    tx = blockchain_mock.dummy_tx(ledger_db, source)
    xcp_before = ledger.balances.get_balance(ledger_db, source, "XCP")

    message = cbor2.dumps([address_util.pack(destination), sweep.FLAG_OWNERSHIP, b""])
    with ProtocolChangesDisabled(["sweep_skip_zero_balances"]):
        sweep.parse(ledger_db, tx, message)

    fee_debits = ledger_db.execute(
        "SELECT quantity FROM debits WHERE address = ? "
        "AND asset = (SELECT asset_index FROM assets WHERE asset_name = 'XCP') "
        "AND action = 'sweep fee' AND event = ?",
        (source, tx["tx_hash"]),
    ).fetchall()
    assert len(fee_debits) == 1
    assert fee_debits[0]["quantity"] > 0
    assert ledger.balances.get_balance(ledger_db, source, "XCP") < xcp_before


def test_parse_flag_2(ledger_db, blockchain_mock, defaults, test_helpers):
    with ProtocolChangesDisabled("taproot_support"):
        tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][6])
        message = b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x02"
        sweep.parse(ledger_db, tx, message)

        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "sweeps",
                    "values": {
                        "block_index": tx["block_index"],
                        "destination": defaults["addresses"][5],
                        "source": defaults["addresses"][6],
                        "status": "valid",
                        "flags": 2,
                        "tx_hash": tx["tx_hash"],
                        "tx_index": tx["tx_index"],
                    },
                },
                {
                    "table": "issuances",
                    "values": {
                        "quantity": 0,
                        "asset_longname": None,
                        "issuer": defaults["addresses"][5],
                        "status": "valid",
                        "locked": 0,
                        "asset": "LOCKEDPREV",
                        "fee_paid": 0,
                        "callable": 0,
                        "call_date": 0,
                        "call_price": 0.0,
                        "tx_hash": tx["tx_hash"],
                        "description": "changed",
                        "divisible": 1,
                        "source": defaults["addresses"][6],
                        "block_index": tx["block_index"],
                        "tx_index": tx["tx_index"],
                        "transfer": True,
                    },
                },
                {
                    "table": "transactions_status",
                    "values": {
                        "tx_index": tx["tx_index"],
                        "valid": True,
                    },
                },
            ],
        )


def test_parse_cbor_invalid_doesnt_halt(ledger_db, blockchain_mock, defaults):
    """Regression: CBOR-encoded sweep with non-int flags must NOT raise
    ParseTransactionError -> halt; the post-unpack normalisation now
    coerces unexpected types to None and validate() then marks the tx
    invalid."""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    address_bytes = b"\x00" + bytes.fromhex("8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec")
    message = cbor2.dumps([address_bytes, "not-an-int-flags", b""])
    sweep.parse(ledger_db, tx, message)


def test_parse_cbor_huge_flags_clamped(ledger_db, blockchain_mock, defaults):
    """Regression: int flags > MAX_INT (CBOR can supply arbitrary ints)
    must be clamped to None before insert_record so the bindings dict
    doesn't trigger an OverflowError on the SQLite INTEGER column."""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    address_bytes = b"\x00" + bytes.fromhex("8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec")
    message = cbor2.dumps([address_bytes, 2**70, b""])
    sweep.parse(ledger_db, tx, message)


def test_parse_truncated_message_marked_invalid(ledger_db, blockchain_mock, defaults):
    """A truncated (1-byte) sweep message must be persisted as invalid,
    not propagate as ParseTransactionError."""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    sweep.parse(ledger_db, tx, b"\x00")


def test_unpack_with_block_index_taproot_off_uses_legacy(ledger_db, defaults):
    """When block_index is set before taproot_support activation, unpack
    falls back to the legacy fixed-size struct path."""
    legacy_message = b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01"
    result = sweep.unpack(legacy_message, block_index=1)
    assert result["destination"] == defaults["addresses"][5]
    assert result["flags"] == 1


def test_unpack_taproot_active_decodes_cbor(ledger_db):
    """When taproot_support is active (default high block_index), CBOR
    payloads decode through the new path."""
    address_bytes = b"\x00" + bytes.fromhex("8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec")
    message = cbor2.dumps([address_bytes, 1, b""])
    result = sweep.unpack(message, block_index=10**8)
    assert result["flags"] == 1
