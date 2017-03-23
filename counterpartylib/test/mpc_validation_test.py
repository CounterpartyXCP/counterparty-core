import tempfile
import pytest

# this is require near the top to do setup of the test suite
# from counterpartylib.test import conftest

from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.lib import util
from counterpartylib.lib.micropayments import exceptions
from counterpartylib.lib.micropayments import validate
from counterpartylib.lib.api import dispatcher
from micropayment_core.scripts import compile_commit_script
from micropayment_core.scripts import InvalidScript


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


def test_is_string():

    # valid string
    validate.is_string("valid string")

    # invalid type
    try:
        validate.is_string(None)
        assert False
    except exceptions.InvalidString:
        pass


def test_is_hex():

    # valid hex
    validate.is_hex("f483")

    # invalid (non hex)
    try:
        validate.is_hex("xy")
        assert False
    except exceptions.InvalidHexData:
        pass

    # invalid (uneven length)
    try:
        validate.is_hex("abc")
        assert False
    except exceptions.InvalidHexData:
        pass


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_pubkey(server_db, mpcenv):

    # valid pubkey
    validate.pubkey(mpcenv["alice_pubkey"])

    # invalid (> 33 bytes)
    try:
        validate.pubkey("a" * 68)
        assert False
    except exceptions.InvalidPubKey:
        pass

    # invalid (< 33 bytes)
    try:
        validate.pubkey("a" * 64)
        assert False
    except exceptions.InvalidPubKey:
        pass


def test_hash160():

    # valid hash160
    validate.hash160("42" * 20)

    # invalid (< 20 bytes)
    try:
        validate.hash160("42" * 19)
        assert False
    except exceptions.InvalidHash160:
        pass

    # invalid (> 20 bytes)
    try:
        validate.hash160("42" * 21)
        assert False
    except exceptions.InvalidHash160:
        pass


def test_is_integer():

    # valid integer
    validate.is_integer(42)

    # invalid type
    try:
        validate.is_integer(4.2)
        assert False
    except exceptions.InvalidInteger:
        pass


def test_is_list():

    # valid list
    validate.is_list([])
    validate.is_list([0, 1, 2])

    # invalid type
    try:
        validate.is_list(None)
        assert False
    except exceptions.InvalidList:
        pass


def test_is_unsigned():

    # valid unsigned
    validate.is_unsigned(0)
    validate.is_unsigned(1)

    # invalid type
    try:
        validate.is_unsigned(-1)
        assert False
    except exceptions.InvalidUnsigned:
        pass


def test_is_sequence():

    # valid sequence
    validate.is_sequence(0)  # min
    validate.is_sequence(0x0000FFFF)  # max

    # invalid (> max)
    try:
        validate.is_sequence(0x0000FFFF + 1)
        assert False
    except exceptions.InvalidSequence:
        pass


