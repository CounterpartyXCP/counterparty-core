from unittest import mock

# Import du module à tester - supposons qu'il est dans counterpartycore.lib.mempool
import counterpartycore.lib.parser.mempool as mempool_module
import pytest
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


def test_parse_mempool_transactions_empty_list(mock_db, mock_current_state, mock_blocks):
    """Test parse_mempool_transactions avec une liste vide"""
    db, cursor = mock_db

    # Configurer les retours des appels à la BD
    cursor.fetchone.side_effect = [None, None, {"message_index": 5}]
    cursor.fetchall.side_effect = [[], []]

    # Appeler la fonction avec une liste vide
    result = mempool_module.parse_mempool_transactions(db, [])

    # Vérifier que les fonctions attendues ont été appelées
    mock_current_state.assert_has_calls([mock.call(True), mock.call(False)])
    assert result == []

    # Vérifier que les opérations de BD ont été effectuées
    assert db.__enter__.called
    assert cursor.execute.called


def test_parse_mempool_transactions_with_transactions(
    mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks
):
    """Test parse_mempool_transactions avec des transactions"""
    db, cursor = mock_db
    mock_list_tx, mock_parse_block = mock_blocks

    # Configuration du curseur
    cursor.fetchone.side_effect = [
        {"tx_index": 10},  # Last mempool tx
        {"tx_index": 5},  # Last tx
        {"message_index": 100},  # Last message
    ]

    # Configuration des transactions et événements
    transaction_events = [
        {
            "tx_hash": "tx1",
            "event": "event1",
            "bindings": "{}",
            "command": "cmd1",
            "category": "cat1",
        }
    ]
    mempool_transactions = [
        {
            "tx_hash": "tx1",
            "tx_index": 11,
            "block_index": 0,
            "block_hash": "mempool",
            "block_time": 123,
        }
    ]

    cursor.fetchall.side_effect = [transaction_events, mempool_transactions]

    # Configuration de deserialize
    mock_deserialize.return_value = {"tx_hash": "tx1", "source": "addr1", "destination": "addr2"}

    # Configuration de get_transaction pour retourner None (tx n'existe pas)
    mock_ledger_blocks.return_value = None

    # Exécution de la fonction avec une transaction
    raw_tx_list = ["raw_tx_data"]
    result = mempool_module.parse_mempool_transactions(db, raw_tx_list)

    # Vérifications
    assert mock_deserialize.called
    assert mock_parse_block.called

    # Vérifier que l'exception MempoolError a été générée
    assert db.__enter__.called

    # Vérifier que les transactions sont insérées dans la mempool
    assert cursor.execute.called

    # Vérifier le résultat - si tout se passe bien, la transaction est supportée
    # et n'apparaît pas dans la liste des transactions non supportées
    assert result == []


def test_parse_mempool_transactions_existing_tx(
    mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks
):
    """Test parse_mempool_transactions avec une transaction déjà existante"""
    db, cursor = mock_db

    # Configuration du curseur
    cursor.fetchone.side_effect = [
        {"tx_index": 10},  # Last mempool tx
        {"tx_index": 5},  # Last tx
        {"message_index": 100},  # Last message
    ]

    # Configuration de deserialize
    mock_deserialize.return_value = {"tx_hash": "tx1", "source": "addr1", "destination": "addr2"}

    # Configuration de get_transaction pour retourner une transaction existante
    mock_ledger_blocks.return_value = {"tx_hash": "tx1"}

    # Exécution de la fonction avec une transaction
    raw_tx_list = ["raw_tx_data"]
    result = mempool_module.parse_mempool_transactions(db, raw_tx_list)

    # Vérifications
    assert mock_deserialize.called
    assert mock_ledger_blocks.called

    # Vérifier le résultat - si la transaction existe déjà, elle est considérée comme non supportée
    assert result == ["tx1"]


def test_parse_mempool_transactions_with_timestamps(
    mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks
):
    """Test parse_mempool_transactions avec des timestamps fournis"""
    db, cursor = mock_db
    mock_list_tx, mock_parse_block = mock_blocks

    # Configuration du curseur
    cursor.fetchone.side_effect = [
        {"tx_index": 10},  # Last mempool tx
        {"tx_index": 5},  # Last tx
        {"message_index": 100},  # Last message
    ]

    # Configuration des transactions et événements
    transaction_events = [
        {
            "tx_hash": "tx1",
            "event": "event1",
            "bindings": "{}",
            "command": "cmd1",
            "category": "cat1",
        }
    ]
    mempool_transactions = [
        {
            "tx_hash": "tx1",
            "tx_index": 11,
            "block_index": 0,
            "block_hash": "mempool",
            "block_time": 123,
        }
    ]

    cursor.fetchall.side_effect = [transaction_events, mempool_transactions]

    # Configuration de deserialize
    mock_deserialize.return_value = {"tx_hash": "tx1", "source": "addr1", "destination": "addr2"}

    # Configuration de get_transaction pour retourner None (tx n'existe pas)
    mock_ledger_blocks.return_value = None

    # Exécution de la fonction avec une transaction et timestamps
    raw_tx_list = ["raw_tx_data"]
    timestamps = {"tx1": 12345}
    result = mempool_module.parse_mempool_transactions(db, raw_tx_list, timestamps)

    # Vérifications
    assert mock_deserialize.called
    assert mock_parse_block.called

    # Vérifier que les données timestamp sont correctement utilisées
    timestamp_found = False
    for call in cursor.execute.call_args_list:
        if "INSERT INTO mempool VALUES" in str(call) and "'timestamp': 12345" in str(call):
            timestamp_found = True
            break
    assert timestamp_found, "Le timestamp spécifié n'a pas été utilisé"

    # Vérifier le résultat
    assert result == []


def test_clean_transaction_from_mempool(mock_db):
    """Test clean_transaction_from_mempool"""
    db, cursor = mock_db

    # Appel de la fonction
    mempool_module.clean_transaction_from_mempool(db, "tx1")

    # Vérifications
    cursor.execute.assert_has_calls(
        [
            mock.call("DELETE FROM mempool WHERE tx_hash = ?", ("tx1",)),
            mock.call("DELETE FROM mempool_transactions WHERE tx_hash = ?", ("tx1",)),
        ]
    )


def test_clean_mempool_with_validated_transactions(
    mock_db, mock_ledger_blocks, mock_backend_bitcoind
):
    """Test clean_mempool avec des transactions validées"""
    db, cursor = mock_db

    # Configuration des événements de mempool
    cursor.fetchall.return_value = [{"tx_hash": "tx1"}, {"tx_hash": "tx2"}]

    # Configuration de get_transaction pour retourner une transaction pour tx1 (validée)
    # et None pour tx2 (non validée)
    mock_ledger_blocks.side_effect = [{"tx_hash": "tx1"}, None]

    # Configuration pour getrawmempool
    mock_backend_bitcoind.return_value = ["tx2"]

    # Appel de la fonction
    mempool_module.clean_mempool(db)

    # Vérifications
    assert cursor.execute.called
    assert mock_ledger_blocks.call_count == 2

    # Vérifier que clean_transaction_from_mempool a été appelé pour tx1
    cursor.execute.assert_any_call("DELETE FROM mempool WHERE tx_hash = ?", ("tx1",))
    cursor.execute.assert_any_call("DELETE FROM mempool_transactions WHERE tx_hash = ?", ("tx1",))
