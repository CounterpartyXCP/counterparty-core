import getpass
import glob
import io
import os
import sqlite3
import subprocess  # nosec B404
import sys
import tempfile
import time
import urllib.request
from multiprocessing import Process, Value

import gnupg
import pyzstd
from termcolor import colored, cprint

from counterpartycore.lib import config
from counterpartycore.lib.cli.publickeys import PUBLIC_KEYS


def download_zst(data_dir, zst_url):
    print(f"Downloading {zst_url}...")
    start_time = time.time()
    zst_filename = os.path.basename(zst_url)
    zst_filepath = os.path.join(data_dir, zst_filename)
    urllib.request.urlretrieve(zst_url, zst_filepath)  # nosec B310  # noqa: S310
    print(f"Downloaded {zst_url} in {time.time() - start_time:.2f}s")
    assert os.path.exists(zst_filepath), f"Failed to download {zst_url}"
    return zst_filepath


def decompress_zst(zst_filepath):
    print(f"Decompressing {zst_filepath}...")
    start_time = time.time()
    version = (
        os.path.basename(zst_filepath)
        .replace("counterparty.db.", "")
        .replace("counterparty.testnet.db.", "")
        .replace("counterparty.testnet4.db.", "")
        .replace("counterparty.testnet3.db.", "")
        .replace("counterparty.signet.db.", "")
        .replace("state.db.", "")
        .replace("state.testnet.db.", "")
        .replace("state.testnet4.db.", "")
        .replace("state.testnet3.db.", "")
        .replace("state.signet.db.", "")
        .replace(".zst", "")
    )
    filename = zst_filepath.replace(f".{version}.zst", "")
    filepath = os.path.join(os.path.dirname(zst_filepath), filename)
    print(f"Decompressing {zst_filepath} to {filepath}...")
    # input_file_size = os.path.getsize(zst_filepath)
    with io.open(filepath, "wb") as output_file:
        with open(zst_filepath, "rb") as input_file:
            pyzstd.decompress_stream(input_file, output_file, read_size=16 * 1024)  # pylint: disable=no-member
    os.remove(zst_filepath)
    os.chmod(filepath, 0o660)  # nosec B103
    print(f"Decompressed {zst_filepath} in {time.time() - start_time:.2f}s")
    return filepath


def verify_signature(public_key_data, signature_path, snapshot_path):
    temp_dir = tempfile.mkdtemp()
    verified = False

    try:
        gpg = gnupg.GPG(gnupghome=temp_dir)
        gpg.import_keys(public_key_data)
        with open(signature_path, "rb") as s:
            verified = gpg.verify_file(s, snapshot_path, close_file=False)
    finally:
        pass

    return verified


def check_signature(filepath, sig_url):
    sig_filename = os.path.basename(sig_url)
    sig_filepath = os.path.join(tempfile.gettempdir(), sig_filename)
    urllib.request.urlretrieve(sig_url, sig_filepath)  # nosec B310  # noqa: S310

    print(f"Verifying signature for {filepath}...")
    start_time = time.time()
    signature_verified = False
    for key in PUBLIC_KEYS:
        if verify_signature(key, sig_filepath, filepath):
            signature_verified = True
            break
    os.remove(sig_filepath)
    print(f"Verified signature for {filepath} in {time.time() - start_time:.2f}s")

    if not signature_verified:
        print(f"{filepath} was not signed by any trusted keys, deleting...")
        os.remove(filepath)
        sys.exit(1)


def verify_and_decompress(zst_filepath, sig_url, decompressors_state):
    try:
        check_signature(zst_filepath, sig_url)
        decompress_zst(zst_filepath)
    except Exception as e:  # pylint: disable=broad-except
        cprint(f"Failed to verify and decompress {zst_filepath}: {e}", "red")
        decompressors_state.value = 1
        sys.exit(1)


def clean_data_dir(data_dir):
    if not os.path.exists(data_dir):
        os.makedirs(data_dir, mode=0o755)
        return
    network = "" if config.NETWORK_NAME == "mainnet" else f".{config.NETWORK_NAME}"
    files_to_delete = []
    for db_name in ["counterparty", "state"]:
        for ext in ["db", "db-wal", "db-shm"]:
            files_to_delete += glob.glob(os.path.join(data_dir, f"{db_name}{network}.{ext}"))
    for file in files_to_delete:
        os.remove(file)


