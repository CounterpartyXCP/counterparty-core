import json
import socket
import socketserver
import threading
import time

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


class RPCHandler(socketserver.StreamRequestHandler):
    def handle(self):
        with self.server.lock:  # Thread safety for handling requests
            try:
                # Read headers
                headers = {}
                while True:
                    line = self.rfile.readline()
                    if not line:
                        return
                    if line in (b"\r\n", b"\n", b""):
                        break
                    try:
                        header_line = line.decode("utf-8")
                        if ":" in header_line:
                            name, value = header_line.strip().split(":", 1)
                            headers[name.strip()] = value.strip()
                    except UnicodeDecodeError:
                        continue

                # Read request body
                content_length = int(headers.get("Content-Length", 0))
                body = self.rfile.read(content_length) if content_length else b""

                try:
                    # Make request to target API
                    response = self.server.session.post(
                        self.server.target_url,
                        auth=(self.server.rpc_user, self.server.rpc_password),
                        data=body,
                        headers={"Content-Type": "application/json", "Accept": "application/json"},
                        verify=False,
                        timeout=30,
                    )

                    # Build response
                    response_content = response.content
                    response_headers = [
                        b"HTTP/1.1 200 OK\r\n",
                        b"Server: Bitcoin Core RPC\r\n",
                        b"Connection: Keep-Alive\r\n",
                        b"Content-Type: application/json\r\n",
                        b"Access-Control-Allow-Headers: Content-Type\r\n",
                        b"Access-Control-Allow-Origin: *\r\n",
                        f"Content-Length: {len(response_content)}\r\n".encode(),
                        b"\r\n",
                    ]

                    # Send response
                    full_response = b"".join(response_headers) + response_content
                    self.wfile.write(full_response)
                    self.wfile.flush()

                except requests.RequestException as e:
                    error_content = json.dumps(
                        {"error": {"code": -32603, "message": str(e)}, "id": None}
                    ).encode()
                    error_headers = [
                        b"HTTP/1.1 500 Internal Server Error\r\n",
                        b"Content-Type: application/json\r\n",
                        f"Content-Length: {len(error_content)}\r\n".encode(),
                        b"\r\n",
                    ]
                    self.wfile.write(b"".join(error_headers) + error_content)
                    self.wfile.flush()

            except Exception:
                import traceback

                traceback.print_exc()


class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True
    daemon_threads = True  # Changed to True for proper cleanup

    def __init__(self, server_address, RequestHandlerClass, target_url, rpc_user, rpc_password):
        super().__init__(server_address, RequestHandlerClass)
        self.target_url = target_url
        self.rpc_user = rpc_user
        self.rpc_password = rpc_password
        self.lock = threading.Lock()

        # Configure session with retries
        self.session = requests.Session()
        retry_strategy = Retry(
            total=3,
            backoff_factor=0.1,
            status_forcelist=[500, 502, 503, 504],
            allowed_methods=["POST"],  # Explicitly allow POST retries
        )
        adapter = HTTPAdapter(pool_connections=20, pool_maxsize=20, max_retries=retry_strategy)
        self.session.mount("https://", adapter)
        self.session.mount("http://", adapter)


def wait_for_port(port, host="127.0.0.1", timeout=10.0):
    """Wait for a port to become available."""
    start_time = time.perf_counter()
    while True:
        try:
            with socket.create_connection((host, port), timeout=timeout):
                return True
        except OSError:
            time.sleep(0.1)
            if time.perf_counter() - start_time >= timeout:
                return False


def start_http_proxy(target_url, port=48500, rpc_user="rpc", rpc_password="rpc"):  # noqa: S107
    # Close any existing connections
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect(("127.0.0.1", port))
        # If we get here, something is using the port
        raise RuntimeError(f"Port {port} is already in use")
    except ConnectionRefusedError:
        pass  # Port is available

    server = ThreadedTCPServer(("127.0.0.1", port), RPCHandler, target_url, rpc_user, rpc_password)

    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()

    # Wait for server to start
    if not wait_for_port(port):
        raise RuntimeError("Failed to start RPC proxy server")

    return server


def stop_http_proxy(server):
    if server:
        server.shutdown()
        server.server_close()

        # Ensure port is released
        time.sleep(0.5)  # Short delay to allow socket cleanup
