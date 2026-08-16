"""Dedicated, isolated health-check listener (issue #3460).

The public API is served by a single shared worker pool (Waitress' ``ThreadedTaskDispatcher``,
default 10 threads). Historically ``/v2/healthz`` was served by that *same* pool, so when
expensive requests occupied every worker, health probes queued behind them for many seconds and
Kubernetes evicted otherwise-healthy pods (v11.2.0 incident, 2026-07-15).

This module runs a tiny HTTP server on its own socket, with its own one-thread-per-request pool,
so it can never be head-of-line blocked by public-worker saturation. Its request handlers only
read a pre-computed, in-memory snapshot maintained by a background sampler thread — no DB query,
no bitcoind RPC, no lock — so responses are deterministically fast.

Endpoints (all GET, JSON):

* ``/healthz/live``    — liveness: is the process internally alive? 200 unless the sampler
                         heartbeat is stale (a genuine deadlock). Never reflects ledger lag or
                         saturation, so a busy-but-alive pod is never restarted.
* ``/healthz/ready``   — readiness: should this pod receive traffic? 503 when the ledger is
                         behind the backend OR the worker pool has been saturated past a grace
                         period (load shedding).
* ``/healthz``         — alias of ``/healthz/ready``.
* ``/healthz/metrics`` — worker-pool + saturation + handler-latency gauges for alerting.
"""

import contextlib
import json
import logging
import threading
import time
from collections import deque
from dataclasses import dataclass
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Optional

from counterpartycore.lib import config
from counterpartycore.lib.api import apiwatcher
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.utils import database

logger = logging.getLogger(config.LOGGER_NAME)

LATENCY_WINDOW = 256  # number of recent request durations retained per endpoint
WORKER_STATS_LOG_INTERVAL = 60  # seconds between throttled WORKER_STATS log lines


@dataclass(frozen=True)
class WorkerMetrics:
    total: int
    busy: int
    idle: int
    draining: int
    queue_depth: int
    queue_head_wait: Optional[float]  # seconds the oldest queued request has waited


@dataclass(frozen=True)
class HealthSnapshot:
    ready: bool
    reason: Optional[str]  # None when ready, else "starting" | "behind_backend" | "saturated"
    backend_height: Optional[int]
    last_parsed: Optional[int]
    lag: Optional[int]
    saturated: bool
    saturation_seconds: float
    workers: Optional[WorkerMetrics]  # None on gunicorn/werkzeug (no introspectable pool)


def _instrument_dispatcher(dispatcher):
    """Stamp each task with its enqueue time so the sampler can report the true head-of-line
    queue wait. Idempotent, lock-free, and fully guarded so it can never break request serving."""
    if dispatcher is None or getattr(dispatcher, "_healthz_instrumented", False):
        return
    original_add_task = dispatcher.add_task

    def add_task(task, _original=original_add_task):
        # Best-effort stamp on a per-request hot path: if the task object ever rejects the
        # attribute, skip the timestamp (its queue-wait reads as unavailable) rather than
        # break request enqueueing. suppress() keeps this guard without a bare try/except/pass.
        with contextlib.suppress(Exception):
            task.healthz_enqueued_at = time.monotonic()
        return _original(task)

    try:
        dispatcher.add_task = add_task
        dispatcher._healthz_instrumented = True  # pylint: disable=protected-access
    except Exception as e:  # pylint: disable=broad-except
        # Some dispatcher implementations may not allow attribute assignment; degrade to
        # reporting no queue-wait rather than failing.
        logger.debug("healthz: could not instrument dispatcher for queue-wait metric: %s", e)


