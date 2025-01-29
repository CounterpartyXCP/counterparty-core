from counterpartycore.pytest.fixtures.ledgerdb import UNITTEST_FIXTURE
from counterpartycore.pytest.mocks.counterpartydbs import run_scenario


def test_multisig_scenario(empty_ledger_db, bitcoind_mock):
    assert empty_ledger_db.execute("SELECT * FROM balances").fetchall() == []
    assert empty_ledger_db.execute("SELECT * FROM issuances").fetchall() == []
    assert empty_ledger_db.execute("SELECT * FROM fairmints").fetchall() == []
    run_scenario(empty_ledger_db, bitcoind_mock, UNITTEST_FIXTURE)
