import binascii
import unittest.mock as mock

import pytest
import requests
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.backend import electrs as electrum_connector


# Fixture for mocking requests.get
@pytest.fixture
def mock_requests_get():
    with mock.patch("requests.get") as mock_get:
        yield mock_get


# Tests for electr_query
def test_electr_query_success(mock_requests_get):
    """Test the electr_query function with a successful result"""
    # Ensure config.ELECTRS_URL is set before calling electr_query
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    mock_response = mock.Mock()
    mock_response.json.return_value = {"test": "data"}
    mock_requests_get.return_value = mock_response

    result = electrum_connector.electr_query("test/url")

    mock_requests_get.assert_called_once_with("http://localhost:3000/test/url", timeout=10)
    assert result == {"test": "data"}

    # Restore original URL
    config.ELECTRS_URL = previous_url


def test_electr_query_no_url():
    """Test the electr_query function without a configured URL"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = None

    with pytest.raises(exceptions.ElectrsError, match="Electrs server not configured"):
        electrum_connector.electr_query("test/url")

    # Restore original URL
    config.ELECTRS_URL = previous_url


def test_electr_query_request_exception(mock_requests_get):
    """Test the electr_query function when a request exception is raised"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    mock_requests_get.side_effect = requests.RequestException("Connection error")

    with pytest.raises(exceptions.ElectrsError):
        electrum_connector.electr_query("test/url")

    # Restore original URL
    config.ELECTRS_URL = previous_url


# Tests for get_utxos
def test_get_utxos_confirmed():
    """Test get_utxos with confirmed transactions"""
    # Set required config values
    previous_unit = getattr(config, "UNIT", None)
    config.UNIT = 10**8

    with mock.patch("counterpartycore.lib.backend.electrs.electr_query") as mock_query:
        mock_query.return_value = [
            {"txid": "tx1", "vout": 0, "value": 10000000, "status": {"confirmed": True}},
            {"txid": "tx2", "vout": 1, "value": 20000000, "status": {"confirmed": True}},
        ]

        result = electrum_connector.get_utxos("test_address")

        expected = [
            {
                "txid": "tx1",
                "vout": 0,
                "value": 10000000,
                "amount": 0.1,
                "status": {"confirmed": True},
            },
            {
                "txid": "tx2",
                "vout": 1,
                "value": 20000000,
                "amount": 0.2,
                "status": {"confirmed": True},
            },
        ]
        assert result == expected
        mock_query.assert_called_once_with("address/test_address/utxo")

    # Restore original value
    config.UNIT = previous_unit


def test_get_utxos_include_unconfirmed():
    """Test get_utxos including unconfirmed transactions"""
    previous_unit = getattr(config, "UNIT", None)
    config.UNIT = 10**8

    with mock.patch("counterpartycore.lib.backend.electrs.electr_query") as mock_query:
        mock_query.return_value = [
            {"txid": "tx1", "vout": 0, "value": 10000000, "status": {"confirmed": True}},
            {"txid": "tx2", "vout": 1, "value": 20000000, "status": {"confirmed": False}},
        ]

        result = electrum_connector.get_utxos("test_address", unconfirmed=True)

        expected = [
            {
                "txid": "tx1",
                "vout": 0,
                "value": 10000000,
                "amount": 0.1,
                "status": {"confirmed": True},
            },
            {
                "txid": "tx2",
                "vout": 1,
                "value": 20000000,
                "amount": 0.2,
                "status": {"confirmed": False},
            },
        ]
        assert result == expected

    # Restore original value
    config.UNIT = previous_unit


def test_get_utxos_exclude_unconfirmed():
    """Test get_utxos excluding unconfirmed transactions"""
    previous_unit = getattr(config, "UNIT", None)
    config.UNIT = 10**8

    with mock.patch("counterpartycore.lib.backend.electrs.electr_query") as mock_query:
        mock_query.return_value = [
            {"txid": "tx1", "vout": 0, "value": 10000000, "status": {"confirmed": True}},
            {"txid": "tx2", "vout": 1, "value": 20000000, "status": {"confirmed": False}},
        ]

        result = electrum_connector.get_utxos("test_address", unconfirmed=False)

        expected = [
            {
                "txid": "tx1",
                "vout": 0,
                "value": 10000000,
                "amount": 0.1,
                "status": {"confirmed": True},
            }
        ]
        assert result == expected

    # Restore original value
    config.UNIT = previous_unit


