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
        target_url = self.server.target_url

        # Read http headers
        headers = {}
        while True:
            line = self.rfile.readline().decode("utf-8")
            if line in ("\r\n", "\n", ""):
                break
            if ":" in line:
                name, value = line.strip().split(":", 1)
                headers[name.strip()] = value.strip()

        # Read http body
        content_length = int(headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length else b""

        try:
            response = self.server.session.post(
                target_url,
                auth=(RPC_USER, RPC_PASSWORD),
                data=body,
                headers={"Content-Type": "application/json"},
                verify=False,
                timeout=15,
            )

            # Send response back to client
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
        print("Proxying to", target_url)

        # Create a session to reuse TCP connection
        self.session = requests.Session()
        retry_strategy = Retry(
            total=2,
            backoff_factor=0.1,
            status_forcelist=[500, 502, 503, 504],
        )
        adapter = HTTPAdapter(
            pool_connections=20,
            pool_maxsize=20,
            max_retries=retry_strategy,
        )
        self.session.mount("https://", adapter)
        self.session.mount("http://", adapter)

        super().__init__(server_address, RequestHandlerClass)


def start_http_proxy(target_url):
    global server  # noqa PLW0603
    server = ThreadedTCPServer(("127.0.0.1", PROXY_PORT), RPCHandler, target_url)  # noqa S104
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()


def stop_http_proxy():
    global server  # noqa PLW0603
    if server:
        server.shutdown()
        server.server_close()
