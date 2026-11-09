"""Best-effort Waitress admission observations; never used for health decisions.

Waitress 3.0.1 compares the *socket map*, not active requests or worker count,
with connection_limit. Its accepting flag and latched overflow flag are distinct
from that comparison. Reading them must not call readable(), which mutates the
listener and can run channel maintenance.
"""

from dataclasses import dataclass
from itertools import islice
from typing import Optional

from waitress.server import BaseWSGIServer, MultiSocketServer

# Waitress creates one listener per configured address at startup; more than
# this is not a topology we know how to aggregate, so it reports unknown.
MAX_LISTENERS = 16


@dataclass(frozen=True)
class AdmissionMetrics:
    listeners: int
    accepted_channels: int
    socket_map_entries: int
    connection_limit: int  # common configured threshold, NOT summed capacity
    accepting_listeners: int
    overflow_listeners: int
    at_limit_listeners: int
    peak_accepted_channels: Optional[int] = None
    peak_socket_map_entries: Optional[int] = None
    overflow_observed: bool = False


def _is_int(value):
    # bool is an int subclass: a ``True`` limit must not read as a limit of 1.
    return isinstance(value, int) and not isinstance(value, bool)


def _listeners(server):
    """Return the Waitress listeners behind ``server``, or None if unsupported."""
    if isinstance(server, BaseWSGIServer):
        return (server,)
    if isinstance(server, MultiSocketServer) and isinstance(server.map, dict):
        return tuple(
            islice(
                (value for value in server.map.values() if isinstance(value, BaseWSGIServer)),
                MAX_LISTENERS + 1,
            )
        )
    return None


def _listener_state(listener):
    """Return ``(channels, sockets, limit)`` for one listener, or None when its
    introspection surface is not the one Waitress 3.0.1 exposes."""
    channels = listener.active_channels
    # Waitress has no public accessor for the socket map that readable()
    # compares with connection_limit, and calling readable() would mutate it.
    sockets = listener._map  # pylint: disable=protected-access
    limit = listener.adj.connection_limit
    if not (isinstance(channels, dict) and isinstance(sockets, dict)):
        return None
    if not _is_int(limit) or limit <= 0:
        return None
    if not (
        isinstance(listener.accepting, bool) and isinstance(listener.in_connection_overflow, bool)
    ):
        return None
    return channels, sockets, limit


def sample(server):
    """Return aggregate counts, or unknown on an unsupported/changing surface.

    MultiSocketServer shares a socket map between listeners. Deduplicate both
    map types by identity; never multiply the connection limit by listener count.
    Snapshot reads are approximate across the event-loop thread, not atomic.
    No socket addresses, descriptors, requests or channel contents are examined.
    """
    try:
        listeners = _listeners(server)
        # The configured listeners are static. A missing/closed multi-listener
        # map or an unexpectedly large topology must not look like zero load.
        if listeners is None or not 1 <= len(listeners) <= MAX_LISTENERS:
            return None
        channel_maps, socket_maps, limits = {}, {}, set()
        accepting = overflow = at_limit = 0
        for listener in listeners:
            state = _listener_state(listener)
            if state is None:
                return None
            channels, sockets, limit = state
            channel_maps[id(channels)] = len(channels)
            socket_maps[id(sockets)] = len(sockets)
            limits.add(limit)
            accepting += listener.accepting
            overflow += listener.in_connection_overflow
            at_limit += len(sockets) >= limit
        if len(limits) != 1:
            return None  # no meaningful common threshold; do not invent one
        return AdmissionMetrics(
            listeners=len(listeners),
            accepted_channels=sum(channel_maps.values()),
            socket_map_entries=sum(socket_maps.values()),
            connection_limit=limits.pop(),
            accepting_listeners=accepting,
            overflow_listeners=overflow,
            at_limit_listeners=at_limit,
        )
    except Exception:  # pylint: disable=broad-except
        # Diagnostics must never break serving or the health sampler.
        return None