def test_get_utxos_filter_by_tx_hash():
    """Test get_utxos with transaction hash filtering"""
    previous_unit = getattr(config, "UNIT", None)
    config.UNIT = 10**8

    with mock.patch("counterpartycore.lib.backend.electrs.electr_query") as mock_query:
        mock_query.return_value = [
            {"txid": "tx1", "vout": 0, "value": 10000000, "status": {"confirmed": True}},
            {"txid": "tx2", "vout": 1, "value": 20000000, "status": {"confirmed": True}},
        ]

        result = electrum_connector.get_utxos("test_address", unspent_tx_hash="tx1")

        expected = [
            {
                "txid": "tx1",
                "vout": 0,
                "value": 10000000,
                "amount": 0.1,
                "status": {"confirmed": True},
            }
        ]
        assert result == expected

    # Restore original value
    config.UNIT = previous_unit


def test_get_utxos_empty_list():
    """Test get_utxos with an empty transaction list"""
    previous_unit = getattr(config, "UNIT", None)
    config.UNIT = 10**8

    with mock.patch("counterpartycore.lib.backend.electrs.electr_query") as mock_query:
        mock_query.return_value = []

        result = electrum_connector.get_utxos("test_address")

        assert result == []

    # Restore original value
    config.UNIT = previous_unit


# Tests for get_history
def test_get_history_confirmed_only():
    """Test get_history including only confirmed transactions"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    with mock.patch("counterpartycore.lib.backend.electrs.electr_query") as mock_query:
        mock_query.return_value = [
            {"txid": "tx1", "status": {"confirmed": True}},
            {"txid": "tx2", "status": {"confirmed": False}},
        ]

        result = electrum_connector.get_history("test_address")

        expected = [{"txid": "tx1", "status": {"confirmed": True}}]
        assert result == expected
        mock_query.assert_called_once_with("address/test_address/txs")

    # Restore original URL
    config.ELECTRS_URL = previous_url


def test_get_history_include_unconfirmed():
    """Test get_history including unconfirmed transactions"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    with mock.patch("counterpartycore.lib.backend.electrs.electr_query") as mock_query:
        mock_query.return_value = [
            {"txid": "tx1", "status": {"confirmed": True}},
            {"txid": "tx2", "status": {"confirmed": False}},
        ]

        result = electrum_connector.get_history("test_address", unconfirmed=True)

        expected = [
            {"txid": "tx1", "status": {"confirmed": True}},
            {"txid": "tx2", "status": {"confirmed": False}},
        ]
        assert result == expected

    # Restore original URL
    config.ELECTRS_URL = previous_url


def test_get_history_empty_list():
    """Test get_history with an empty transaction list"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    with mock.patch("counterpartycore.lib.backend.electrs.electr_query") as mock_query:
        mock_query.return_value = []

        result = electrum_connector.get_history("test_address")

        assert result == []

    # Restore original URL
    config.ELECTRS_URL = previous_url


# Tests for get_utxos_by_addresses
def test_get_utxos_by_addresses():
    """Test get_utxos_by_addresses with multiple addresses"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    with mock.patch("counterpartycore.lib.backend.electrs.get_utxos") as mock_get_utxos:
        mock_get_utxos.side_effect = [
            [
                {
                    "txid": "tx1",
                    "vout": 0,
                    "value": 10000000,
                    "amount": 0.1,
                    "status": {"confirmed": True},
                }
            ],
            [
                {
                    "txid": "tx2",
                    "vout": 1,
                    "value": 20000000,
                    "amount": 0.2,
                    "status": {"confirmed": True},
                }
            ],
        ]

        result = electrum_connector.get_utxos_by_addresses("addr1,addr2")

        expected = [
            {
                "txid": "tx1",
                "vout": 0,
                "value": 10000000,
                "amount": 0.1,
                "status": {"confirmed": True},
                "address": "addr1",
            },
            {
                "txid": "tx2",
                "vout": 1,
                "value": 20000000,
                "amount": 0.2,
                "status": {"confirmed": True},
                "address": "addr2",
            },
        ]
        assert result == expected
        assert mock_get_utxos.call_count == 2

    # Restore original URL
    config.ELECTRS_URL = previous_url