def download_bootstrap_files(data_dir, files):
    decompressors = []
    decompressors_state = Value("i", 0)
    for zst_url, sig_url in files:
        # download .zst file
        try:
            zst_filepath = download_zst(data_dir, zst_url)
        except Exception as e:  # pylint: disable=broad-except
            cprint(f"Failed to download {zst_url}: {e}", "red")
            for decompressor in decompressors:
                decompressor.kill()
            sys.exit(1)

        decompressor = Process(
            target=verify_and_decompress,
            args=(zst_filepath, sig_url, decompressors_state),
        )
        decompressor.start()
        decompressors.append(decompressor)

    while True:
        # Check for failed processes by examining exit codes
        for decompressor in decompressors:
            decompressor.join(timeout=0)  # Non-blocking join to check if finished
            if decompressor.exitcode is not None and decompressor.exitcode != 0:
                cprint(
                    f"Decompression process failed with exit code {decompressor.exitcode}", "red"
                )
                for other_decompressor in decompressors:
                    if other_decompressor.is_alive():
                        other_decompressor.kill()
                sys.exit(1)

        # Check shared state as backup error detection mechanism
        if decompressors_state.value == 1:
            cprint("Failed to decompress and verify bootstrap files.", "red")
            for decompressor in decompressors:
                if decompressor.is_alive():
                    decompressor.kill()
            sys.exit(1)

        # Check if all processes are finished
        if not any(decompressor.is_alive() for decompressor in decompressors):
            break

        time.sleep(0.1)


def confirm_bootstrap():
    warning_message = """WARNING: `counterparty-server bootstrap` downloads a recent snapshot of a Counterparty database
from a centralized server maintained by the Counterparty Core development team.
Because this method does not involve verifying the history of Counterparty transactions yourself,
the `bootstrap` command should not be used for mission-critical, commercial or public-facing nodes.
        """
    cprint(warning_message, "yellow")

    confirmation_message = colored("Continue? (y/N): ", "magenta")
    if input(confirmation_message).lower() != "y":
        sys.exit(0)


def generate_urls(counterparty_zst_url):
    state_zst_url = counterparty_zst_url.replace("/counterparty.", "/state.")
    return [
        (
            counterparty_zst_url,
            counterparty_zst_url.replace(".zst", ".sig"),
        ),
        (
            state_zst_url,
            state_zst_url.replace(".zst", ".sig"),
        ),
    ]


def bootstrap(no_confirm=False, snapshot_url=None):
    if not no_confirm:
        confirm_bootstrap()

    start_time = time.time()

    clean_data_dir(config.DATA_DIR)

    if snapshot_url is None:
        if config.NETWORK_NAME not in config.BOOTSTRAP_URLS:
            cprint(
                f"No bootstrap snapshot is available for the '{config.NETWORK_NAME}' network. "
                "Use --bootstrap-url to provide one manually.",
                "red",
            )
            sys.exit(1)
        files = config.BOOTSTRAP_URLS[config.NETWORK_NAME]
    else:
        files = generate_urls(snapshot_url)

    download_bootstrap_files(config.DATA_DIR, files)

    cprint(
        f"Databases have been successfully bootstrapped to {config.DATA_DIR} in {time.time() - start_time:.2f}s.",
        "green",
    )


# --- Bootstrap preparation (snapshot -> checkpoint -> compress -> sign -> verify) ---

# Networks for which we prepare bootstrap snapshots from the local data dir.
# Kept in sync with the networks published in config.BOOTSTRAP_URLS so a prepared
# snapshot always has a matching download URL (and vice versa).
BOOTSTRAP_NETWORKS = list(config.BOOTSTRAP_URLS.keys())
# Default GnuPG local-user used to sign the snapshots (Counterparty Core primary key).
DEFAULT_SIGNING_KEY = "dev@counterparty.io"
# Default zstd compression level.
DEFAULT_COMPRESSION_LEVEL = 15