def test_quantity():

    # valid quantity
    validate.is_quantity(42)

    # invalid (< min)
    try:
        validate.is_quantity(0)
        assert False
    except exceptions.InvalidQuantity:
        pass

    # invalid (> max)
    try:
        validate.is_quantity(2100000000000001)
        assert False
    except exceptions.InvalidQuantity:
        pass


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_deposit_script(server_db, mpcenv):

    # valid deposit script
    validate.deposit_script(mpcenv["deposit_script"], mpcenv["bob_pubkey"],
                            mpcenv["spend_secret_hash"])

    # validates opcodes match
    try:
        validate.deposit_script("ab" + mpcenv["deposit_script"],
                                mpcenv["bob_pubkey"],
                                mpcenv["spend_secret_hash"])
        assert False
    except InvalidScript:
        pass
    try:
        validate.deposit_script(mpcenv["deposit_script"] + "ab",
                                mpcenv["bob_pubkey"],
                                mpcenv["spend_secret_hash"])
        assert False
    except InvalidScript:
        pass

    # spend secret mismatch
    try:
        validate.deposit_script(mpcenv["deposit_script"],
                                mpcenv["bob_pubkey"], "a" * 40)
        assert False
    except exceptions.IncorrectSpendSecretHash:
        pass

    # payee pubkey mismatch
    try:
        validate.deposit_script(
            mpcenv["deposit_script"], mpcenv["alice_pubkey"],
            mpcenv["spend_secret_hash"]
        )
        assert False
    except exceptions.IncorrectPubKey:
        pass


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_commit_script(server_db, mpcenv):

    # valid commit script
    commit_script = compile_commit_script(
        mpcenv["alice_pubkey"], mpcenv["bob_pubkey"],
        mpcenv["spend_secret_hash"], "a" * 40, 5
    )
    validate.commit_script(commit_script, mpcenv["deposit_script"])

    # validates opcodes match
    try:
        commit_script = compile_commit_script(
            mpcenv["alice_pubkey"], mpcenv["bob_pubkey"],
            mpcenv["spend_secret_hash"], "a" * 40, 5
        )
        validate.commit_script("ab" + commit_script, mpcenv["deposit_script"])
        assert False
    except InvalidScript:
        pass
    try:
        commit_script = compile_commit_script(
            mpcenv["alice_pubkey"], mpcenv["bob_pubkey"],
            mpcenv["spend_secret_hash"], "a" * 40, 5
        )
        validate.commit_script(commit_script + "ab", mpcenv["deposit_script"])
        assert False
    except InvalidScript:
        pass

    # payee pubkey mismatch
    try:
        commit_script = compile_commit_script(
            mpcenv["alice_pubkey"], mpcenv["alice_pubkey"],
            mpcenv["spend_secret_hash"], "a" * 40, 5
        )
        validate.commit_script(commit_script, mpcenv["deposit_script"])
        assert False
    except exceptions.IncorrectPubKey:
        pass

    # payer pubkey mismatch
    try:
        commit_script = compile_commit_script(
            mpcenv["bob_pubkey"], mpcenv["bob_pubkey"],
            mpcenv["spend_secret_hash"], "a" * 40, 5
        )
        validate.commit_script(commit_script, mpcenv["deposit_script"])
        assert False
    except exceptions.IncorrectPubKey:
        pass

    # spend secret hash mismatch
    try:
        commit_script = compile_commit_script(
            mpcenv["alice_pubkey"], mpcenv["bob_pubkey"], "b" * 40, "a" * 40, 5
        )
        validate.commit_script(commit_script, mpcenv["deposit_script"])
        assert False
    except exceptions.IncorrectSpendSecretHash:
        pass


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_is_send_tx_no_cp(server_db, mpcenv):
    rawtx = util.api('create_send', {
        'source': mpcenv["alice_address"],
        'destination': mpcenv["bob_address"],
        'asset': 'BTC',
        'quantity': 10000
    })

    try:
        validate.is_send_tx(dispatcher, rawtx)
        assert False
    except ValueError:
        pass


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("mpcenv")
def test_is_send_tx(server_db, mpcenv):
    rawtx = util.api('create_send', {
        'source': mpcenv["alice_address"],
        'destination': mpcenv["bob_address"],
        'asset': 'XCP',
        'quantity': 33
    })

    try:
        validate.is_send_tx(dispatcher, rawtx, expected_dest="foo")
        assert False
    except exceptions.DestinationMissmatch:
        pass

    try:
        validate.is_send_tx(dispatcher, rawtx, expected_src="foo")
        assert False
    except exceptions.SourceMissmatch:
        pass

    try:
        validate.is_send_tx(
            dispatcher, rawtx, expected_asset="A18446744073709551615"
        )
        assert False
    except exceptions.AssetMissmatch:
        pass

    try:
        validate.is_send_tx(dispatcher, rawtx, validate_signature=True)
        assert False
    except exceptions.InvalidSignature:
        pass