def test_get_utxos_by_addresses_with_params():
    """Test get_utxos_by_addresses with additional parameters"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    with mock.patch("counterpartycore.lib.backend.electrs.get_utxos") as mock_get_utxos:
        mock_get_utxos.return_value = [
            {
                "txid": "tx1",
                "vout": 0,
                "value": 10000000,
                "amount": 0.1,
                "status": {"confirmed": True},
            }
        ]

        result = electrum_connector.get_utxos_by_addresses(
            "addr1", unconfirmed=True, unspent_tx_hash="tx1"
        )

        expected = [
            {
                "txid": "tx1",
                "vout": 0,
                "value": 10000000,
                "amount": 0.1,
                "status": {"confirmed": True},
                "address": "addr1",
            }
        ]
        assert result == expected
        mock_get_utxos.assert_called_once_with("addr1", True, "tx1")

    # Restore original URL
    config.ELECTRS_URL = previous_url


def test_get_utxos_by_addresses_empty_string():
    """Test get_utxos_by_addresses with an empty string"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    # Mock get_utxos to return an empty list when called
    with mock.patch("counterpartycore.lib.backend.electrs.get_utxos") as mock_get_utxos:
        # It's crucial to set a return value for the mock
        mock_get_utxos.return_value = []

        result = electrum_connector.get_utxos_by_addresses("")

        # Verify the function returns an empty list for an empty string input
        assert result == []

        # Check if get_utxos was called with empty string
        # (you can remove this if the function should skip calling get_utxos for empty inputs)
        mock_get_utxos.assert_called_with("", False, None)

    # Restore original URL
    config.ELECTRS_URL = previous_url


# Tests for pubkey_from_tx
def test_pubkey_from_tx_witness():
    """Test pubkey_from_tx with a witness"""
    with mock.patch("counterpartycore.lib.backend.electrs.PublicKey") as mock_pubkey:
        mock_segwit_addr = mock.Mock()
        mock_segwit_addr.to_string.return_value = "test_pubkeyhash"
        mock_pubkey_instance = mock.Mock()
        mock_pubkey_instance.get_segwit_address.return_value = mock_segwit_addr
        mock_pubkey.from_hex.return_value = mock_pubkey_instance

        tx = {"vin": [{"witness": ["witness0", "pubkey_witness"]}], "vout": []}

        result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

        assert result == "pubkey_witness"


def test_pubkey_from_tx_witness_binascii_error():
    """Test pubkey_from_tx with a binascii error on the witness"""
    with mock.patch("counterpartycore.lib.backend.electrs.PublicKey") as mock_pubkey:
        mock_pubkey.from_hex.side_effect = binascii.Error()

        tx = {"vin": [{"witness": ["witness0", "invalid_pubkey"]}], "vout": []}

        result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

        assert result is None


def test_pubkey_from_tx_witness_short():
    """Test pubkey_from_tx with a witness that's too short"""
    tx = {
        "vin": [
            {
                "witness": ["witness0"]  # Only one element, no public key
            }
        ],
        "vout": [],
    }

    result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

    assert result is None


def test_pubkey_from_tx_p2pkh_uncompressed():
    """Test pubkey_from_tx with uncompressed p2pkh"""
    with mock.patch("counterpartycore.lib.backend.electrs.PublicKey") as mock_pubkey:
        mock_addr_uncompressed = mock.Mock()
        mock_addr_uncompressed.to_string.return_value = "test_pubkeyhash"
        mock_addr_compressed = mock.Mock()
        mock_addr_compressed.to_string.return_value = "different_pubkeyhash"
        mock_pubkey_instance = mock.Mock()
        mock_pubkey_instance.get_address.side_effect = [
            mock_addr_uncompressed,
            mock_addr_compressed,
        ]
        mock_pubkey.from_hex.return_value = mock_pubkey_instance

        tx = {"vin": [{"scriptsig_asm": "asm0 asm1 asm2 pubkey_asm"}], "vout": []}

        result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

        assert result == "pubkey_asm"