class HealthSampler(threading.Thread):
    """Background thread that recomputes a :class:`HealthSnapshot` every ``interval`` seconds.

    Owns its own read-only state-DB connection (opened in :meth:`run`, since apsw connections are
    thread-affine) and, on Waitress, a reference to the shared task dispatcher. Everything a
    request handler needs is baked into the immutable snapshot, swapped in via a single atomic
    attribute assignment, so handlers never touch the DB, the dispatcher lock, or a mutex.
    """

    def __init__(
        self,
        dispatcher=None,
        *,
        interval=1.0,
        saturation_grace=None,
        ready_lag_blocks=None,
        ready_recent_parse_seconds=None,
        liveness_heartbeat_timeout=None,
        last_parsed_provider=None,
        backend_height_provider=None,
        block_time_provider=None,
        api_only_provider=None,
    ):
        super().__init__(name="HealthSampler", daemon=True)
        self.dispatcher = dispatcher
        self.interval = interval
        self.saturation_grace = (
            saturation_grace
            if saturation_grace is not None
            else getattr(
                config,
                "HEALTHZ_SATURATION_GRACE",
                config.DEFAULT_HEALTHZ_SATURATION_GRACE_SECONDS,
            )
        )
        self.ready_lag_blocks = (
            ready_lag_blocks
            if ready_lag_blocks is not None
            else config.DEFAULT_HEALTHZ_READY_LAG_BLOCKS
        )
        self.ready_recent_parse_seconds = (
            ready_recent_parse_seconds
            if ready_recent_parse_seconds is not None
            else config.DEFAULT_HEALTHZ_READY_RECENT_PARSE_SECONDS
        )
        self.liveness_heartbeat_timeout = (
            liveness_heartbeat_timeout
            if liveness_heartbeat_timeout is not None
            else config.DEFAULT_HEALTHZ_LIVENESS_HEARTBEAT_TIMEOUT_SECONDS
        )

        # Injectable providers (real defaults resolved lazily; tests pass fakes).
        # When no last-parsed provider is injected, the sampler owns and opens its own read-only
        # state-DB connection inside run() (apsw connections are thread-affine).
        self._last_parsed_provider = last_parsed_provider
        self._owns_db = last_parsed_provider is None
        self._backend_height_provider = (
            backend_height_provider or CurrentState().current_backend_height
        )
        self._block_time_provider = block_time_provider or CurrentState().current_block_time
        self._api_only_provider = api_only_provider or (
            lambda: bool(getattr(config, "API_ONLY", False))
        )

        self.stop_event = threading.Event()
        self._snapshot = HealthSnapshot(
            ready=False,
            reason="starting",
            backend_height=None,
            last_parsed=None,
            lag=None,
            saturated=False,
            saturation_seconds=0.0,
            workers=None,
        )
        self._last_sample_monotonic = time.monotonic()
        self._saturated_since = None
        self._saturation_warned = False
        self._last_parsed_value = None
        self._last_parsed_advanced_at = None
        self._last_stats_log = 0.0

    # -- public, lock-free reads used by the request handlers --------------------------------
    def current_snapshot(self) -> HealthSnapshot:
        return self._snapshot

    def heartbeat_age(self) -> float:
        return time.monotonic() - self._last_sample_monotonic

    # -- sampler loop ------------------------------------------------------------------------
    def run(self):
        own_db = None
        try:
            self._tick()  # publish a snapshot immediately (worker metrics available at once)
            while not self.stop_event.wait(self.interval):
                # Open the state DB lazily and tolerate transient unavailability (e.g. during
                # early startup) by retrying, rather than letting the sampler thread die.
                if self._owns_db and own_db is None:
                    try:
                        own_db = database.get_db_connection(
                            config.STATE_DATABASE, read_only=True, check_wal=False
                        )
                        self._last_parsed_provider = (
                            lambda db=own_db: apiwatcher.get_last_block_parsed(db)
                        )
                    except Exception as e:  # pylint: disable=broad-except
                        logger.debug("healthz: state DB not ready yet: %s", e)
                self._tick()
        finally:
            if own_db is not None:
                try:
                    own_db.close()
                except Exception as e:  # pylint: disable=broad-except
                    logger.debug("healthz: error closing state DB connection: %s", e)

    def stop(self):
        self.stop_event.set()
        if self.is_alive():
            self.join(timeout=5)

    def _tick(self):
        now = time.monotonic()
        self._last_sample_monotonic = now

        workers, saturated_now = self._sample_workers(now)
        saturation_seconds = self._track_saturation(now, saturated_now)
        over_saturated = (
            self.saturation_grace > 0
            and self.dispatcher is not None
            and saturated_now
            and saturation_seconds >= self.saturation_grace
        )
        self._warn_on_saturation(over_saturated, workers, saturation_seconds)

        caught_up, lag, ledger_reason, backend_height, last_parsed = self._compute_caught_up(now)
        ready = caught_up and not over_saturated
        if ready:
            reason = None
        elif not caught_up:
            reason = ledger_reason
        else:
            reason = "saturated"

        self._snapshot = HealthSnapshot(
            ready=ready,
            reason=reason,
            backend_height=backend_height,
            last_parsed=last_parsed,
            lag=lag,
            saturated=saturated_now,
            saturation_seconds=saturation_seconds,
            workers=workers,
        )
        self._maybe_log_worker_stats(now, workers, saturation_seconds)

    def _sample_workers(self, now):
        if self.dispatcher is None:
            return None, False
        try:
            total = len(self.dispatcher.threads) or getattr(config, "WAITRESS_THREADS", 0)
            busy = int(self.dispatcher.active_count)
            draining = int(self.dispatcher.stop_count)
            queue_depth = len(self.dispatcher.queue)
            idle = max(0, total - draining - busy)
            queue_head_wait = self._queue_head_wait(now)
            workers = WorkerMetrics(
                total=total,
                busy=busy,
                idle=idle,
                draining=draining,
                queue_depth=queue_depth,
                queue_head_wait=queue_head_wait,
            )
            saturated = 0 < total <= busy and queue_depth > 0
            return workers, saturated
        except Exception as e:  # pylint: disable=broad-except
            logger.debug("healthz: could not sample worker pool: %s", e)
            return None, False

    def _queue_head_wait(self, now):
        try:
            head = self.dispatcher.queue[0]  # workers popleft(), so [0] is the oldest
        except IndexError:
            return 0.0
        except Exception:  # pylint: disable=broad-except
            return None
        enqueued_at = getattr(head, "healthz_enqueued_at", None)
        if enqueued_at is None:
            return None
        return round(max(0.0, now - enqueued_at), 3)

    def _track_saturation(self, now, saturated_now):
        if saturated_now:
            if self._saturated_since is None:
                self._saturated_since = now
            return now - self._saturated_since
        self._saturated_since = None
        return 0.0

    def _warn_on_saturation(self, over_saturated, workers, saturation_seconds):
        if over_saturated and not self._saturation_warned:
            busy = workers.busy if workers else "?"
            total = workers.total if workers else "?"
            queue_depth = workers.queue_depth if workers else "?"
            logger.warning(
                "API worker pool saturated for %.1fs (busy=%s/%s queue=%s) - "
                "readiness reporting degraded to shed load",
                saturation_seconds,
                busy,
                total,
                queue_depth,
            )
            self._saturation_warned = True
        elif not over_saturated and self._saturated_since is None:
            self._saturation_warned = False

    def _compute_caught_up(self, now):
        """Returns (caught_up, lag, reason, backend_height, last_parsed).

        Sourced only from the shared-memory backend height and the sampler's own state-DB read,
        so it is correct on every WSGI backend (including gunicorn, where the master's
        ``CurrentState`` block index is stale). Mirrors ``apiserver.is_server_ready``.
        """
        if self._api_only_provider():
            # API-only nodes serve a static/frozen ledger and do not track the backend tip.
            return True, None, None, None, None

        backend_height = self._backend_height_provider()
        last_parsed = None
        if self._last_parsed_provider is not None:
            try:
                last_parsed = self._last_parsed_provider()
            except Exception as e:  # pylint: disable=broad-except
                logger.debug("healthz: could not read last parsed block: %s", e)

        if last_parsed is not None and (
            self._last_parsed_value is None or last_parsed > self._last_parsed_value
        ):
            self._last_parsed_value = last_parsed
            self._last_parsed_advanced_at = now

        if not backend_height:  # None (starting) or 0
            return False, None, "starting", backend_height, last_parsed
        if last_parsed is None:
            return False, None, "starting", backend_height, last_parsed

        lag = backend_height - last_parsed
        if lag <= self.ready_lag_blocks:
            return True, lag, None, backend_height, last_parsed

        # Grace: if the most recent parsed block is itself recent, we are effectively at the tip
        # and the backend number is merely momentarily ahead (matches is_server_ready's 120s rule).
        block_time = None
        try:
            block_time = self._block_time_provider()
        except Exception:  # pylint: disable=broad-except
            block_time = None
        if block_time and (time.time() - block_time) < self.ready_recent_parse_seconds:
            return True, lag, None, backend_height, last_parsed

        return False, lag, "behind_backend", backend_height, last_parsed

    def _maybe_log_worker_stats(self, now, workers, saturation_seconds):
        if workers is None:
            return
        if now - self._last_stats_log < WORKER_STATS_LOG_INTERVAL:
            return
        self._last_stats_log = now
        logger.info(
            "WORKER_STATS busy=%d/%d idle=%d queue=%d saturated_for=%.1fs",
            workers.busy,
            workers.total,
            workers.idle,
            workers.queue_depth,
            saturation_seconds,
        )


