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
from counterpartylib.lib.micropayments import validate
from counterpartylib.lib.api import dispatcher
from micropayment_core.keys import generate_wif
from micropayment_core.scripts import compile_deposit_script
from micropayment_core.scripts import compile_commit_script
from micropayment_core.scripts import InvalidScript


FIXTURE_SQL_FILE = CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql'
FIXTURE_DB = tempfile.gettempdir() + '/fixtures.unittest_fixture.db'


ALICE_WIF = DP["addresses"][0][2]
ALICE_PUBKEY = pubkey_from_wif(ALICE_WIF)
ALICE_ADDRESS = address_from_wif(ALICE_WIF)
BOB_WIF = generate_wif(netcode="XTN")
BOB_PUBKEY = pubkey_from_wif(BOB_WIF)
BOB_ADDRESS = address_from_wif(BOB_WIF)
SPEND_SECRET_HASH = "a7ec62542b0d393d43442aadf8d55f7da1e303cb"
DEPOSIT_SCRIPT = compile_deposit_script(
    ALICE_PUBKEY, BOB_PUBKEY, SPEND_SECRET_HASH, 42
)


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


def test_pubkey():

    # valid pubkey
    validate.pubkey(ALICE_PUBKEY)

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


def test_deposit_script():

    # valid deposit script
    validate.deposit_script(DEPOSIT_SCRIPT, BOB_PUBKEY, SPEND_SECRET_HASH)

    # validates opcodes match
    try:
        validate.deposit_script("ab" + DEPOSIT_SCRIPT,
                                BOB_PUBKEY, SPEND_SECRET_HASH)
        assert False
    except InvalidScript:
        pass
    try:
        validate.deposit_script(DEPOSIT_SCRIPT + "ab",
                                BOB_PUBKEY, SPEND_SECRET_HASH)
        assert False
    except InvalidScript:
        pass

    # spend secret mismatch
    try:
        validate.deposit_script(DEPOSIT_SCRIPT, BOB_PUBKEY, "a" * 40)
        assert False
    except exceptions.IncorrectSpendSecretHash:
        pass

    # payee pubkey mismatch
    try:
        validate.deposit_script(
            DEPOSIT_SCRIPT, ALICE_PUBKEY, SPEND_SECRET_HASH
        )
        assert False
    except exceptions.IncorrectPubKey:
        pass


def test_commit_script():

    # valid commit script
    commit_script = compile_commit_script(
        ALICE_PUBKEY, BOB_PUBKEY, SPEND_SECRET_HASH, "a" * 40, 5
    )
    validate.commit_script(commit_script, DEPOSIT_SCRIPT)

    # validates opcodes match
    try:
        commit_script = compile_commit_script(
            ALICE_PUBKEY, BOB_PUBKEY, SPEND_SECRET_HASH, "a" * 40, 5
        )
        validate.commit_script("ab" + commit_script, DEPOSIT_SCRIPT)
        assert False
    except InvalidScript:
        pass
    try:
        commit_script = compile_commit_script(
            ALICE_PUBKEY, BOB_PUBKEY, SPEND_SECRET_HASH, "a" * 40, 5
        )
        validate.commit_script(commit_script + "ab", DEPOSIT_SCRIPT)
        assert False
    except InvalidScript:
        pass

    # payee pubkey mismatch
    try:
        commit_script = compile_commit_script(
            ALICE_PUBKEY, ALICE_PUBKEY, SPEND_SECRET_HASH, "a" * 40, 5
        )
        validate.commit_script(commit_script, DEPOSIT_SCRIPT)
        assert False
    except exceptions.IncorrectPubKey:
        pass

    # payer pubkey mismatch
    try:
        commit_script = compile_commit_script(
            BOB_PUBKEY, BOB_PUBKEY, SPEND_SECRET_HASH, "a" * 40, 5
        )
        validate.commit_script(commit_script, DEPOSIT_SCRIPT)
        assert False
    except exceptions.IncorrectPubKey:
        pass

    # spend secret hash mismatch
    try:
        commit_script = compile_commit_script(
            ALICE_PUBKEY, BOB_PUBKEY, "b" * 40, "a" * 40, 5
        )
        validate.commit_script(commit_script, DEPOSIT_SCRIPT)
        assert False
    except exceptions.IncorrectSpendSecretHash:
        pass


@pytest.mark.usefixtures("server_db")
@pytest.mark.usefixtures("api_server")
def test_is_send_tx():
    rawtx = util.api('create_send', {
        'source': ALICE_ADDRESS,
        'destination': BOB_ADDRESS,
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
        validate.is_send_tx(dispatcher, rawtx, validate_signature=True)
        assert False
    except exceptions.InvalidSignature:
        pass
