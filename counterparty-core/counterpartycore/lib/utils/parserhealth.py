"""Cross-process progress signal for speculative mempool work only.

Confirmed parsing, idle following and startup never arm this watchdog. The API
process samples the parent's shared timestamp; its own healthy threads cannot
mask a stalled parser. Only the parser process writes this value.
"""

import time

STALL_TIMEOUT_SECONDS = 120
_progress = None


def configure(shared_progress):
    global _progress  # noqa: PLW0603  # pylint: disable=global-statement
    _progress = shared_progress


def begin():
    if _progress is not None:
        _progress.value = time.monotonic()


def progress():
    if _progress is not None and _progress.value > 0:
        _progress.value = time.monotonic()


def finish():
    if _progress is not None:
        _progress.value = 0
