import os
import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.lib import util
from micropayment_core.util import b2h
from micropayment_core.util import hash160hex
from micropayment_core import scripts


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


def get_txs(txids):
    return util.api(
        method="getrawtransaction_batch", params={"txhash_list": txids}
    )


def assert_transferred(payer, payee, quantity):
    assert util.api("mpc_transferred_amount", {"state": payer}) == quantity
    assert util.api("mpc_transferred_amount", {"state": payee}) == quantity


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_dont_surpass_xcp(server_db, mpcenv):

    # check initial balances
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    bob_balance = util.get_balance(server_db, mpcenv["bob_address"],
                                   mpcenv["asset"])
    assert alice_balance == 1000000
    assert deposit_balance == 0
    assert bob_balance == 1000000

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
    deposit_rawtx = result["topublish"]
    deposit_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                         result["topublish"])

    # ===== PAYEE SETS DEPOSIT =====

    bob_state = util.api("mpc_set_deposit", {
        "asset": "XCP",
        "deposit_script": mpcenv["deposit_script"],
        "expected_payee_pubkey": mpcenv["bob_pubkey"],
        "expected_spend_secret_hash": mpcenv["spend_secret_hash"]
    })

    assert util.api("mpc_highest_commit", {"state": bob_state}) is None
    assert util.api("mpc_deposit_ttl", {"state": bob_state}) is None

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    before_deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(before_deposit_transactions) == 0

    # insert send, this automatically also creates a block
    util_test.insert_raw_transaction(deposit_rawtx, server_db)

    # check balances after send to deposit
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    bob_balance = util.get_balance(server_db, mpcenv["bob_address"],
                                   mpcenv["asset"])
    assert alice_balance == 1000000 - deposit_quantity
    assert deposit_balance == deposit_quantity
    assert bob_balance == 1000000
    assert util.api("mpc_deposit_ttl", {"state": bob_state}) == 41

    after_deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(after_deposit_transactions) == 1

    # ===== TRANSFER MICRO PAYMENTS =====

    assert_transferred(alice_state, bob_state, 0)

    revoke_secrets = {}
    for transfer_quantity in [1, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41]:

        # ===== PAYEE REQUESTS COMMIT =====

        revoke_secret = b2h(os.urandom(32))
        revoke_secret_hash = hash160hex(revoke_secret)
        revoke_secrets[revoke_secret_hash] = revoke_secret
        bob_state = util.api("mpc_request_commit", {
            "state": bob_state,
            "quantity": transfer_quantity,
            "revoke_secret_hash": revoke_secret_hash
        })

        # ===== PAYER CREATES COMMIT =====

        result = util.api("mpc_create_commit", {
            "state": alice_state,
            "quantity": transfer_quantity,
            "revoke_secret_hash": revoke_secret_hash,
            "delay_time": mpcenv["delay_time"]
        })
        alice_state = result["state"]
        commit_script = result["commit_script"]
        commit_rawtx = result["tosign"]["commit_rawtx"]
        deposit_script = result["tosign"]["deposit_script"]
        signed_commit_rawtx = scripts.sign_created_commit(
            get_txs, mpcenv["alice_wif"], commit_rawtx, deposit_script
        )

        # ===== PAYEE UPDATES STATE =====

        bob_state = util.api("mpc_add_commit", {
            "state": bob_state,
            "commit_rawtx": signed_commit_rawtx,
            "commit_script": commit_script,
        })
        assert_transferred(alice_state, bob_state, transfer_quantity)

    # ===== PAYEE RETURNS FUNDS =====

    # get secrets to revoke
    revoke_hashes = util.api("mpc_revoke_hashes_until", {
        "state": bob_state, "quantity": 15, "surpass": False,
    })
    secrets = [v for k, v in revoke_secrets.items() if k in revoke_hashes]
    assert len(secrets) == 6

    # payee revokes commits
    bob_state = util.api("mpc_revoke_all", {
        "state": bob_state, "secrets": secrets,
    })

    # payer revokes commits
    alice_state = util.api("mpc_revoke_all", {
        "state": alice_state, "secrets": secrets,
    })
    assert_transferred(alice_state, bob_state, 17)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_do_surpass_xcp(server_db, mpcenv):

    # check initial balances
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    bob_balance = util.get_balance(server_db, mpcenv["bob_address"],
                                   mpcenv["asset"])
    assert alice_balance == 1000000
    assert deposit_balance == 0
    assert bob_balance == 1000000

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
    deposit_rawtx = result["topublish"]
    deposit_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                         result["topublish"])

    # ===== PAYEE SETS DEPOSIT =====

    bob_state = util.api("mpc_set_deposit", {
        "asset": "XCP",
        "deposit_script": mpcenv["deposit_script"],
        "expected_payee_pubkey": mpcenv["bob_pubkey"],
        "expected_spend_secret_hash": mpcenv["spend_secret_hash"]
    })

    assert util.api("mpc_highest_commit", {"state": bob_state}) is None
    assert util.api("mpc_deposit_ttl", {"state": bob_state}) is None

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    before_deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(before_deposit_transactions) == 0

    # insert send, this automatically also creates a block
    util_test.insert_raw_transaction(deposit_rawtx, server_db)

    # check balances after send to deposit
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    bob_balance = util.get_balance(server_db, mpcenv["bob_address"],
                                   mpcenv["asset"])
    assert alice_balance == 1000000 - deposit_quantity
    assert deposit_balance == deposit_quantity
    assert bob_balance == 1000000
    assert util.api("mpc_deposit_ttl", {"state": bob_state}) == 41

    after_deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(after_deposit_transactions) == 1

    # ===== TRANSFER MICRO PAYMENTS =====

    assert_transferred(alice_state, bob_state, 0)

    revoke_secrets = {}
    for transfer_quantity in [1, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41]:

        # ===== PAYEE REQUESTS COMMIT =====

        revoke_secret = b2h(os.urandom(32))
        revoke_secret_hash = hash160hex(revoke_secret)
        revoke_secrets[revoke_secret_hash] = revoke_secret
        bob_state = util.api("mpc_request_commit", {
            "state": bob_state,
            "quantity": transfer_quantity,
            "revoke_secret_hash": revoke_secret_hash
        })

        # ===== PAYER CREATES COMMIT =====

        result = util.api("mpc_create_commit", {
            "state": alice_state,
            "quantity": transfer_quantity,
            "revoke_secret_hash": revoke_secret_hash,
            "delay_time": mpcenv["delay_time"]
        })
        alice_state = result["state"]
        commit_script = result["commit_script"]
        commit_rawtx = result["tosign"]["commit_rawtx"]
        deposit_script = result["tosign"]["deposit_script"]
        signed_commit_rawtx = scripts.sign_created_commit(
            get_txs, mpcenv["alice_wif"], commit_rawtx, deposit_script
        )

        # ===== PAYEE UPDATES STATE =====

        bob_state = util.api("mpc_add_commit", {
            "state": bob_state,
            "commit_rawtx": signed_commit_rawtx,
            "commit_script": commit_script,
        })
        assert_transferred(alice_state, bob_state, transfer_quantity)

    # ===== PAYEE RETURNS FUNDS =====

    # get secrets to revoke
    revoke_hashes = util.api("mpc_revoke_hashes_until", {
        "state": bob_state, "quantity": 15, "surpass": True,
    })
    secrets = [v for k, v in revoke_secrets.items() if k in revoke_hashes]
    assert len(secrets) == 7

    # payee revokes commits
    bob_state = util.api("mpc_revoke_all", {
        "state": bob_state, "secrets": secrets,
    })

    # payer revokes commits
    alice_state = util.api("mpc_revoke_all", {
        "state": alice_state, "secrets": secrets,
    })
    assert_transferred(alice_state, bob_state, 13)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_exact_match_xcp(server_db, mpcenv):

    # check initial balances
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    bob_balance = util.get_balance(server_db, mpcenv["bob_address"],
                                   mpcenv["asset"])
    assert alice_balance == 1000000
    assert deposit_balance == 0
    assert bob_balance == 1000000

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
    deposit_rawtx = result["topublish"]
    deposit_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                         result["topublish"])

    # ===== PAYEE SETS DEPOSIT =====

    bob_state = util.api("mpc_set_deposit", {
        "asset": "XCP",
        "deposit_script": mpcenv["deposit_script"],
        "expected_payee_pubkey": mpcenv["bob_pubkey"],
        "expected_spend_secret_hash": mpcenv["spend_secret_hash"]
    })

    assert util.api("mpc_highest_commit", {"state": bob_state}) is None
    assert util.api("mpc_deposit_ttl", {"state": bob_state}) is None

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    before_deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(before_deposit_transactions) == 0

    # insert send, this automatically also creates a block
    util_test.insert_raw_transaction(deposit_rawtx, server_db)

    # check balances after send to deposit
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    bob_balance = util.get_balance(server_db, mpcenv["bob_address"],
                                   mpcenv["asset"])
    assert alice_balance == 1000000 - deposit_quantity
    assert deposit_balance == deposit_quantity
    assert bob_balance == 1000000
    assert util.api("mpc_deposit_ttl", {"state": bob_state}) == 41

    after_deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(after_deposit_transactions) == 1

    # ===== TRANSFER MICRO PAYMENTS =====

    assert_transferred(alice_state, bob_state, 0)

    revoke_secrets = {}
    for transfer_quantity in [1, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41]:

        # ===== PAYEE REQUESTS COMMIT =====

        revoke_secret = b2h(os.urandom(32))
        revoke_secret_hash = hash160hex(revoke_secret)
        revoke_secrets[revoke_secret_hash] = revoke_secret
        bob_state = util.api("mpc_request_commit", {
            "state": bob_state,
            "quantity": transfer_quantity,
            "revoke_secret_hash": revoke_secret_hash
        })

        # ===== PAYER CREATES COMMIT =====

        result = util.api("mpc_create_commit", {
            "state": alice_state,
            "quantity": transfer_quantity,
            "revoke_secret_hash": revoke_secret_hash,
            "delay_time": mpcenv["delay_time"]
        })
        alice_state = result["state"]
        commit_script = result["commit_script"]
        commit_rawtx = result["tosign"]["commit_rawtx"]
        deposit_script = result["tosign"]["deposit_script"]
        signed_commit_rawtx = scripts.sign_created_commit(
            get_txs, mpcenv["alice_wif"], commit_rawtx, deposit_script
        )

        # ===== PAYEE UPDATES STATE =====

        bob_state = util.api("mpc_add_commit", {
            "state": bob_state,
            "commit_rawtx": signed_commit_rawtx,
            "commit_script": commit_script,
        })
        assert_transferred(alice_state, bob_state, transfer_quantity)

    # ===== PAYEE RETURNS FUNDS =====

    # get secrets to revoke
    revoke_hashes = util.api("mpc_revoke_hashes_until", {
        "state": bob_state, "quantity": 31, "surpass": False,
    })
    secrets = [v for k, v in revoke_secrets.items() if k in revoke_hashes]
    assert len(secrets) == 2

    # payee revokes commits
    bob_state = util.api("mpc_revoke_all", {
        "state": bob_state, "secrets": secrets,
    })

    # payer revokes commits
    alice_state = util.api("mpc_revoke_all", {
        "state": alice_state, "secrets": secrets,
    })
    assert_transferred(alice_state, bob_state, 31)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_zero_xcp(server_db, mpcenv):

    # check initial balances
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    bob_balance = util.get_balance(server_db, mpcenv["bob_address"],
                                   mpcenv["asset"])
    assert alice_balance == 1000000
    assert deposit_balance == 0
    assert bob_balance == 1000000

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
    deposit_rawtx = result["topublish"]
    deposit_rawtx = scripts.sign_deposit(get_txs, mpcenv["alice_wif"],
                                         result["topublish"])

    # ===== PAYEE SETS DEPOSIT =====

    bob_state = util.api("mpc_set_deposit", {
        "asset": "XCP",
        "deposit_script": mpcenv["deposit_script"],
        "expected_payee_pubkey": mpcenv["bob_pubkey"],
        "expected_spend_secret_hash": mpcenv["spend_secret_hash"]
    })

    assert util.api("mpc_highest_commit", {"state": bob_state}) is None
    assert util.api("mpc_deposit_ttl", {"state": bob_state}) is None

    # ===== PAYER PUBLISHES DEPOSIT TX =====

    before_deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(before_deposit_transactions) == 0

    # insert send, this automatically also creates a block
    util_test.insert_raw_transaction(deposit_rawtx, server_db)

    # check balances after send to deposit
    alice_balance = util.get_balance(server_db, mpcenv["alice_address"],
                                     mpcenv["asset"])
    deposit_balance = util.get_balance(server_db, mpcenv["deposit_address"],
                                       mpcenv["asset"])
    bob_balance = util.get_balance(server_db, mpcenv["bob_address"],
                                   mpcenv["asset"])
    assert alice_balance == 1000000 - deposit_quantity
    assert deposit_balance == deposit_quantity
    assert bob_balance == 1000000
    assert util.api("mpc_deposit_ttl", {"state": bob_state}) == 41

    after_deposit_transactions = util.api(
        method="search_raw_transactions",
        params={"address": mpcenv["deposit_address"], "unconfirmed": False}
    )
    assert len(after_deposit_transactions) == 1

    # ===== TRANSFER MICRO PAYMENTS =====

    assert_transferred(alice_state, bob_state, 0)

    revoke_secrets = {}
    for transfer_quantity in [1, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41]:

        # ===== PAYEE REQUESTS COMMIT =====

        revoke_secret = b2h(os.urandom(32))
        revoke_secret_hash = hash160hex(revoke_secret)
        revoke_secrets[revoke_secret_hash] = revoke_secret
        bob_state = util.api("mpc_request_commit", {
            "state": bob_state,
            "quantity": transfer_quantity,
            "revoke_secret_hash": revoke_secret_hash
        })

        # ===== PAYER CREATES COMMIT =====

        result = util.api("mpc_create_commit", {
            "state": alice_state,
            "quantity": transfer_quantity,
            "revoke_secret_hash": revoke_secret_hash,
            "delay_time": mpcenv["delay_time"]
        })
        alice_state = result["state"]
        commit_script = result["commit_script"]
        commit_rawtx = result["tosign"]["commit_rawtx"]
        deposit_script = result["tosign"]["deposit_script"]
        signed_commit_rawtx = scripts.sign_created_commit(
            get_txs, mpcenv["alice_wif"], commit_rawtx, deposit_script
        )

        # ===== PAYEE UPDATES STATE =====

        bob_state = util.api("mpc_add_commit", {
            "state": bob_state,
            "commit_rawtx": signed_commit_rawtx,
            "commit_script": commit_script,
        })
        assert_transferred(alice_state, bob_state, transfer_quantity)

    # ===== PAYEE RETURNS FUNDS =====

    # get secrets to revoke
    revoke_hashes = util.api("mpc_revoke_hashes_until", {
        "state": bob_state, "quantity": 0, "surpass": False,
    })
    secrets = [v for k, v in revoke_secrets.items() if k in revoke_hashes]
    assert len(secrets) == 13

    # payee revokes commits
    bob_state = util.api("mpc_revoke_all", {
        "state": bob_state, "secrets": secrets,
    })

    # payer revokes commits
    alice_state = util.api("mpc_revoke_all", {
        "state": alice_state, "secrets": secrets,
    })
    assert_transferred(alice_state, bob_state, 0)


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_usage_btc(server_db, mpcenv):
    pass
