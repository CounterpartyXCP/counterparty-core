import os
import sqlite3

import pytest
import pyzstd
from counterpartycore.lib import config
from counterpartycore.lib.cli import bootstrap
from counterpartycore.lib.cli.bootstrap import verify_signature


def test_verify_signature():
    dir = os.path.dirname(os.path.abspath(__file__))
    public_key_path = os.path.join(dir, "..", "..", "fixtures", "test_public_key.asc")
    signature_path = os.path.join(dir, "..", "..", "fixtures", "test_snapshot.sig")
    snapshot_path = os.path.join(dir, "..", "..", "fixtures", "test_snapshot.tar.gz")
    other_path = os.path.join(dir, "..", "..", "fixtures", "rawtransactions.db")
    with open(public_key_path, "rb") as f:
        public_key_data = f.read()

    assert verify_signature(public_key_data, signature_path, snapshot_path)
    assert not verify_signature(public_key_data, signature_path, other_path)


def test_generate_urls():
    counterparty_url = "https://example.com/counterparty.db.v11.2.0.zst"
    urls = bootstrap.generate_urls(counterparty_url)
    assert urls == [
        (
            "https://example.com/counterparty.db.v11.2.0.zst",
            "https://example.com/counterparty.db.v11.2.0.sig",
        ),
        (
            "https://example.com/state.db.v11.2.0.zst",
            "https://example.com/state.db.v11.2.0.sig",
        ),
    ]


# --- checkpoint_and_clean ---


def test_checkpoint_and_clean_removes_empty_sidecars(tmp_path):
    db_path = str(tmp_path / "counterparty.db")
    conn = sqlite3.connect(db_path)
    conn.execute("CREATE TABLE t (id INTEGER)")
    conn.commit()
    conn.close()
    # Plant empty -wal / -shm side-cars that should be removed.
    for ext in ["-wal", "-shm"]:
        open(db_path + ext, "wb").close()

    bootstrap.checkpoint_and_clean(db_path)

    assert os.path.exists(db_path)
    assert not os.path.exists(db_path + "-wal")
    assert not os.path.exists(db_path + "-shm")


def test_checkpoint_and_clean_raises_on_non_empty_wal(tmp_path, monkeypatch):
    db_path = str(tmp_path / "counterparty.db")
    open(db_path, "wb").close()
    # A non-empty WAL side-car that survives the checkpoint must abort the snapshot.
    with open(db_path + "-wal", "wb") as wal:
        wal.write(b"not empty")

    class DummyConn:
        def execute(self, *args, **kwargs):
            pass

        def commit(self):
            pass

        def close(self):
            pass

    # Stub the checkpoint so the planted (non-empty) WAL is left in place.
    monkeypatch.setattr(bootstrap.sqlite3, "connect", lambda *a, **k: DummyConn())

    with pytest.raises(RuntimeError, match="is not empty"):
        bootstrap.checkpoint_and_clean(db_path)


# --- compress_db ---


def test_compress_db_roundtrip(tmp_path):
    db_path = str(tmp_path / "counterparty.db")
    payload = b"counterparty" * 10_000
    with open(db_path, "wb") as f:
        f.write(payload)

    zst_path = bootstrap.compress_db(db_path, "v11.2.0", compression_level=1)

    assert zst_path == db_path + ".v11.2.0.zst"
    assert os.path.exists(zst_path)
    with open(zst_path, "rb") as f:
        assert pyzstd.decompress(f.read()) == payload


# --- verify_prepared_signature ---


def test_verify_prepared_signature_ok(tmp_path, monkeypatch, capsys):
    zst_path = str(tmp_path / "counterparty.db.v11.2.0.zst")
    sig_path = str(tmp_path / "counterparty.db.v11.2.0.sig")
    open(zst_path, "wb").close()
    open(sig_path, "wb").close()

    monkeypatch.setattr(bootstrap, "verify_signature", lambda *a, **k: True)

    # Returns without raising when a trusted key verifies the signature.
    assert bootstrap.verify_prepared_signature(zst_path, sig_path) is None
    assert "Signature OK" in capsys.readouterr().out


def test_verify_prepared_signature_raises(tmp_path, monkeypatch):
    zst_path = str(tmp_path / "counterparty.db.v11.2.0.zst")
    sig_path = str(tmp_path / "counterparty.db.v11.2.0.sig")
    open(zst_path, "wb").close()
    open(sig_path, "wb").close()

    monkeypatch.setattr(bootstrap, "verify_signature", lambda *a, **k: False)

    with pytest.raises(RuntimeError, match="not signed by any trusted key"):
        bootstrap.verify_prepared_signature(zst_path, sig_path)


# --- prepare_bootstrap ---


def test_prepare_bootstrap_no_db(tmp_path, monkeypatch):
    monkeypatch.setattr(config, "DATA_DIR", str(tmp_path))

    with pytest.raises(SystemExit) as exc:
        bootstrap.prepare_bootstrap()
    assert exc.value.code == 1


def test_prepare_bootstrap_happy_path(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(config, "DATA_DIR", str(tmp_path))
    monkeypatch.setattr(bootstrap, "BOOTSTRAP_NETWORKS", ["mainnet"])
    # Provide the two mainnet databases prepare_bootstrap looks for.
    for db_name in ["counterparty", "state"]:
        open(os.path.join(str(tmp_path), f"{db_name}.db"), "wb").close()

    calls = []
    monkeypatch.setattr(bootstrap, "checkpoint_and_clean", lambda db: calls.append(db))
    monkeypatch.setattr(bootstrap, "compress_db", lambda db, version, level=None: db + ".zst")
    monkeypatch.setattr(bootstrap, "sign_file", lambda zst, key: zst.replace(".zst", ".sig"))
    monkeypatch.setattr(bootstrap, "verify_prepared_signature", lambda zst, sig: None)

    bootstrap.prepare_bootstrap(signing_key="dev@counterparty.io", version="v11.2.0")

    assert len(calls) == 2
    assert "Prepared 2 snapshot(s)" in capsys.readouterr().out


# --- bootstrap (download) ---


def test_bootstrap_no_snapshot_for_network(monkeypatch):
    monkeypatch.setattr(bootstrap, "clean_data_dir", lambda data_dir: None)
    monkeypatch.setattr(config, "NETWORK_NAME", "unknownnet")
    monkeypatch.setattr(config, "BOOTSTRAP_URLS", {"mainnet": []})

    with pytest.raises(SystemExit) as exc:
        bootstrap.bootstrap(no_confirm=True)
    assert exc.value.code == 1
