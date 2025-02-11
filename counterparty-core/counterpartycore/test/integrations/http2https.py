import json
import socketserver
import threading

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Configuration
RPC_USER = "rpc"
RPC_PASSWORD = "rpc"  # noqa S105
PROXY_PORT = 48500
server = None


class RPCHandler(socketserver.StreamRequestHandler):
    def handle(self):
        print("Received request from client")
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

        print(f"Received request from client: {body}")

        try:
            print(f"Forwarding request to {target_url}", body)
            response = self.server.session.post(
                target_url,
                auth=(RPC_USER, RPC_PASSWORD),
                data=body,
                headers={"Content-Type": "application/json"},
                verify=False,
                timeout=5,
            )
            print(f"Received response from {target_url}")

            # Envoyer la réponse HTTP
            print("Sending response to client")
            self.wfile.write(b"HTTP/1.1 200 OK\r\n")
            self.wfile.write(b"Content-Type: application/json\r\n")
            self.wfile.write(b"Connection: keep-alive\r\n")
            self.wfile.write(f"Content-Length: {len(response.content)}\r\n".encode())
            self.wfile.write(b"\r\n")
            self.wfile.write(response.content)
            self.wfile.flush()
            print("Response sent to client")

        except Exception as e:
            print(f"Error forwarding request: {e}")
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
    print(f"Proxy starting on port {PROXY_PORT}")
    server = ThreadedTCPServer(("0.0.0.0", PROXY_PORT), RPCHandler, target_url)  # noqa S104
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()


def stop_http_proxy():
    global server  # noqa PLW0603
    if server:
        server.shutdown()
        server.server_close()
        print("Server stopped")
