"""Tests for counterpartycore.lib.api.apiwatcher.

Focuses on the PR-touched code paths:
- DETACH_FROM_UTXO source_address typo fix
- update_xcp_supply status='valid' guard
- update_assets_info description_locked propagation
- update_address_events removed `no_cache` parameter
"""

import inspect
import json
import re

import pytest
from counterpartycore.lib.api import apiwatcher


def test_detach_from_utxo_field_name_correct():
    """DETACH_FROM_UTXO must reference `source_address` (not the legacy typo
    `sourc_address`); the streamed handler keys off this dict and silently
    dropped the source row for every detach until the typo was fixed."""
    fields = apiwatcher.EVENTS_ADDRESS_FIELDS["DETACH_FROM_UTXO"]
    assert "source_address" in fields
    assert "sourc_address" not in fields
    assert "destination" in fields


def test_update_address_events_signature():
    """update_address_events no longer accepts a `no_cache` kwarg; this is
    a regression guard against an accidental re-introduction that would
    silently make callers' kwargs go nowhere."""
    sig = inspect.signature(apiwatcher.update_address_events)
    assert list(sig.parameters.keys()) == ["state_db", "event"]


def test_update_xcp_supply_skips_invalid_status(state_db):
    """When the streaming handler sees an invalid issuance/sweep with a
    non-zero fee_paid, it must NOT debit XCP supply -- migration 0004
    derives supply via valid-only ledger queries, so a divergence here
    causes snapshot vs streamed nodes to diverge."""

    # Snapshot supply before
    cursor = state_db.cursor()
    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    supply_before = row["supply"] if row else 0

    invalid_event = {
        "event": "ASSET_ISSUANCE",
        "bindings": json.dumps(
            {
                "status": "invalid: insufficient funds",
                "fee_paid": 50000000,
                "asset": "BOGUS",
            }
        ),
    }
    apiwatcher.update_xcp_supply(state_db, invalid_event)

    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    supply_after = row["supply"] if row else 0
    assert supply_after == supply_before


def test_update_xcp_supply_applies_for_valid(state_db):
    """A valid issuance with non-zero fee_paid must reduce XCP supply
    on the streamed handler side."""

    cursor = state_db.cursor()
    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    if row is None:
        pytest.skip("No XCP row in assets_info to mutate")
    supply_before = row["supply"]

    valid_event = {
        "event": "ASSET_ISSUANCE",
        "bindings": json.dumps(
            {
                "status": "valid",
                "fee_paid": 12345,
                "asset": "WHATEVER",
            }
        ),
    }
    apiwatcher.update_xcp_supply(state_db, valid_event)

    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    assert row["supply"] == supply_before - 12345


def test_update_xcp_supply_skips_zero_fee(state_db):
    """fee_paid == 0 is a no-op even on a valid event."""
    cursor = state_db.cursor()
    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    if row is None:
        pytest.skip("No XCP row in assets_info to mutate")
    supply_before = row["supply"]

    event = {
        "event": "ASSET_ISSUANCE",
        "bindings": json.dumps({"status": "valid", "fee_paid": 0}),
    }
    apiwatcher.update_xcp_supply(state_db, event)

    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    assert row["supply"] == supply_before


def test_update_xcp_supply_ignores_non_destroy_events(state_db):
    """Events outside XCP_DESTROY_EVENTS must not touch supply at all."""
    cursor = state_db.cursor()
    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    if row is None:
        pytest.skip("No XCP row in assets_info to mutate")
    supply_before = row["supply"]

    event = {
        "event": "DEBIT",
        "bindings": json.dumps({"status": "valid", "fee_paid": 9999}),
    }
    apiwatcher.update_xcp_supply(state_db, event)

    row = cursor.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()
    assert row["supply"] == supply_before


def test_update_assets_info_propagates_description_locked(state_db):
    """An ASSET_ISSUANCE event with description_locked=True must update
    the column; the streamed handler used to ignore this flag and that
    drift broke snapshot vs streamed parity."""
    cursor = state_db.cursor()
    asset_row = cursor.execute(
        "SELECT asset FROM assets_info WHERE asset NOT IN ('XCP', 'BTC') LIMIT 1"
    ).fetchone()
    if asset_row is None:
        pytest.skip("No mutable asset to test description_locked")
    asset = asset_row["asset"]

    cursor.execute("UPDATE assets_info SET description_locked = 0 WHERE asset = ?", (asset,))

    event = {
        "event": "ASSET_ISSUANCE",
        "bindings": json.dumps(
            {
                "status": "valid",
                "asset": asset,
                "asset_longname": None,
                "asset_id": "1",
                "issuer": "addr",
                "divisible": True,
                "description": "x",
                "mime_type": "text/plain",
                "quantity": 0,
                "block_index": 200,
                "locked": False,
                "description_locked": True,
                "fee_paid": 0,
            }
        ),
    }
    apiwatcher.update_assets_info(state_db, event)

    row = cursor.execute(
        "SELECT description_locked FROM assets_info WHERE asset = ?", (asset,)
    ).fetchone()
    assert bool(row["description_locked"]) is True


def test_update_assets_info_skips_invalid_status(state_db):
    """Only valid issuance events update assets_info."""
    cursor = state_db.cursor()
    asset_row = cursor.execute(
        "SELECT asset, description FROM assets_info WHERE asset NOT IN ('XCP', 'BTC') LIMIT 1"
    ).fetchone()
    if asset_row is None:
        pytest.skip("No mutable asset to test")
    asset, original_desc = asset_row["asset"], asset_row["description"]

    event = {
        "event": "ASSET_ISSUANCE",
        "bindings": json.dumps(
            {
                "status": "invalid",
                "asset": asset,
                "asset_longname": None,
                "asset_id": "1",
                "issuer": "addr",
                "divisible": True,
                "description": "SHOULD NOT WIN",
                "mime_type": "text/plain",
                "quantity": 0,
                "block_index": 200,
                "locked": False,
            }
        ),
    }
    apiwatcher.update_assets_info(state_db, event)

    row = cursor.execute("SELECT description FROM assets_info WHERE asset = ?", (asset,)).fetchone()
    assert row["description"] == original_desc


def test_events_address_fields_keys_are_lowercase_underscore():
    """Defensive: every field name listed in EVENTS_ADDRESS_FIELDS must
    look like a real binding key (lowercase + underscores). This would
    have caught the original `sourc_address` typo."""
    pattern = re.compile(r"^[a-z][a-z0-9_]*$")
    for event_name, fields in apiwatcher.EVENTS_ADDRESS_FIELDS.items():
        for field in fields:
            assert pattern.match(field), f"{event_name} declares a malformed field name {field!r}"
