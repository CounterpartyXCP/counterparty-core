import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.utils import multisig


def test_multisig_functions(defaults):
    assert not multisig.is_multisig(defaults["addresses"][0])

    assert multisig.is_multisig(f"1_{defaults['addresses'][0]}_{defaults['addresses'][1]}_2")

    assert (
        multisig.test_array(
            "1",
            [
                defaults["addresses"][1],
                defaults["addresses"][0],
            ],
            2,
        )
        is None
    )

    with pytest.raises(exceptions.MultiSigAddressError, match="Signature values not integers."):
        multisig.test_array(
            "Q",
            [
                defaults["addresses"][1],
                defaults["addresses"][0],
            ],
            2,
        )

    with pytest.raises(exceptions.MultiSigAddressError, match="Signature values not integers."):
        multisig.test_array(
            "1",
            [
                defaults["addresses"][1],
                defaults["addresses"][0],
            ],
            None,
        )

    with pytest.raises(exceptions.MultiSigAddressError, match="Invalid signatures_required."):
        multisig.test_array(
            "0",
            [
                defaults["addresses"][1],
                defaults["addresses"][0],
            ],
            2,
        )

    with pytest.raises(exceptions.MultiSigAddressError, match="Invalid signatures_required."):
        multisig.test_array(
            "4",
            [
                defaults["addresses"][1],
                defaults["addresses"][0],
            ],
            2,
        )

    with pytest.raises(exceptions.MultiSigAddressError, match="Invalid signatures_possible."):
        multisig.test_array(
            "1",
            [
                defaults["addresses"][1],
                defaults["addresses"][0],
            ],
            1,
        )

    with pytest.raises(exceptions.MultiSigAddressError, match="Invalid signatures_possible."):
        multisig.test_array(
            "2",
            [
                defaults["addresses"][1],
                defaults["addresses"][0],
            ],
            4,
        )

    with pytest.raises(
        exceptions.MultiSigAddressError, match="Invalid characters in pubkeys/pubkeyhashes."
    ):
        multisig.test_array(
            "1",
            [
                defaults["addresses"][1],
                f"{defaults['addresses'][0]}_2",
            ],
            2,
        )

    with pytest.raises(
        exceptions.InputError,
        match="Incorrect number of pubkeys/pubkeyhashes in multi-signature address.",
    ):
        multisig.test_array(
            "3",
            [
                defaults["addresses"][1],
                defaults["addresses"][0],
            ],
            3,
        )

    assert (
        multisig.construct_array(
            "1",
            [
                defaults["addresses"][1],
                defaults["addresses"][0],
            ],
            2,
        )
        == f"1_{defaults['addresses'][0]}_{defaults['addresses'][1]}_2"
    )

    assert multisig.extract_array(f"1_{defaults['addresses'][0]}_{defaults['addresses'][1]}_2") == (
        1,
        [
            defaults["addresses"][0],
            defaults["addresses"][1],
        ],
        2,
    )