def test_pubkey_from_tx_p2pkh_compressed():
    """Test pubkey_from_tx with compressed p2pkh"""
    with mock.patch("counterpartycore.lib.backend.electrs.PublicKey") as mock_pubkey:
        mock_addr_uncompressed = mock.Mock()
        mock_addr_uncompressed.to_string.return_value = "different_pubkeyhash"
        mock_addr_compressed = mock.Mock()
        mock_addr_compressed.to_string.return_value = "test_pubkeyhash"
        mock_pubkey_instance = mock.Mock()
        mock_pubkey_instance.get_address.side_effect = [
            mock_addr_uncompressed,
            mock_addr_compressed,
        ]
        mock_pubkey.from_hex.return_value = mock_pubkey_instance

        tx = {"vin": [{"scriptsig_asm": "asm0 asm1 asm2 pubkey_asm"}], "vout": []}

        result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

        assert result == "pubkey_asm"


def test_pubkey_from_tx_p2pkh_binascii_error():
    """Test pubkey_from_tx with a binascii error on p2pkh"""
    with mock.patch("counterpartycore.lib.backend.electrs.PublicKey") as mock_pubkey:
        mock_pubkey.from_hex.side_effect = binascii.Error()

        tx = {"vin": [{"scriptsig_asm": "asm0 asm1 asm2 invalid_pubkey"}], "vout": []}

        result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

        assert result is None


def test_pubkey_from_tx_p2pkh_invalid_format():
    """Test pubkey_from_tx with an invalid ASM format"""
    tx = {
        "vin": [
            {
                "scriptsig_asm": "invalid_format"  # Not 4 elements
            }
        ],
        "vout": [],
    }

    result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

    assert result is None


def test_pubkey_from_tx_p2pk_uncompressed():
    """Test pubkey_from_tx with uncompressed p2pk"""
    with mock.patch("counterpartycore.lib.backend.electrs.PublicKey") as mock_pubkey:
        mock_addr_uncompressed = mock.Mock()
        mock_addr_uncompressed.to_string.return_value = "test_pubkeyhash"
        mock_addr_compressed = mock.Mock()
        mock_addr_compressed.to_string.return_value = "different_pubkeyhash"
        mock_pubkey_instance = mock.Mock()
        mock_pubkey_instance.get_address.side_effect = [
            mock_addr_uncompressed,
            mock_addr_compressed,
        ]
        mock_pubkey.from_hex.return_value = mock_pubkey_instance

        tx = {"vin": [], "vout": [{"scriptpubkey_asm": "OP_PUBKEY pubkey_asm OP_CHECKSIG"}]}

        result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

        assert result == "pubkey_asm"


def test_pubkey_from_tx_p2pk_compressed():
    """Test pubkey_from_tx with compressed p2pk"""
    with mock.patch("counterpartycore.lib.backend.electrs.PublicKey") as mock_pubkey:
        mock_addr_uncompressed = mock.Mock()
        mock_addr_uncompressed.to_string.return_value = "different_pubkeyhash"
        mock_addr_compressed = mock.Mock()
        mock_addr_compressed.to_string.return_value = "test_pubkeyhash"
        mock_pubkey_instance = mock.Mock()
        mock_pubkey_instance.get_address.side_effect = [
            mock_addr_uncompressed,
            mock_addr_compressed,
        ]
        mock_pubkey.from_hex.return_value = mock_pubkey_instance

        tx = {"vin": [], "vout": [{"scriptpubkey_asm": "OP_PUBKEY pubkey_asm OP_CHECKSIG"}]}

        result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

        assert result == "pubkey_asm"


def test_pubkey_from_tx_p2pk_binascii_error():
    """Test pubkey_from_tx with a binascii error on p2pk"""
    with mock.patch("counterpartycore.lib.backend.electrs.PublicKey") as mock_pubkey:
        mock_pubkey.from_hex.side_effect = binascii.Error()

        tx = {"vin": [], "vout": [{"scriptpubkey_asm": "OP_PUBKEY invalid_pubkey OP_CHECKSIG"}]}

        result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

        assert result is None


def test_pubkey_from_tx_p2pk_invalid_format():
    """Test pubkey_from_tx with an invalid ASM format in vout"""
    tx = {
        "vin": [],
        "vout": [
            {
                "scriptpubkey_asm": "invalid_format"  # Not 3 elements or no OP_CHECKSIG
            }
        ],
    }

    result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

    assert result is None


