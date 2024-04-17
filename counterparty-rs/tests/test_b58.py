import pytest
from counterparty_rs import b58  # noqa: F401


# TODO
def test_b58():
    assert b58.b58_encode(b"hello world") == "3vQB7B6MrGQZaxCuFg4oh"
    assert b58.b58_decode("3vQB7B6MrGQZaxCuFg4oh") == b"hello world"

    with pytest.raises(ValueError) as excinfo:
        b58.b58_decode("hello world")
    assert str(excinfo.value) == "Bad input"
