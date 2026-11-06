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


def sample(server):
    """Return aggregate counts, or unknown on an unsupported/changing surface.

    MultiSocketServer shares a socket map between listeners. Deduplicate both
    map types by identity; never multiply the connection limit by listener count.
    Snapshot reads are approximate across the event-loop thread, not atomic.
    No socket addresses, descriptors, requests or channel contents are examined.
    """
    try:
        if isinstance(server, BaseWSGIServer):
            listeners = (server,)
        elif isinstance(server, MultiSocketServer) and type(server.map) is dict:
            listeners = tuple(
                islice(
                    (value for value in server.map.values() if isinstance(value, BaseWSGIServer)),
                    17,
                )
            )
        else:
            return None
        # The configured listeners are static. A missing/closed multi-listener
        # map or an unexpectedly large topology must not look like zero load.
        if not 1 <= len(listeners) <= 16:
            return None
        channel_maps, socket_maps, limits = {}, {}, set()
        accepting = overflow = at_limit = 0
        for listener in listeners:
            channels, sockets = listener.active_channels, listener._map
            limit = listener.adj.connection_limit
            if (
                type(channels) is not dict
                or type(sockets) is not dict
                or type(limit) is not int
                or limit <= 0
                or type(listener.accepting) is not bool
                or type(listener.in_connection_overflow) is not bool
            ):
                return None
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
    except Exception:  # diagnostics must never break serving or the health sampler
        return None