def test_pubkey_from_tx_coinbase():
    """Test pubkey_from_tx with a coinbase transaction"""
    tx = {"vin": [{"is_coinbase": True}], "vout": []}

    result = electrum_connector.pubkey_from_tx(tx, "test_pubkeyhash")

    assert result is None


# Tests for search_pubkey
def test_search_pubkey_found():
    """Test search_pubkey when the public key is found"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    with mock.patch(
        "counterpartycore.lib.backend.electrs.get_history"
    ) as mock_get_history, mock.patch(
        "counterpartycore.lib.backend.electrs.pubkey_from_tx"
    ) as mock_pubkey_from_tx:
        mock_get_history.return_value = [{"txid": "tx1"}, {"txid": "tx2"}]
        mock_pubkey_from_tx.side_effect = [None, "found_pubkey"]

        result = electrum_connector.search_pubkey("test_pubkeyhash")

        assert result == "found_pubkey"
        assert mock_pubkey_from_tx.call_count == 2

    # Restore original URL
    config.ELECTRS_URL = previous_url


def test_search_pubkey_not_found():
    """Test search_pubkey when the public key is not found"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    with mock.patch(
        "counterpartycore.lib.backend.electrs.get_history"
    ) as mock_get_history, mock.patch(
        "counterpartycore.lib.backend.electrs.pubkey_from_tx"
    ) as mock_pubkey_from_tx:
        mock_get_history.return_value = [{"txid": "tx1"}, {"txid": "tx2"}]
        mock_pubkey_from_tx.return_value = None

        result = electrum_connector.search_pubkey("test_pubkeyhash")

        assert result is None
        assert mock_pubkey_from_tx.call_count == 2

    # Restore original URL
    config.ELECTRS_URL = previous_url


def test_search_pubkey_empty_history():
    """Test search_pubkey with an empty history"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    with mock.patch("counterpartycore.lib.backend.electrs.get_history") as mock_get_history:
        mock_get_history.return_value = []

        result = electrum_connector.search_pubkey("test_pubkeyhash")

        assert result is None

    # Restore original URL
    config.ELECTRS_URL = previous_url


# Tests for list_unspent
def test_list_unspent_with_utxos():
    """Test list_unspent with available UTXOs"""
    previous_unit = getattr(config, "UNIT", None)
    config.UNIT = 10**8
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    with mock.patch("counterpartycore.lib.backend.electrs.get_utxos") as mock_get_utxos:
        mock_get_utxos.return_value = [
            {"txid": "tx1", "vout": 0, "value": 10000000, "status": {"confirmed": True}},
            {"txid": "tx2", "vout": 1, "value": 20000000, "status": {"confirmed": True}},
        ]

        result = electrum_connector.list_unspent("test_source", True)

        expected = [
            {"txid": "tx1", "vout": 0, "value": 10000000, "amount": 0.1},
            {"txid": "tx2", "vout": 1, "value": 20000000, "amount": 0.2},
        ]
        assert result == expected
        mock_get_utxos.assert_called_once_with("test_source", unconfirmed=True)

    # Restore original values
    config.UNIT = previous_unit
    config.ELECTRS_URL = previous_url


def test_list_unspent_no_utxos():
    """Test list_unspent without available UTXOs"""
    previous_unit = getattr(config, "UNIT", None)
    config.UNIT = 10**8
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    with mock.patch("counterpartycore.lib.backend.electrs.get_utxos") as mock_get_utxos:
        mock_get_utxos.return_value = []

        result = electrum_connector.list_unspent("test_source", False)

        assert result == []
        mock_get_utxos.assert_called_once_with("test_source", unconfirmed=False)

    # Restore original values
    config.UNIT = previous_unit
    config.ELECTRS_URL = previous_url


# Tests for pubkeyhash_to_pubkey
def test_pubkeyhash_to_pubkey():
    """Test pubkeyhash_to_pubkey"""
    previous_url = config.ELECTRS_URL
    config.ELECTRS_URL = "http://localhost:3000"

    with mock.patch("counterpartycore.lib.backend.electrs.search_pubkey") as mock_search_pubkey:
        mock_search_pubkey.return_value = "found_pubkey"

        result = electrum_connector.pubkeyhash_to_pubkey("test_address")

        assert result == "found_pubkey"
        mock_search_pubkey.assert_called_once_with("test_address")

    # Restore original URL
    config.ELECTRS_URL = previous_url
