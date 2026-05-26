import json
import threading
from unittest.mock import MagicMock

import pytest
import requests
from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages.data import checkpoints
from counterpartycore.lib.parser import check


def test_check_change_version_ok():
    """Test check_change when version is acceptable."""
    protocol_change = {
        "block_index": 100,
        "minimum_version_major": config.VERSION_MAJOR,
        "minimum_version_minor": config.VERSION_MINOR,
        "minimum_version_revision": config.VERSION_REVISION,
    }

    # Should not raise any exception
    check.check_change(protocol_change, "test_change")


def test_check_change_version_major_too_low(ledger_db, current_block_index):
    """Test check_change when major version is too low."""
    protocol_change = {
        "block_index": 1,  # In the past
        "minimum_version_major": config.VERSION_MAJOR + 1,
        "minimum_version_minor": 0,
        "minimum_version_revision": 0,
    }

    with pytest.raises(exceptions.VersionUpdateRequiredError):
        check.check_change(protocol_change, "test_change")


def test_check_change_version_minor_too_low(ledger_db, current_block_index):
    """Test check_change when minor version is too low."""
    protocol_change = {
        "block_index": 1,  # In the past
        "minimum_version_major": config.VERSION_MAJOR,
        "minimum_version_minor": config.VERSION_MINOR + 1,
        "minimum_version_revision": 0,
    }

    with pytest.raises(exceptions.VersionUpdateRequiredError):
        check.check_change(protocol_change, "test_change")


def test_check_change_version_revision_too_low(ledger_db, current_block_index):
    """Test check_change when revision version is too low."""
    protocol_change = {
        "block_index": 1,  # In the past
        "minimum_version_major": config.VERSION_MAJOR,
        "minimum_version_minor": config.VERSION_MINOR,
        "minimum_version_revision": config.VERSION_REVISION + 1,
    }

    with pytest.raises(exceptions.VersionUpdateRequiredError):
        check.check_change(protocol_change, "test_change")


def test_check_change_version_warning_future_block(ledger_db, current_block_index, caplog):
    """Test check_change logs warning when block is in the future."""
    protocol_change = {
        "block_index": 999999999,  # Far in the future
        "minimum_version_major": config.VERSION_MAJOR + 1,
        "minimum_version_minor": 0,
        "minimum_version_revision": 0,
    }

    # Should not raise, just log a warning (block is in the future)
    check.check_change(protocol_change, "test_change")


def test_software_version_force_mode():
    """Test software_version with FORCE mode enabled."""
    original_force = config.FORCE
    config.FORCE = True

    try:
        result = check.software_version()
        assert result is True
    finally:
        config.FORCE = original_force


def test_software_version_connection_error(monkeypatch):
    """Test software_version with connection error."""
    original_force = config.FORCE
    config.FORCE = False

    def mock_get(*args, **kwargs):
        raise ConnectionRefusedError("Connection refused")

    monkeypatch.setattr("requests.get", mock_get)

    try:
        with pytest.raises(exceptions.VersionCheckError) as exc_info:
            check.software_version()
        message = str(exc_info.value)
        assert "Unable to check Counterparty version from" in message
        assert config.PROTOCOL_CHANGES_URL in message
        assert "Connection refused" in message
        assert "Use --force to ignore verification." in message
        assert "verfication" not in message
    finally:
        config.FORCE = original_force


def test_software_version_timeout_error(monkeypatch):
    """Test software_version with timeout error."""
    original_force = config.FORCE
    config.FORCE = False

    def mock_get(*args, **kwargs):
        raise requests.exceptions.ReadTimeout("Read timed out")

    monkeypatch.setattr("requests.get", mock_get)

    try:
        with pytest.raises(exceptions.VersionCheckError) as exc_info:
            check.software_version()
        message = str(exc_info.value)
        assert "Unable to check Counterparty version from" in message
        assert "Read timed out" in message
        assert "Use --force to ignore verification." in message
    finally:
        config.FORCE = original_force