def checkpoint_and_clean(db_path):
    """Connect to the database to flush the WAL into the main file, then remove
    the (now empty) -wal / -shm side-car files so the snapshot is a single .db file."""
    print(f"Checkpointing {os.path.basename(db_path)}...")
    conn = sqlite3.connect(db_path)
    try:
        conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        conn.commit()
    finally:
        conn.close()

    for ext in ["-wal", "-shm"]:
        sidecar = db_path + ext
        if not os.path.exists(sidecar):
            continue
        size = os.path.getsize(sidecar)
        if size == 0:
            os.remove(sidecar)
            print(f"Removed empty {os.path.basename(sidecar)}")
        else:
            raise Exception(  # noqa: TRY002
                f"{os.path.basename(sidecar)} is not empty ({size} bytes) after checkpoint; "
                "refusing to snapshot a database with a non-empty WAL"
            )


def compress_db(db_path, version, compression_level=DEFAULT_COMPRESSION_LEVEL):
    zst_path = f"{db_path}.{version}.zst"
    print(f"Compressing {os.path.basename(db_path)} -> {os.path.basename(zst_path)}...")
    start_time = time.time()
    input_size = os.path.getsize(db_path)
    option = {
        pyzstd.CParameter.compressionLevel: compression_level,
        pyzstd.CParameter.nbWorkers: os.cpu_count() or 1,
    }
    with open(db_path, "rb") as input_file, io.open(zst_path, "wb") as output_file:
        pyzstd.compress_stream(  # pylint: disable=no-member
            input_file,
            output_file,
            level_or_option=option,
            pledged_input_size=input_size,
            read_size=1024 * 1024,
        )
    print(
        f"Compressed in {time.time() - start_time:.2f}s "
        f"({input_size} -> {os.path.getsize(zst_path)} bytes)"
    )
    return zst_path


def sign_file(zst_path, signing_key):
    sig_path = zst_path.replace(".zst", ".sig")
    if os.path.exists(sig_path):
        os.remove(sig_path)
    print(f"Signing {os.path.basename(zst_path)} with key '{signing_key}'...")
    command = [
        "gpg",
        "--batch",
        "--yes",
        "--local-user",
        signing_key,
        "--output",
        sig_path,
        "--detach-sign",
        zst_path,
    ]
    subprocess.run(command, check=True)  # noqa: S603  # nosec B603
    return sig_path


def verify_prepared_signature(zst_path, sig_path):
    print(f"Verifying signature for {os.path.basename(zst_path)}...")
    for key in PUBLIC_KEYS:
        if verify_signature(key, sig_path, zst_path):
            print(f"Signature OK: {os.path.basename(sig_path)}")
            return
    raise Exception(  # noqa: TRY002
        f"Signature verification FAILED for {os.path.basename(sig_path)}: "
        "not signed by any trusted key"
    )


def prepare_bootstrap(signing_key=None, version=None, compression_level=DEFAULT_COMPRESSION_LEVEL):
    signing_key = signing_key or DEFAULT_SIGNING_KEY
    version = version or config.BOOTSTRAP_VERSION
    data_dir = config.DATA_DIR
    start_time = time.time()

    cprint(
        f"Preparing bootstrap snapshots (version={version}) from {data_dir}",
        "cyan",
    )

    prepared = []
    for network in BOOTSTRAP_NETWORKS:
        suffix = "" if network == "mainnet" else f".{network}"
        for db_name in ["counterparty", "state"]:
            db_path = os.path.join(data_dir, f"{db_name}{suffix}.db")
            if not os.path.exists(db_path):
                cprint(f"  [{network}] {os.path.basename(db_path)} not found, skipping", "yellow")
                continue
            cprint(f"  [{network}] {os.path.basename(db_path)}", "cyan")
            checkpoint_and_clean(db_path)
            zst_path = compress_db(db_path, version, compression_level)
            sig_path = sign_file(zst_path, signing_key)
            verify_prepared_signature(zst_path, sig_path)
            prepared.append((zst_path, sig_path))

    if not prepared:
        cprint("No database found to prepare.", "red")
        sys.exit(1)

    cprint(f"\nPrepared {len(prepared)} snapshot(s) in {time.time() - start_time:.2f}s:", "green")
    for zst_path, sig_path in prepared:
        cprint(f"  {os.path.basename(zst_path)}  +  {os.path.basename(sig_path)}", "green")


# --- Bootstrap signing key backup / restore (password-protected, portable) ---

