import json

# Import du module à tester
import counterpartycore.lib.parser.mempool as mempool_module
import pytest
from counterpartycore.lib import config
from counterpartycore.lib.api import apiwatcher


@pytest.mark.parametrize(
    "event_data",
    [
        # Cas 1: Événement simple sans adresses
        {
            "event": "simple_event",
            "bindings": json.dumps({"param1": "value1", "param2": "value2"}),
            "command": "cmd1",
            "category": "cat1",
        },
        # Cas 2: Événement avec adresses
        {
            "event": "send",
            "bindings": json.dumps({"source": "addr1", "destination": "addr2", "amount": 100}),
            "command": "send",
            "category": "sends",
        },
        # Cas 3: Événement avec une adresse null
        {
            "event": "send",
            "bindings": json.dumps({"source": "addr1", "destination": None, "amount": 100}),
            "command": "send",
            "category": "sends",
        },
        # Cas 4: Événement avec plusieurs adresses identiques
        {
            "event": "send",
            "bindings": json.dumps({"source": "addr1", "destination": "addr1", "amount": 100}),
            "command": "send",
            "category": "sends",
        },
    ],
)
def test_parse_mempool_transactions_with_various_events(
    mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks, event_data
):
    """Test parse_mempool_transactions avec différents types d'événements"""
    db, cursor = mock_db
    mock_list_tx, mock_parse_block = mock_blocks

    # Configuration du curseur
    cursor.fetchone.side_effect = [
        {"tx_index": 10},  # Last mempool tx
        {"tx_index": 5},  # Last tx
        {"message_index": 100},  # Last message
    ]

    # Configuration des transactions et événements
    tx_hash = "tx1"
    event_data["tx_hash"] = tx_hash
    transaction_events = [event_data]

    mempool_transactions = [
        {
            "tx_hash": tx_hash,
            "tx_index": 11,
            "block_index": config.MEMPOOL_BLOCK_INDEX,
            "block_hash": config.MEMPOOL_BLOCK_HASH,
            "block_time": 123,
        }
    ]

    cursor.fetchall.side_effect = [transaction_events, mempool_transactions]

    # Configuration de deserialize
    mock_deserialize.return_value = {"tx_hash": tx_hash, "source": "addr1", "destination": "addr2"}

    # Configuration de get_transaction pour retourner None (tx n'existe pas)
    mock_ledger_blocks.return_value = None

    # Mock pour EVENTS_ADDRESS_FIELDS si l'événement est 'send'
    original_events_address_fields = getattr(apiwatcher, "EVENTS_ADDRESS_FIELDS", {})
    try:
        apiwatcher.EVENTS_ADDRESS_FIELDS = {"send": ["source", "destination"]}

        # Exécution de la fonction avec une transaction
        raw_tx_list = ["raw_tx_data"]
        result = mempool_module.parse_mempool_transactions(db, raw_tx_list)

        # Vérifications
        assert mock_deserialize.called
        assert mock_parse_block.called

        # Vérifier que les transactions sont insérées dans la mempool
        found_insert = False
        for call in cursor.execute.call_args_list:
            if "INSERT INTO mempool VALUES" in str(call) and tx_hash in str(call):
                found_insert = True
                break

        assert found_insert, f"L'événement {event_data['event']} n'a pas été inséré correctement"

        # Vérifier le résultat
        assert result == []
    finally:
        # Restaurer EVENTS_ADDRESS_FIELDS
        apiwatcher.EVENTS_ADDRESS_FIELDS = original_events_address_fields


