import sqlite3
from unittest import mock

# Import le module à tester
import counterpartycore.lib.parser.mempool as mempool_module
import pytest
from counterpartycore.lib import exceptions


def test_parse_mempool_transactions_sql_error(
    mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks
):
    """Test parse_mempool_transactions avec une erreur SQL"""
    db, cursor = mock_db

    # Simuler une erreur SQL lors de l'exécution
    cursor.execute.side_effect = sqlite3.Error("SQL Error")

    # Appel de la fonction
    with pytest.raises(sqlite3.Error):
        mempool_module.parse_mempool_transactions(db, ["raw_tx"])

    # Vérifier que CurrentState.set_parsing_mempool(True) a été appelé
    mock_current_state.assert_called_with(True)

    # Note: On ne peut pas vérifier set_parsing_mempool(False) car l'erreur SQL
    # interrompt l'exécution avant que cette méthode soit appelée


def test_parse_mempool_transactions_deserialize_error(
    mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks
):
    """Test parse_mempool_transactions avec une erreur de désérialisation"""
    db, cursor = mock_db

    # Configuration du curseur
    cursor.fetchone.side_effect = [
        {"tx_index": 10},  # Last mempool tx
        {"tx_index": 5},  # Last tx
        {"message_index": 100},  # Last message
    ]

    # Simuler une erreur lors de la désérialisation
    mock_deserialize.side_effect = ValueError("Deserialize Error")

    # Appel de la fonction
    with pytest.raises(ValueError):
        mempool_module.parse_mempool_transactions(db, ["raw_tx"])

    # Vérifier que CurrentState.set_parsing_mempool(True) a été appelé
    mock_current_state.assert_called_with(True)

    # Note: On ne peut pas vérifier set_parsing_mempool(False) car l'erreur de désérialisation
    # interrompt l'exécution avant que cette méthode soit appelée


def test_clean_transaction_from_mempool_sql_error(mock_db):
    """Test clean_transaction_from_mempool avec une erreur SQL"""
    db, cursor = mock_db

    # Simuler une erreur SQL lors de l'exécution
    cursor.execute.side_effect = sqlite3.Error("SQL Error")

    # Appel de la fonction
    with pytest.raises(sqlite3.Error):
        mempool_module.clean_transaction_from_mempool(db, "tx1")


def test_clean_mempool_get_transaction_error(mock_db, mock_ledger_blocks):
    """Test clean_mempool avec une erreur dans get_transaction"""
    db, cursor = mock_db

    # Configuration des événements de mempool
    cursor.fetchall.return_value = [{"tx_hash": "tx1"}]

    # Simuler une erreur dans get_transaction
    mock_ledger_blocks.side_effect = ValueError("Get Transaction Error")

    # Appel de la fonction
    with pytest.raises(ValueError):
        mempool_module.clean_mempool(db)


def test_clean_mempool_getrawmempool_error(mock_db, mock_ledger_blocks, mock_backend_bitcoind):
    """Test clean_mempool avec une erreur dans getrawmempool"""
    db, cursor = mock_db

    # Configuration des événements de mempool
    cursor.fetchall.side_effect = [
        [{"tx_hash": "tx1"}],  # Pour la première requête SELECT
        [{"tx_hash": "tx1"}],  # Pour la deuxième requête SELECT
    ]

    # Configuration de get_transaction
    mock_ledger_blocks.return_value = None

    # Simuler une erreur dans getrawmempool
    mock_backend_bitcoind.side_effect = ValueError("GetRawMempool Error")

    # Appel de la fonction
    with pytest.raises(ValueError):
        mempool_module.clean_mempool(db)


def test_parse_mempool_transactions_rollback(
    mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks
):
    """Test que parse_mempool_transactions effectue correctement le rollback de la transaction"""
    db, cursor = mock_db

    # Configuration du contexte de la base de données
    db_context = mock.MagicMock()
    db.__enter__.return_value = db_context

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

    # Configuration de get_transaction
    mock_ledger_blocks.return_value = None

    # Exécution de la fonction
    mempool_module.parse_mempool_transactions(db, ["raw_tx"])

    # Vérifier que db.__enter__ a été appelé (début de la transaction)
    assert db.__enter__.called

    # Vérifier que db.cursor a été appelé
    assert db.cursor.called

    # Vérifier que la MempoolError a été levée pour effectuer le rollback
    assert isinstance(db.__exit__.call_args[0][1], exceptions.MempoolError)

    # Vérifier que les insertions dans la mempool ont été effectuées après le rollback
    assert cursor.execute.called
