"""Cached software compatibility, shared by the parser and API processes.

This is an operator upgrade guard, not transaction consensus logic. Only the
background checker fetches remote metadata; readers do no network or DB I/O.
"""

import json
import time
from multiprocessing import Array

from counterpartycore.lib import config, exceptions

CHECK_INTERVAL = 300
RETRY_INTERVAL = 60
MAX_METADATA_AGE = CHECK_INTERVAL * 2
_state = None


class ProtocolStatus:
    def __init__(self):
        # Only requirements newer than this binary are stored, not the whole
        # protocol manifest. No Manager process or DB writes are necessary.
        self.buffer = Array("c", 32768)

    def read(self):
        if not self.buffer.get_lock().acquire(timeout=0.1):
            return None
        try:
            value = self.buffer.value
            return json.loads(value) if value else {}
        finally:
            self.buffer.get_lock().release()

    def update(self, fields):
        if not self.buffer.get_lock().acquire(timeout=0.1):
            raise exceptions.VersionCheckError("Protocol status is unavailable")
        try:
            value = self.buffer.value
            current = json.loads(value) if value else {}
            # Read/modify/write under one lock: a refresh must never erase a
            # parser's concurrently recorded activation barrier.
            current.update(fields)
            encoded = json.dumps(current).encode()
            if len(encoded) >= len(self.buffer):
                raise exceptions.VersionCheckError("Protocol requirements exceed the status limit")
            self.buffer.value = encoded
        finally:
            self.buffer.get_lock().release()

    def publish(self, requirements, height=None):
        now = time.time()
        self.update(
            {
                "requirements": requirements,
                "last_checked": now,
                "last_successful_check": now,
                "metadata_error": None,
                "height": height,
            }
        )

    def unavailable(self):
        self.update({"last_checked": time.time(), "metadata_error": "metadata_unavailable"})

    def summary(self, height=None):
        cached = self.read()
        if cached is None:
            cached = {"metadata_error": "state_unavailable"}
        requirements = cached.get("requirements", [])
        height = max(height or 0, cached.get("height") or 0)
        active = [
            entry
            for entry in requirements
            if height is not None and height >= entry["activation_height"]
        ]
        blocked = cached.get("blocked")
        if blocked is not None:
            active.append(blocked)
        # Report the strongest active requirement, otherwise the next upgrade.
        selected = (
            max(active, key=lambda entry: entry["version"])
            if active
            else (
                min(requirements, key=lambda entry: entry["activation_height"])
                if requirements
                else None
            )
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
        if getattr(config, "FORCE", False):
            status = "bypassed"
        return {
            "status": status,
            "required_version": ".".join(map(str, selected["version"])) if selected else None,
            "activation_height": selected["activation_height"] if selected else None,
            "change_name": selected["change_name"] if selected else None,
            "last_checked": cached.get("last_checked"),
            "last_successful_check": checked,
            "metadata_error": cached.get("metadata_error"),
            "force_override": bool(getattr(config, "FORCE", False)),
        }

    def require_supported(self, height):
        if getattr(config, "FORCE", False):
            return
        cached = self.read()
        if cached is None or "last_successful_check" not in cached:
            raise exceptions.VersionCheckError("Protocol status has not been verified")
        active = [
            entry
            for entry in cached.get("requirements", [])
            if height >= entry["activation_height"]
        ]
        if cached.get("blocked"):
            active.append(cached["blocked"])
        if active:
            selected = max(active, key=lambda entry: entry["version"])
            self.update({"blocked": selected})
            version = ".".join(map(str, selected["version"]))
            raise exceptions.VersionUpdateRequiredError(
                f"Protocol upgrade required: {selected['change_name']} activates at block "
                f"{selected['activation_height']}; install v{version} or newer."
            )


def configure(state):
    global _state  # noqa: PLW0603
    _state = state


def current():
    return _state


def summary(height=None):
    if _state is not None:
        return _state.summary(height)
    return {
        "status": "bypassed" if getattr(config, "FORCE", False) else "unknown",
        "required_version": None,
        "activation_height": None,
        "change_name": None,
        "last_checked": None,
        "last_successful_check": None,
        "metadata_error": None,
        "force_override": bool(getattr(config, "FORCE", False)),
    }


def can_serve(height=None):
    return summary(height)["status"] not in ("incompatible", "unknown")


def require_supported(height):
    # Offline reparse/test tools do not start the server's background monitor.
    # Their existing local protocol/consensus checks remain unchanged.
    if _state is not None:
        _state.require_supported(height)