@pytest.mark.parametrize(
    "tx_index_config",
    [
        # Cas 1: Pas de transactions dans la mempool ou la base principale
        (None, None, 1),
        # Cas 2: Transactions dans la mempool mais pas dans la base principale
        ({"tx_index": 10}, None, 11),
        # Cas 3: Transactions dans la base principale mais pas dans la mempool
        (None, {"tx_index": 20}, 21),
        # Cas 4: Transactions dans les deux, mempool a index plus élevé
        ({"tx_index": 30}, {"tx_index": 20}, 31),
        # Cas 5: Transactions dans les deux, base principale a index plus élevé
        ({"tx_index": 20}, {"tx_index": 30}, 31),
    ],
)
def test_parse_mempool_transactions_tx_index_calculation(
    mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks, tx_index_config
):
    """Test le calcul correct de tx_index dans parse_mempool_transactions"""
    db, cursor = mock_db
    mock_list_tx, mock_parse_block = mock_blocks

    # Configuration du curseur avec différentes configurations de tx_index
    last_mempool_tx, last_tx, expected_tx_index = tx_index_config
    cursor.fetchone.side_effect = [
        last_mempool_tx,  # Last mempool tx
        last_tx,  # Last tx
        {"message_index": 100},  # Last message
    ]

    # Configuration des transactions et événements (vides pour ce test)
    cursor.fetchall.side_effect = [[], []]

    # Exécution de la fonction avec une liste vide
    mempool_module.parse_mempool_transactions(db, [])

    # Vérifier que les requêtes pour obtenir les derniers tx_index ont été appelées
    assert any(
        "SELECT tx_index FROM mempool_transactions ORDER BY tx_index DESC LIMIT 1" in str(call)
        for call in cursor.execute.call_args_list
    ), "Requête mempool_transactions non trouvée"

    assert any(
        "SELECT tx_index FROM transactions ORDER BY tx_index DESC LIMIT 1" in str(call)
        for call in cursor.execute.call_args_list
    ), "Requête transactions non trouvée"

    # Vérifier qu'une insertion dans la table blocks a été effectuée
    insert_block_calls = [
        call for call in cursor.execute.call_args_list if "INSERT INTO blocks" in str(call)
    ]
    assert insert_block_calls, "Aucune insertion dans la table blocks trouvée"

    # Vérifier que les paramètres d'insertion contiennent le bon block_index
    block_params = insert_block_calls[0][0][1]
    assert block_params[0] == config.MEMPOOL_BLOCK_INDEX, "Mauvais block_index utilisé"
    assert block_params[1] == config.MEMPOOL_BLOCK_HASH, "Mauvais block_hash utilisé"


def test_clean_mempool_empty(mock_db, mock_backend_bitcoind):
    """Test clean_mempool avec une mempool vide"""
    db, cursor = mock_db

    # Configuration des événements de mempool (vide)
    cursor.fetchall.return_value = []

    # Configuration de getrawmempool
    mock_backend_bitcoind.return_value = []

    # Appel de la fonction
    mempool_module.clean_mempool(db)

    # Vérifications
    assert cursor.execute.called
    cursor.execute.assert_any_call("SELECT * FROM mempool")
    cursor.execute.assert_any_call("SELECT distinct tx_hash FROM mempool")

    # Aucun appel à clean_transaction_from_mempool ne devrait être fait
    assert "DELETE FROM mempool WHERE tx_hash" not in str(cursor.execute.call_args_list)


def test_clean_mempool_with_removed_transactions(
    mock_db, mock_ledger_blocks, mock_backend_bitcoind
):
    """Test clean_mempool avec des transactions supprimées du mempool"""
    db, cursor = mock_db

    # Configuration des événements de mempool
    cursor.fetchall.side_effect = [
        # Premier appel: transactions dans la mempool
        [{"tx_hash": "tx1"}, {"tx_hash": "tx2"}],
        # Deuxième appel: tx_hash distincts dans la mempool
        [{"tx_hash": "tx1"}, {"tx_hash": "tx2"}],
    ]

    # Configuration de get_transaction pour retourner None (transactions non validées)
    mock_ledger_blocks.return_value = None

    # Mock pour backend.bitcoind.getrawmempool
    # Retourne seulement tx1, tx2 n'est plus dans la mempool brute
    mock_backend_bitcoind.return_value = ["tx1"]

    # Appel de la fonction
    mempool_module.clean_mempool(db)

    # Vérifications
    assert cursor.execute.called

    # Vérifier que clean_transaction_from_mempool a été appelé pour tx2
    cursor.execute.assert_any_call("DELETE FROM mempool WHERE tx_hash = ?", ("tx2",))
    cursor.execute.assert_any_call("DELETE FROM mempool_transactions WHERE tx_hash = ?", ("tx2",))
