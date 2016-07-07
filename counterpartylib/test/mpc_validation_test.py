from counterpartylib.lib.micropayments import validate
from counterpartylib.lib.micropayments import exceptions
from counterpartylib.lib.micropayments.util import b2h
from counterpartylib.lib.micropayments.util import wif2pubkey
from counterpartylib.lib.micropayments.util import random_wif
from counterpartylib.lib.micropayments.scripts import compile_deposit_script
from counterpartylib.lib.micropayments.scripts import compile_commit_script


ALICE_WIF = random_wif(netcode="XTN")
ALICE_PUBKEY = wif2pubkey(ALICE_WIF)
BOB_WIF = random_wif(netcode="XTN")
BOB_PUBKEY = wif2pubkey(BOB_WIF)
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
    validate.deposit_script(b2h(DEPOSIT_SCRIPT), BOB_PUBKEY, SPEND_SECRET_HASH)

    # spend secret missmatch
    try:
        validate.deposit_script(b2h(DEPOSIT_SCRIPT), BOB_PUBKEY, "a" * 40)
        assert False
    except exceptions.IncorrectSpendSecretHash:
        pass

    # payee pubkey missmatch
    try:
        validate.deposit_script(
            b2h(DEPOSIT_SCRIPT), ALICE_PUBKEY, SPEND_SECRET_HASH
        )
        assert False
    except exceptions.IncorrectPubKey:
        pass

    # FIXME opcode missmatch


def test_commit_script():

    # valid commit script
    commit_script = compile_commit_script(
        ALICE_PUBKEY, BOB_PUBKEY, SPEND_SECRET_HASH, "a" * 40, 5
    )
    validate.commit_script(b2h(commit_script), b2h(DEPOSIT_SCRIPT))

    # FIXME validates opcodes match

    # payee pubkey missmatch
    try:
        commit_script = compile_commit_script(
            ALICE_PUBKEY, ALICE_PUBKEY, SPEND_SECRET_HASH, "a" * 40, 5
        )
        validate.commit_script(b2h(commit_script), b2h(DEPOSIT_SCRIPT))
        assert False
    except exceptions.IncorrectPubKey:
        pass

    # payer pubkey missmatch
    try:
        commit_script = compile_commit_script(
            BOB_PUBKEY, BOB_PUBKEY, SPEND_SECRET_HASH, "a" * 40, 5
        )
        validate.commit_script(b2h(commit_script), b2h(DEPOSIT_SCRIPT))
        assert False
    except exceptions.IncorrectPubKey:
        pass

    # spend secret hash missmatch
    try:
        commit_script = compile_commit_script(
            ALICE_PUBKEY, BOB_PUBKEY, "b" * 40, "a" * 40, 5
        )
        validate.commit_script(b2h(commit_script), b2h(DEPOSIT_SCRIPT))
        assert False
    except exceptions.IncorrectSpendSecretHash:
        pass


def test_state():
    pass
