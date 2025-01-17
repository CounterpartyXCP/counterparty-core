from counterpartycore.lib import exceptions


def is_multisig(address):
    """Check if the address is multi-signature."""
    array = address.split("_")
    return len(array) > 1


def test_array(signatures_required, pubs, signatures_possible):
    """Check if multi-signature data is valid."""
    try:
        signatures_required, signatures_possible = (
            int(signatures_required),
            int(signatures_possible),
        )
    except (ValueError, TypeError):
        raise exceptions.MultiSigAddressError("Signature values not integers.")  # noqa: B904
    if signatures_required < 1 or signatures_required > 3:
        raise exceptions.MultiSigAddressError("Invalid signatures_required.")
    if signatures_possible < 2 or signatures_possible > 3:
        raise exceptions.MultiSigAddressError("Invalid signatures_possible.")
    for pubkey in pubs:
        if "_" in pubkey:
            raise exceptions.MultiSigAddressError("Invalid characters in pubkeys/pubkeyhashes.")
    if signatures_possible != len(pubs):
        raise exceptions.InputError(
            "Incorrect number of pubkeys/pubkeyhashes in multi-signature address."
        )


def construct_array(signatures_required, pubs, signatures_possible):
    """Create a multi-signature address."""
    test_array(signatures_required, pubs, signatures_possible)
    address = "_".join([str(signatures_required)] + sorted(pubs) + [str(signatures_possible)])
    return address


def extract_array(address):
    """Extract data from multi-signature address."""
    assert is_multisig(address)
    array = address.split("_")
    signatures_required, pubs, signatures_possible = array[0], sorted(array[1:-1]), array[-1]
    test_array(signatures_required, pubs, signatures_possible)
    return int(signatures_required), pubs, int(signatures_possible)
