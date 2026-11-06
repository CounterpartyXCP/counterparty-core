"""Bounded, privacy-safe in-flight API route counts for saturation diagnostics.

Only Flask's registered rule template is passed here, never a request URL,
query string, address, credential, or client identifier. The sampler reads a
short snapshot only when the worker pool is actually saturated.
"""

import threading
from collections import Counter


class RouteActivity:
    def __init__(self):
        self._lock = threading.Lock()
        self._active = Counter()

    def begin(self, rule):
        if rule is None:
            return
        with self._lock:
            self._active[rule] += 1

    def end(self, rule):
        if rule is None:
            return
        with self._lock:
            if self._active[rule] <= 1:
                self._active.pop(rule, None)
            else:
                self._active[rule] -= 1

    def summary(self, limit=8):
        """Return deterministic top routes and a bounded remainder count."""
        with self._lock:
            ordered = sorted(self._active.items(), key=lambda item: (-item[1], item[0]))
        visible = ordered[:limit]
        remainder = sum(count for _, count in ordered[limit:])
        if remainder:
            visible.append(("<other routes>", remainder))
        return tuple(visible)
