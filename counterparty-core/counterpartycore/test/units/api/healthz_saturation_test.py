"""End-to-end saturation test for the isolated health listener (issue #3460).

Spins up a *real* Waitress server (2 threads, mirroring production's small pool) serving a slow
WSGI app, wires the *real* :class:`HealthSampler` + HTTP handler to Waitress' actual task
dispatcher, then occupies every public worker with concurrent slow requests. It asserts the two
acceptance-criteria guarantees directly:

* liveness keeps responding quickly while every public worker is blocked, and
* readiness reports degraded (503) once the pool stays saturated past the grace, then recovers.

No bitcoind / database is involved: the readiness ledger axis is fed by injected providers so the
test isolates the worker-saturation behaviour.
"""

import http.client
import threading
import time
from collections import deque

import waitress.server
from counterpartycore.lib.api import healthz_server
from counterpartycore.lib.api.healthz_server import (
    HealthRequestHandler,
    HealthSampler,
    ThreadingHTTPServer,
)

WAITRESS_THREADS = 2
SATURATION_GRACE = 1.0
SAMPLER_INTERVAL = 0.2


class SlowApp:
    """Minimal WSGI app whose /slow requests block until released, to occupy workers."""

    def __init__(self):
        self.release = threading.Event()
        self.in_flight = 0
        self._lock = threading.Lock()

    def __call__(self, environ, start_response):
        if environ.get("PATH_INFO") == "/slow":
            with self._lock:
                self.in_flight += 1
            try:
                self.release.wait(timeout=30)
            finally:
                with self._lock:
                    self.in_flight -= 1
        start_response("200 OK", [("Content-Type", "text/plain")])
        return [b"ok"]


def _run_waitress(server):
    # Mirrors WaitressApplication.run(): server.close() from another thread makes the asyncore
    # loop raise OSError(errno 9) on the closed socket during shutdown; that is expected.
    try:
        server.run()
    except OSError as e:
        if e.errno != 9:
            raise


def _get(port, path, timeout=5):
    conn = http.client.HTTPConnection("127.0.0.1", port, timeout=timeout)
    try:
        conn.request("GET", path)
        resp = conn.getresponse()
        resp.read()
        return resp.status
    finally:
        conn.close()


def _poll_until(fn, expected, timeout=8.0, interval=0.1):
    deadline = time.monotonic() + timeout
    last = None
    while time.monotonic() < deadline:
        last = fn()
        if last == expected:
            return last
        time.sleep(interval)
    return last


def test_liveness_survives_full_worker_saturation():
    app = SlowApp()
    wsgi_server = waitress.server.create_server(
        app, host="127.0.0.1", port=0, threads=WAITRESS_THREADS
    )
    wsgi_port = wsgi_server.socket.getsockname()[1]
    dispatcher = wsgi_server.task_dispatcher
    healthz_server._instrument_dispatcher(dispatcher)

    sampler = HealthSampler(
        dispatcher=dispatcher,
        interval=SAMPLER_INTERVAL,
        saturation_grace=SATURATION_GRACE,
        last_parsed_provider=lambda: 100,
        backend_height_provider=lambda: 100,
        block_time_provider=lambda: None,
        api_only_provider=lambda: False,
    )
    sampler.start()

    httpd = ThreadingHTTPServer(("127.0.0.1", 0), HealthRequestHandler)
    httpd.daemon_threads = True
    httpd.sampler = sampler
    httpd.started_at_monotonic = time.monotonic()
    httpd.live_latencies_ms = deque(maxlen=256)
    httpd.ready_latencies_ms = deque(maxlen=256)
    health_port = httpd.server_address[1]

    wsgi_thread = threading.Thread(target=_run_waitress, args=(wsgi_server,), daemon=True)
    health_thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    wsgi_thread.start()
    health_thread.start()

    slow_threads = []
    try:
        # Readiness is healthy before the flood.
        assert _get(health_port, "/healthz/ready") == 200

        # Occupy every worker plus the queue: 2 workers + 4 queued.
        for _ in range(WAITRESS_THREADS + 4):
            t = threading.Thread(target=lambda: _get(wsgi_port, "/slow", timeout=30), daemon=True)
            t.start()
            slow_threads.append(t)

        # Wait until all workers are actually blocked in the slow handler.
        deadline = time.monotonic() + 5
        while app.in_flight < WAITRESS_THREADS and time.monotonic() < deadline:
            time.sleep(0.05)
        assert app.in_flight >= WAITRESS_THREADS, "workers never got saturated"

        # Liveness must stay fast and green while the public pool is fully blocked.
        for _ in range(15):
            start = time.monotonic()
            assert _get(health_port, "/healthz/live") == 200
            assert (time.monotonic() - start) < 1.0, "liveness was blocked by worker saturation"

        # Readiness must flip to degraded once saturation persists past the grace.
        assert _poll_until(lambda: _get(health_port, "/healthz/ready"), 503, timeout=8.0) == 503

        # Release the slow requests; readiness must recover.
        app.release.set()
        assert _poll_until(lambda: _get(health_port, "/healthz/ready"), 200, timeout=8.0) == 200
    finally:
        app.release.set()
        for t in slow_threads:
            t.join(timeout=5)
        httpd.shutdown()
        httpd.server_close()
        sampler.stop()
        wsgi_server.close()