def test_software_version_json_decode_error(monkeypatch):
    """Test software_version with invalid JSON response."""

    original_force = config.FORCE
    config.FORCE = False

    class MockResponse:
        status_code = 200
        text = "not valid json"

    def mock_get(*args, **kwargs):
        return MockResponse()

    monkeypatch.setattr("requests.get", mock_get)

    try:
        with pytest.raises(exceptions.VersionCheckError) as exc_info:
            check.software_version()
        message = str(exc_info.value)
        assert "Unable to check Counterparty version from" in message
        assert "Expecting value" in message
        assert "Use --force to ignore verification." in message
    finally:
        config.FORCE = original_force


def test_software_version_success(monkeypatch):
    """Test software_version with valid response."""
    original_force = config.FORCE
    config.FORCE = False

    class MockResponse:
        status_code = 200
        text = json.dumps(
            {
                "test_change": {
                    "block_index": 999999999,
                    "minimum_version_major": 0,
                    "minimum_version_minor": 0,
                    "minimum_version_revision": 0,
                }
            }
        )

    def mock_get(*args, **kwargs):
        return MockResponse()

    monkeypatch.setattr("requests.get", mock_get)

    try:
        result = check.software_version()
        assert result is True
    finally:
        config.FORCE = original_force


def test_consensus_hash_invalid_field(ledger_db):
    """Test consensus_hash with invalid field."""
    with pytest.raises(AssertionError):
        check.consensus_hash(ledger_db, "invalid_field", None, [])


# Tests for lines 28-35: Get previous hash from database
def test_consensus_hash_get_previous_from_db():
    """Test consensus_hash getting previous hash from database when not provided (lines 28-33)."""
    # Create a mock database
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor

    # Set up current block index (skip_lock_time=True to avoid DB connection)
    CurrentState().set_current_block_index(config.BLOCK_FIRST + 2, skip_lock_time=True)

    # Mock cursor.execute to return a block with ledger_hash for previous block query
    # and then return the current block
    def execute_side_effect(sql, params=()):
        if "block_index = ?" in sql:
            block_index = params[0]
            if block_index == config.BLOCK_FIRST + 1:  # Previous block
                return iter(
                    [{"ledger_hash": "abc123", "txlist_hash": "def456", "messages_hash": "ghi789"}]
                )
            else:  # Current block
                return iter([{"ledger_hash": None, "txlist_hash": None, "messages_hash": None}])
        return iter([])

    mock_cursor.execute.side_effect = execute_side_effect

    # Call consensus_hash with previous_consensus_hash=None to trigger lines 28-33
    result, found_hash = check.consensus_hash(mock_db, "ledger_hash", None, ["test_content"])

    # Should return a valid hash
    assert result is not None
    assert len(result) == 64  # SHA256 hash length in hex
    assert found_hash is None  # Current block has no hash


def test_consensus_hash_empty_previous_hash_error():
    """Test consensus_hash raises ConsensusError when previous hash is empty (lines 34-35)."""
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor

    # Set current block beyond BLOCK_FIRST (skip_lock_time=True to avoid DB connection)
    CurrentState().set_current_block_index(config.BLOCK_FIRST + 2, skip_lock_time=True)

    # Mock cursor.execute to return a block with None ledger_hash
    def execute_side_effect(sql, params=()):
        if "block_index = ?" in sql:
            # Return block with None hash for previous block
            return iter([{"ledger_hash": None, "txlist_hash": None, "messages_hash": None}])
        return iter([])

    mock_cursor.execute.side_effect = execute_side_effect

    with pytest.raises(exceptions.ConsensusError, match="Empty previous ledger_hash"):
        check.consensus_hash(mock_db, "ledger_hash", None, ["test"])


def test_consensus_hash_index_error_previous_block():
    """Test consensus_hash handles IndexError when previous block doesn't exist (line 32-33)."""
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor

    # Set current block to a value where previous block doesn't exist (skip_lock_time=True)
    CurrentState().set_current_block_index(config.BLOCK_FIRST + 1, skip_lock_time=True)

    # Mock cursor.execute to return empty list for previous block query
    def execute_side_effect(sql, params=()):
        if "block_index = ?" in sql:
            # Return empty iterator to trigger IndexError
            return iter([])
        return iter([])

    mock_cursor.execute.side_effect = execute_side_effect

    with pytest.raises(exceptions.ConsensusError, match="Empty previous ledger_hash"):
        check.consensus_hash(mock_db, "ledger_hash", None, ["test"])


