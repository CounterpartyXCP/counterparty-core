"""Process-local progress of a long-running State DB maintenance operation.

Building, refreshing or fully rebuilding the State DB takes tens of minutes on
mainnet, and until now it was completely opaque: it ran before the API and the
health-check listener existed, so probes got a connection refusal, and it
logged nothing above DEBUG. An operator watching a pod could not distinguish
"rebuilding, making progress" from "hung" -- and Kubernetes could not either,
so a liveness probe would kill the pod mid-rebuild and the next start would
begin again from zero.

This module is the shared, lock-free-to-read status those two consumers need:
:mod:`counterpartycore.lib.api.dbbuilder` publishes each phase as it starts it,
and the health sampler (:mod:`counterpartycore.lib.api.healthz_server`) turns it
into a distinct ``rebuilding`` readiness state. It is deliberately trivial:
a single immutable snapshot swapped in under a lock, read without one.
"""

import logging
import threading
import time
from dataclasses import dataclass
from typing import Optional

from counterpartycore.lib import config

logger = logging.getLogger(config.LOGGER_NAME)


@dataclass(frozen=True)
class RebuildProgress:
    operation: str  # "build" | "refresh" | "rollback"
    phase: str  # human-readable name of the step under way
    step: Optional[int]  # 1-based index of that step, when countable
    total: Optional[int]  # number of steps, when known upfront
    started_at: float  # time.monotonic() when the operation began

    @property
    def seconds(self) -> float:
        return time.monotonic() - self.started_at

    def as_dict(self):
        body = {
            "operation": self.operation,
            "phase": self.phase,
            "seconds": round(self.seconds, 1),
        }
        if self.step is not None:
            body["step"] = self.step
        if self.total is not None:
            body["total_steps"] = self.total
        return body


_lock = threading.Lock()
_current: Optional[RebuildProgress] = None


def current() -> Optional[RebuildProgress]:
    """The operation under way, or ``None``. Read without taking the lock:
    ``_current`` is only ever rebound to a new immutable value."""
    return _current


def start(operation, phase, total=None):
    global _current  # noqa: PLW0603
    with _lock:
        _current = RebuildProgress(
            operation=operation,
            phase=phase,
            step=None,
            total=total,
            started_at=time.monotonic(),
        )


def step(phase, index=None):
    """Advance to the next phase, keeping the operation's start time."""
    global _current  # noqa: PLW0603
    with _lock:
        if _current is None:
            return
        _current = RebuildProgress(
            operation=_current.operation,
            phase=phase,
            step=index,
            total=_current.total,
            started_at=_current.started_at,
        )


def finish():
    global _current  # noqa: PLW0603
    with _lock:
        _current = None


class rebuilding:  # noqa: N801  # used as a context manager, reads as a verb
    """Publish ``operation`` for the duration of the block, whatever happens.

    ``with dbstatus.rebuilding("refresh", "applying migrations", total=14) as p:``
    then ``p.step("0006.create_and_populate_consolidated_tables", 6)``.
    """

    def __init__(self, operation, phase, total=None):
        self.operation = operation
        self.phase = phase
        self.total = total

    def __enter__(self):
        start(self.operation, self.phase, total=self.total)
        return self

    def step(self, phase, index=None):
        step(phase, index=index)

    def __exit__(self, exc_type, exc_value, traceback):
        finish()
        return False
