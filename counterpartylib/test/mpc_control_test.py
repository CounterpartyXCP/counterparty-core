import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.lib import util
from counterpartylib.lib.micropayments.control import get_transferred
from counterpartylib.lib.micropayments.control import get_spendable
from counterpartylib.lib.api import dispatcher
from micropayment_core import scripts


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


def get_txs(txids):
    return util.api(
        method="getrawtransaction_batch", params={"txhash_list": txids}
    )


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_get_transferred_not_send_tx(server_db, mpcenv):
    unsigned_rawtx = util.api('create_burn', {
        'source': mpcenv["alice_address"],
        'quantity': 100000,
        'encoding': 'multisig'  # opreturn, multisig, pubkeyhash
    })
    signed_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                        unsigned_rawtx)

    asset_quantity, btc_quantity = get_transferred(
        dispatcher, signed_rawtx, mpcenv["asset"]
    )
    assert asset_quantity == 0
    assert btc_quantity == 0


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_get_transferred_incorrect_asset(server_db, mpcenv):
    unsigned_rawtx = util.api('create_send', {
        'source': mpcenv["alice_address"],
        'destination': mpcenv["bob_address"],
        'asset': 'XCP',
        'quantity': 33
    })
    signed_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                        unsigned_rawtx)
    asset_quantity, btc_quantity = get_transferred(
        dispatcher, signed_rawtx, "A18446744073709551615"
    )
    assert asset_quantity == 0
    assert btc_quantity == 0


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_get_transferred_incorrect_address(server_db, mpcenv):
    unsigned_rawtx = util.api('create_send', {
        'source': mpcenv["alice_address"],
        'destination': mpcenv["bob_address"],
        'asset': 'XCP',
        'quantity': 33
    })
    signed_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                        unsigned_rawtx)
    asset_quantity, btc_quantity = get_transferred(
        dispatcher, signed_rawtx, asset="XCP",
        address="mgLDQmQt2jqLgPbcNQ1XUKPRK4vWA9pujr"
    )
    assert asset_quantity == 0
    assert btc_quantity == 0


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_get_transferred_source_address(server_db, mpcenv):
    unsigned_rawtx = util.api('create_send', {
        'source': mpcenv["alice_address"],
        'destination': mpcenv["bob_address"],
        'asset': 'XCP',
        'quantity': 33
    })
    signed_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                        unsigned_rawtx)
    asset_quantity, btc_quantity = get_transferred(
        dispatcher, signed_rawtx, asset="XCP", address=mpcenv["alice_address"]
    )
    assert asset_quantity == -33
    assert btc_quantity < 0


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_get_balance_confirmed(server_db, mpcenv):

    # alice before
    asset_balance, btc_balance, utxos = get_spendable(
        dispatcher, mpcenv["alice_address"], mpcenv["asset"]
    )
    assert asset_balance == 1000000
    assert btc_balance == 1000000

    # bob before
    asset_balance, btc_balance, utxos = get_spendable(
        dispatcher, mpcenv["bob_address"], mpcenv["asset"]
    )
    assert asset_balance == 1000000
    assert btc_balance == 1000000

    # alice sends to bob
    unsigned_rawtx = util.api('create_send', {
        'source': mpcenv["alice_address"],
        'destination': mpcenv["bob_address"],
        'asset': mpcenv["asset"],
        'quantity': 33,
        'fee': 50000,
        'regular_dust_size': 42
    })
    signed_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                        unsigned_rawtx)
    util_test.insert_raw_transaction(signed_rawtx, server_db)

    # bob sends to alice
    unsigned_rawtx = util.api('create_send', {
        'source': mpcenv["bob_address"],
        'destination': mpcenv["alice_address"],
        'asset': mpcenv["asset"],
        'quantity': 13,
        'fee': 50000,
        'regular_dust_size': 42
    })
    signed_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                        unsigned_rawtx)
    util_test.insert_raw_transaction(signed_rawtx, server_db)

    # alice after
    asset_balance, btc_balance, utxos = get_spendable(
        dispatcher, mpcenv["alice_address"], mpcenv["asset"]
    )
    assert asset_balance == 1000000 - 33 + 13
    assert btc_balance == 1000000 - 42 - 50000 + 42

    # bob after
    asset_balance, btc_balance, utxos = get_spendable(
        dispatcher, mpcenv["bob_address"], mpcenv["asset"]
    )
    assert asset_balance == 1000000 + 33 - 13
    assert btc_balance == 1000000 + 42 - 42 - 50000
