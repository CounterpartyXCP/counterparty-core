"""Cached software compatibility, shared by the parser and API processes.

This is an operator upgrade guard, not transaction consensus logic. Only the
background checker fetches remote metadata; readers do no network or DB I/O.
"""

import json
import time
from multiprocessing import Array

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger.currentstate import CurrentState

CHECK_INTERVAL = 300
RETRY_INTERVAL = 60
MAX_METADATA_AGE = CHECK_INTERVAL * 2
_state = None  # pylint: disable=invalid-name


def evaluate(cached, height):
    """One compatibility decision for parser guards, warnings and API consumers."""
    if cached is None:
        cached = {"metadata_error": "state_unavailable"}
    requirements = cached.get("requirements", [])
    height = max(height or 0, cached.get("height") or 0)
    active = [entry for entry in requirements if height >= entry["activation_height"]]
    if cached.get("blocked"):
        active.append(cached["blocked"])
    selected = (
        max(active, key=lambda entry: entry["version"])
        if active
        else min(requirements, key=lambda entry: entry["activation_height"], default=None)
    )
    checked = cached.get("last_successful_check")
    if active:
        status = "incompatible"
    elif checked is None:
        status = "unknown"
    elif cached.get("metadata_error") or not 0 <= time.time() - checked <= MAX_METADATA_AGE:
        status = "stale"
    elif requirements:
        status = "upgrade_pending"
    else:
        status = "compatible"
    forced = bool(getattr(config, "FORCE", False))
    return {
        "status": "bypassed" if forced else status,
        "required_version": ".".join(map(str, selected["version"])) if selected else None,
        "activation_height": selected["activation_height"] if selected else None,
        "change_name": selected["change_name"] if selected else None,
        "last_checked": cached.get("last_checked"),
        "last_successful_check": checked,
        "metadata_error": cached.get("metadata_error"),
        "force_override": forced,
    }, selected


class ProtocolStatus:
    def __init__(self):
        # Only requirements newer than this binary are stored, not the whole
        # protocol manifest. No Manager process or DB writes are necessary.
        self.buffer = Array("c", 32768)
        # Last snapshot this process read or wrote. A reader that cannot take
        # the shared lock in time (a busy API process, a spinning watcher) keeps
        # this policy instead of degrading to "unknown", which would turn lock
        # contention into 503s and parser halts.
        self.last_read = None

    def read(self):
        if not self.buffer.get_lock().acquire(timeout=0.1):
            return self.last_read
        try:
            value = self.buffer.value
            self.last_read = json.loads(value) if value else {}
            return self.last_read
        finally:
            self.buffer.get_lock().release()

    def update(self, fields):
        if not self.buffer.get_lock().acquire(timeout=0.1):
            raise exceptions.VersionCheckError("Protocol status is unavailable")
        try:
            value = self.buffer.value
            stored = json.loads(value) if value else {}
            # Read/modify/write under one lock: a refresh must never erase a
            # parser's concurrently recorded activation barrier.
            if stored.get("blocked") and fields.get("blocked"):
                fields = fields | {
                    "blocked": max(
                        (stored["blocked"], fields["blocked"]), key=lambda entry: entry["version"]
                    )
                }
            stored.update(fields)
            encoded = json.dumps(stored).encode()
            if len(encoded) >= len(self.buffer):
                raise exceptions.VersionCheckError("Protocol requirements exceed the status limit")
            self.buffer.value = encoded
            self.last_read = stored
        finally:
            self.buffer.get_lock().release()

    def publish(self, requirements, height=None):
        now = time.time()
        fields = {
            "requirements": requirements,
            "last_checked": now,
            "last_successful_check": now,
            "metadata_error": None,
            "height": height,
        }
        status, selected = evaluate(fields, height)
        if height is not None and status["status"] == "incompatible":
            fields["blocked"] = selected
        self.update(fields)

    def unavailable(self):
        self.update({"last_checked": time.time(), "metadata_error": "metadata_unavailable"})

    def summary(self, height=None):
        return evaluate(self.read(), height)[0]

    def require_supported(self, height):
        status, selected = evaluate(self.read(), height)
        if status["status"] == "unknown":
            raise exceptions.VersionCheckError("Protocol status has not been verified")
        if status["status"] == "incompatible":
            try:
                self.update({"blocked": selected})
            except exceptions.VersionCheckError:
                # Latching is best effort: the barrier applies to this call
                # either way and must not surface as a metadata failure.
                pass
            raise exceptions.VersionUpdateRequiredError(
                f"Protocol upgrade required: {selected['change_name']} activates at block "
                f"{selected['activation_height']}; install v{status['required_version']} or newer."
            )


def configure(state):
    global _state  # noqa: PLW0603  # pylint: disable=global-statement
    _state = state


def current():
    return _state


def summary(height=None):
    if height is None:
        height = max(
            CurrentState().current_block_count() or 0, CurrentState().current_block_index() or 0
        )
    return evaluate(_state.read() if _state is not None else {}, height)[0]


def error(status):
    return {
        "incompatible": "protocol_upgrade_required",
        "unknown": "protocol_status_unknown",
    }.get(status["status"])


def can_serve(height=None):
    return error(summary(height)) is None


def require_supported(height):
    # Offline reparse/test tools do not start the server's background monitor.
    # Their existing local protocol/consensus checks remain unchanged.
    if _state is not None:
        _state.require_supported(height)
