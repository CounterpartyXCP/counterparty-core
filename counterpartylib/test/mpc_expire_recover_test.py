import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.lib import config
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.lib import util
from micropayment_core import scripts
from counterpartylib.lib.micropayments.control import get_spendable
from counterpartylib.lib.api import dispatcher


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


def get_txs(txids):
    return util.api(
        method="getrawtransaction_batch", params={"txhash_list": txids}
    )


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_expire_recover_xcp(server_db, mpcenv):

    # check initial balances
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    assert alice_balance == 1000000
    assert deposit_balance == 0

    # ===== PAYER CREATES DEPOSIT TX =====

    deposit_quantity = 41
    result = util.api(
        method="mpc_make_deposit",
        params={
            "asset": "XCP",
            "payer_pubkey": mpcenv["alice_pubkey"],
            "payee_pubkey": mpcenv["bob_pubkey"],
            "spend_secret_hash": mpcenv["spend_secret_hash"],
            "expire_time": mpcenv["deposit_expire_time"],  # in blocks
            "quantity": deposit_quantity  # in satoshis
        }
    )
    alice_state = result["state"]
    deposit_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                         result["topublish"])

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    util_test.insert_raw_transaction(deposit_rawtx, server_db)

    # check funds moved to deposit p2sh address
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    assert alice_balance == 1000000 - deposit_quantity
    assert deposit_balance == deposit_quantity

    assert util.api("mpc_deposit_ttl", {"state": alice_state}) == 41

    # ===== LET DEPOSIT EXPIRE =====

    # create blocks until deposit expired
    while util.api("mpc_deposit_ttl", {"state": alice_state}) > 0:
        recoverables = util.api("mpc_recoverables", {"state": alice_state})
        assert(len(recoverables["expire"]) == 0)
        util_test.create_next_block(server_db)

    # ===== PAYER RECOVERS EXPIRED DEPOSIT =====

    # sign and publish expire recover transaction
    recoverables = util.api("mpc_recoverables", {"state": alice_state})
    for expire in recoverables["expire"]:
        signed_expire_rawtx = scripts.sign_expire_recover(
            get_txs,
            mpcenv["alice_wif"],
            expire["expire_rawtx"],
            expire["deposit_script"]
        )
        util_test.insert_raw_transaction(signed_expire_rawtx, server_db)

    # ckech funds recovered from deposit p2sh address
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    assert alice_balance == 1000000
    assert deposit_balance == 0

    # deposit p2sh should have two transaction (fund and expire recover)
    deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(deposit_transactions) == 2


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_expire_recover_vs_funding_attack_xcp(server_db, mpcenv):

    # Send dust to deposit address in attempt to trip up lib:
    # a) try recover expire with unexpired utxo (non-BIP68-final backend error)
    # b) not be able to recover expired funds due to newer dust utxos

    # check initial balances
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    assert alice_balance == 1000000
    assert deposit_balance == 0

    # ===== PAYER CREATES DEPOSIT TX =====

    deposit_quantity = 41
    result = util.api(
        method="mpc_make_deposit",
        params={
            "asset": "XCP",
            "payer_pubkey": mpcenv["alice_pubkey"],
            "payee_pubkey": mpcenv["bob_pubkey"],
            "spend_secret_hash": mpcenv["spend_secret_hash"],
            "expire_time": mpcenv["deposit_expire_time"],  # in blocks
            "quantity": deposit_quantity  # in satoshis
        }
    )
    alice_state = result["state"]
    deposit_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                         result["topublish"])

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    util_test.insert_raw_transaction(deposit_rawtx, server_db)

    # check funds moved to deposit p2sh address
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    assert alice_balance == 1000000 - deposit_quantity
    assert deposit_balance == deposit_quantity

    assert util.api("mpc_deposit_ttl", {"state": alice_state}) == 41

    # ===== LET DEPOSIT EXPIRE =====

    # create blocks until deposit expired
    while util.api("mpc_deposit_ttl", {"state": alice_state}) > 0:
        recoverables = util.api("mpc_recoverables", {"state": alice_state})
        assert(len(recoverables["expire"]) == 0)
        util_test.create_next_block(server_db)

    # ===== SEND DUST TO ADDRESS =====

    dust_quantity = 13
    rawtx = util.api("create_send", {
        "source": mpcenv["alice_address"],
        "destination": mpcenv["deposit_address"],
        "quantity": dust_quantity,
        "asset": "XCP",
        "disable_utxo_locks": True
    })
    util_test.insert_raw_transaction(rawtx, server_db)

    # ===== PAYER RECOVERS EXPIRED DEPOSIT =====

    # sign and publish expire recover transaction
    recoverables = util.api("mpc_recoverables", {"state": alice_state})
    expire = recoverables["expire"][0]
    signed_expire_rawtx = scripts.sign_expire_recover(
        get_txs,
        mpcenv["alice_wif"],
        expire["expire_rawtx"],
        expire["deposit_script"]
    )
    util_test.insert_raw_transaction(signed_expire_rawtx, server_db)

    # deposit address has (fund, dust and expire recover)
    deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(deposit_transactions) == 3

    # ckech funds recovered from deposit p2sh address
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    assert alice_balance == 1000000
    assert deposit_balance == 0
    asset_balance, btc_balance, utxos = get_spendable(
        dispatcher, mpcenv["deposit_address"], mpcenv["asset"]
    )
    assert asset_balance == 0
    assert btc_balance != 0  # dust output
    assert len(utxos) != 0  # dust utxo


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_expire_recover_btc(server_db, mpcenv):
    pass  # TODO test


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_expire_recover_suboptimal_fee_xcp(server_db, mpcenv):

    # check initial balances
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    assert alice_balance == 1000000
    assert deposit_balance == 0

    # fund deposit with suboptimal recover fee
    quantity = 42
    rawtx = util.api("create_send", {
        "source": mpcenv["alice_address"],
        "destination": mpcenv["deposit_address"],
        "quantity": quantity,
        "regular_dust_size": config.DEFAULT_REGULAR_DUST_SIZE + 1,
        "asset": "XCP",
        "disable_utxo_locks": True
    })
    util_test.insert_raw_transaction(rawtx, server_db)

    # check balances after fund
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    assert alice_balance == 1000000 - quantity
    assert deposit_balance == quantity

    # let deposit expire
    for i in range(mpcenv["deposit_expire_time"]):
        util_test.create_next_block(server_db)

    # sign and publish expire recover transaction
    alice_state = {
        "asset": mpcenv["asset"],
        "deposit_script": mpcenv["deposit_script"],
        "commits_requested": [],
        "commits_active": [],
        "commits_revoked": []
    }
    recoverables = util.api("mpc_recoverables", {"state": alice_state})
    assert len(recoverables["expire"]) == 1
    expire = recoverables["expire"][0]
    signed_expire_rawtx = scripts.sign_expire_recover(
        get_txs,
        mpcenv["alice_wif"],
        expire["expire_rawtx"],
        expire["deposit_script"]
    )
    util_test.insert_raw_transaction(signed_expire_rawtx, server_db)

    # check balances after recover
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    assert alice_balance == 1000000
    assert deposit_balance == 0