# Tests for lines 41, 43, 46-49: Network-specific consensus hash versions
def test_consensus_hash_testnet3_version():
    """Test consensus_hash uses TESTNET3 version (line 41)."""
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor

    # Mock to return current block with no found_hash
    mock_cursor.execute.return_value = iter([{"ledger_hash": None}])

    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_regtest = config.REGTEST
    original_signet = config.SIGNET

    try:
        config.TESTNET3 = True
        config.TESTNET4 = False
        config.REGTEST = False
        config.SIGNET = False

        # Use a block index not in checkpoints to avoid checkpoint validation
        CurrentState().set_current_block_index(999999, skip_lock_time=True)

        result, found_hash = check.consensus_hash(
            mock_db, "ledger_hash", "previous_hash", ["test_content"]
        )
        assert result is not None
    finally:
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.REGTEST = original_regtest
        config.SIGNET = original_signet


def test_consensus_hash_testnet4_version():
    """Test consensus_hash uses TESTNET4 version (line 43)."""
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor

    mock_cursor.execute.return_value = iter([{"ledger_hash": None}])

    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_regtest = config.REGTEST
    original_signet = config.SIGNET

    try:
        config.TESTNET3 = False
        config.TESTNET4 = True
        config.REGTEST = False
        config.SIGNET = False

        CurrentState().set_current_block_index(999999, skip_lock_time=True)

        result, found_hash = check.consensus_hash(
            mock_db, "ledger_hash", "previous_hash", ["test_content"]
        )
        assert result is not None
    finally:
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.REGTEST = original_regtest
        config.SIGNET = original_signet


def test_consensus_hash_signet_version():
    """Test consensus_hash uses SIGNET version (lines 46-47)."""
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor

    mock_cursor.execute.return_value = iter([{"ledger_hash": None}])

    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_regtest = config.REGTEST
    original_signet = config.SIGNET

    try:
        config.TESTNET3 = False
        config.TESTNET4 = False
        config.REGTEST = False
        config.SIGNET = True

        CurrentState().set_current_block_index(999999, skip_lock_time=True)

        result, found_hash = check.consensus_hash(
            mock_db, "ledger_hash", "previous_hash", ["test_content"]
        )
        assert result is not None
    finally:
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.REGTEST = original_regtest
        config.SIGNET = original_signet


def test_consensus_hash_mainnet_version():
    """Test consensus_hash uses MAINNET version (lines 48-49)."""
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor

    mock_cursor.execute.return_value = iter([{"ledger_hash": None}])

    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_regtest = config.REGTEST
    original_signet = config.SIGNET

    try:
        config.TESTNET3 = False
        config.TESTNET4 = False
        config.REGTEST = False
        config.SIGNET = False

        CurrentState().set_current_block_index(999999, skip_lock_time=True)

        result, found_hash = check.consensus_hash(
            mock_db, "ledger_hash", "previous_hash", ["test_content"]
        )
        assert result is not None
    finally:
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.REGTEST = original_regtest
        config.SIGNET = original_signet


# Tests for lines 65-66: ConsensusError when calculated hash doesn't match found hash
def test_consensus_hash_mismatch_error(ledger_db, current_block_index):
    """Test consensus_hash raises ConsensusError when hash doesn't match database (lines 65-66)."""
    # Get a block with a ledger_hash
    block = ledger_db.execute(
        "SELECT block_index, ledger_hash FROM blocks WHERE ledger_hash IS NOT NULL ORDER BY block_index DESC LIMIT 1"
    ).fetchone()

    if block and block["ledger_hash"]:
        CurrentState().set_current_block_index(block["block_index"])

        # Get the previous block's hash
        prev_block = ledger_db.execute(
            "SELECT ledger_hash FROM blocks WHERE block_index = ?",
            (block["block_index"] - 1,),
        ).fetchone()

        if prev_block and prev_block["ledger_hash"]:
            # Call with the correct previous hash but different content to generate different hash
            # This should trigger the mismatch since we're using different content
            with pytest.raises(exceptions.ConsensusError, match="Inconsistent ledger_hash"):
                check.consensus_hash(
                    ledger_db,
                    "ledger_hash",
                    prev_block["ledger_hash"],
                    ["different_content_that_will_produce_different_hash"],
                )


