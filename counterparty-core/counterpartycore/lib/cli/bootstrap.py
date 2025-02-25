import glob
import io
import os
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
    return zst_filepath


def get_zst_callbacl(input_file_size):
    def print_decompression_progress(total_input, _total_output, _read_data, _write_data):
        percent = 100 * total_input / input_file_size
        print(f"Progress: {percent:.1f}%", end="\r")

    return print_decompression_progress


def decompress_zst(zst_filepath):
    print(f"Decompressing {zst_filepath}...")
    start_time = time.time()
    version = (
        os.path.basename(zst_filepath)
        .replace("counterparty.db.", "")
        .replace("counterparty.testnet.db.", "")
        .replace("counterparty.testnet4.db.", "")
        .replace("counterparty.testnet3.db.", "")
        .replace("state.db.", "")
        .replace("state.testnet.db.", "")
        .replace("state.testnet4.db.", "")
        .replace("state.testnet3.db.", "")
        .replace(".zst", "")
    )
    filename = zst_filepath.replace(f".{version}.zst", "")
    filepath = os.path.join(os.path.dirname(zst_filepath), filename)
    print(f"Decompressing {zst_filepath} to {filepath}...")
    # input_file_size = os.path.getsize(zst_filepath)
    with io.open(filepath, "wb") as output_file:
        with open(zst_filepath, "rb") as input_file:
            pyzstd.decompress_stream(input_file, output_file, read_size=16 * 1024)
    os.remove(zst_filepath)
    os.chmod(filepath, 0o660)  # nosec B103
    print(f"Decompressed {zst_filepath} in {time.time() - start_time:.2f}s")
    return filepath


def download_and_decompress(data_dir, zst_url):
    # download and decompress .tar.zst file
    print(f"Downloading and decompressing {zst_url}...")
    start_time = time.time()
    response = urllib.request.urlopen(zst_url)  # nosec B310  # noqa: S310
    zst_filename = os.path.basename(zst_url)
    filename = zst_filename.replace(".latest.zst", "")
    filepath = os.path.join(data_dir, filename)
    with io.open(filepath, "wb") as output_file:
        pyzstd.decompress_stream(response, output_file, read_size=16 * 1024)
    os.chmod(filepath, 0o660)  # nosec B103
    print(f"Downloaded and decompressed {zst_url} in {time.time() - start_time:.2f}s")
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


def decompress_and_verify(zst_filepath, sig_url):
    filepath = decompress_zst(zst_filepath)
    check_signature(filepath, sig_url)


def verfif_and_decompress(zst_filepath, sig_url, decompressors_state):
    try:
        check_signature(zst_filepath, sig_url)
        decompress_zst(zst_filepath)
    except Exception as e:
        cprint(f"Failed to verify and decompress {zst_filepath}: {e}", "red")
        decompressors_state.value = 1


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
        except Exception as e:
            cprint(f"Failed to download {zst_url}: {e}", "red")
            for decompressor in decompressors:
                decompressor.kill()
                sys.exit(1)

        decompressor = Process(
            target=verfif_and_decompress,
            args=(zst_filepath, sig_url, decompressors_state),
        )
        decompressor.start()
        decompressors.append(decompressor)

    while True:
        if not any(decompressor.is_alive() for decompressor in decompressors):
            break
        if decompressors_state.value == 1:
            cprint("Failed to decompress and verify bootstrap files.", "red")
            for decompressor in decompressors:
                decompressor.kill()
            sys.exit(1)
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
        exit()


def generate_urls(counterparty_zst_url):
    state_zst_url = counterparty_zst_url.replace("/counterparty.db", "/state.db")
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
        files = config.BOOTSTRAP_URLS[config.NETWORK_NAME]
    else:
        files = generate_urls(snapshot_url)

    download_bootstrap_files(config.DATA_DIR, files)

    cprint(
        f"Databases have been successfully bootstrapped to {config.DATA_DIR} in {time.time() - start_time:.2f}s.",
        "green",
    )
