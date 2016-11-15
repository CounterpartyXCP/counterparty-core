import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP
from counterpartylib.lib import util
from micropayment_core.keys import address_from_wif
from micropayment_core.keys import generate_wif


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


# actors
ALICE_WIF = DP["addresses"][0][2]
ALICE_ADDRESS = DP["addresses"][0][0]
BOB_WIF = generate_wif(netcode="XTN")
BOB_ADDRESS = address_from_wif(BOB_WIF)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_search_tx(server_db):

    transactions = util.api(
        method="search_raw_transactions",
        params={"address": BOB_ADDRESS, "unconfirmed": False}
    )
    assert len(transactions) == 0

    # send funds to bob
    rawtx = util.api('create_send', {
        'source': ALICE_ADDRESS,
        'destination': BOB_ADDRESS,
        'asset': 'XCP',
        'quantity': 42,
        'regular_dust_size': 25000,
    })
    util_test.insert_raw_transaction(rawtx, server_db)
    transactions = util.api(
        method="search_raw_transactions",
        params={"address": BOB_ADDRESS, "unconfirmed": False}
    )
    assert len(transactions) == 1

    # return funds to alice
    rawtx = util.api('create_send', {
        'destination': ALICE_ADDRESS,
        'source': BOB_ADDRESS,
        'asset': 'XCP',
        'quantity': 42
    })
    util_test.insert_raw_transaction(rawtx, server_db)
    transactions = util.api(
        method="search_raw_transactions",
        params={"address": BOB_ADDRESS, "unconfirmed": False}
    )
    assert len(transactions) == 2
