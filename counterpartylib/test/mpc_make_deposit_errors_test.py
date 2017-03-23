import tempfile
import pytest
# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test import util_test
from counterpartylib.lib import util
from counterpartylib.test.util_test import CURR_DIR
from micropayment_core.keys import pubkey_from_wif
from micropayment_core.keys import address_from_wif
from micropayment_core.keys import generate_wif


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_unsupported_asset(server_db, mpcenv):

    try:
        quantity = 42
        util.api(
            method="mpc_make_deposit",
            params={
                "asset": "BTC",
                "payer_pubkey": mpcenv["alice_pubkey"],
                "payee_pubkey": mpcenv["bob_pubkey"],
                "spend_secret_hash": mpcenv["spend_secret_hash"],
                "expire_time": mpcenv["deposit_expire_time"],  # in blocks
                "quantity": quantity  # in satoshis
            }
        )
        assert False
    except util.RPCError as e:
        assert "AssetNotSupported" in str(e)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_channel_already_used(server_db, mpcenv):

    quantity = 42
    result = util.api(
        method="mpc_make_deposit",
        params={
            "asset": "XCP",
            "payer_pubkey": mpcenv["alice_pubkey"],
            "payee_pubkey": mpcenv["bob_pubkey"],
            "spend_secret_hash": mpcenv["spend_secret_hash"],
            "expire_time": mpcenv["deposit_expire_time"],  # in blocks
            "quantity": quantity  # in satoshis
        }
    )

    # insert send, this automatically also creates a block
    util_test.insert_raw_transaction(result["topublish"], server_db)

    try:
        util.api(
            method="mpc_make_deposit",
            params={
                "asset": "XCP",
                "payer_pubkey": mpcenv["alice_pubkey"],
                "payee_pubkey": mpcenv["bob_pubkey"],
                "spend_secret_hash": mpcenv["spend_secret_hash"],
                "expire_time": mpcenv["deposit_expire_time"],  # in blocks
                "quantity": quantity  # in satoshis
            }
        )
        assert False
    except util.RPCError as e:
        assert "ChannelAlreadyUsed" in str(e)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_insufficient_asset_funds(server_db, mpcenv):
    alice_pubkey = pubkey_from_wif(generate_wif(netcode="XTN"))
    bob_pubkey = pubkey_from_wif(generate_wif(netcode="XTN"))

    try:
        quantity = 42
        util.api(
            method="mpc_make_deposit",
            params={
                "asset": "XCP",
                "payer_pubkey": alice_pubkey,
                "payee_pubkey": bob_pubkey,
                "spend_secret_hash": mpcenv["spend_secret_hash"],
                "expire_time": mpcenv["deposit_expire_time"],  # in blocks
                "quantity": quantity  # in satoshis
            }
        )
        assert False
    except util.RPCError as e:
        assert "InsufficientFunds" in str(e)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_insufficient_btc_funds(server_db, mpcenv):
    carl_wif = generate_wif(netcode="XTN")
    carl_pubkey = pubkey_from_wif(carl_wif)
    carl_address = address_from_wif(carl_wif)
    david_pubkey = pubkey_from_wif(generate_wif(netcode="XTN"))

    rawtx = util.api('create_send', {
        'source': mpcenv["alice_address"],
        'destination': carl_address,
        'asset': 'XCP',
        'quantity': 42,
    })
    util_test.insert_raw_transaction(rawtx, server_db)

    try:
        quantity = 42
        util.api(
            method="mpc_make_deposit",
            params={
                "asset": "XCP",
                "payer_pubkey": carl_pubkey,
                "payee_pubkey": david_pubkey,
                "spend_secret_hash": mpcenv["spend_secret_hash"],
                "expire_time": mpcenv["deposit_expire_time"],  # in blocks
                "quantity": quantity  # in satoshis
            }
        )
        assert False
    except util.RPCError as e:
        assert "InsufficientFunds" in str(e)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_ignores_unconfirmed_funds(server_db, mpcenv):
    emma_wif = generate_wif(netcode="XTN")
    emma_pubkey = pubkey_from_wif(emma_wif)
    emma_address = address_from_wif(emma_wif)
    fred_pubkey = pubkey_from_wif(generate_wif(netcode="XTN"))

    rawtx = util.api('create_send', {
        'source': mpcenv["alice_address"],
        'destination': emma_address,
        'asset': 'XCP',
        'quantity': 42,
        'regular_dust_size': 300000
    })

    txs = util.api(
        method="search_raw_transactions",
        params={"address": emma_address, "unconfirmed": True}
    )
    assert(len(txs) == 0)
    util_test.insert_unconfirmed_raw_transaction(rawtx, server_db)
    txs = util.api(
        method="search_raw_transactions",
        params={"address": emma_address, "unconfirmed": True}
    )
    assert(len(txs) == 1)

    try:
        quantity = 42
        util.api(
            method="mpc_make_deposit",
            params={
                "asset": "XCP",
                "payer_pubkey": emma_pubkey,
                "payee_pubkey": fred_pubkey,
                "spend_secret_hash": mpcenv["spend_secret_hash"],
                "expire_time": mpcenv["deposit_expire_time"],  # in blocks
                "quantity": quantity  # in satoshis
            }
        )
        assert False
    except util.RPCError as e:
        assert "InsufficientFunds" in str(e)