# Tests for lines 72, 74, 77-80: Network-specific checkpoints
def test_consensus_hash_testnet3_checkpoints():
    """Test consensus_hash uses TESTNET3 checkpoints (line 72)."""
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor
    mock_cursor.execute.return_value = iter([{"ledger_hash": None}])

    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_regtest = config.REGTEST
    original_signet = config.SIGNET

    try:
        config.TESTNET3 = True
        config.TESTNET4 = False
        config.REGTEST = False
        config.SIGNET = False

        # Use a block index not in checkpoints
        CurrentState().set_current_block_index(999999, skip_lock_time=True)

        result, found_hash = check.consensus_hash(mock_db, "ledger_hash", "previous_hash", ["test"])
        assert result is not None
    finally:
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.REGTEST = original_regtest
        config.SIGNET = original_signet


def test_consensus_hash_testnet4_checkpoints():
    """Test consensus_hash uses TESTNET4 checkpoints (line 74)."""
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor
    mock_cursor.execute.return_value = iter([{"ledger_hash": None}])

    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_regtest = config.REGTEST
    original_signet = config.SIGNET

    try:
        config.TESTNET3 = False
        config.TESTNET4 = True
        config.REGTEST = False
        config.SIGNET = False

        CurrentState().set_current_block_index(999999, skip_lock_time=True)

        result, found_hash = check.consensus_hash(mock_db, "ledger_hash", "previous_hash", ["test"])
        assert result is not None
    finally:
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.REGTEST = original_regtest
        config.SIGNET = original_signet


def test_consensus_hash_signet_checkpoints():
    """Test consensus_hash uses SIGNET checkpoints (lines 77-78)."""
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor
    mock_cursor.execute.return_value = iter([{"ledger_hash": None}])

    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_regtest = config.REGTEST
    original_signet = config.SIGNET

    try:
        config.TESTNET3 = False
        config.TESTNET4 = False
        config.REGTEST = False
        config.SIGNET = True

        CurrentState().set_current_block_index(999999, skip_lock_time=True)

        result, found_hash = check.consensus_hash(mock_db, "ledger_hash", "previous_hash", ["test"])
        assert result is not None
    finally:
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.REGTEST = original_regtest
        config.SIGNET = original_signet


def test_consensus_hash_mainnet_checkpoints():
    """Test consensus_hash uses MAINNET checkpoints (lines 79-80)."""
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor
    mock_cursor.execute.return_value = iter([{"ledger_hash": None}])

    original_testnet3 = config.TESTNET3
    original_testnet4 = config.TESTNET4
    original_regtest = config.REGTEST
    original_signet = config.SIGNET

    try:
        config.TESTNET3 = False
        config.TESTNET4 = False
        config.REGTEST = False
        config.SIGNET = False

        CurrentState().set_current_block_index(999999, skip_lock_time=True)

        result, found_hash = check.consensus_hash(mock_db, "ledger_hash", "previous_hash", ["test"])
        assert result is not None
    finally:
        config.TESTNET3 = original_testnet3
        config.TESTNET4 = original_testnet4
        config.REGTEST = original_regtest
        config.SIGNET = original_signet


# Tests for lines 87-88: ConsensusError when hash doesn't match checkpoint
def test_consensus_hash_checkpoint_mismatch():
    """Test consensus_hash raises ConsensusError when hash doesn't match checkpoint (lines 87-88)."""
    mock_db = MagicMock()
    mock_cursor = MagicMock()
    mock_db.cursor.return_value = mock_cursor
    mock_cursor.execute.return_value = iter([{"ledger_hash": None}])

    # Use a specific block index for the test
    test_block_index = 999888

    # Set current block to test block (skip_lock_time=True)
    CurrentState().set_current_block_index(test_block_index, skip_lock_time=True)

    # Temporarily add a fake checkpoint with a different hash
    original_checkpoints = checkpoints.CHECKPOINTS_REGTEST.copy()

    try:
        checkpoints.CHECKPOINTS_REGTEST[test_block_index] = {
            "ledger_hash": "wrong_hash_that_wont_match_anything",
            "txlist_hash": "wrong_hash_that_wont_match_anything",
        }

        with pytest.raises(exceptions.ConsensusError, match="Incorrect ledger_hash hash"):
            check.consensus_hash(mock_db, "ledger_hash", "previous_hash", ["test"])
    finally:
        checkpoints.CHECKPOINTS_REGTEST.clear()
        checkpoints.CHECKPOINTS_REGTEST.update(original_checkpoints)


