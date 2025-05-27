# Import le module à tester
import counterpartycore.lib.parser.mempool as mempool_module
from counterpartycore.lib import config


class TestMempoolIntegration:
    """Tests d'intégration pour le module mempool"""

    def test_parse_and_clean_mempool(
        self,
        mock_db,
        mock_current_state,
        mock_deserialize,
        mock_blocks,
        mock_ledger_blocks,
        mock_backend_bitcoind,
    ):
        """Test parse_mempool_transactions suivi de clean_mempool"""
        db, cursor = mock_db
        mock_list_tx, mock_parse_block = mock_blocks

        # Configuration pour parse_mempool_transactions
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
            },
            {
                "tx_hash": "tx2",
                "event": "event2",
                "bindings": "{}",
                "command": "cmd2",
                "category": "cat2",
            },
        ]
        mempool_transactions = [
            {
                "tx_hash": "tx1",
                "tx_index": 11,
                "block_index": config.MEMPOOL_BLOCK_INDEX,
                "block_hash": config.MEMPOOL_BLOCK_HASH,
                "block_time": 123,
            },
            {
                "tx_hash": "tx2",
                "tx_index": 12,
                "block_index": config.MEMPOOL_BLOCK_INDEX,
                "block_hash": config.MEMPOOL_BLOCK_HASH,
                "block_time": 123,
            },
        ]

        cursor.fetchall.side_effect = [
            transaction_events,  # Pour parse_mempool_transactions
            mempool_transactions,  # Pour parse_mempool_transactions
            [{"tx_hash": "tx1"}, {"tx_hash": "tx2"}],  # Pour clean_mempool (liste des transactions)
            [{"tx_hash": "tx1"}, {"tx_hash": "tx2"}],  # Pour clean_mempool (liste des tx_hash)
        ]

        # Configuration de deserialize pour parse_mempool_transactions
        mock_deserialize.side_effect = [
            {"tx_hash": "tx1", "source": "addr1", "destination": "addr2"},
            {"tx_hash": "tx2", "source": "addr3", "destination": "addr4"},
        ]

        # Configuration de get_transaction pour parse_mempool_transactions (tx n'existent pas)
        mock_ledger_blocks.side_effect = [None, None]

        # Configuration de list_tx
        mock_list_tx.side_effect = [11, 12]

        # Exécution de parse_mempool_transactions avec deux transactions
        raw_tx_list = ["raw_tx_data1", "raw_tx_data2"]
        mempool_module.parse_mempool_transactions(db, raw_tx_list)

        # Vérifications pour parse_mempool_transactions
        assert mock_deserialize.call_count == 2
        # blocks.list_tx n'est jamais appelé directement, suppression de cette vérification
        assert mock_parse_block.called

        # Réinitialiser les mocks pour clean_mempool
        mock_ledger_blocks.reset_mock()
        mock_ledger_blocks.side_effect = [
            {"tx_hash": "tx1"},
            None,
        ]  # tx1 est validée, tx2 ne l'est pas

        # Configuration de getrawmempool pour clean_mempool
        mock_backend_bitcoind.return_value = []  # Aucune transaction dans la mempool brute

        # Exécution de clean_mempool
        mempool_module.clean_mempool(db)

        # Vérifications pour clean_mempool
        assert mock_ledger_blocks.call_count == 2
        assert mock_backend_bitcoind.called

        # Vérifier que clean_transaction_from_mempool a été appelé pour tx1 (validée) et tx2 (plus dans la mempool)
        cursor.execute.assert_any_call("DELETE FROM mempool WHERE tx_hash = ?", ("tx1",))
        cursor.execute.assert_any_call(
            "DELETE FROM mempool_transactions WHERE tx_hash = ?", ("tx1",)
        )
        cursor.execute.assert_any_call("DELETE FROM mempool WHERE tx_hash = ?", ("tx2",))
        cursor.execute.assert_any_call(
            "DELETE FROM mempool_transactions WHERE tx_hash = ?", ("tx2",)
        )

    def test_parse_mempool_transactions_existing_in_mempool(
        self, mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks
    ):
        """Test parse_mempool_transactions avec une transaction déjà dans la mempool"""
        db, cursor = mock_db

        # Configuration du curseur
        cursor.fetchone.side_effect = [
            {"tx_index": 10},  # Last mempool tx
            {"tx_index": 5},  # Last tx
            {"message_index": 100},  # Last message
        ]

        # Configuration des événements (vides pour ce test)
        cursor.fetchall.side_effect = [[], []]

        # Configuration pour vérifier si une transaction existe déjà dans la mempool
        cursor.execute.return_value.fetchone.return_value = {"tx_hash": "tx1"}

        # Configuration de deserialize
        mock_deserialize.return_value = {
            "tx_hash": "tx1",
            "source": "addr1",
            "destination": "addr2",
        }

        # Configuration de get_transaction pour retourner None (tx n'existe pas dans la base principale)
        mock_ledger_blocks.return_value = None

        # Exécution de la fonction avec une transaction
        raw_tx_list = ["raw_tx_data"]
        result = mempool_module.parse_mempool_transactions(db, raw_tx_list)

        # Vérifications
        assert mock_deserialize.called
        assert mock_ledger_blocks.called
        assert cursor.execute.called

        # Vérifier le résultat
        assert result == ["tx1"]
