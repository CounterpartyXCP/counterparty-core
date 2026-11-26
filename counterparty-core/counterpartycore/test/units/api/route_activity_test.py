"""In-flight route diagnostics never require request URLs or affect admission."""

from concurrent.futures import ThreadPoolExecutor

from counterpartycore.lib.api.route_activity import RouteActivity


def test_tracks_only_active_registered_route_templates():
    activity = RouteActivity()
    activity.begin("/v2/addresses/<address>/balances")
    activity.begin("/v2/addresses/<address>/balances")
    activity.begin("/v2/assets/<asset>")
    assert activity.summary() == (
        ("/v2/addresses/<address>/balances", 2),
        ("/v2/assets/<asset>", 1),
    )
    activity.end("/v2/addresses/<address>/balances")
    activity.end("/v2/addresses/<address>/balances")
    assert activity.summary() == (("/v2/assets/<asset>", 1),)
    activity.end("/v2/assets/<asset>")
    assert activity.summary() == ()


def test_summary_is_bounded_and_deterministic():
    activity = RouteActivity()
    for route in ("/z", "/b", "/a", "/c"):
        activity.begin(route)
    activity.begin("/z")
    assert activity.summary(limit=2) == (("/z", 2), ("/a", 1), ("<other routes>", 2))
    assert activity.summary(limit=2) == activity.summary(limit=2)


def test_concurrent_begin_end_leaves_no_counts():
    activity = RouteActivity()

    def request():
        activity.begin("/v2/assets/<asset>")
        activity.end("/v2/assets/<asset>")

    with ThreadPoolExecutor(max_workers=20) as pool:
        list(pool.map(lambda _: request(), range(1000)))
    assert activity.summary() == ()


def test_unknown_rule_is_not_recorded():
    activity = RouteActivity()
    activity.begin(None)
    activity.end(None)
    assert activity.summary() == ()