def _latency_stats(samples):
    data = list(samples)
    if not data:
        return {"count": 0, "last_ms": None, "p99_ms": None, "max_ms": None}
    ordered = sorted(data)
    idx = min(len(ordered) - 1, int(len(ordered) * 0.99))
    return {
        "count": len(data),
        "last_ms": round(data[-1], 3),
        "p99_ms": round(ordered[idx], 3),
        "max_ms": round(ordered[-1], 3),
    }


class HealthRequestHandler(BaseHTTPRequestHandler):
    # HTTP/1.0 (default): the connection closes after each response, which keeps probe handling
    # trivial and robust. Health probes are infrequent, so keep-alive buys nothing here.
    server_version = "counterparty-healthz"

    # camelCase name is mandated by the http.server dispatch API (BaseHTTPRequestHandler.do_<VERB>).
    def do_GET(self):  # noqa: N802  # pylint: disable=invalid-name
        start = time.monotonic()
        path = self.path.split("?", 1)[0].rstrip("/")
        bucket = None
        if path in ("", "/healthz", "/healthz/ready"):
            code, body = self._readiness()
            bucket = "ready"
        elif path == "/healthz/live":
            code, body = self._liveness()
            bucket = "live"
        elif path == "/healthz/metrics":
            code, body = 200, self._metrics()
        else:
            code, body = 404, {"error": "not found"}
        self._respond(code, body)
        elapsed_ms = (time.monotonic() - start) * 1000
        if bucket == "live":
            self.server.live_latencies_ms.append(elapsed_ms)
        elif bucket == "ready":
            self.server.ready_latencies_ms.append(elapsed_ms)

    def _liveness(self):
        sampler = self.server.sampler
        age = sampler.heartbeat_age()
        if age > sampler.liveness_heartbeat_timeout:
            return 503, {
                "status": "unhealthy",
                "reason": "heartbeat_stale",
                "heartbeat_age_seconds": round(age, 1),
            }
        return 200, {"status": "alive"}

    def _readiness(self):
        snap = self.server.sampler.current_snapshot()
        if snap.ready:
            return 200, {"status": "ready"}
        body = {"status": "degraded", "reason": snap.reason}
        if snap.backend_height is not None:
            body["backend_height"] = snap.backend_height
        if snap.last_parsed is not None:
            body["last_parsed_block"] = snap.last_parsed
        if snap.lag is not None:
            body["lag"] = snap.lag
        if snap.reason == "saturated":
            body["saturation_seconds"] = round(snap.saturation_seconds, 1)
        return 503, body

    def _metrics(self):
        snap = self.server.sampler.current_snapshot()
        workers = None
        if snap.workers is not None:
            workers = {
                "total": snap.workers.total,
                "busy": snap.workers.busy,
                "idle": snap.workers.idle,
                "draining": snap.workers.draining,
                "queue_depth": snap.workers.queue_depth,
                "queue_head_wait_seconds": snap.workers.queue_head_wait,
            }
        return {
            "wsgi_server": getattr(config, "WSGI_SERVER", None),
            "workers": workers,
            "saturation": {
                "saturated": snap.saturated,
                "duration_seconds": round(snap.saturation_seconds, 1),
            },
            "readiness": {
                "ready": snap.ready,
                "reason": snap.reason,
                "backend_height": snap.backend_height,
                "last_parsed_block": snap.last_parsed,
                "lag": snap.lag,
            },
            "health_handler": {
                "live": _latency_stats(self.server.live_latencies_ms),
                "ready": _latency_stats(self.server.ready_latencies_ms),
            },
            "process": {
                "uptime_seconds": round(time.monotonic() - self.server.started_at_monotonic, 1),
            },
        }

    def _respond(self, code, body):
        payload = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(payload)

    # ``format`` shadows the builtin but must match BaseHTTPRequestHandler's signature exactly,
    # otherwise pylint flags arguments-differ on this override.
    def log_message(self, format, *args):  # noqa: A002  # pylint: disable=redefined-builtin
        # Silence the default stderr access log; route to trace for debugging only.
        if hasattr(logger, "trace"):
            logger.trace("healthz %s - %s", self.address_string(), format % args)


