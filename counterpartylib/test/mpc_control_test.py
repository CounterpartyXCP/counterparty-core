import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures.params import DP
from counterpartylib.lib import util
from micropayment_core.keys import address_from_wif
from micropayment_core.keys import pubkey_from_wif
from counterpartylib.lib.micropayments.control import get_quantity
from counterpartylib.lib.micropayments.control import get_balance
from counterpartylib.lib.micropayments import exceptions
from counterpartylib.lib.api import dispatcher
from micropayment_core.keys import generate_wif


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


# actors
ALICE_WIF = DP["addresses"][0][2]  # payer
ALICE_ADDRESS = address_from_wif(ALICE_WIF)
ALICE_PUBKEY = pubkey_from_wif(ALICE_WIF)
BOB_WIF = generate_wif(netcode="XTN")
BOB_ADDRESS = address_from_wif(BOB_WIF)
BOB_PUBKEY = pubkey_from_wif(BOB_WIF)


ASSET = "XCP"
NETCODE = "XTN"


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_not_send_tx(server_db):
    try:
        rawtx = util.api('create_burn', {
            'source': ALICE_ADDRESS,
            'quantity': 100000,
            'encoding': 'multisig'  # opreturn, multisig, pubkeyhash
        })
        get_quantity(dispatcher, "XCP", rawtx)
        assert False
    except ValueError as e:
        assert "No data for given transaction!" in str(e)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_incorrect_asset(server_db):
    rawtx = util.api('create_send', {
        'source': ALICE_ADDRESS,
        'destination': BOB_ADDRESS,
        'asset': 'XCP',
        'quantity': 33
    })
    try:
        get_quantity(dispatcher, "A18446744073709551615", rawtx)
        assert False
    except exceptions.AssetMissmatch:
        pass


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_get_balance_confirmed(server_db):

    rawtx = util.api('create_send', {
        'source': ALICE_ADDRESS,
        'destination': BOB_ADDRESS,
        'asset': 'XCP',
        'quantity': 33,
        'regular_dust_size': 42
    })

    asset_balance, btc_balance = get_balance(dispatcher, "XCP", BOB_ADDRESS)
    assert asset_balance == 0
    assert btc_balance == 0

    util_test.insert_raw_transaction(rawtx, server_db)

    asset_balance, btc_balance = get_balance(dispatcher, "XCP", BOB_ADDRESS)
    assert asset_balance == 33
    assert btc_balance == 42
