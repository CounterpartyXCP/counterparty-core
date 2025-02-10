import json
import os
import socketserver
import sys
import tempfile
import threading
import time

import apsw
import requests
import sh
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Configuration
RPC_USER = "rpc"
RPC_PASSWORD = "rpc"  # noqa S105
PROXY_PORT = 48500
server = None


class RPCHandler(socketserver.StreamRequestHandler):
    def handle(self):
        target_url = self.server.target_url

        # Lire l'en-tête HTTP
        headers = {}
        while True:
            line = self.rfile.readline().decode("utf-8")
            if line in ("\r\n", "\n", ""):
                break
            if ":" in line:
                name, value = line.strip().split(":", 1)
                headers[name.strip()] = value.strip()

        # Lire le corps de la requête
        content_length = int(headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length else b""

        try:
            response = self.server.session.post(
                target_url,
                auth=(RPC_USER, RPC_PASSWORD),
                data=body,
                headers={"Content-Type": "application/json"},
                verify=False,
                timeout=5,
            )

            # Envoyer la réponse HTTP
            self.wfile.write(b"HTTP/1.1 200 OK\r\n")
            self.wfile.write(b"Content-Type: application/json\r\n")
            self.wfile.write(b"Connection: keep-alive\r\n")
            self.wfile.write(f"Content-Length: {len(response.content)}\r\n".encode())
            self.wfile.write(b"\r\n")
            self.wfile.write(response.content)
            self.wfile.flush()

        except Exception as e:
            error_response = json.dumps({"error": str(e)}).encode()
            self.wfile.write(b"HTTP/1.1 500 Internal Server Error\r\n")
            self.wfile.write(b"Content-Type: application/json\r\n")
            self.wfile.write(b"Connection: close\r\n")
            self.wfile.write(f"Content-Length: {len(error_response)}\r\n".encode())
            self.wfile.write(b"\r\n")
            self.wfile.write(error_response)
            self.wfile.flush()


class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True

    def __init__(self, server_address, RequestHandlerClass, target_url):
        self.target_url = target_url

        # Configuration de la session avec pool de connexions
        self.session = requests.Session()
        retry_strategy = Retry(
            total=2,  # Nombre de tentatives
            backoff_factor=0.1,  # Délai entre les tentatives
            status_forcelist=[500, 502, 503, 504],  # Statuts HTTP à réessayer
        )
        adapter = HTTPAdapter(
            pool_connections=20,  # Nombre de connexions dans le pool
            pool_maxsize=20,  # Taille maximale du pool
            max_retries=retry_strategy,
        )
        self.session.mount("https://", adapter)
        self.session.mount("http://", adapter)

        super().__init__(server_address, RequestHandlerClass)


server = None


def start_http_proxy(target_url):
    global server  # noqa PLW0603
    server = ThreadedTCPServer(("127.0.0.1", PROXY_PORT), RPCHandler, target_url)
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()
    print(f"Server started on port {PROXY_PORT}")


def stop_http_proxy():
    global server  # noqa PLW0603
    if server:
        server.shutdown()
        server.server_close()
        print("Server stopped")


def bootstrap_and_reparse(network):
    DATA_DIR = os.path.join(tempfile.gettempdir(), "counterparty-data")
    if os.path.exists(DATA_DIR):
        sh.rm("-rf", DATA_DIR)
    sh.mkdir(DATA_DIR)

    args = [
        "-vv",
        "--data-dir",
        DATA_DIR,
        "--no-confirm",
        # "--backend-ssl",
    ]
    if network == "testnet4":
        args.append("--testnet4")
        args += ["--backend-port", PROXY_PORT]
        backend_url = "https://testnet4.counterparty.io:48332"
        db_file = "counterparty.testnet4.db"
        api_url = "http://localhost:44000/v2/"
    else:
        args += ["--backend-connect", "api.counterparty.io"]
        backend_url = "https://api.counterparty.io:8332"
        db_file = "counterparty.db"
        api_url = "http://localhost:4000/v2/"

    sh_counterparty_server = sh.counterparty_server.bake(*args, _out=sys.stdout, _err_to_out=True)

    sh_counterparty_server("bootstrap")

    db = apsw.Connection(os.path.join(DATA_DIR, db_file))
    last_block = db.execute(
        "SELECT block_index, ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    last_block_index = last_block[0]
    ledger_hash_before = last_block[1]
    txlist_hash_before = last_block[2]
    db.close()

    reparse_from = last_block_index - 1000

    sh_counterparty_server("reparse", reparse_from)

    db = apsw.Connection(os.path.join(DATA_DIR, db_file))
    last_block = db.execute(
        "SELECT ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    ledger_hash_after = last_block[0]
    txlist_hash_after = last_block[1]
    db.close()

    assert ledger_hash_before == ledger_hash_after
    assert txlist_hash_before == txlist_hash_after

    try:
        start_http_proxy(backend_url)
        server_process = sh_counterparty_server("start", _bg=True)

        server_ready = False
        while not server_ready:
            try:
                server_ready = requests.get(api_url, timeout=5).json()["result"]["server_ready"]
                if not server_ready:
                    print("Waiting for server to be ready...")
                    time.sleep(1)
            except Exception:
                # print(e)
                time.sleep(1)
                pass
    finally:
        stop_http_proxy()
        server_process.terminate()

    sh.rm("-rf", DATA_DIR)


def test_reparse():
    bootstrap_and_reparse("testnet4")
    # bootstrap_and_reparse("mainnet")