class HealthCheckServer:
    """Owns the isolated HTTP listener + its sampler. Starting/stopping is non-fatal by design:
    a failure to bind must never reduce API availability (the legacy in-API ``/healthz`` remains).
    """

    def __init__(self, host, port, dispatcher=None, saturation_grace=None, stop_event=None):
        self.host = host
        self.port = port
        self.dispatcher = dispatcher
        self.saturation_grace = saturation_grace
        # stop_event is accepted for symmetry with the other server threads; the health server
        # is a daemon and is torn down explicitly via stop(), so it is not otherwise used.
        self.stop_event = stop_event
        self.httpd = None
        self.sampler = None
        self._serve_thread = None
        self.started_at_monotonic = time.monotonic()

    def start(self):
        try:
            _instrument_dispatcher(self.dispatcher)
            self.sampler = HealthSampler(
                dispatcher=self.dispatcher, saturation_grace=self.saturation_grace
            )
            self.sampler.start()

            self.httpd = ThreadingHTTPServer((self.host, self.port), HealthRequestHandler)
            self.httpd.daemon_threads = True
            self.httpd.sampler = self.sampler
            self.httpd.started_at_monotonic = self.started_at_monotonic
            self.httpd.live_latencies_ms = deque(maxlen=LATENCY_WINDOW)
            self.httpd.ready_latencies_ms = deque(maxlen=LATENCY_WINDOW)

            self._serve_thread = threading.Thread(
                target=self.httpd.serve_forever, name="HealthCheckServer", daemon=True
            )
            self._serve_thread.start()
            logger.info(
                "Health check server listening on %s:%s (isolated from the API worker pool)",
                self.host,
                self.port,
            )
        except OSError as e:
            logger.error(
                "Could not start dedicated health check server on %s:%s (%s); "
                "the in-API /healthz route still works, but probes are not isolated.",
                self.host,
                self.port,
                e,
            )
            self._cleanup_after_failure()
        except Exception as e:  # pylint: disable=broad-except
            logger.error("Unexpected error starting health check server: %s", e)
            self._cleanup_after_failure()

    def _cleanup_after_failure(self):
        if self.sampler is not None:
            try:
                self.sampler.stop()
            except Exception as e:  # pylint: disable=broad-except
                logger.debug("healthz: error stopping sampler after failed start: %s", e)
        self.sampler = None
        self.httpd = None
        self._serve_thread = None

    def stop(self):
        if self.httpd is not None:
            try:
                # shutdown() must be called from a different thread than serve_forever().
                self.httpd.shutdown()
                self.httpd.server_close()
            except Exception as e:  # pylint: disable=broad-except
                logger.debug("Error stopping health check server: %s", e)
        if self.sampler is not None:
            self.sampler.stop()
        if self._serve_thread is not None:
            self._serve_thread.join(timeout=5)
        logger.trace("Health check server stopped.")
