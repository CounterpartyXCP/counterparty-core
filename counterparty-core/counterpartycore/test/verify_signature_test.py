import os

from counterpartycore.lib.bootstrap import verify_signature


def test_verify_signature():
    dir = os.path.dirname(os.path.abspath(__file__))
    public_key_path = os.path.join(dir, "fixtures", "test_public_key.asc")
    signature_path = os.path.join(dir, "fixtures", "test_snapshot.sig")
    snapshot_path = os.path.join(dir, "fixtures", "test_snapshot.tar.gz")
    other_path = os.path.join(dir, "fixtures", "rawtransactions.db")
    with open(public_key_path, "rb") as f:
        public_key_data = f.read()

    assert verify_signature(public_key_data, signature_path, snapshot_path)
    assert not verify_signature(public_key_data, signature_path, other_path)