# Tests for lines 94-115: asset_conservation function
def test_asset_conservation_success(ledger_db, monkeypatch, caplog, test_helpers):
    """Test asset_conservation completes successfully (lines 94-115)."""

    # Mock supplies and held to return matching values
    def mock_supplies(db):
        return {"XCP": 1000, "ASSET1": 500}

    def mock_held(db):
        return {"XCP": 1000, "ASSET1": 500}

    def mock_value_out(db, value, asset):
        return str(value)

    monkeypatch.setattr(ledger.supplies, "supplies", mock_supplies)
    monkeypatch.setattr(ledger.supplies, "held", mock_held)
    monkeypatch.setattr(ledger.issuances, "value_out", mock_value_out)

    with test_helpers.capture_log(caplog, "Checking for conservation of assets."):
        check.asset_conservation(ledger_db)


def test_asset_conservation_with_stop_event(ledger_db, monkeypatch, caplog, test_helpers):
    """Test asset_conservation exits early when stop_event is set (lines 99-101)."""
    stop_event = threading.Event()

    # Mock supplies to return at least one asset so we enter the loop
    def mock_supplies(db):
        return {"XCP": 1000, "ASSET1": 500}

    def mock_held(db):
        return {"XCP": 1000, "ASSET1": 500}

    monkeypatch.setattr(ledger.supplies, "supplies", mock_supplies)
    monkeypatch.setattr(ledger.supplies, "held", mock_held)

    # Set the stop event after start
    stop_event.set()

    with test_helpers.capture_log(
        caplog, "Stop event received. Exiting asset conservation check..."
    ):
        check.asset_conservation(ledger_db, stop_event=stop_event)


def test_asset_conservation_mismatch_error(ledger_db, monkeypatch):
    """Test asset_conservation raises SanityError when issued != held (lines 104-108)."""

    # Mock supplies to return mismatched values
    def mock_supplies(db):
        return {"XCP": 1000}

    def mock_held(db):
        return {"XCP": 500}  # Different from supplies

    monkeypatch.setattr(ledger.supplies, "supplies", mock_supplies)
    monkeypatch.setattr(ledger.supplies, "held", mock_held)

    with pytest.raises(exceptions.SanityError, match="issued ≠"):
        check.asset_conservation(ledger_db)


def test_asset_conservation_asset_not_in_held(ledger_db, monkeypatch, caplog, test_helpers):
    """Test asset_conservation handles asset not in held dict (line 103)."""

    # Mock supplies to return an asset
    def mock_supplies(db):
        return {"TEST_ASSET": 0}  # Zero supply should equal zero held

    def mock_held(db):
        return {}  # Asset not in held dict - should default to 0

    def mock_value_out(db, value, asset):
        return str(value)

    monkeypatch.setattr(ledger.supplies, "supplies", mock_supplies)
    monkeypatch.setattr(ledger.supplies, "held", mock_held)
    monkeypatch.setattr(ledger.issuances, "value_out", mock_value_out)

    # Should not raise since 0 == 0
    with test_helpers.capture_log(caplog, "All assets have been conserved."):
        check.asset_conservation(ledger_db)


def test_asset_conservation_held_is_none(ledger_db, monkeypatch, caplog, test_helpers):
    """Test asset_conservation handles None value in held dict (line 103)."""

    # Mock supplies to return an asset
    def mock_supplies(db):
        return {"TEST_ASSET": 0}

    def mock_held(db):
        return {"TEST_ASSET": None}  # None should be treated as 0

    def mock_value_out(db, value, asset):
        return str(value)

    monkeypatch.setattr(ledger.supplies, "supplies", mock_supplies)
    monkeypatch.setattr(ledger.supplies, "held", mock_held)
    monkeypatch.setattr(ledger.issuances, "value_out", mock_value_out)

    # Should not raise since 0 == 0 (None treated as 0)
    with test_helpers.capture_log(caplog, "All assets have been conserved."):
        check.asset_conservation(ledger_db)