# Default file name for the password-protected key backup.
DEFAULT_KEY_BACKUP_FILENAME = "counterparty-bootstrap-signing-key.gpg"
PRIVATE_KEY_MARKER = "PGP PRIVATE KEY BLOCK"


def _run_gpg(args, input_bytes=None, passphrase=None):
    """Run gpg. When a passphrase is given it is passed through a dedicated pipe
    (never on the command line / never on disk) using loopback pinentry."""
    command = ["gpg", "--batch"]
    pass_read_fd = None
    pass_fds = ()
    if passphrase is not None:
        pass_read_fd, pass_write_fd = os.pipe()
        os.write(pass_write_fd, (passphrase + "\n").encode())
        os.close(pass_write_fd)
        command += ["--pinentry-mode", "loopback", "--passphrase-fd", str(pass_read_fd)]
        pass_fds = (pass_read_fd,)
    command += args
    try:
        result = subprocess.run(  # noqa: S603  # nosec B603
            command,
            input=input_bytes,
            capture_output=True,
            pass_fds=pass_fds,
            check=True,
        )
    finally:
        if pass_read_fd is not None:
            os.close(pass_read_fd)
    return result.stdout


def _prompt_new_passphrase():
    passphrase = getpass.getpass("Enter a password to protect the backup: ")
    if not passphrase:
        cprint("Password must not be empty.", "red")
        sys.exit(1)
    if passphrase != getpass.getpass("Confirm password: "):
        cprint("Passwords do not match.", "red")
        sys.exit(1)
    return passphrase


def backup_bootstrap_key(output_path=None, key=None):
    key = key or DEFAULT_SIGNING_KEY
    output_path = os.path.abspath(output_path or DEFAULT_KEY_BACKUP_FILENAME)

    # Export the (unprotected) secret key from the local keyring. Stays in memory only.
    exported = _run_gpg(["--export-secret-keys", "--armor", key])
    if not exported or PRIVATE_KEY_MARKER not in exported.decode(errors="ignore"):
        cprint(f"No secret key found for '{key}' in the local GnuPG keyring.", "red")
        sys.exit(1)

    passphrase = _prompt_new_passphrase()

    # Symmetric AES256 encryption of the secret key, protected by the password.
    encrypted = _run_gpg(
        ["--symmetric", "--cipher-algo", "AES256", "--armor"],
        input_bytes=exported,
        passphrase=passphrase,
    )
    with open(output_path, "wb") as output_file:
        output_file.write(encrypted)
    os.chmod(output_path, 0o600)  # nosec B103

    # Sanity check: the backup must decrypt back to the secret key with this password.
    decrypted = _run_gpg(["--decrypt"], input_bytes=encrypted, passphrase=passphrase)
    if PRIVATE_KEY_MARKER not in decrypted.decode(errors="ignore"):
        cprint("Backup verification failed (could not decrypt the key back).", "red")
        os.remove(output_path)
        sys.exit(1)

    cprint(f"Signing key '{key}' backed up (AES256, password-protected) to:", "green")
    cprint(f"  {output_path}", "green")
    cprint(
        "Keep this file AND the password in separate, safe places. "
        "Restore it on another machine with `counterparty-server restore-bootstrap-key`.",
        "yellow",
    )


def restore_bootstrap_key(input_path):
    input_path = os.path.abspath(input_path)
    if not os.path.exists(input_path):
        cprint(f"Backup file not found: {input_path}", "red")
        sys.exit(1)

    with open(input_path, "rb") as input_file:
        encrypted = input_file.read()

    passphrase = getpass.getpass("Enter the backup password: ")
    try:
        decrypted = _run_gpg(["--decrypt"], input_bytes=encrypted, passphrase=passphrase)
    except subprocess.CalledProcessError:
        cprint("Could not decrypt the backup (wrong password or corrupted file).", "red")
        sys.exit(1)

    if PRIVATE_KEY_MARKER not in decrypted.decode(errors="ignore"):
        cprint("Decrypted data does not contain a private key.", "red")
        sys.exit(1)

    # Import the secret key into the local keyring. Plaintext key stays in memory only.
    _run_gpg(["--import"], input_bytes=decrypted)
    cprint("Signing key restored into the local GnuPG keyring:", "green")
    listing = _run_gpg(["--list-secret-keys", "--keyid-format", "LONG"])
    print(listing.decode(errors="ignore"))
