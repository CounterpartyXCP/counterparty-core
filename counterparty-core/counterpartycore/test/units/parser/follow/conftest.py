from unittest.mock import MagicMock, patch

import pytest


@pytest.fixture
def mock_db():
    """Mock de la base de données."""
    db = MagicMock()
    cursor = MagicMock()
    cursor.execute.return_value.fetchone.side_effect = [
        {"tx_index": 10},  # last_mempool_tx
        {"tx_index": 20},  # last_tx
    ]
    db.cursor.return_value = cursor
    return db


@pytest.fixture
def mock_rpc_call():
    """Mock de la fonction rpc_call de bitcoind."""
    with patch("counterpartycore.lib.backend.bitcoind.rpc_call") as mock:
        yield mock


@pytest.fixture
def mock_bitcoind():
    """Mock du module bitcoind."""
    with patch("counterpartycore.lib.backend.bitcoind") as mock:
        yield mock


@pytest.fixture
def mock_current_state():
    """Mock de la classe CurrentState."""
    with patch("counterpartycore.lib.ledger.currentstate.CurrentState") as mock:
        instance = MagicMock()
        instance.current_block_index.return_value = 123
        mock.return_value = instance
        yield instance


@pytest.fixture
def mock_blocks():
    """Mock du module blocks."""
    with patch("counterpartycore.lib.parser.blocks") as mock:
        yield mock


@pytest.fixture
def mock_mempool():
    """Mock du module mempool."""
    with patch("counterpartycore.lib.parser.mempool") as mock:
        yield mock


@pytest.fixture
def mock_deserialize():
    """Mock du module deserialize."""
    with patch("counterpartycore.lib.parser.deserialize") as mock:
        yield mock


@pytest.fixture
def mock_time():
    """Mock de la fonction time."""
    with patch("time.time") as mock:
        mock.return_value = 1000.0
        yield mock


@pytest.fixture
def mock_ledger():
    """Mock du module ledger."""
    with patch("counterpartycore.lib.ledger") as mock:
        yield mock


@pytest.fixture
def mock_loop():
    """Mock de asyncio loop."""
    loop = MagicMock()
    with patch("asyncio.new_event_loop", return_value=loop), patch("asyncio.set_event_loop"):
        yield loop


@pytest.fixture
def mock_zmq_socket():
    """Mock du socket ZMQ."""
    socket = MagicMock()
    zmq_context = MagicMock()
    zmq_context.socket.return_value = socket
    with patch("zmq.asyncio.Context", return_value=zmq_context):
        yield socket, zmq_context
