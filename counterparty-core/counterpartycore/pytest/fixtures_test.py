import apsw
import pytest

from .fixtures import unitestdb
from .mocks import bitcoind


def is_valid_der(der):
    print(len(der))
    if len(der) == 71:
        return True
    return False


@pytest.fixture(scope="function")
def bitcoind_mock(monkeypatch):
    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.list_unspent", bitcoind.list_unspent)
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.satoshis_per_vbyte", bitcoind.satoshis_per_vbyte
    )
    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.get_vin_info", bitcoind.get_vin_info)
    monkeypatch.setattr("counterpartycore.lib.parser.gettxinfo.is_valid_der", is_valid_der)
    return bitcoind


@pytest.fixture(scope="function")
def ledger_db(bitcoind_mock):
    return unitestdb.buid_unitest_db(bitcoind_mock)


def test_ledger(ledger_db):
    assert isinstance(ledger_db, apsw.Connection)
    cursor = ledger_db.cursor()
    blocks = cursor.execute("SELECT * FROM blocks").fetchall()
    burns = cursor.execute("SELECT * FROM burns").fetchall()
    assert len(blocks) == 2
    assert len(burns) == 1
