from unittest import mock

import pytest

# Import les modules nécessaires
from counterpartycore.lib.ledger.currentstate import CurrentState


@pytest.fixture
def mock_db():
    """Fixture pour créer un mock de la base de données"""
    db = mock.MagicMock()
    cursor = mock.MagicMock()
    db.cursor.return_value = cursor
    return db, cursor


@pytest.fixture
def mock_current_state():
    """Fixture pour mocker CurrentState"""
    with mock.patch.object(CurrentState, "set_parsing_mempool") as mock_set:
        yield mock_set


@pytest.fixture
def mock_deserialize():
    """Fixture pour mocker deserialize.deserialize_tx"""
    with mock.patch(
        "counterpartycore.lib.parser.deserialize.deserialize_tx"
    ) as mock_deserialize_tx:
        yield mock_deserialize_tx


@pytest.fixture
def mock_blocks():
    """Fixture pour mocker blocks.list_tx et blocks.parse_block"""
    with mock.patch("counterpartycore.lib.parser.blocks.list_tx") as mock_list_tx, mock.patch(
        "counterpartycore.lib.parser.blocks.parse_block"
    ) as mock_parse_block:
        yield mock_list_tx, mock_parse_block


@pytest.fixture
def mock_ledger_blocks():
    """Fixture pour mocker ledger.blocks.get_transaction"""
    with mock.patch("counterpartycore.lib.ledger.blocks.get_transaction") as mock_get_tx:
        yield mock_get_tx


@pytest.fixture
def mock_backend_bitcoind():
    """Fixture pour mocker backend.bitcoind.getrawmempool"""
    with mock.patch("counterpartycore.lib.backend.bitcoind.getrawmempool") as mock_getrawmempool:
        yield mock_getrawmempool
